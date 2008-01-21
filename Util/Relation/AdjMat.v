(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Leo Ducas, 2007-08-06

Describe the morphism between graph restricted to [[0,n-1]]
and the corresponding boolean adjacency matrix of size n*n.
*)

Set Implicit Arguments.

Require Export Matrix.
Require Export SemiRing.
Require Export Bool.
Require Import Omega.
Require Export Path.
Require Export Iter.
Require Export SCC.
Require Export ListExtras.

Module BMatrix := Matrix BOrdSemiRingT.
Export BMatrix.

(***********************************************************************)
(** Definition of the graph of a boolean matrix *)

Section GoM.

Variable dim : nat.

Definition mat_unbound (M : matrix dim dim) i j :=
  match le_gt_dec dim i with
    | left _ => false
    | right hi =>
      match le_gt_dec dim j with
        | left _ => false
        | right hj => Vnth (Vnth M hi) hj
      end
  end.

Notation "z [[ x , y ]]" := (@mat_unbound z x y) (at level 30).

Definition GoM M x y := M[[x,y]] = true.

(***********************************************************************)
(** Basic properties *)

Section basic.

Variable M : matrix dim dim.

Lemma GoM_true_bounds : forall x y, GoM M x y -> x < dim /\ y < dim.

Proof.
intros. split; unfold GoM, mat_unbound in H;
destruct (le_gt_dec dim x);
destruct (le_gt_dec dim y); try discriminate; auto with *.
Qed.

Lemma GoM_dec : forall x y, {GoM M x y} + {~GoM M x y}.

Proof.
intros; unfold GoM; apply (bool_dec (M[[x,y]]) true).
Qed.

Lemma GoM_restricted : is_restricted (GoM M) (nfirst dim).

Proof.
unfold is_restricted; intros x y. repeat rewrite nfirst_exact.
intro. unfold GoM in H. unfold mat_unbound in *.
destruct (le_gt_dec dim x); auto. discriminate.
destruct (le_gt_dec dim y); auto. discriminate.
Qed.

End basic.

(***********************************************************************)
(** Addition of matrix is union of relation *)

Section GoM_union.

Variables M N : matrix dim dim.

Lemma orb_matadd : forall x y, (M <+> N)[[x, y]] = M[[x, y]] || N[[x, y]].

Proof.
intros. unfold mat_unbound.
destruct (le_gt_dec dim x); auto. destruct (le_gt_dec dim y); auto.
unfold mat_plus. unfold vec_plus. mat_get_simpl.
Qed.

Lemma Gmorph_plus : forall x y,
  GoM (M <+> N) x y <-> ((GoM M) U (GoM N)) x y.

Proof.
intros. assert (GoM (M <+> N) x y <-> (GoM M x y \/ GoM N x y)).
unfold GoM. rewrite orb_matadd. split; intro.
eapply orb_prop; auto. destruct H; auto with *. auto.
Qed.

End GoM_union.

(***********************************************************************)
(** Product of matrix is composition of relation *)

Section GoM_Compose.

Variables M N : matrix dim dim.

Lemma existandb_dotprod : forall n (v w : vec n),
  dot_product v w = true
  <-> exists z, exists hz : z<n, Is_true (andb (Vnth v hz) (Vnth w hz)).

Proof.
induction n; intros; unfold dot_product in *; unfold Vfold_left.
simpl; unfold A0; split; intro.
discriminate.
destruct H; destruct H; auto with *.

assert (v = Vcons (Vhead v) (Vtail v)) as Hv.
apply VSn_eq.
assert (w = Vcons (Vhead w) (Vtail w)) as Hw.
apply VSn_eq.

simpl; unfold Aplus; split; intros.
apply orb_prop in H.
destruct H.
unfold dot_product in IHn.
rewrite IHn in H; repeat destruct H.
exists (S x); exists (lt_n_S x0); clear IHn.

rewrite Hv; rewrite Hw.
rewrite (Vnth_cons (Vtail v) (Vhead v) (lt_n_S x0) x0).
rewrite (Vnth_cons (Vtail w) (Vhead w) (lt_n_S x0) x0).
auto.

exists 0; exists (lt_O_Sn n); rewrite Hv; rewrite Hw;
  repeat rewrite Vnth_head; auto.
unfold Amult in *; auto with *.

repeat destruct H; unfold Amult; apply Is_true_eq_true; apply orb_prop_intro.

