(* * Natural Deduction *)

From Undecidability Require Import FOL.Util.FullTarski FOL.Util.Syntax.
From Undecidability Require Import Shared.ListAutomation.
Import ListAutomationNotations.
Local Set Implicit Arguments.





Ltac comp := repeat (progress (cbn in *; autounfold in *)).

Inductive peirce := class | intu.
Existing Class peirce.

Section ND_def.

  Context {Σ_funcs : funcs_signature}.
  Context {Σ_preds : preds_signature}.

  Reserved Notation "A ⊢ phi" (at level 61).
  
  (* ** Definition *)

  Implicit Type p : peirce.
  Implicit Type ff : falsity_flag.

  Inductive prv : forall (ff : falsity_flag) (p : peirce), list form -> form -> Prop :=
  | II {ff} {p} A phi psi : phi::A ⊢ psi -> A ⊢ phi --> psi
  | IE {ff} {p} A phi psi : A ⊢ phi --> psi -> A ⊢ phi -> A ⊢ psi
  | AllI {ff} {p} A phi : map (subst_form ↑) A ⊢ phi -> A ⊢ ∀ phi
  | AllE {ff} {p} A t phi : A ⊢ ∀ phi -> A ⊢ phi[t..]
  | ExI {ff} {p} A t phi : A ⊢ phi[t..] -> A ⊢ ∃ phi
  | ExE {ff} {p} A phi psi : A ⊢ ∃ phi -> phi::(map (subst_form ↑) A) ⊢ psi[↑] -> A ⊢ psi
  | Exp {p} A phi : prv p A falsity -> prv p A phi
  | Ctx {ff} {p} A phi : phi el A -> A ⊢ phi
  | CI {ff} {p} A phi psi : A ⊢ phi -> A ⊢ psi -> A ⊢ phi ∧ psi
  | CE1 {ff} {p} A phi psi : A ⊢ phi ∧ psi -> A ⊢ phi
  | CE2 {ff} {p} A phi psi : A ⊢ phi ∧ psi -> A ⊢ psi
  | DI1 {ff} {p} A phi psi : A ⊢ phi -> A ⊢ phi ∨ psi
  | DI2 {ff} {p} A phi psi : A ⊢ psi -> A ⊢ phi ∨ psi
  | DE {ff} {p} A phi psi theta : A ⊢ phi ∨ psi -> phi::A ⊢ theta -> psi::A ⊢ theta -> A ⊢ theta
  | Pc {ff} A phi psi : prv class A (((phi --> psi) --> phi) --> phi)
  where "A ⊢ phi" := (prv _ A phi).

  Arguments prv {_} _ _.

  Context {ff : falsity_flag}.
  Context {p : peirce}.

  Lemma impl_prv A B phi :
    (rev B ++ A) ⊢ phi -> A ⊢ (B ==> phi).
  Proof.
    revert A; induction B; intros A; cbn; simpl_list; intros.
    - firstorder.
    - eapply II. now eapply IHB.
  Qed.

  Theorem Weak A B phi :
    A ⊢ phi -> A <<= B -> B ⊢ phi.
  Proof.
    intros H. revert B.
    induction H; intros B HB; try unshelve (solve [econstructor; intuition]); try now econstructor.
  Qed.

  Lemma nameless_equiv_all A phi :
    { t : term | map (subst_form ↑) A ⊢ phi <-> A ⊢ phi[t..] }.
  Proof.
  Admitted.

  Lemma nameless_equiv_ex A phi psi :
    { t : term | phi :: map (subst_form ↑) A ⊢ psi[↑] <-> phi[t..]::A ⊢ psi }.
  Proof.
  Admitted.

  Hint Constructors prv : core.

  Lemma imps T phi psi :
    T ⊢ phi --> psi <-> (phi :: T) ⊢ psi.
  Proof.
    split; try apply II.
    intros H. apply IE with phi; auto. apply (Weak H). auto.
  Qed.

  Lemma CE T phi psi :
    T ⊢ phi ∧ psi -> T ⊢ phi /\ T ⊢ psi.
  Proof.
    intros H. split.
    - apply (CE1 H).
    - apply (CE2 H).
  Qed.

  Lemma DE' A phi :
    A ⊢ phi ∨ phi -> A ⊢ phi.
  Proof.
    intros H. apply (DE H); auto.
  Qed.

  Lemma switch_conj_imp alpha beta phi A :
    A ⊢ alpha ∧ beta --> phi <-> A ⊢ alpha --> beta --> phi.
  Proof.
    split; intros H.
    - apply II, II. eapply IE.
      apply (@Weak A). apply H. firstorder.
      apply CI; apply Ctx; firstorder.
    - apply II. eapply IE. eapply IE.
      eapply Weak. apply H.
      firstorder.
      eapply CE1, Ctx; firstorder.
      eapply CE2, Ctx; firstorder.
  Qed.

  Definition tprv (T : form -> Prop) phi :=
    exists A, (forall psi, psi el A -> T psi) /\ A ⊢ phi.
    
