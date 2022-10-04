(** ** Tarski Completeness *)

From Undecidability.FOL Require Import Syntax.Facts Syntax.Asimpl Deduction.FragmentNDFacts Syntax.Theories Semantics.Tarski.FragmentFacts Semantics.Tarski.FragmentSoundness.
From Undecidability.Synthetic Require Import Definitions DecidabilityFacts MPFacts EnumerabilityFacts ListEnumerabilityFacts ReducibilityFacts.
From Undecidability Require Import Shared.ListAutomation Shared.Dec.
From Undecidability Require Import Shared.Libs.PSL.Vectors.Vectors Shared.Libs.PSL.Vectors.VectorForall.
Import ListAutomationNotations.
From Undecidability.FOL.Completeness Require Export TarskiConstructions.
(* ** Completeness *)

(* ** Standard Models **)

Section Completeness.
  Context {Σf : funcs_signature} {Σp : preds_signature}.
  Context {HdF : eq_dec Σf} {HdP : eq_dec Σp}.
  Variable eF : nat -> option Σf.
  Context {HeF : enumerator__T eF Σf}.
  Variable eP : nat -> option Σp.
  Context {HeP : enumerator__T eP Σp}.

  #[local] Hint Constructors bounded : core.
  
  Section Enumeration.
  

    Definition list_enum_to_enum {X} (L : nat -> list X) (n : nat) : option X :=
      let (n, m) := Cantor.of_nat n in nth_error (L n) m.

    Definition form_list_enum := (@L_form _ _ _
                                  _ (enumerator__T_of_list HeF) _ (enumerator__T_of_list HeP)
                                  _ enum_frag_logic_binop _ enum_frag_logic_quant).

    Definition form_list_enum_bounded {ff:falsity_flag} (n:nat) : list form := 
      (flat_map (fun f => if bounded_dec f n then [f] else []) (form_list_enum ff n)).

    Lemma form_list_is_enum {ff:falsity_flag} : list_enumerator__T (form_list_enum ff) _.
    Proof.
      apply enum_form.
    Qed.

    Lemma form_list_bounded_is_enum {ff:falsity_flag} : list_enumerator__T (@form_list_enum_bounded ff) _.
    Proof.
      intros f. destruct (form_list_is_enum f) as [m Hm].
      destruct (find_bounded f) as [m2 Hm2].
      exists (max m m2).
      unfold form_list_enum_bounded. eapply in_flat_map. exists f; split.
      - unfold form_list_enum. eapply cum_ge'. 1: apply L_form_cml. 1: apply Hm. lia.
      - destruct bounded_dec as [Hl|Hr]. 1:now left. exfalso. apply Hr. eapply bounded_up. 1: apply Hm2. lia.
    Qed.

    Definition form_enum_with_default {ff} d n := match list_enum_to_enum (@form_list_enum_bounded ff) n with Some k => k | _ => d end.

    Lemma form_default_is_enum {ff:falsity_flag} d : forall f, exists n, (@form_enum_with_default ff d n) = f.
    Proof.
      intros f. destruct (form_list_bounded_is_enum f) as [m Hm].
      unfold form_enum_with_default, list_enum_to_enum.
      destruct (In_nth_error _ _ Hm) as [n Hn].
      exists (Cantor.to_nat (m, n)). rewrite Cantor.cancel_of_to.
      rewrite Hn. easy.
    Qed.

    Lemma form_default_is_bounded {ff:falsity_flag} d : bounded 0 d -> forall n, bounded n (@form_enum_with_default ff d n).
    Proof.
      intros Hb n.
      unfold form_enum_with_default, list_enum_to_enum.
      destruct (Cantor.of_nat n) as [n' m'] eqn:Hn.
      pose proof (Cantor.to_nat_non_decreasing n' m'). rewrite <- Hn in H.
      rewrite Cantor.cancel_to_of in H.
      unfold form_list_enum_bounded.
      generalize (form_list_enum ff n'); intros l.
      destruct (nth_error _ _) as [k|] eqn:Heq.
      2: eapply bounded_up; [apply Hb|lia].
      apply nth_error_In in Heq.
      apply in_flat_map in Heq.
      destruct Heq as [x [Hx1 Hx2]].
      destruct (bounded_dec x n') as [Hbo|]. 2:easy.
      destruct Hx2 as [->|[]]. eapply bounded_up. 1: apply Hbo. lia.
    Qed.

  End Enumeration.

  Section BotModel.
    #[local] Existing Instance falsity_on | 0.
    Variable T : theory.
    Hypothesis T_closed : closed_T T.
    Hypothesis Hcon : consistent class T.

    Definition input_bot : ConstructionInputs :=
      {|
        NBot := ⊥ ;
        NBot_closed := bounded_falsity 0;

        variant := falsity_on ;

        In_T := T ;
        In_T_closed := T_closed ;
        TarskiConstructions.enum := form_enum_with_default ⊥;
        TarskiConstructions.enum_enum := form_default_is_enum _;
        TarskiConstructions.enum_bounded := form_default_is_bounded (bounded_falsity _)
      |}.

    Definition output_bot := construct_construction input_bot.

    Instance model_bot : interp term :=
      {| i_func := func; i_atom := fun P v => atom P v ∈ Out_T output_bot|}.

    Lemma eval_ident rho (t : term) :
      eval rho t = subst_term rho t.
    Proof.
      induction t in rho|-*.
      - easy.
      - cbn. easy.
    Qed.

    Lemma model_bot_correct phi rho :
      (phi[rho] ∈ Out_T output_bot <-> rho ⊨ phi).
    Proof.
      revert rho. induction phi using form_ind_falsity; intros rho. 1,2,3: cbn.
      - split; try tauto. intros H. apply Hcon.
        apply Out_T_econsistent with output_bot. exists [⊥].
        split; try apply Ctx. 2: now left. intros a [<-|[]]; easy.
      - erewrite (Vector.map_ext_in _ _ _ (eval rho)). 1:easy.
        easy.
      - destruct b0. rewrite <- IHphi1. rewrite <- IHphi2. apply Out_T_impl.
      - destruct q. cbn. setoid_rewrite <- IHphi. setoid_rewrite Out_T_all.
        split; intros H t; asimpl; specialize (H t); now asimpl in H.
    Qed.

    Lemma model_bot_classical :
      classical model_bot.
    Proof.
      intros rho phi psi. apply model_bot_correct, Out_T_prv.
      use_theory (nil : list form). apply Pc.
    Qed.

    Lemma valid_T_model_bot phi :
      phi ∈ T -> var ⊨ phi.
    Proof.
      intros H % (Out_T_sub output_bot). apply model_bot_correct. now rewrite subst_id.
    Qed.
  End BotModel.

  Section StandardCompletenes.
    Variables (T : @theory _ _ _ falsity_on) (phi : @form _ _ _ falsity_on).
    Hypothesis (HT : closed_T T) (Hphi : closed phi).

    Lemma semi_completeness_standard :
      valid_theory T phi -> ~ ~ T ⊢TC phi.
    Proof.
      intros Hval Hcons. rewrite refutation_prv in Hcons. 
      assert (Hcl : closed_T (T ⋄ (¬ phi))) by (apply closed_T_extend; try econstructor; eauto).
      unshelve eapply (model_bot_correct (T_closed := Hcl) Hcons (¬ phi) var).
      - apply Out_T_sub. cbn. right. now asimpl.
      - apply Hval. intros ? ?. apply valid_T_model_bot; intuition.
    Qed.

    Definition stable P := ~~P -> P.

    Lemma completeness_standard_stability :
      stable (T ⊢TC phi) -> valid_theory T phi -> T ⊢TC phi.
    Proof.
      intros Hstab Hsem. now apply Hstab, semi_completeness_standard.
    Qed.

    Lemma completeness_standard_stability' :
      (valid_theory_C (classical (ff := falsity_on)) T phi -> T ⊢TC phi) -> stable (T ⊢TC phi).
    Proof.
      intros Hcomp Hdn. apply Hcomp.
      intros D I rho Hclass Hsat. unfold classical in Hclass. cbn in Hclass.
      eapply (Hclass _ _ ⊥). intros Hsat2. exfalso. apply Hdn. intros [A [HA Hc]]. apply Hsat2.
      eapply sound_for_classical_model.
      - easy.
      - exact Hc.
      - intros a Ha. apply Hsat. apply HA, Ha.
    Qed.
  End StandardCompletenes.

  Section ExplodingCompletenessConstr.
    Variables (T : @theory _ _ _ falsity_on).
    Hypothesis (HT : closed_T T).

    Definition expl_interp := (model_bot HT).
    Existing Instance expl_interp.

    Lemma model_expl_correct phi rho :
      (phi[rho] ∈ Out_T (output_bot HT) <-> sat_bot (falsity ∈ Out_T (output_bot HT)) rho phi).
    Proof.
      revert rho. induction phi using form_ind_falsity; intros rho. 1,2,3: cbn.
      - easy.
      - erewrite (Vector.map_ext_in _ _ _ (eval rho)). 1:easy.
        easy.
      - destruct b0. unfold sat_bot in *. rewrite <- IHphi1. rewrite <- IHphi2. apply Out_T_impl.
      - destruct q. cbn. unfold sat_bot in *. setoid_rewrite <- IHphi. setoid_rewrite Out_T_all.
        split; intros H t; asimpl; specialize (H t); now asimpl in H.
    Qed.

    Lemma model_bot_exploding :
      FragmentFacts.exploding (model_bot HT) (falsity ∈ Out_T (output_bot HT)).
    Proof.
      intros rho phi. cbn. intros H. apply model_expl_correct.
      apply (Out_T_impl (output_bot HT) ⊥ (phi[rho])). 2: easy.
      apply Out_T_prv. exists []. split.
      - intros ? [].
      - apply II. apply FragmentND.Exp. apply Ctx. now left.
    Qed.

    Lemma valid_T_model_exploding phi :
      phi ∈ T -> sat_bot (falsity ∈ Out_T (output_bot HT)) var phi.
    Proof.
      intros H % (Out_T_sub (output_bot HT)). apply model_expl_correct. now rewrite subst_id.
    Qed.
  End ExplodingCompletenessConstr.
  Section ExplodingCompleteness.

    #[local] Existing Instance falsity_on | 0.
    Lemma semi_completeness_exploding T phi :
      closed_T T -> closed phi -> valid_exploding_theory T phi -> T ⊢TC phi.
    Proof.
      intros HT Hphi Hval.
      assert (Hcl : closed_T (T ⋄ (¬ phi))).
      1: { intros ? ?; subst; eauto. destruct H as [Hl| ->].
           + apply HT, Hl.
           + repeat econstructor. apply Hphi. }
      apply refutation_prv.
      apply (@Out_T_econsistent _ _ _ (output_bot Hcl)).
      use_theory [⊥]. 2: { apply Ctx. now left. }
      intros ? [<-|[]].
      specialize (Hval term (model_bot Hcl) (falsity ∈ Out_T (output_bot Hcl)) var (@model_bot_exploding _ Hcl)).
      rewrite <- (@subst_id _ _ _ _ ⊥ var). 2: easy.
      apply (@model_expl_correct _ Hcl (¬ phi) var).
      - apply Out_T_sub. cbn. rewrite subst_id. 2:easy. now right.
      - apply Hval. intros psi Hpsi. apply model_expl_correct. rewrite subst_id; [|easy].
        apply Out_T_sub. left. apply Hpsi.
    Qed.

  End ExplodingCompleteness.


  Section FragmentCompleteness.
    #[local] Existing Instance falsity_off | 0.
  End FragmentCompleteness.
 

  Section MPStrongCompleteness.
    Hypothesis mp : MP.
    Variables (T : @theory _ _ _ falsity_on) (phi : @form _ _ _ falsity_on).
    Hypothesis (HT : closed_T T) (Hphi : closed phi).
    Hypothesis (He : list_enumerable T).

    Lemma mp_tprv_stability :
      ~ ~ T ⊢TC phi -> T ⊢TC phi.
    Proof.
      apply (MP_stable_enumerable mp). 2: apply dec_form; eauto.
      apply list_enumerable_enumerable. destruct He as [L HL]. eexists. apply enum_tprv. apply HL.
    Qed.

    Lemma mp_standard_completeness :
      valid_theory T phi -> T ⊢TC phi.
    Proof.
      apply completeness_standard_stability; eauto. unfold stable.
      apply mp_tprv_stability.
    Qed.
  End MPStrongCompleteness.

(* *** Minimal Models **)

  Section FragmentModel.
    #[local] Existing Instance falsity_off | 0.
    Variable T : theory.
    Hypothesis T_closed : closed_T T.

    Variable GBot : form.
    Hypothesis GBot_closed : closed GBot.

    Definition input_fragment :=
      {|
        NBot := GBot ;
        NBot_closed := GBot_closed ;

        variant := falsity_off ;

        In_T := T ;
        In_T_closed := T_closed ;

        TarskiConstructions.enum := form_enum_with_default GBot;
        TarskiConstructions.enum_enum := form_default_is_enum _;
        TarskiConstructions.enum_bounded := form_default_is_bounded (GBot_closed)
      |}.

    Definition output_fragment := construct_construction input_fragment.

    Instance model_fragment : interp term :=
      {| i_func := func; i_atom := fun P v => atom P v ∈ Out_T output_fragment|}.

    Lemma model_fragment_correct phi rho :
      (phi[rho] ∈ Out_T output_fragment <-> rho ⊨ phi).
    Proof.
      revert rho. unfold model_fragment, output_fragment, input_fragment in *; cbn in *.
      remember falsity_off as ff eqn:Hff.
      induction phi; intros rho. 1,2,3: cbn.
      - split; try tauto. discriminate Hff.
      - erewrite (Vector.map_ext_in _ _ _ (eval rho)). 1:easy.
        easy.
      - destruct b0. rewrite <- IHphi1. rewrite <- IHphi2. apply Out_T_impl. 1-2:congruence.
      - destruct q. cbn. setoid_rewrite <- IHphi. setoid_rewrite Out_T_all. 2:congruence.
        split; intros H t; asimpl; specialize (H t); now asimpl in H.
    Qed.

    Lemma model_fragment_classical :
      classical model_fragment.
    Proof.
      intros rho phi psi. apply model_fragment_correct, Out_T_prv.
      use_theory (nil : list form). apply Pc.
    Qed.

    Lemma valid_T_fragment phi :
      phi ∈ T -> var ⊨ phi.
    Proof.
      intros H % (Out_T_sub output_fragment). apply model_fragment_correct. rewrite subst_id. 1:easy. easy.
    Qed.
  End FragmentModel.

  Section FragmentCompleteness.
    #[local] Existing Instance falsity_off | 0.
    Lemma semi_completeness_fragment T phi :
      closed_T T -> closed phi -> valid_theory T phi -> T ⊢TC phi.
    Proof.
      intros HT Hphi Hval.
      apply (@Out_T_econsistent _ _ _ (@output_fragment T HT phi Hphi)).
      use_theory [phi[var]]. 2: apply Ctx; left; now rewrite subst_id.
      intros ? [<- | []].
      apply (@model_fragment_correct T HT phi Hphi phi var).
      apply Hval. intros psi Hpsi.
      apply valid_T_fragment, Hpsi.
    Qed.
  End FragmentCompleteness.
End Completeness.

(* ** Extending the Completeness Results *)
(*
Section FiniteCompleteness.
  Context {Sigma : Signature}.
  Context {HdF : eq_dec Funcs} {HdP : eq_dec Preds}.
  Context {HeF : enumT Funcs} {HeP : enumT Preds}.

  Lemma list_completeness_standard A phi :
    ST__f -> valid_L SM A phi -> A ⊢CE phi.
  Proof.
    intros stf Hval % valid_L_to_single. apply prv_from_single.
    apply con_T_correct. apply completeness_standard_stability.
    1: intros ? ? []. 1: apply close_closed. 2: now apply valid_L_valid_T in Hval.
    apply stf, fin_T_con_T.
    - intros ? ? [].
    - eapply close_closed.
  Qed.

  Lemma list_completeness_expl A phi :
    valid_L EM A phi -> A ⊢CE phi.
  Proof.
    intros Hval % valid_L_to_single. apply prv_from_single.
    apply tprv_list_T. apply completeness_expl. 1: intros ? ? [].
    1: apply close_closed. now apply valid_L_valid_T in Hval.
  Qed.

  Lemma list_completeness_fragment A phi :
    valid_L BLM A phi -> A ⊢CL phi.
  Proof.
    intros Hval % valid_L_to_single. apply prv_from_single.
    apply tprv_list_T. apply semi_completeness_fragment. 1: intros ? ? [].
    1: apply close_closed. now apply valid_L_valid_T in Hval.
  Qed.
End FiniteCompleteness.

Section StrongCompleteness.
  Context {Sigma : Signature}.
  Context {HdF : eq_dec Funcs} {HdP : eq_dec Preds}.
  Context {HeF : enumT Funcs} {HeP : enumT Preds}.

  Lemma dn_inherit (P Q : Prop) :
    (P -> Q) -> ~ ~ P -> ~ ~ Q.
  Proof. tauto. Qed.

  Lemma strong_completeness_standard (S : stab_class) T phi :
    (forall (T : theory) (phi : form), S Sigma T -> stable (tmap (fun psi : form => (sig_lift psi)[ext_c]) T ⊢TC phi)) -> @map_closed S Sigma (sig_ext Sigma) (fun phi => (sig_lift phi)[ext_c]) -> S Sigma T -> T ⊫S phi -> T ⊢TC phi.
  Proof.
    intros sts cls HT Hval. apply sig_lift_out_T. apply completeness_standard_stability.
    1: apply lift_ext_c_closes_T. 1: apply lift_ext_c_closes. 2: apply (sig_lift_subst_valid droppable_S Hval).
    now apply sts.
  Qed.

  Lemma strong_completeness_expl T phi :
    T ⊫E phi -> T ⊢TC phi.
  Proof.
    intros Hval. apply sig_lift_out_T, completeness_expl.
    1: apply lift_ext_c_closes_T. 1: apply lift_ext_c_closes.
    apply (sig_lift_subst_valid droppable_E Hval).
  Qed.

  Lemma strong_completeness_fragment T phi :
    T ⊫M phi -> T ⊩CL phi.
  Proof.
    intros Hval. apply sig_lift_out_T, semi_completeness_fragment.
    1: apply lift_ext_c_closes_T. 1: apply lift_ext_c_closes.
    apply (sig_lift_subst_valid droppable_BL Hval).
  Qed.

End StrongCompleteness.

*)