destruct x.
right.
rewrite <- (Vnth_head (Vhead v) (Vtail v) x0); auto.
rewrite <-Hv.
rewrite <- (Vnth_head (Vhead w) (Vtail w) x0); auto.
rewrite <-Hw.
auto.

left.
rewrite Hv in H; rewrite Hw in H; generalize (lt_S_n x0); intro.
rewrite (Vnth_cons (Vtail v) (Vhead v) x0 H0) in H.
rewrite (Vnth_cons (Vtail w) (Vhead w) x0 H0) in H.
apply Is_true_eq_left; rewrite IHn; exists x; exists H0; trivial.
Qed.

Lemma existandb_matmult : forall x y,
  (M <*> N)[[x, y]] = true <-> exists z, M[[x,z]] && N[[z,y]] = true.

Proof.
intros.
unfold mat_unbound.
destruct (le_gt_dec dim x).
simpl; intuition.
discriminate.
destruct H; tauto.

destruct (le_gt_dec dim y).
intuition.
discriminate.
destruct H.
destruct (le_gt_dec dim x0).
trivial.
destruct H; symmetry; apply andb_false_r.
unfold mat_mult; rewrite mat_build_nth; unfold get_row; unfold get_col.
split; intros.
rewrite existandb_dotprod in H; repeat destruct H; exists x0.

destruct (le_gt_dec dim x0); auto with *.
apply Is_true_eq_true; unfold gt in g1; generalize (lt_unique x1 g1);
intro; subst.
rewrite Vnth_map in H; auto.
destruct H; destruct (le_gt_dec dim x0).
simpl in *; discriminate.
rewrite existandb_dotprod.
exists x0; exists g1; rewrite Vnth_map; auto with *.
Qed.

Lemma Gmorph_mult : forall x y,
  GoM (M <*> N) x y <-> (GoM M @ GoM N) x y.

Proof.
intros. unfold GoM; unfold compose. rewrite existandb_matmult.
intuition; destruct H as [z]; exists z; auto with *.
Qed.

End GoM_Compose.

(***********************************************************************)
(** Exponentiation of matrix is iteration of relation *)

Section GoM_Iter_le.

Variable M : matrix dim dim.

Fixpoint mat_exp_fast (M : matrix dim dim) n :=
  match n with
    | O => M
    | S i => let N := @mat_exp_fast M i in (N <+> id_matrix dim) <*> N
  end.

Lemma mat_id_spec : forall x y,
  (id_matrix dim)[[x,y]] = true <-> x=y /\ x<dim /\ y<dim.

Proof.
intros. split; intro. unfold mat_unbound in H.
destruct (le_gt_dec dim x). discriminate.
destruct (le_gt_dec dim y). discriminate.
unfold id_matrix in H; rewrite Vbuild_nth in H.
unfold id_vec in H; rewrite Vbuild_nth in H.
unfold A0, A1 in *; destruct (eq_nat_dec x y); auto.
discriminate.
destruct H; destruct H0; unfold mat_unbound.
destruct (le_gt_dec dim x); auto with *.
destruct (le_gt_dec dim y); auto with *.
unfold id_matrix; rewrite Vbuild_nth.
unfold id_vec; rewrite Vbuild_nth.
unfold A0, A1 in *; destruct (eq_nat_dec x y); auto.
Qed.

Lemma G_morph_id : forall x y,
  GoM (id_matrix dim) x y <-> x=y /\ x<dim /\ y<dim.

Proof.
intros. unfold GoM. apply mat_id_spec.
Qed.

Lemma Gmorph_iter_le_fast : forall n x y,
  GoM (mat_exp_fast M n) x y <-> iter_le_fast (GoM M) n x y.

Proof.
induction n; intros.
simpl; auto; tauto.
simpl; split; intros.
rewrite Gmorph_mult in H.
unfold compose in H; destruct H as [z]; destruct H.
rewrite Gmorph_plus in H. destruct H.
left; unfold compose; exists z; rewrite IHn in *; auto with *.
right; unfold GoM in H; rewrite mat_id_spec in H.
destruct H; destruct H1; subst; rewrite IHn in H0; auto with *.
rewrite Gmorph_mult.
unfold compose in *; destruct H.
destruct H as [z]; exists z; destruct H.
rewrite Gmorph_plus; split;
try left; auto; rewrite IHn; auto.
exists x; split; rewrite <- IHn in H; auto.
generalize (GoM_true_bounds H); intros.
rewrite Gmorph_plus; right; unfold GoM; rewrite mat_id_spec;
intuition; auto with *.
Qed.

(***********************************************************************)
(** High enough exponentiation is transitive closure *)

