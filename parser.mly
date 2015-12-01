%token <Symbol.t> IDENT
%token <int> INT
%token ARROW
%token FUN

%token EOF
%token LPAR
%token RPAR
%token LBRACE
%token RBRACE
%token LBRACK
%token RBRACK
%token COMMA
%token SEMI
%token UNIT
%token TY_MEET
%token TY_JOIN
%token EQUALS
%token REC
%token LET
%token IN
%token ASC
%token DOT
%token TRUE
%token FALSE
%token IF
%token THEN
%token ELSE

%token EQEQUALS
%token CMP_LT
%token CMP_GT
%token CMP_LTE
%token CMP_GTE
%token OP_ADD
%token OP_SUB

%token CONS
%token MATCH
%token WITH
%token LIST

%token SUBSUME
%token TOP
%token BOT

%right EQUALS
%right ARROW
%right TY_MEET
%right TY_JOIN

%nonassoc EQEQUALS
%nonassoc CMP_LT
%nonassoc CMP_GT
%nonassoc CMP_LTE
%nonassoc CMP_GTE
%left OP_ADD
%left OP_SUB
%right CONS

%{
  open Types 
  open Typecheck
  open Exp
  open Location
%}

%start <Exp.exp> prog
%start <(Symbol.t * Exp.exp) list> modlist
%start <Types.var Types.typeterm> onlytype
%start <Types.var Types.typeterm * Types.var Types.typeterm> subsumption


%%

prog:
| e = exp; EOF { e }

modlist:
| EOF { [] }
| LET; v = IDENT; EQUALS; e = exp; m = modlist; { (v,e) :: m }
| LET; ve = exp_rec; m = modlist; { ve :: m }

exp_rec:
| REC; v = IDENT; EQUALS; e = exp
    { v , (Pos ($startpos(v), $endpos), Rec(v, e)) }

exp_r:
| FUN; v = IDENT; ARROW; e = exp 
    { Lambda (v, e) }
| LET; v = IDENT; EQUALS; e1 = exp; IN; e2 = exp
    { Let (v, e1, e2) }
| LET; ve1 = exp_rec; IN; e2 = exp
    { let (v, e1) = ve1 in Let (v, e1, e2) }
| IF; cond = exp; THEN; tcase = exp; ELSE; fcase = exp
    { If (cond, tcase, fcase) }
| MATCH; e = term; WITH; 
    LBRACK; RBRACK; ARROW; n = exp; 
    TY_JOIN; x = IDENT; CONS; xs = IDENT; ARROW; c = exp
    { Match (e, n, x, xs, c) }
| e = simple_exp_r
    { e }

exp:
| e = exp_r
    { (Pos ($startpos, $endpos), e) }

simple_exp_r:
| e1 = simple_exp; op = binop; e2 = simple_exp
    { App((Pos ($startpos(e1), $endpos(op)), App((Pos ($startpos(op), $endpos(op)), Var (Symbol.intern op)), e1)), e2) }
| x = app; CONS; xs = simple_exp
    { Cons(x, xs) }
| e = app_r
    { e }

simple_exp:
| e = simple_exp_r
    { (Pos ($startpos, $endpos), e) }

%inline binop:
| EQUALS   { "(=)" }
| EQEQUALS { "(==)" }
| CMP_LT   { "(<)" }
| CMP_GT   { "(>)" }
| CMP_LTE  { "(<=)" }
| CMP_GTE  { "(>=)" }
| OP_ADD   { "(+)" }
| OP_SUB   { "(-)" }

app_r:
| t = term_r
    { t }
| f = app; x = term
    { App (f, x) }

app:
| e = app_r
    { (Pos ($startpos, $endpos), e) }

term_r:
| v = IDENT 
    { Var v }
| LPAR; e = exp_r; RPAR
    { e }
| LPAR; e = exp; ASC; t = typeterm; RPAR
    { Ascription (e, t) }
| LPAR; RPAR
    { Unit }
| LBRACE; o = obj; RBRACE
    { Object o }
| LBRACK; RBRACK
    { Nil }
| LBRACK; e = nonemptylist_r; RBRACK
    { e }
| e = term; DOT; f = IDENT
    { GetField (e, f) }
| i = INT
    { Int i }
| TRUE
    { Bool true }
| FALSE
    { Bool false }

term:
| t = term_r
    { (Pos ($startpos, $endpos), t) }

obj:
| v = IDENT; EQUALS; e = exp
    { [v, e] }
| v = IDENT; EQUALS; e = exp; SEMI; o = obj
    { (v, e) :: o }

nonemptylist_r:
| x = exp
    { Cons(x, (let (l, _) = x in l, Nil)) }
| x = exp; SEMI; xs = nonemptylist
    { Cons(x, xs) }

nonemptylist:
| e = nonemptylist_r
    { (Pos ($startpos, $endpos), e) }

subsumption:
| t1 = typeterm; SUBSUME; t2 = typeterm; EOF { (t1, t2) }

onlytype:
| t = typeterm; EOF { t }


typeterm:
| v = IDENT { TVar (Symbol.to_string v) }
| t1 = typeterm; ARROW ; t2 = typeterm  { ty_fun t1 t2 }
| TOP { ty_zero }
| BOT { ty_zero }
| LPAR; t = typeterm; LIST; RPAR { ty_list t }
| UNIT { ty_base (Symbol.intern "unit") }
| t1 = typeterm; meetjoin; t2 = typeterm { TAdd (t1, t2) } %prec TY_MEET
| REC; v = IDENT; EQUALS; t = typeterm { TRec (Symbol.to_string v, t) }
| LPAR; t = typeterm; RPAR { t }

%inline meetjoin : TY_MEET | TY_JOIN {}

(*
prog:
  | v = value { Some v }
  | EOF       { None   } ;

value:
  | LEFT_BRACE; obj = obj_fields; RIGHT_BRACE { `Assoc obj  }
  | LEFT_BRACK; vl = list_fields; RIGHT_BRACK { `List vl    }
  | s = STRING                                { `String s   }
  | i = INT                                   { `Int i      }
  | x = FLOAT                                 { `Float x    }
  | TRUE                                      { `Bool true  }
  | FALSE                                     { `Bool false }
  | NULL                                      { `Null       } ;

obj_fields:
    obj = separated_list(COMMA, obj_field)    { obj } ;

obj_field:
    k = STRING; COLON; v = value              { (k, v) } ;

list_fields:
    vl = separated_list(COMMA, value)         { vl } ;
*)
