open Base
open Hardcaml

module IO = struct
  type 'd t =
    { data : 'd
    ; ack : Signal.t
    }
end

module Pipeline_stage = struct
  type t =
    { ack_up : Signal.t
    ; ack_dn : Signal.t
    }
end

type ('a, 'b) t =
  | Id : ('a, 'a) t
  | Compose : (('a, 'b) t * ('b, 'c) t) -> ('a, 'c) t
  | Component : ('a IO.t -> 'b IO.t) -> ('a, 'b) t

let id = Id
let ( >>> ) a b = Compose (a, b)
let of_list items = List.fold items ~init:id ~f:(fun acc x -> acc >>> x)
let component f = Component f

let build_pipeline_stages =
  let rec loop : type a b. (a, b) t -> a -> Pipeline_stage.t list * b =
    fun (type a b) (t : (a, b) t) (source : a) ->
    match t with
    | Id -> [], (source : b)
    | Compose (left, right) ->
      let left_stages, data_from_left = loop left source in
      let right_stages, data_from_right = loop right data_from_left in
      left_stages @ right_stages, data_from_right
    | Component f ->
      let ack_dn = Signal.wire 1 in
      let output = f { data = source; ack = ack_dn } in
      let this_stage = { Pipeline_stage.ack_up = output.ack; ack_dn } in
      [ this_stage ], output.data
  in
  loop
;;

let arr f = Component (fun (io : _ IO.t) -> { IO.data = f io.data; ack = io.ack })

let run (components : _ t) (io : _ IO.t) =
  let pipeline_stages, data_dn = build_pipeline_stages components io.data in
  let ack_up =
    List.fold_right pipeline_stages ~init:io.ack ~f:(fun pipeline_stage ack ->
      Signal.( <-- ) pipeline_stage.ack_dn ack;
      pipeline_stage.ack_up)
  in
  { IO.data = data_dn; ack = ack_up }
;;
