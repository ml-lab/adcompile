type qid = string
type uid = string

(* uid "X"
uid "Y"
uid "Z"

uid "XX"
uid "YY"
uid "ZZ" *)

type parid = string
(* theta1, theta2 etc  *)
type par = parid list
(* The list of parameters  *)

type evaledparid = float
type evaledpar = evaledparid list
type evalpar = par -> evaledpar
(* evaluating a list of parameters, e.g: (theta_1,theta_2)\mapsto
(0,5,0.7)  *)



type qbit =
| Qvar of qid

type qlist = qbit list




(* below: syntax for parameterized progs (\S 4.1) *)
type unitary = 
| Gate of uid * par
| OneBRot of uid * par (* e^{-i * theta/2 * X}, etc *)
| TwoBRot of uid * par 
(* e^{-i * theta/2 * X\otimes X}, etc*)
(* The above: parameterized unitary, 
  e.g U(theta_1, theta_2)*)

type com =
| Abort of qlist
| Skip of qlist
| Init of qbit
| Uapp of unitary * qlist
| Seq of com * com
| Case of qbit * com * com
| Bwhile of int * qbit * com 

let unparse_qbit qb : string =
  match qb with
  | Qvar q -> q


let rec unparse_qlist ql : string =
  match ql with
  | [] -> ""
  | q :: [] -> unparse_qbit q
  | q :: l -> 
     let uq = unparse_qbit q in
     let ul = unparse_qlist l in
     uq ^ "," ^ ul

let rec unparse_par theta : string =
   match theta with
   | [] -> ""
   | p :: [] -> p
   | p :: l ->  
      let sl = unparse_par l in
      p ^ "," ^ sl


let unparse_unitary u : string =
  match u with
  | Gate (g, t) -> 
     let st = unparse_par t in 
     g ^ "(" ^ st ^ ")"
  | OneBRot (g, t) -> 
     let st = unparse_par t in 
     g ^ "(" ^ st ^ ")"
  | TwoBRot (g, t) -> 
     let st = unparse_par t in 
     g ^ "(" ^ st ^ ")"

let rec unparse_com c : string = 
  match c with
  | Abort ql -> 
     let sql = unparse_qlist ql in
     "Abort[" ^ sql ^ "]"
  | Skip ql -> 
     let sql = unparse_qlist ql in
      "Skip[" ^ sql ^ "]"
  | Init q -> 
     let s = unparse_qbit q in 
     s ^ ":=∣0⟩"
  | Uapp (u, ql) -> 
     let su = unparse_unitary u in 
     let sql = unparse_qlist ql in 
     sql ^ ":=" ^ su ^ "[" ^ sql ^ "]"
  | Seq (c1, c2) ->
     let s1 = unparse_com c1 in
     let s2 = unparse_com c2 in
     s1 ^ "; " ^ s2
  | Case (qb, u1, u2) ->
     let q = unparse_qbit qb in
     let s1 = unparse_com u1 in
     let s2 = unparse_com u2 in
     "case M(" ^ q ^ ") = 0 then " ^ s1 ^ "else " ^ s2
  | Bwhile (num, qb, u1) ->
     let nt = Printf.sprintf "%d" num in
     let q = unparse_qbit qb in
     let s1 = unparse_com u1 in
     "while^" ^ nt ^ " M(" ^ q ^ ")= 1 do " ^ s1   
(* endof syntax for parameterized progs (\S 4.1) *)


(* below: syntax for UNparameterized progs (\S 3.1) *)

type unparunitary = 
| UnparGate of uid * evaledpar 
| UnparOneBRot of uid * evaledpar 
| UnparTwoBRot of uid * evaledpar 

(* The above:  e.g U(0.5, 0.7). *)

 type uNcom = 
| UNAbort of qlist
| UNSkip of qlist
| UNInit of qbit
| UNUapp of unparunitary * qlist
| UNSeq of uNcom * uNcom
| UNCase of qbit * uNcom * uNcom
| UNBwhile of int * qbit * uNcom 


let rec unparse_evaledpar theta : string =
   match theta with
   | [] -> ""
   | p :: [] -> Printf.sprintf "%5f" p
   | p :: l ->  
      let sl = unparse_evaledpar l in
      Printf.sprintf "%5f" p ^ "," ^ sl


let unparse_unparunitary u : string =
  match u with
  | UnparGate (g, t) -> 
     let st = unparse_evaledpar t in 
     g ^ "(" ^ st ^ ")"
  | UnparOneBRot (g, t) -> 
     let st = unparse_evaledpar t in 
     g ^ "(" ^ st ^ ")"
  | UnparTwoBRot (g, t) -> 
     let st = unparse_evaledpar t in 
     g ^ "(" ^ st ^ ")"

