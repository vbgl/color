(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Frederic Blanqui, 2009-03-18

extension of BigZ
*)

Set Implicit Arguments.

From CoLoR Require Import LogicUtil BigNUtil NatUtil.
From Bignums Require Export BigZ.

From Coq Require Import Zcompare.

Open Scope bigZ_scope.

Lemma compare_antisym : forall x y, CompOpp (x?=y) = (y?=x).

Proof. intros x y. rewrite !BigZ.spec_compare. apply Zcompare_antisym. Qed.

From CoLoR Require Import OrdUtil.

Lemma compare_antisym_eq : forall x y c, (x?=y = CompOpp c) <-> (y?=x = c).

Proof.
  intros. rewrite <- (compare_antisym y x). split; intro.
  rewrite CompOpp_eq in H. hyp. rewrite H. refl.
Qed.

Lemma le_gt_dec : forall n m, {n <= m} + {n > m}.

Proof.
  intros. unfold BigZ.le, BigZ.lt. destruct (Z_le_gt_dec [n] [m]).
  left. hyp. right. unfold Z.lt. rewrite <- Zcompare_antisym, g. refl.
Defined.
