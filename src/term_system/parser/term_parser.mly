%{
(* Distributed under the MIT License.
  (See accompanying file LICENSE.txt)
  (C) Copyright Matthieu Dien
  (C) Copyright Vincent Botbol
*)

  open Parsing
  open Lexing
  (* open Rewriting_ast *)
  open Term_ast

  let err_msg = fun kwd name msg ->
    let pos = Parsing.symbol_start_pos () in
    kwd ^ " \"" ^ name ^"\" " ^ msg ^ " line \
    " ^ (string_of_int (pos.Lexing.pos_lnum)) ^ ", col \
    " ^ (string_of_int (pos.Lexing.pos_cnum - pos.Lexing.pos_bol))

  let annote_pos item = 
    let pos = Parsing.symbol_start_pos () in
    { value = item ; info = pos }

%}

/* values */
%token <float> NUM
%token <string> IDENT
%token <string> VARIDENT

/* punctuation */
%token LPAREN RPAREN LBRACKET RBRACKET COMMA NEWLINE SEMICOL

%token EOF

%start start
%type <Lexing.position Term_ast.expression> start

%start toplevel_phrase
%type <Lexing.position Term_ast.expression> toplevel_phrase


%%

start:
| expression EOF { $1 }

toplevel_phrase:
| expression SEMICOL SEMICOL { $1 }
| EOF { raise End_of_file }

expression:
| IDENT LPAREN LBRACKET VARIDENT RBRACKET COMMA expression_params RPAREN 
  { annote_pos @@ Abstraction($1, $4, $7) }
| IDENT LPAREN expression_params RPAREN 
  { annote_pos @@ Call($1, $3) }
| IDENT { annote_pos @@ Const($1) }
| VARIDENT { annote_pos @@ Var($1) }

expression_params:
| expression { [$1] }
| expression COMMA expression_params { $1::$3 }
%%