let rec unparse_UNcom c : string = 
  match c with
  | UNAbort ql -> 
     let sql = unparse_qlist ql in
     "Abort[" ^ sql ^ "]"
  | UNSkip ql -> 
     let sql = unparse_qlist ql in
      "Skip[" ^ sql ^ "]"
  | UNInit q -> 
     let s = unparse_qbit q in 
     s ^ ":=∣0⟩"
  | UNUapp (u, ql) -> 
     let su = unparse_unparunitary u in 
     let sql = unparse_qlist ql in 
     sql ^ ":=" ^ su ^ "[" ^ sql ^ "]"
  | UNSeq (c1, c2) ->
     let s1 = unparse_UNcom c1 in
     let s2 = unparse_UNcom c2 in
     s1 ^ "; " ^ s2
  | UNCase (qb, u1, u2) ->
     let q = unparse_qbit qb in
     let s1 = unparse_UNcom u1 in
     let s2 = unparse_UNcom u2 in
     "case M(" ^ q ^ ") = 0 then " ^ s1 ^ "else " ^ s2
  | UNBwhile (num, qb, u1) ->
     let nt = Printf.sprintf "%d" num in
     let q = unparse_qbit qb in
     let s1 = unparse_UNcom u1 in
     "while^" ^ nt ^ " M(" ^ q ^ ")= 1 do " ^ s1   
(* endof syntax for UNparameterized progs (\S 3.1) *)



(* below: syntax for non-deterministic parameterized progs (\S 5.1) *)
type underlineUnitary = 
| UnderlineGate of uid * par
| UnderlineOneBRot of uid * par
| UnderlineTwoBRot of uid * par

(* The above: parameterized unitary with non-det type (before compilation),
 e.g \underline{U(theta_1, theta_2)} *)

type underlineCom =
| UnderlineAbort of qlist
| UnderlineSkip of qlist
| UnderlineInit of qbit
| UnderlineUapp of underlineUnitary * qlist
| UnderlineSeq of underlineCom * underlineCom
| UnderlineCase of qbit * underlineCom * underlineCom
| UnderlineBwhile of int * qbit * underlineCom 
| UnderlineAdd of underlineCom * underlineCom



let unparse_UnderlineUnitary u : string =
  match u with
  | UnderlineGate (g, t) -> 
     let st = unparse_par t in 
     g ^ "(" ^ st ^ ")"
  | UnderlineOneBRot (g, t) -> 
     let st = unparse_par t in 
     g ^ "(" ^ st ^ ")"
  | UnderlineTwoBRot (g, t) -> 
     let st = unparse_par t in 
     g ^ "(" ^ st ^ ")"


let rec unparse_UnderlineCom c : string = 
  match c with
  | UnderlineAbort ql -> 
     let sql = unparse_qlist ql in
     " ___ Abort[" ^ sql ^ "] ___ "
  | UnderlineSkip ql -> 
     let sql = unparse_qlist ql in
      " ___ Skip[" ^ sql ^ "] ___ "
  | UnderlineInit q -> 
     let s = unparse_qbit q in 
     " ___ " ^ s ^ ":=∣0⟩ ___ "
  | UnderlineUapp (u, ql) -> 
     let su = unparse_UnderlineUnitary u in 
     let sql = unparse_qlist ql in 
     " ___ " ^ sql ^ ":=" ^ su ^ "[" ^ sql ^ "] ___ "
  | UnderlineSeq (c1, c2) ->
     let s1 = unparse_UnderlineCom c1 in
     let s2 = unparse_UnderlineCom c2 in
     " ___ " ^ s1 ^ "; " ^ s2 ^ " ___ "
  | UnderlineCase (qb, u1, u2) ->
     let q = unparse_qbit qb in
     let s1 = unparse_UnderlineCom u1 in
     let s2 = unparse_UnderlineCom u2 in
     " ___ case M(" ^ q ^ ") = 0 then " ^ s1 ^ "else " ^ s2 ^ " ___ "
  | UnderlineBwhile (num, qb, u1) ->
     let nt = Printf.sprintf "%d" num in
     let q = unparse_qbit qb in
     let s1 = unparse_UnderlineCom u1 in
     " ___ while^" ^ nt ^ " M(" ^ q ^ ")= 1 do " ^ s1 ^ " ___ "
  | UnderlineAdd (u1, u2) -> 
     let s1 = unparse_UnderlineCom u1 in
     let s2 = unparse_UnderlineCom u2 in
     " ___ " ^ s1 ^ "+" ^ s2 ^ " ___ "

