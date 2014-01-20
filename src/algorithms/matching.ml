(* Distributed under the MIT License.
  (See accompanying file LICENSE.txt)
  (C) Copyright Pierrick Couderc
*)

open Term_ast
open Rewriting_ast

(* Placeholders bindings *)
module SMap = Map.Make(String)

exception PlaceholderAlreadyDefined of string

type 'info placeholders = 'info expression SMap.t

let matching term pattern =
  let rec step term pattern placeholders =
    match term.value, pattern with
    | Abstraction (t_id, _, t_terms), POperator (p_id, p_terms)
    | Call (t_id, t_terms), POperator (p_id, p_terms) ->
      if t_id = p_id then
        List.fold_left
          (fun (matches, placeholders) (term, pattern) ->
             if matches then step term pattern placeholders
             else matches, placeholders)
          (true, placeholders)
        @@ List.combine t_terms p_terms
      else false, placeholders

    | Const t_id, PConstant p_id -> (t_id = p_id, placeholders)

    | _, PPlaceholder id ->
      (* Testing placeholder unicity at typing phase ? *)
      if SMap.mem id placeholders then raise (PlaceholderAlreadyDefined id)
      else (true, SMap.add id term placeholders)

    | _, PAny -> (true, placeholders)
    | _, _ -> (false, placeholders)
  in
  let matches, pl = step term pattern SMap.empty in
  (matches, if matches then pl else SMap.empty)