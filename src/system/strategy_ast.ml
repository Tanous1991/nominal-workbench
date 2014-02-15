type strategy = 
  | SId
  | SFail
  | STest of strategy
  | SNot of strategy
  | SAll of strategy
  | SSome of strategy
  | SOne of strategy
  | SProj of int * strategy
  | SSeq of strategy * strategy
  | SEither of strategy * strategy
  | SRec of string * strategy
  | SVar of string
  | SRule of string option
  | SCall of string * strategy list

type strategy_def = string list * strategy 

let try_app s = SEither(s, SId)
let repeat s = SRec("x", SSeq(try_app s, SVar("x")))
let topdown s = SRec("x", SSeq(s, SAll(SVar("x"))))
let bottomup s = SRec("x", SSeq(SAll(SVar("x")), s))
let any_rule = SRule(None)

let strategy_def_of_fun f = 
  let var = "_s" in
  ([var], f @@ SVar(var))

let rec string_of_strategy = function
  | SId -> "id"
  | SFail -> "fail"
  | SSeq(s1, s2) -> 
    (string_of_strategy s1) ^ "; " ^ (string_of_strategy s2)
  | SEither(s1, s2) ->
    (string_of_strategy s1) ^ " +> " ^ (string_of_strategy s2)
  | SRec(var, s) -> "rec(" ^ var ^ ", " ^ (string_of_strategy s) ^ ")"
  | STest(s) -> "test(" ^ (string_of_strategy s) ^ ")"
  | SNot(s) -> "not(" ^ (string_of_strategy s) ^ ")"
  | SVar(name) -> name
  | SRule(Some(name)) -> "rule(" ^ name ^ ")"
  | SRule(None) -> "rule()"
  | SAll(s) -> "all(" ^ (string_of_strategy s) ^ ")"
  | SSome(s) -> "some(" ^ (string_of_strategy s) ^ ")"
  | SOne(s) -> "one(" ^ (string_of_strategy s) ^ ")"
  | SProj(i, s) -> "proj(" ^ (string_of_int i) ^ ", " ^ (string_of_strategy s) ^ ")"
  | SCall(name, params) -> 
    let params = List.map string_of_strategy params in
    name ^ "(" ^ (String.concat "," params) ^ ")"

let base_strat name content =
  match name with
  | "test" -> STest content
  | "not" -> SNot content
  | "all" -> SAll content
  | "some" -> SSome content
  | "one" -> SOne content
  | _ -> assert false

let base_strat_simple = function
  | "id" -> SId
  | "fail" -> SFail
  | _ -> assert false
