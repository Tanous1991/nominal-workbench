open Term_ast_dag
open Term_ast_hashconsed

let create_tests () =
  Format.printf "Create tests@.";
  (* Testing for Const *)

  let c1 = DConst "A" in
  let c2 = DConst "B" in
  let c3 = DConst "B" in

  let hc1 = create_term c1 in
  let hc2 = create_term c2 in
  let hc3 = create_term c3 in

  assert (not (hc1.term == hc2.term));
  assert (hc2.term == hc3.term);

  Format.printf "Const OK@.";

  (* Testing for FreeVars *)

  let fv1 = DVar "v" in
  let fv2 = DVar "u" in
  let fv3 = DVar "v" in

  let hfv1 = create_term fv1 in
  let hfv2 = create_term fv2 in
  let hfv3 = create_term fv3 in

  assert (not (hfv1.term == hfv2.term));
  assert (hfv1.term == hfv3.term);

  Format.printf "FreeVars OK@.";

  (* Testing for Vars *)

  let b1 = DBinder "a"in
  let b2 = DBinder "b" in
  let v1 = DVar "a" in
  let v2 = DVar "b" in
  let v3 = DVar "b" in

  (* We have to encapsulate the binders and variables into lsits to have a
    correctly binded term *)

  let l1 = [b1; b1; b2; v1; v2; v3] in
  let l2 = [b1; b1; b2; v1; v2; v3] in

  let hl1, _ = create_hlist [] [] l1 in
  let hl2, _ = create_hlist [] [] l2 in

  List.iter2 (fun t1 t2 ->
      match t1.value, t2.value with
      | HBinder b1, HBinder b2 -> assert (b1 == b2)
      | _ -> ()
    ) hl1 hl2;

  assert(hl1 == hl2);

  Format.printf "Binded variables OK@.";

  (* We now test term creation, since other constructs and lists can be
     correctly hashconsed. *)
  (* We suppose a system with constants A and B which are Naturals and addition
     on it.
     Two operators :
     - Bind : [Variable] * Nat -> Nat
     - Add : Nat * Nat -> Nat
  *)

  let add1 = DTerm ("Add", [v1; c1]) in
  let t1 = DTerm ("Bind", [b1; add1]) in

  let add2 = DTerm ("Add", [v2; c1]) in
  let t2 = DTerm ("Bind", [b2; add2]) in

  let ht1 = create_term t1 in
  let ht2 = create_term t2 in

  assert (ht1.term == ht2.term);
  Format.printf "Terms OK@."

let peano_tests () =
  (* Tests with more complex terms *)

  (* We now suppose the Peano system
     Only one constant : Zero, and two operators : Successor and Add.
     There is no binders in this system.
  *)

  let zero = DConst "Zero" in
  let one = DTerm ("Successor", [zero]) in
  let one2 = DTerm ("Successor", [zero]) in

  let add1 = DTerm ("Add", [one; one]) in
  let add2 = DTerm ("Add", [one; one2]) in
  let add3 = DTerm ("Add", [one2; one]) in
  let add4 = DTerm ("Add", [one2; one2]) in

  let ha1 = create_term add1 in
  let ha2 = create_term add2 in
  let ha3 = create_term add3 in
  let ha4 = create_term add4 in

  assert(ha1.term == ha2.term);
  assert(ha2.term == ha3.term);
  assert(ha3.term == ha4.term);

  Format.printf "Peano OK@."

let lambda_tests () =
  (* The lambda calculus uses binders, it can be more tricky.
     There is no constant, but variables (free or not).
     We have four operators :
     - Var : Variable -> Term
     - App : Term * Term -> Term
     - Lambda : [Variable]. Term -> Term
     - Subst : [Variable]. Term * Term -> Term
  *)


  (* First, we try on two identical id functions, modulo apha-conversion *)
  let bx = DBinder "x" in
  let id1 = DTerm ("Lambda", [bx; DVar "x"]) in
  let by = DBinder "y" in
  let id2 = DTerm ("Lambda", [by; DVar "y"]) in

  let hid1 = create_term id1 in
  let hid2 = create_term id2 in

  assert (hid1.term == hid2.term);

  (* Term for getting the second element of a pair in lambda calculus, which is
  also the encoding for "false". *)
  let lsnd = DTerm ("Lambda",
                   [bx; DTerm ("Lambda", [by; DVar "y"])]) in
  let hsnd = create_term lsnd in

  (* We open the term and get the second lambda, which is basically id *)
  let hid3 = match hsnd.term with
    | HTerm (_, hl) ->
      (List.hd @@ List.tl hl).value
    | _ -> assert false in

  (* pretty_print hid2; *)
  (* pretty_print hid3; *)

  (* dot hsnd "graphsnd.dot"; *)

  assert (hid2.term == hid3);

  (* let app = DTerm ("App", [id1; id2]) in *)
  (* let happ = create_term app in *)
  (* dot happ "graphapp.dot" *)

  Format.printf "Lambda calculs OK@."

let naming_tests () =
  (* Tests the naming capture, to be able to recreate a term_dag after
     hashconsing it. We reuse some previously defined terms, especially in the
     lambda calculus examples.  *)

  let bx = DBinder "x" in
  let id1 = DTerm ("Lambda", [bx; DVar "x"]) in
  let by = DBinder "y" in
  let id2 = DTerm ("Lambda", [by; DVar "y"]) in
  let bz = DBinder "z" in
  let id3 = DTerm ("Lambda", [bz; DVar "z"]) in

  let lsnd = DTerm ("Lambda",
                    [bx; DTerm ("Lambda", [by; DVar "y"])]) in

  let hsnd = create_term lsnd in

  (* pretty_print hsnd; *)
  (* Format.printf "[%s]@." @@ String.concat ", " hsnd_names; *)

  assert (hsnd.binders = ["x"; "y"]);

  let app = DTerm ("App", [lsnd; id3]) in
  let happ = create_term app in

  (* pretty_print happ; *)
  (* Format.printf "[%s]@." @@ String.concat ", " happ_names; *)
  (* dot happ "happgraph.dot"; *)

  assert (happ.binders = ["x"; "y"; "z"]);

  Format.printf "Binders names OK@."

let reconstruct_tests () =
  (* Tests the reconstruction of the hterms into terms
     *)

  let bx = DBinder "x" in
  let id1 = DTerm ("Lambda", [bx; DVar "x"]) in
  let by = DBinder "y" in
  let id2 = DTerm ("Lambda", [by; DVar "y"]) in
  let bz = DBinder "z" in
  let id3 = DTerm ("Lambda", [bz; DVar "z"]) in

  let lsnd = DTerm ("Lambda",
                    [bx; DTerm ("Lambda", [by; DVar "y"])]) in
  let hsnd = create_term lsnd in

  let snd = create_dterm hsnd in
  (* Format.printf "Before: %s@." @@ string_of_term lsnd; *)
  (* Format.printf "After: %s@." @@ string_of_term snd; *)

  assert (lsnd = snd);

  let app = DTerm ("App", [lsnd; id3]) in
  let happ = create_term app in
  let recr_app = create_dterm happ in

  (* Format.printf "Before: %s@." @@ string_of_term app; *)
  (* Format.printf "After: %s@." @@ string_of_term recr_app; *)

  assert (app = recr_app);

  Format.printf "Term reconstruction OK@."


let _ =
  create_tests ();
  peano_tests ();
  lambda_tests ();
  naming_tests ();
  reconstruct_tests ()