(* Note that when printing we will have different lengths
 of the " ___ " lines and length correspond to the number
 of recursive layers. *)    
(* endof syntax for parameterized progs (\S 5.1) *)



(* Test cases: test_p2 for parameterized (\S 4.1), 
test_p3 for unparameterized (\S 3.1),
test_p4 for parameterized non-det (\S 5.1) *)

(*  let test_p1 =
  let c1 = Init (Qvar "q0") in
  let c2 = (Uapp (Gate ("H", ["theta"]), [Qvar "q0"])) in
  Seq(Seq(c1, c2), c2)  *)

let test_p2 =
  let c0 = Init (Qvar "q0") in
  let c1 = Init (Qvar "q1") in
  let c2 = (Uapp (Gate ("H", ["theta_1"]), [Qvar "q0"])) in
  let c3 = (Uapp (Gate ("CNOT", ["theta_2"]), [Qvar "q0"; Qvar "q1"])) in
  let c4 = Seq(Seq(c0, c1), Seq(c2, c3)) in
  let guard = Qvar "q3" in 
  Bwhile (2, guard, c4)     
 
  
(* let () =
  let c = test_p2 in
  (* let c = Skip in  *)
  let s = unparse_com c in
  print_endline s

Printf.sprintf "\r" *)

let test_p3 =
  let c0 = UNInit (Qvar "q0") in
  let c1 = UNInit (Qvar "q1") in
  let c2 = (UNUapp (UnparTwoBRot ("XX", [0.99]), [Qvar "q0"; Qvar "q1"])) in
  let c3 = (UNUapp (UnparOneBRot ("Y", [0.66]), [Qvar "q0"; Qvar "q1"])) in
  let c4 = UNSeq(UNSeq(c0, c3), UNSeq(c2, c1)) in
  let c5 = UNSeq(UNSeq(c2, c0), UNSeq(c1, c3)) in 
  let guard = Qvar "q3" in 
  UNCase (guard, c4, c5)

  (* let () =
  let c = test_p3 in
  (* let c = Skip in  *)
  let s = unparse_UNcom c in
  print_endline s

Printf.sprintf "\r"  *)

let test_p4 =
  let c0 = UnderlineInit (Qvar "q0") in
  let c1 = UnderlineInit (Qvar "q1") in
  let c2 = (UnderlineUapp (UnderlineOneBRot ("X", ["theta_1"]), [Qvar "q0"])) in
  let c3 = (UnderlineUapp (UnderlineTwoBRot ("YY", ["theta_2"]), [Qvar "q1"])) in
  let c4 = UnderlineSeq(c1, c2) in
  let c5 = UnderlineAdd(c0, c3) in 
  let guard = Qvar "q3" in 
  UnderlineCase (guard, c4, c5)

  let () =  
  let c2 = test_p2 in 
  let s2 = unparse_com c2 in
  print_endline s2

  let () =
  let cnextline = "\r" in 
  print_endline cnextline

  let () =  
  let c3 = test_p3 in 
  let s3 = unparse_UNcom c3 in
  print_endline s3

  let () =
  let cnextline = "\r" in 
  print_endline cnextline
  
  let () =  
  let c4 = test_p4 in 
  let s4 = unparse_UnderlineCom c4 in
  print_endline s4

  let () =
  let cnextline = "\r" in 
  print_endline cnextline


(* Code Transformation Rules (Figure 6) *)


(* First, given any normal parameterized program, we view it
as the corresponding non-det parameterized program. A func 
tranforming it naturally (i.e. takes a normal and returns a non-det0) 
is in order.*)

let normalUnitToNonDetUnit u : underlineUnitary =
  match u with 
  | Gate (u, pl) -> UnderlineGate(u, pl)
  | OneBRot (u, pl) -> UnderlineOneBRot(u, pl)
  | TwoBRot (u, pl) -> UnderlineTwoBRot(u, pl)



let rec normalToNonDet u : underlineCom =
  match u with 
  | Abort ql -> UnderlineAbort ql
  | Skip ql -> UnderlineSkip ql 
  | Init q -> UnderlineInit q
  | Uapp (u, ql) -> UnderlineUapp (normalUnitToNonDetUnit (u), ql)
  | Seq (c1, c2) -> UnderlineSeq (normalToNonDet c1, normalToNonDet c2)
  | Case (qb, u1, u2) ->
     UnderlineCase(qb, normalToNonDet u1, normalToNonDet u2)
  | Bwhile (num, qb, u1) ->
     UnderlineBwhile(num, qb, normalToNonDet u1)


