(* This file is part of the Catala compiler, a specification language for tax
   and social benefits computation rules. Copyright (C) 2020-2022 Inria,
   contributor: Denis Merigoux <denis.merigoux@inria.fr>, Alain Delaët-Tixeuil
   <alain.delaet--tixeuil@inria.fr>, Louis Gesbert <louis.gesbert@inria.fr>

   Licensed under the Apache License, Version 2.0 (the "License"); you may not
   use this file except in compliance with the License. You may obtain a copy of
   the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
   License for the specific language governing permissions and limitations under
   the License. *)

(** Functions handling the expressions of [shared_ast] *)

open Utils
open Definitions

(** {2 Boxed constructors} *)

val box : ('a, 't) gexpr -> ('a, 't) gexpr box
val evar : ('a, 't) gexpr Var.t -> 't -> ('a, 't) gexpr box

val etuple :
  (([< dcalc | lcalc ] as 'a), 't) gexpr box list ->
  StructName.t option ->
  't ->
  ('a, 't) gexpr box

val etupleaccess :
  (([< dcalc | lcalc ] as 'a), 't) gexpr box ->
  int ->
  StructName.t option ->
  typ list ->
  't ->
  ('a, 't) gexpr box

val einj :
  (([< dcalc | lcalc ] as 'a), 't) gexpr box ->
  int ->
  EnumName.t ->
  typ list ->
  't ->
  ('a, 't) gexpr box

val ematch :
  (([< dcalc | lcalc ] as 'a), 't) gexpr box ->
  ('a, 't) gexpr box list ->
  EnumName.t ->
  't ->
  ('a, 't) gexpr box

val earray : ('a any, 't) gexpr box list -> 't -> ('a, 't) gexpr box
val elit : 'a any glit -> 't -> ('a, 't) gexpr box

val eabs :
  (('a any, 't) naked_gexpr, ('a, 't) gexpr) Bindlib.mbinder box ->
  typ list ->
  't ->
  ('a, 't) gexpr box

val eapp :
  ('a any, 't) gexpr box -> ('a, 't) gexpr box list -> 't -> ('a, 't) gexpr box

val eassert :
  (([< dcalc | lcalc ] as 'a), 't) gexpr box -> 't -> ('a, 't) gexpr box

val eop : operator -> 't -> (_ any, 't) gexpr box

val edefault :
  (([< desugared | scopelang | dcalc ] as 'a), 't) gexpr box list ->
  ('a, 't) gexpr box ->
  ('a, 't) gexpr box ->
  't ->
  ('a, 't) gexpr box

val eifthenelse :
  ('a any, 't) gexpr box ->
  ('a, 't) gexpr box ->
  ('a, 't) gexpr box ->
  't ->
  ('a, 't) gexpr box

val eerroronempty :
  (([< desugared | scopelang | dcalc ] as 'a), 't) gexpr box ->
  't ->
  ('a, 't) gexpr box

val ecatch :
  (lcalc, 't) gexpr box ->
  except ->
  (lcalc, 't) gexpr box ->
  't ->
  (lcalc, 't) gexpr box

val eraise : except -> 't -> (lcalc, 't) gexpr box

(** Manipulation of marks *)

val no_mark : 'm mark -> 'm mark
val mark_pos : 'm mark -> Pos.t
val pos : ('e, _ mark) gexpr -> Pos.t
val ty : (_, typed mark) Marked.t -> typ
val with_ty : typ -> ('a, _ mark) Marked.t -> ('a, typed mark) Marked.t
val map_mark : (Pos.t -> Pos.t) -> (typ -> typ) -> 'm mark -> 'm mark

val map_mark2 :
  (Pos.t -> Pos.t -> Pos.t) ->
  (typed -> typed -> typ) ->
  'm mark ->
  'm mark ->
  'm mark

val fold_marks :
  (Pos.t list -> Pos.t) -> (typed list -> typ) -> 'm mark list -> 'm mark

val untype : ('a, 'm mark) gexpr -> ('a, untyped mark) gexpr box

(** {2 Traversal functions} *)

val map :
  'ctx ->
  f:('ctx -> ('a, 't1) gexpr -> ('a, 't2) gexpr box) ->
  (('a, 't1) naked_gexpr, 't2) Marked.t ->
  ('a, 't2) gexpr box
(** Flat (non-recursive) mapping on expressions.

    If you want to apply a map transform to an expression, you can save up
    writing a painful match over all the cases of the AST. For instance, if you
    want to remove all errors on empty, you can write

    {[
      let remove_error_empty =
        let rec f () e =
          match Marked.unmark e with
          | ErrorOnEmpty e1 -> Expr.map () f e1
          | _ -> Expr.map () f e
        in
        f () e
    ]}

    The first argument of map_expr is an optional context that you can carry
    around during your map traversal. *)

val map_top_down :
  f:(('a, 't1) gexpr -> (('a, 't1) naked_gexpr, 't2) Marked.t) ->
  ('a, 't1) gexpr ->
  ('a, 't2) gexpr box
(** Recursively applies [f] to the nodes of the expression tree. The type
    returned by [f] is hybrid since the mark at top-level has been rewritten,
    but not yet the marks in the subtrees. *)

val map_marks : f:('t1 -> 't2) -> ('a, 't1) gexpr -> ('a, 't2) gexpr box

(** {2 Expression building helpers} *)

val make_var : ('a, 't) gexpr Var.t * 'b -> (('a, 't) naked_gexpr * 'b) box

val make_abs :
  ('a, 't) gexpr Var.vars ->
  ('a, 't) gexpr box ->
  typ list ->
  't ->
  ('a, 't) gexpr box

val make_app :
  ('a any, 'm mark) gexpr box ->
  ('a, 'm mark) gexpr box list ->
  'm mark ->
  ('a, 'm mark) gexpr box

val empty_thunked_term :
  'm mark -> ([< dcalc | desugared | scopelang ], 'm mark) gexpr

val make_let_in :
  ('a, 'm mark) gexpr Var.t ->
  typ ->
  ('a, 'm mark) gexpr box ->
  ('a, 'm mark) gexpr box ->
  Utils.Pos.t ->
  ('a, 'm mark) gexpr box

val make_multiple_let_in :
  ('a, 'm mark) gexpr Var.vars ->
  typ list ->
  ('a, 'm mark) gexpr box list ->
  ('a, 'm mark) gexpr box ->
  Pos.t ->
  ('a, 'm mark) gexpr box

val make_default :
  (([< desugared | scopelang | dcalc ] as 'a), 't) gexpr list ->
  ('a, 't) gexpr ->
  ('a, 't) gexpr ->
  't ->
  ('a, 't) gexpr
(** [make_default ?pos exceptions just cons] builds a term semantically
    equivalent to [<exceptions | just :- cons>] (the [EDefault] constructor)
    while avoiding redundant nested constructions. The position is extracted
    from [just] by default.

    Note that, due to the simplifications taking place, the result might not be
    of the form [EDefault]:

    - [<true :- x>] is rewritten as [x]
    - [<ex | true :- def>], when [def] is a default term [<j :- c>] without
      exceptions, is collapsed into [<ex | def>]
    - [<ex | false :- _>], when [ex] is a single exception, is rewritten as [ex] *)

(** {2 Transformations} *)

val remove_logging_calls : ('a any, 't) gexpr -> ('a, 't) gexpr box
(** Removes all calls to [Log] unary operators in the AST, replacing them by
    their argument. *)

val format :
  ?debug:bool (** [true] for debug printing *) ->
  decl_ctx ->
  Format.formatter ->
  (_, _ mark) gexpr ->
  unit

(** {2 Analysis and tests} *)

val equal_lit : 'a glit -> 'a glit -> bool
val compare_lit : 'a glit -> 'a glit -> int
val equal_location : 'a glocation Marked.pos -> 'a glocation Marked.pos -> bool
val compare_location : 'a glocation Marked.pos -> 'a glocation Marked.pos -> int

val equal : ('a, 't) gexpr -> ('a, 't) gexpr -> bool
(** Determines if two expressions are equal, omitting their position information *)

val compare : ('a, 't) gexpr -> ('a, 't) gexpr -> int
(** Standard comparison function, suitable for e.g. [Set.Make]. Ignores position
    information *)

val compare_typ : typ -> typ -> int
val is_value : ('a any, 't) gexpr -> bool
val free_vars : ('a any, 't) gexpr -> ('a, 't) gexpr Var.Set.t

val size : ('a, 't) gexpr -> int
(** Used by the optimizer to know when to stop *)