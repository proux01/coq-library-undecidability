From Undecidability Require Import ProgrammingTools.
From Undecidability Require Import CaseList WriteString. 

Module Cons_constant.
Section Fix.

  Context {Σ__X: finType} {X : Type} {cX : codable Σ__X X}.

  
  (* Local Instance retr_X : Retract Σ__X Σ := (Retract_sigList_X _). *)

  Variable (c:X).

  Definition M : pTM (sigList Σ__X)^+ unit 1 :=
      WriteString Lmove (rev (inr sigList_cons::map (fun x => inr (sigList_X x)) ((encode c))));;
      Move Lmove;;
      Write (inl START).

  Definition Rel : pRel (sigList Σ__X)^+ unit 1 :=
    ignoreParam (
        fun tin tout =>
          forall l (s0 : nat),
            tin[@Fin0] ≃(;s0) l ->
            tout[@Fin0] ≃(;s0 - size _ c - 1) c :: l
    ).

  
  Lemma Realises : M ⊨ Rel.
  Proof.
    eapply Realise_monotone.
    { unfold M. TM_Correct. eapply RealiseIn_Realise,WriteString_Sem. }
    {
      intros tin ((), tout) H. TMSimp.
      destruct H2 as (?&->&?);cbn.
      simpl_tape.
      rewrite WriteString_L_left;cbn. autorewrite with list.
      erewrite !tape_right_move_left. 
      2:{rewrite WriteString_L_current. autorewrite with list. cbn. reflexivity. }   
      rewrite WriteString_L_right. cbn.
      eexists. repeat (cbn;autorewrite with list;try rewrite !map_map).
      split. reflexivity.
      rewrite tl_length,List.skipn_length. unfold size. nia.
    }
  Qed.

  Definition time {sigX X : Type} {cX : codable sigX X} := 5 + 2 * size _ c.

  Lemma Terminates :
    projT1 M ↓
           (fun tin k =>
              exists (l: list X) ,
                tin[@Fin0] ≃ l /\
                time <= k).
  Proof.
    unfold Constr_cons_steps. eapply TerminatesIn_monotone.
    { unfold M. TM_Correct.
      eapply RealiseIn_Realise. 2:eapply RealiseIn_TerminatesIn.
      all:apply WriteString_Sem.
    }
    {
      intros tin k (l&Hin&Hk). cbn. autorewrite with list.
      infTer 4.
      2:{
        intros. infTer 4. intros. reflexivity.   
      }
      cbn. unfold time,size in Hk. nia.
    } 
  Qed.

End Fix.  
End Cons_constant.
