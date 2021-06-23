(**************************************************************)
(*   Copyright Dominique Larchey-Wendling [*]                 *)
(*                                                            *)
(*                             [*] Affiliation LORIA -- CNRS  *)
(**************************************************************)
(*      This file is distributed under the terms of the       *)
(*         CeCILL v2 FREE SOFTWARE LICENSE AGREEMENT          *)
(**************************************************************)

(* Certified Undecidability of Intuitionistic Linear Logic via Binary Stack Machines and Minsky Machines. Yannick Forster and Dominique Larchey-Wendling. CPP '19. http://uds-psl.github.io/ill-undecidability/ *)

Require Import List Bool.

From Undecidability.Shared.Libs.DLW 
  Require Import list_bool pos vec.

(** * Halting problem for binary stack machines BSM_HALTING  *)

(* * Binary Stack Machines
   Binary stack machines have n stacks and there are just two instructions
  
   1/ POP s p q : pops the value on stack s and
                  if Empty then jumps to q 
                  if Zero then jumps to p
                  if One then jumps to next instruction,
   2/ PUSH s b : pushes the value b on stack s and jumps to next instructions 

 *)

Inductive bsm_instr n : Set :=
  | bsm_pop  : pos n -> nat -> nat -> bsm_instr n
  | bsm_push : pos n -> bool -> bsm_instr n
  .

(* ** Semantics for BSM *)

Section Binary_Stack_Machine.

  Variable (n : nat).

  Notation POP  := (bsm_pop n).
  Notation PUSH := (bsm_push n).

  Local Notation "e #> x" := (vec_pos e x).
  Local Notation "e [ x := v ]" := (vec_change e x v) (no associativity, at level 50).

  Local Reserved Notation "P // e ▷ v" (at level 50, no associativity).

  Inductive eval : nat * list (bsm_instr n) -> (nat*vec (list bool) n) -> (nat*vec (list bool) n) -> Prop :=
  | eval_bsm_out i P c v :
      c < i \/ i + length P <= c ->
  (* ---------------------------- *)
      (i,P) // (c, v) ▷ (c, v)
  | eval_bsm_push i P c v j b c' v' :
      c >= i -> nth_error P (c - i) = Some (PUSH j b) ->
      (i, P) // (c + 1, v[j := b :: v #> j]) ▷ (c', v') ->
  (* -------------------------------------------------- *)
     (i,P) // (c, v) ▷ (c', v')
  | eval_bsm_pop_true i P c v j c1 c2 c' v' l :
      c >= i -> nth_error P (c - i) = Some (POP j c1 c2) ->
      v #> j = true :: l -> (i, P) // (c +1, v [j := l]) ▷ (c',v') ->
  (* -------------------------------------------------- *)
      (i,P) // (c, v) ▷ (c', v')

  | eval_bsm_pop_false i P c v j c1 c2 c' v' l :
      c >= i -> nth_error P (c - i) = Some (POP j c1 c2) ->
      v #> j = false :: l -> (i, P) // (c1, v [j := l]) ▷ (c',v') ->
  (* -------------------------------------------------- *)
      (i,P) // (c, v) ▷ (c', v')
  | eval_bsm_pop_empty i P c v j c1 c2 c' v' :
      c >= i -> nth_error P (c - i) = Some (POP j c1 c2) ->
      v #> j = nil -> (i, P) // (c2, v) ▷ (c',v') ->
  (* -------------------------------------------------- *)
      (i,P) // (c, v) ▷ (c', v')

  where "P // e ▷ v" := (eval P e v).

End Binary_Stack_Machine.

(* The Halting problem for BSM *)
  
Definition Halt_BSM :
  { n : nat & { i : nat & { P : list (bsm_instr n) & vec (list bool) n } } } -> Prop:=
  fun '(existT _ n (existT _ i (existT _ P v))) => exists c' v', eval n (i,P) (i,v) (c', v').