End ND_def.


Hint Constructors prv : core.

Arguments prv {_ _ _ _} _ _.
Notation "A ⊢ phi" := (prv A phi) (at level 55).
Notation "A ⊢C phi" := (@prv _ _ _ class A phi) (at level 55).
Notation "A ⊢I phi" := (@prv _ _ _ intu A phi) (at level 55).
Notation "A ⊢M phi" := (@prv _ _ falsity_off intu A phi) (at level 55).
Notation "T ⊢TI phi" := (@tprv _ _ _ intu T phi) (at level 55).



(** ** Custom induction principle *)

Lemma prv_ind_full {Σ_funcs : funcs_signature} {Σ_preds : preds_signature} :
  forall P : peirce -> list (form falsity_on) -> (form falsity_on) -> Prop,
    (forall (p : peirce) (A : list form) (phi psi : form),
        (phi :: A) ⊢ psi -> P p (phi :: A) psi -> P p A (phi --> psi)) ->
    (forall (p : peirce) (A : list form) (phi psi : form),
        A ⊢ phi --> psi -> P p A (phi --> psi) -> A ⊢ phi -> P p A phi -> P p A psi) ->
    (forall (p : peirce) (A : list form) (phi : form),
        (map (subst_form ↑) A) ⊢ phi -> P p (map (subst_form ↑) A) phi -> P p A (∀ phi)) ->
    (forall (p : peirce) (A : list form) (t : term) (phi : form),
        A ⊢ ∀ phi -> P p A (∀ phi) -> P p A phi[t..]) ->
    (forall (p : peirce) (A : list form) (t : term) (phi : form),
        A ⊢ phi[t..] -> P p A phi[t..] -> P p A (∃ phi)) ->
    (forall (p : peirce) (A : list form) (phi psi : form),
        A ⊢ ∃ phi ->
              P p A (∃ phi) ->
              (phi :: [p[↑] | p ∈ A]) ⊢ psi[↑] -> P p (phi :: [p[↑] | p ∈ A]) psi[↑] -> P p A psi) ->
    (forall (p : peirce) (A : list form) (phi : form), A ⊢ ⊥ -> P p A ⊥ -> P p A phi) ->
    (forall (p : peirce) (A : list form) (phi : form), phi el A -> P p A phi) ->
    (forall (p : peirce) (A : list form) (phi psi : form),
        A ⊢ phi -> P p A phi -> A ⊢ psi -> P p A psi -> P p A (phi ∧ psi)) ->
    (forall (p : peirce) (A : list form) (phi psi : form),
        A ⊢ phi ∧ psi -> P p A (phi ∧ psi) -> P p A phi) ->
    (forall (p : peirce) (A : list form) (phi psi : form),
        A ⊢ phi ∧ psi -> P p A (phi ∧ psi) -> P p A psi) ->
    (forall (p : peirce) (A : list form) (phi psi : form),
        A ⊢ phi -> P p A phi -> P p A (phi ∨ psi)) ->
    (forall (p : peirce) (A : list form) (phi psi : form),
        A ⊢ psi -> P p A psi -> P p A (phi ∨ psi)) ->
    (forall (p : peirce) (A : list form) (phi psi theta : form),
        A ⊢ phi ∨ psi ->
        P p A (phi ∨ psi) ->
        (phi :: A) ⊢ theta ->
        P p (phi :: A) theta -> (psi :: A) ⊢ theta -> P p (psi :: A) theta -> P p A theta) ->
    (forall (A : list form) (phi psi : form), P class A (((phi --> psi) --> phi) --> phi)) ->
    forall (p : peirce) (l : list form) (f14 : form), l ⊢ f14 -> P p l f14.
