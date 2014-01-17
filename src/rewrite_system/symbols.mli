open Ast

val add : string * info * rewriting_declaration -> unit

val lookup_kind : string -> info * kind
val lookup_const : string -> info * constant
val lookup_op : string -> info * operator
val lookup_rule : string -> info * rule
