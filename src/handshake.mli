open Hardcaml

module IO : sig
  type 'd t =
    { data : 'd
    ; ack : Signal.t
    }
end

type ('a, 'b) t

(** An identity arrow. Purely combinational and does nothing. *)
val id : ('a, 'a) t

(** Creates a handshake component with an explicit custom ack signal.

    This function should be used to use regular hardcaml components within the handshake
    framework. *)
val component : ('a IO.t -> 'b IO.t) -> ('a, 'b) t

(** Creates a handshake arrow from a regular OCaml function.

    This is useful for combinational logic that requires no ack signals. *)
val arr : ('a -> 'b) -> ('a, 'b) t

(** [>>> a b] composes two handshake components together. *)
val ( >>> ) : ('a, 'b) t -> ('b, 'c) t -> ('a, 'c) t

(** x[0] >>> x[1] >>> x[2] .... >>> x[n-1] *)
val of_list : ('a, 'a) t list -> ('a, 'a) t

(** Creates a chained handshake component comprising of an arbitrary number of components.
    List of components can be empty, of which no handshake pipelining will be done. *)
val run : ('a, 'b) t -> 'a IO.t -> 'b IO.t