Proof.
  intros. specialize (prv_ind (fun ff => match ff with falsity_on => P | _ => fun _ _ _ => True end)). intros H'.
  apply H' with (ff := falsity_on); clear H'. all: intros; try destruct ff; trivial. all: intuition eauto 2.
Qed.



(** ** Soundness *)

Section Soundness.

  Context {Σ_funcs : funcs_signature}.
  Context {Σ_preds : preds_signature}.

  Lemma soundness {ff : falsity_flag} A phi :
    A ⊢I phi -> valid_ctx A phi.
  Proof.
    remember intu as p.
    induction 1; intros D I rho HA; comp.
    - intros Hphi. apply IHprv; trivial. intros ? []; subst. assumption. now apply HA.
    - now apply IHprv1, IHprv2.
    - intros d. apply IHprv; trivial. intros psi [psi'[<- H' % HA]] % in_map_iff.
      eapply sat_comp. now comp.
    - eapply sat_comp, sat_ext. 2: apply (IHprv Heqp D I rho HA (eval rho t)). now intros [].
    - exists (eval rho t). cbn. specialize (IHprv Heqp D I rho HA).
      apply sat_comp in IHprv. eapply sat_ext; try apply IHprv. now intros [].
    - edestruct IHprv1 as [d HD]; eauto.
      assert (H' : forall psi, phi = psi \/ psi el map (subst_form ↑) A -> (d.:rho) ⊨ psi).
      + intros P [<-|[psi'[<- H' % HA]] % in_map_iff]; trivial. apply sat_comp. apply H'.
      + specialize (IHprv2 Heqp D I (d.:rho) H'). apply sat_comp in IHprv2. apply IHprv2.
    - apply (IHprv Heqp) in HA. firstorder.
    - firstorder.
    - firstorder.
    - firstorder. now apply H0.
    - firstorder. now apply H0.
    - firstorder.
    - firstorder.
    - edestruct IHprv1; eauto.
      + apply IHprv2; trivial. intros xi [<-|HX]; auto.
      + apply IHprv3; trivial. intros xi [<-|HX]; auto.
    - discriminate.
  Qed.

  Lemma soundness' {ff : falsity_flag} phi :
    [] ⊢I phi -> valid phi.
  Proof.
    intros H % soundness. firstorder.
  Qed.

  Corollary tsoundness {ff : falsity_flag} T phi :
    T ⊢TI phi -> forall D (I : interp D) rho, (forall psi, T psi -> rho ⊨ psi) -> rho ⊨ phi.
  Proof.
    intros (A & H1 & H2) D I rho HI. apply (soundness H2).
    intros psi HP. apply HI, H1, HP.
  Qed.

End Soundness.



(** ** Rudimentary tactics for ND manipulations *)

Ltac subsimpl_in H :=
  rewrite ?up_term, ?subst_term_shift in H.

Ltac subsimpl :=
  rewrite ?up_term, ?subst_term_shift.

Ltac assert1 H :=
  match goal with |- (?phi :: ?T) ⊢ _ => assert (H : (phi :: T) ⊢ phi) by auto end.

Ltac assert2 H :=
  match goal with |- (?phi :: ?psi :: ?T) ⊢ _ => assert (H : (phi :: psi :: T) ⊢ psi) by auto end.

Ltac assert3 H :=
  match goal with |- (?phi :: ?psi :: ?theta :: ?T) ⊢ _ => assert (H : (phi :: psi :: theta :: T) ⊢ theta) by auto end.

Ltac assert4 H :=
  match goal with |- (?f :: ?phi :: ?psi :: ?theta :: ?T) ⊢ _ => assert (H : (f :: phi :: psi :: theta :: T) ⊢ theta) by auto end.

Ltac prv_all x :=
  apply AllI; edestruct nameless_equiv_all as [x ->]; cbn; subsimpl.

Ltac use_exists H x :=
  apply (ExE _ H); edestruct nameless_equiv_ex as [x ->]; cbn; subsimpl.