let test_p5 =
  let c0 = Init (Qvar "q0") in
  let c1 = Init (Qvar "q1") in
  let c2 = (Uapp (OneBRot ("X", ["theta_1"]), [Qvar "q0"])) in
  let c3 = (Uapp (TwoBRot ("ZZ", ["theta_2"]), [Qvar "q0"; Qvar "q1"])) in
  let c4 = Seq(Seq(c0, c1), Seq(c2, c3)) in
  normalToNonDet (c4)


let () =  
  let c5 = test_p5 in 
  let s5 = unparse_UnderlineCom c5 in
  print_endline s5


let () =
  let cnextline = "\r" in 
  print_endline cnextline

(* TODO TODO: define unitary differentiation rule first, then use 
that rule in codeTransformation. *)

let rec codeTransformation u parid: underlineCom = 
match u with
| UnderlineAbort ql -> UnderlineAbort (List.append ql [Qvar "A"])
| UnderlineSkip ql -> UnderlineAbort (List.append ql [Qvar "A"])
| UnderlineInit q -> UnderlineAbort (List.append [q] [Qvar "A"]) 
| UnderlineUapp (uu, ql) -> (match uu with
  | UnderlineGate (uuu, t) -> ( match (List.mem parid t) with 
    | true -> UnderlineUapp(UnderlineGate(uuu,t), (List.append ql [Qvar "Place holder 00, change later."]))
    | false -> UnderlineAbort (List.append ql [Qvar "Place holder 01, change later."]) )
  | UnderlineOneBRot (uuu, t) -> ( match (List.mem parid t) with 
    | true -> UnderlineUapp(UnderlineGate(uuu,t), (List.append ql [Qvar "Place holder 10, change later."]))
    | false -> UnderlineAbort (List.append ql [Qvar "Place holder 11, change later."]) )
  | UnderlineTwoBRot (uuu, t) -> ( match (List.mem parid t) with 
    | true -> UnderlineUapp(UnderlineGate(uuu,t), (List.append ql [Qvar "Place holder 20, change later."]))
    | false -> UnderlineAbort (List.append ql [Qvar "Place holder 21, change later."]) )
  )
 | UnderlineAdd (u1, u2) -> UnderlineAdd (codeTransformation u1 parid,
  codeTransformation u2 parid)
 | UnderlineSeq (u1, u2) -> UnderlineAdd (UnderlineSeq (codeTransformation u1 parid,
 u2), UnderlineSeq (u1, codeTransformation u2 parid) )
 | _ -> UnderlineAbort [Qvar "Place holder, to change later."]

(* Place holder message: please Express Unitary as 
    Product of 1qb or 2qb rotations, as that's the only
    things that our rules allow. *)
(* Then it's application of code tranformation rules. the rules
should still be non-det to non-det, as the paper said.*)


let test_p6 = 
  (* let c0 = Init (Qvar "q0") in
  let c1 = Init (Qvar "q1") in
  let c2 = (Uapp (OneBRot ("X", ["theta_1"]), [Qvar "q0"])) in *)
  let c3 = (Uapp (TwoBRot ("ZZ", ["theta_2"]), [Qvar "q0"; Qvar "q1"])) in
  (* let c4 = Seq(Seq(c0, c1), Seq(c2, c3)) in *)
  (* let ndprog = normalToNonDet (c4) in *)
  let ndprog = normalToNonDet (c3) in
  let papar = "theta_1" in 
  codeTransformation ndprog papar

let () =  
  let c6 = test_p6 in 
  let s6 = unparse_UnderlineCom c6 in
  print_endline s6 

let () =
  let cnextline = "\r" in 
  print_endline cnextline

  (* TODO: We need to be assign values to parameters,
     so need a function type assign: parid -> float: done.

     We also need to define a function type mapping from parameterized
     unitary to actual unitaries, i.e.
     a function type that takes a (parameterized)unitary * assign, returns
     unparameterized unitary. This function assigns
     real values to the parameters in the parameterized unitary,
     and outputs an unparameterized unitary. The assignment is done
     in compliance with the "assign" function *)


  (*Garbage code: match (List.mem parid t2) with
    | true -> UnderlineAbort (List.append ql [Qvar "Place holder, change later."])
    | false -> UnderlineAbort (List.append ql [Qvar "Place holder, change later."])*)
