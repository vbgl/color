(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Frederic Blanqui, 2011-05-06

Properties of infinite sequences of terms. Uses classical logic, the
axiom of indefinite description, and the axiom WF_notIS for
WF_absorb. *)

Set Implicit Arguments.

Require Import RelUtil ATrs LogicUtil ACalls SN InfSeq NatLeast List
  IndefiniteDescription ClassicalChoice ProofIrrelevance.

Section S.

  Variable Sig : Signature.

  Notation term := (term Sig).
  Notation subterm_eq := (@subterm_eq Sig).
  Notation supterm_eq := (@supterm_eq Sig).

(*****************************************************************************)
(** general boolean conditions for which [WF (hd_red_mod R D)] is
equivalent to [WF (hd_red_Mod (int_red R #) D)] *)

  Section WF_hd_red_mod_of_WF_hd_red_Mod_int.

    Variables R D : rules Sig.

    Variable hyp1 : forallb (@is_notvar_lhs Sig) R = true.

    Lemma undef_red_is_int_red : forall t u, red R t u ->
      undefined R t = true -> int_red R t u /\ undefined R u = true.

    Proof.
      intros t u tu ht. unfold undefined in ht. destruct t. discr.
      redtac. destruct l.
      rewrite forallb_forall in hyp1. ded (hyp1 _ lr). discr.
      ded (fun_eq_fill xl). decomp H.
      subst. simpl in xl. Funeqtac. rewrite (lhs_fun_defined lr) in ht. discr.
      split. rewrite xl, yr. exists (Fun f0 v0). exists r. exists c. exists s.
      intuition. subst. discr.
      subst. simpl. hyp.
    Qed.

    Lemma undef_rtc_red_is_rtc_int_red : forall t u, red R # t u ->
      undefined R t = true -> int_red R # t u /\ undefined R u = true.

    Proof.
      induction 1.
      intro hx. ded (undef_red_is_int_red H hx). intuition.
      intuition.
      intuition. apply rt_trans with y; auto.
    Qed.

    Variable hyp2 : forallb (undefined_rhs R) D = true.

    Lemma WF_hd_red_Mod_int :
      WF (hd_red_Mod (int_red R #) D) -> WF (hd_red_mod R D).

    Proof.
      rewrite forallb_forall in hyp1, hyp2.
      intro wf. unfold hd_red_mod. apply WF_mod_rev2. apply WF_mod_rev in wf.
      intro t. generalize (wf t). induction 1.
      apply SN_intro. intros z [y [xy yz]]. apply H0. exists y. intuition.
      assert (hy : undefined R y = true). redtac. generalize (hyp2 _ lr).
      unfold undefined_rhs. simpl. unfold undefined. subst. destruct r.
      discr. simpl. auto.
      destruct (undef_rtc_red_is_rtc_int_red yz hy). hyp.
    Qed.

  End WF_hd_red_mod_of_WF_hd_red_Mod_int.

(*****************************************************************************)
(** subtype of minimal non-terminating terms *)

  Section NTM.

    Variable R : relation term.

    Record NTM : Type := mkNTM {
      NTM_val :> term;
      NTM_prop :> NT_min R NTM_val }.

  End NTM.

(*****************************************************************************)
(** getting a minimal non-terminating subterm *)

  Section NT_min.

    Variables (R : relation term) (t : term) (ht : NT R t).

    Lemma NT_min_intro : exists u, subterm_eq u t /\ NT_min R u.

    Proof.
      set (P := fun n => exists u, subterm_eq u t /\ size u = n /\ NT R u).
      assert (exP : exists n, P n). exists (size t). exists t. intuition.
      destruct (ch_min exP) as [n [[Pn nleP] nmin]].
      destruct Pn as [u [ut [un hu]]]. subst n. exists u. unfold NT_min, min.
      intuition. rename u0 into v.
      assert (size u <= size v). apply nleP. exists v. intuition.
      eapply subterm_eq_trans. apply subterm_strict. apply H. hyp.
      ded (subterm_size H). omega.
    Qed.

    Definition min_term :=
      projT1 (constructive_indefinite_description _ NT_min_intro).

    Lemma NT_min_term : NT_min R min_term.

    Proof.
      unfold min_term. destruct (constructive_indefinite_description
      (fun u : term => subterm_eq u t /\ NT_min R u) NT_min_intro) as [u hu].
      simpl. intuition.
    Qed.

    Lemma subterm_eq_min_term : subterm_eq min_term t.

    Proof.
      unfold min_term. destruct (constructive_indefinite_description
      (fun u : term => subterm_eq u t /\ NT_min R u) NT_min_intro) as [u hu].
      simpl. intuition.
    Qed.

  End NT_min.

(*****************************************************************************)
(** getting a minimal infinite (R @ supterm_eq)-sequence from an
infinite R-sequence *)

  Section ISMin.

    Variable R : relation term.

    Definition Rsup : relation (NTM R) := R @ supterm_eq.

    (* every minimal non-terminating term admits an Rsup-reduct that is a
    minimal non-terminating term too *)
    Lemma Rsup_left_total : forall t, exists u, Rsup t u.

    Proof.
      intros [t [[f [h0 hf]] ht]].
      exists (mkNTM (NT_min_term (NT_IS_elt 1 hf))).
      unfold Rsup. simpl. exists (f 1). subst t. intuition.
      apply subterm_eq_min_term.
    Qed.

    Lemma ISMin_intro : forall f,
      IS R f -> exists g, IS (R @ supterm_eq) g /\ Min R g.

    Proof.
      intros f hf. set (Min' := fun f : nat -> NTM R =>
        forall i x, subterm x (f i) -> forall g, g 0 = x -> ~IS R g).
      cut (exists g : nat -> NTM R, IS Rsup g /\ Min' g).
      intros [g [h1 h2]]. exists (fun i => g i). intuition.
      destruct (choice _ Rsup_left_total) as [next hnext].
      set (a := mkNTM (NT_min_term (NT_IS_elt 0 hf))).
      exists (iter a next). split.
      apply IS_iter. apply hnext.
      intros i x hx g g0 hg. destruct (iter a next i) as [t [[h [h0 hh]] ht]].
      simpl in hx. ded (ht _ hx). absurd (NT R x). hyp. exists g. intuition.
    Qed.

  End ISMin.

(*****************************************************************************)
(** getting a minimal infinite (hd_red_mod R (dp R))-sequence from an
infinite R-sequence *)

  Require Import ADP VecUtil IS_NotSN ASN BoolUtil.

  Section ISMinDP.

    Variable R : rules Sig.

    Variable hyp1 : forallb (@is_notvar_lhs Sig) R = true.
    Variable hyp2 : rules_preserve_vars R.

    Lemma min_hd_red_dp : forall t u v, NT_min (red R) t -> hd_red R t u ->
      subterm_eq v u -> NT_min (red R) v -> hd_red (dp R) t v.

    Proof.
      intros t u v ht tu vu hv. redtac. subst.
      (* forall x, ~NT (red R) (s x) *)
      assert (hs : forall x, In x (vars l) -> ~NT (red R) (s x)).
      intros x vx nx. assert (hx : subterm (Var x) l).
      destruct (in_vars_subterm_eq vx) as [c hx]. destruct c.
      rewrite forallb_forall in hyp1. ded (hyp1 _ lr). rewrite hx in H. discr.
      exists (Cont f e v0 c v1). intuition. discr.
      ded (subterm_sub s hx). destruct ht as [ht1 ht2].
      ded (ht2 _ H). contradiction.
      (* end assert *)
      destruct (subterm_eq_sub_elim vu) as [w [hw1 hw2]]. destruct w.
      (* w = Var n *)
      assert (hn : In n (vars l)). eapply hyp2. apply lr.
      eapply subterm_eq_vars. apply hw1. simpl. auto.
      destruct hv as [hv1 hv2]. absurd (NT (red R) v).
      rewrite <- SN_notNT. eapply subterm_eq_sn. rewrite SN_notNT.
      apply hs. apply hn. hyp. hyp.
      (* w = Fun f v0 *)
      subst. exists l. exists (Fun f v0). exists s. intuition.
      eapply dp_intro. apply lr.
      (* In (Fun f v0) (calls R r) *)
      apply subterm_in_calls. 2: hyp. case_eq (defined f R). refl.
      destruct hv as [hv1 hv2].
      absurd (NT (red R) (sub s (Fun f v0))). 2: hyp.
      rewrite <- SN_notNT. apply sn_args_sn_fun. hyp. hyp.
      apply Vforall_intro. intros a ha. rewrite SN_notNT.
      apply hv2. apply subterm_fun. hyp.
      (* nebg_subterm l (Fun f v0) = true *)
      unfold negb_subterm. rewrite negb_ok. 2: apply bsubterm_ok. intro h.
      destruct ht as [ht1 ht2]. absurd (NT (red R) (sub s (Fun f v0))).
      apply ht2. apply subterm_sub. hyp. destruct hv as [hv1 hv2]. hyp.
    Qed.

    Require Import ListUtil NatUtil.

    Definition int_red_pos_at i t u :=
      exists f, exists h : i < arity f, exists ts, t = Fun f ts
      /\ exists v, red R (Vnth ts h) v /\ u = Fun f (Vreplace ts h v).

    Definition int_red_pos t u := exists i, int_red_pos_at i t u.

    Lemma int_red_pos_eq : int_red_pos == int_red R.

    Proof.
      split; intros t u tu.
      (* -> *)
      destruct tu as [i [f [hi [ts [e [v [h1 h2]]]]]]].
      redtac. subst. exists l. exists r.
      (* context *)
      assert (l1 : 0 + i <= arity f). omega. set (v1 := Vsub ts l1).
      assert (l2 : S i + (arity f - S i) <= arity f). omega.
      set (v2 := Vsub ts l2).
      assert (l3 : i + S (arity f - S i) = arity f). omega.
      exists (Cont f l3 v1 c v2). exists s. intuition. discr.
      (* lhs *)
      simpl. apply args_eq. apply Veq_nth. intros j hj.
      rewrite Vnth_cast, Vnth_app. destruct (le_gt_dec i j).
      rewrite Vnth_cons. destruct (lt_ge_dec 0 (j-i)).
      unfold v2. rewrite Vnth_sub. apply Vnth_eq. omega.
      assert (j=i). omega. subst. rewrite (lt_unique _ hi). hyp.
      unfold v1. rewrite Vnth_sub. apply Vnth_eq. refl.
      (* rhs *)
      simpl. apply args_eq. apply Veq_nth. intros j hj.
      rewrite Vnth_cast, Vnth_app. destruct (le_gt_dec i j).
      rewrite Vnth_cons. destruct (lt_ge_dec 0 (j-i)).
      rewrite Vnth_replace_neq. 2: omega. unfold v2. rewrite Vnth_sub.
      apply Vnth_eq. omega.
      assert (j=i). omega. subst. apply Vnth_replace.
      rewrite Vnth_replace_neq. 2: omega. unfold v1. rewrite Vnth_sub.
      apply Vnth_eq. omega.
      (* <- *)
      redtac. subst. destruct c. irrefl. exists i. exists f.
      assert (hi : i < arity f). omega. exists hi.
      simpl. exists (Vcast (Vapp v (Vcons (fill c (sub s l)) v0)) e).
      intuition. exists (fill c (sub s r)). split.
      rewrite Vnth_cast, Vnth_app. destruct (le_gt_dec i i).
      rewrite Vnth_cons. destruct (lt_ge_dec 0 (i-i)). absurd_arith.
      apply red_rule. hyp. absurd_arith.
      apply args_eq. apply Veq_nth. intros k hk.
      rewrite Vnth_cast, Vnth_app. case_eq (le_gt_dec i k).
      rewrite Vnth_cons. case_eq (lt_ge_dec 0 (k-i)).
      rewrite Vnth_replace_neq, Vnth_cast, Vnth_app, H, Vnth_cons, H0.
      refl. omega.
      assert (k=i). omega. subst. symmetry. apply Vnth_replace.
      rewrite Vnth_replace_neq, Vnth_cast, Vnth_app, H. refl. omega.
    Qed.

    Lemma NT_int_red_subterm_NT_red : forall t,
      NT (int_red R) t -> exists u, subterm u t /\ NT (red R) u.

    Proof.
      intros t [f [h0 hf]]. subst. rewrite forallb_forall in hyp1.
      ded (hf 0). redtac. destruct l. ded (hyp1 _ lr). discr.
      destruct c. irrefl. simpl in *. clear yr lr cne r.
      (* forall i, exists ts, f i = Fun f1 ts *)
      assert (h : forall i, exists ts, f i = Fun f1 ts).
      induction i0. exists
        (Vcast (Vapp v0 (Vcons (fill c (Fun f0 (Vmap (sub s) v))) v1)) e). hyp.
      clear xl s v1 c v0 e j i. destruct IHi0 as [ts hts].
      ded (hf i0). redtac. destruct l. ded (hyp1 _ lr). discr.
      destruct c. irrefl. simpl in *. rewrite hts in xl. Funeqtac.
      rewrite yr. exists
        (Vcast (Vapp v1 (Vcons (fill c (sub s r)) v2)) e). refl.
      clear xl s v1 c v0 e i j f0 v. destruct (choice _ h) as [v hv]. clear h.
      (* forall i, exists k, exists hk : k < arity f1,
         int_red_pos_at k (f i) (f (S i)) *)
      assert (h : forall i, exists k, exists hk : k < arity f1,
         int_red_pos_at k (f i) (f (S i))).
      intro i. ded (hf i). apply int_red_pos_eq in H. destruct H as [k H].
      cut (int_red_pos_at k (f i) (f (S i))). 2: hyp.
      intro H'. destruct H as [g [hk [w [e H]]]]. rewrite hv in e. Funeqtac.
      exists k. exists hk. hyp. destruct (choice _ h) as [k hk]. clear h.
      (*REMOVE: forall i, exists k, exists hk : k < arity f1,
         red R (Vnth hk (v i)) (Vnth hk (v (S i))) *)
      (*assert (h : forall i, exists k, exists hk : k < arity f1,
        red R (Vnth (v i) hk) (Vnth (v (S i)) hk)).
      intro i. ded (hf i). redtac. destruct l. ded (hyp1 _ lr). discr.
      destruct c. irrefl. simpl in *. rewrite hv in xl, yr. do 2 Funeqtac.
      assert (hi0 : i0 < arity f1). omega. exists i0. exists hi0.
      rewrite H, H0. do 2 rewrite Vnth_cast, Vnth_app_cons.
      change (red R (fill c (sub s (Fun f0 v0))) (fill c (sub s r))).
      apply red_rule. hyp. destruct (choice _ h) as [k hk]. clear h.*)
      (* infinite constant sub-sequence *)
      set (As := nats_decr_lt (arity f1)).
      assert (h : forall i, In (k i) As). intro i. destruct (hk i) as [hi ri].
      unfold As. rewrite <- In_nats_decr_lt. hyp.
      destruct (finite_codomain eq_nat_dec h) as [a [g [h1 [h2 h3]]]].
      clear h As.
      assert (ha : a < arity f1). rewrite <- (h2 0). destruct (hk (g 0)). hyp.
      (* monotony of g *)
      ded (monS lt_trans h1). assert (me : forall x y, x <= y -> g x <= g y).
      intros x y xy. destruct (lt_dec x y). ded (H _ _ l). omega.
      assert (x=y). omega. subst. refl.
      (* forall i j, g i < j < g (S i) -> k j <> a *)
      assert (hg : forall i j, g i < j < g (S i) -> k j <> a).
      intros i j hj e. destruct (h3 _ e) as [l hl]. subst.
      destruct (ge_dec i l). ded (me _ _ g0). omega.
      destruct (ge_dec l (S i)). ded (me _ _ g0). omega. omega.
      (* forall i, Vnth (v (S (g i))) ha = Vnth (v (g (S i))) ha *)
      assert (h : forall i, Vnth (v (S (g i))) ha = Vnth (v (g (S i))) ha).
      intro i. ded (h1 i). cut (forall l, 0 <= l < g (S i) - g i ->
        Vnth (v (S (g i))) ha = Vnth (v (S (g i) + l)) ha).
      intro hi. assert (e : g (S i) = S (g i) + (g (S i) - g i - 1)). omega.
      rewrite e. apply hi. clear e. omega.
      induction l; intro. rewrite plus_0_r. refl.
      assert (hl : 0 <= l < g (S i) - g i). omega. rewrite (IHl hl).
      rewrite <- plus_Snm_nSm. simpl. set (x := S (g i + l)).
      assert (n : k x <> a). apply hg with (i:=i). unfold x. omega.
      destruct (hk x) as [_ r]. destruct r as [f' [hi [ts [e [w [p1 p2]]]]]].
      rewrite hv in e, p2. Funeqtac. Funeqtac. rewrite H2, H3.
      rewrite Vnth_replace_neq. refl. hyp.
      (* [Vnth (v 0) ha] is a subterm of [f 0] *)
      exists (Vnth (v 0) ha). split.
      rewrite hv. apply subterm_fun. apply Vnth_in.
      (* [Vnth (v 0) ha] is non-terminating *)
      exists (fun i => Vnth (v (g i)) ha). split.

    Abort.

  End ISMinDP.

End S.