Lemma Gmorph_clos_trans : forall x y,
  GoM (mat_exp_fast M (S (log2 dim))) x y <-> GoM M! x y.

Proof.
split; intros.
rewrite Gmorph_iter_le_fast in H; rewrite iter_le_fast_exp2_same in H.
rewrite iter_le_spec in H; destruct H as [p]; destruct H.
deduce (iter_tc _ _ _ _ H0); trivial.
deduce(eq_dec_midex eq_nat_dec).
deduce (clos_trans_bound_path H0 (@GoM_restricted M)).
rewrite nfirst_length in H1; unfold inclusion in H1.
deduce (H1 _ _ H); deduce (bound_path_iter_le H2).
rewrite Gmorph_iter_le_fast; rewrite iter_le_fast_spec.
rewrite iter_le_spec in H3.
destruct H3 as [p]; exists p. intuition.
deduce (exp2_log2 dim).
omega.
Qed.

End GoM_Iter_le.

(***********************************************************************)
(** Tranposition of matrix is transposition of relation *)

Section GoM_transpose.

Variable M : matrix dim dim.

Lemma transp_mat_unbound : forall x y, M[[x,y]] = (mat_transpose M)[[y,x]].

Proof.
intros; unfold mat_unbound.
destruct (le_gt_dec dim x); auto; destruct (le_gt_dec dim y); auto.
unfold mat_transpose; rewrite mat_build_nth; trivial.
Qed.

Lemma Gmorph_transpose : forall x y,
  GoM (mat_transpose M) x y <-> transp (GoM M) x y.

Proof.
intros; unfold GoM; unfold transp; rewrite transp_mat_unbound; tauto.
Qed.

End GoM_transpose.

(***********************************************************************)
(** The "and" of matrix (element by element) is intersection of relation *)

Section GoM_intersection.

Variable M N : matrix dim dim.

Definition mat_andb := Vmap2 (Vmap2 andb (n := dim)) (n := dim).

Lemma andb_mat_unbound : forall x y,
  (mat_andb M N)[[x,y]] = M[[x,y]] && N[[x,y]].

Proof.
intros; unfold mat_unbound.
destruct (le_gt_dec dim x); auto with *.
destruct (le_gt_dec dim y); auto with *.
unfold mat_andb; repeat rewrite Vmap2_nth; auto.
Qed.

Lemma Gmorph_intersect : forall x y,
  GoM (mat_andb M N) x y <-> GoM M x y /\ GoM N x y.

Proof.
intros; unfold GoM. rewrite andb_mat_unbound.
destruct (M [[x, y]]); destruct (M [[x, y]]); intuition; simpl.
Qed.

End GoM_intersection.

(***********************************************************************)
(** Exponentation, transposition, AND of the matrix,
gives the SCC of the relation *)

Section GoM_SCC.

Definition SCC_mat M :=
  let N := mat_exp_fast M (S(log2 dim)) in
  mat_andb N (@mat_transpose dim dim N).

Variable M : matrix dim dim.

Lemma GoM_SCC : forall x y, GoM (SCC_mat M) x y <-> SCC (GoM M) x y.

Proof.
unfold SCC_mat in *; split; intros; rewrite Gmorph_intersect in *; 
try rewrite Gmorph_transpose in *; unfold transp in *;
repeat rewrite Gmorph_clos_trans in *; unfold SCC in *;
trivial.
Qed.

End GoM_SCC.

End GoM.

Notation "z [[ x , y ]] " := (@mat_unbound _ z x y) (at level 30).

(***********************************************************************)
(** Adjacency matrix of a relation. *)

Section MoG.

Variable dim : nat.
Variable R : relation nat.
Variable R_dec : forall x y, {R x y} + {~R x y}.

Definition MoG := @mat_build dim dim
  (fun x y _ _ =>
    match R_dec x y with
      | left _ => true
      | right _ => false 
    end).

Variable hyp : forall x y, R x y -> x < dim /\ y < dim.

Lemma GoM_MoG : forall x y, GoM MoG x y <-> R x y.

Proof.
intros. unfold GoM, mat_unbound. split; intros;
destruct (le_gt_dec dim x); destruct (le_gt_dec dim y);
try deduce (hyp H);
auto; intuition; try omega; try tauto; try discriminate.
unfold MoG in H; rewrite mat_build_nth in H.
destruct (R_dec x y); auto; try discriminate.
unfold MoG; rewrite mat_build_nth.
destruct (R_dec x y); auto with *.
Qed.

End MoG.
