Module Import Carrier.
Notation Hom obj := (obj -> obj -> Type) (only parsing).
Notation binop obj := (obj -> obj -> obj) (only parsing).
End Carrier.

Delimit Scope cat_scope with cat.

Section CatOps.

Context {obj : Type} (C : Hom obj).

Class Eq2 : Type :=
  eq2 : forall a b (f g : C a b), Prop.

Class Id_ : Type :=
  id_ : forall a, C a a.

Class Cat : Type :=
  cat : forall a b c, C a b -> C b c -> C a c.

Class Initial (i : obj) :=
  empty : forall a, C i a.

End CatOps.

Arguments eq2 {obj C Eq2 a b}.
Arguments id_ {obj C Id_}.
Arguments cat {obj C Cat a b c}.
Arguments empty {obj C i Initial a}.

Section CocartesianOps.

Context {obj : Type} (C : Hom obj) (bif : binop obj).

(** *** Bifctor *)

Class Bimap :=
  bimap : forall a b c d, C a c -> C b d -> C (bif a b) (bif c d).

(** *** Coproduct *)

Class CoprodCase :=
  case_ : forall a b c, C a c -> C b c -> C (bif a b) c.

Class CoprodInl :=
  inl_ : forall a b, C a (bif a b).

Class CoprodInr :=
  inr_ : forall a b, C b (bif a b).

(** *** Tensor (monoidal) *)

Class AssocR :=
  assoc_r : forall a b c, C (bif (bif a b) c) (bif a (bif b c)).

Class AssocL :=
  assoc_l : forall a b c, C (bif a (bif b c)) (bif (bif a b) c).

Class UnitL (i : obj) :=
  unit_l : forall a, C (bif i a) a.

Class UnitL' (i : obj) :=
  unit_l' : forall a, C a (bif i a).

Class UnitR (i : obj) :=
  unit_r : forall a, C (bif a i) a.

Class UnitR' (i : obj) :=
  unit_r' : forall a, C a (bif a i).

(** *** Symmetry *)

Class Swap :=
  swap : forall a b, C (bif a b) (bif b a).

End CocartesianOps.

Arguments bimap {obj C bif Bimap a b c d}.
Arguments case_ {obj C bif CoprodCase a b c}.
Arguments inl_ {obj C bif CoprodInl a b}.
Arguments inr_ {obj C bif CoprodInr a b}.
Arguments assoc_r {obj C bif AssocR a b c}.
Arguments assoc_l {obj C bif AssocL a b c}.
Arguments unit_l  {obj C bif i UnitL a}.
Arguments unit_l' {obj C bif i UnitL' a}.
Arguments unit_r  {obj C bif i UnitR a}.
Arguments unit_r' {obj C bif i UnitR' a}.
Arguments swap {obj C bif Swap a b}.

Notation assoc_r_ a b c := (@assoc_r _ _ _ _ a b c) (only parsing).
Notation assoc_l_ a b c := (@assoc_l _ _ _ _ a b c) (only parsing).
Notation unit_l_  i a := (@unit_l  _ _ _ i _ a) (only parsing).
Notation unit_l'_ i a := (@unit_l' _ _ _ i _ a) (only parsing).
Notation unit_r_  i a := (@unit_r  _ _ _ i _ a) (only parsing).
Notation unit_r'_ i a := (@unit_r' _ _ _ i _ a) (only parsing).
Notation swap_ a b := (@swap _ _ _ _ a b) (only parsing).

Notation case__ C := (@case_ _ C _ _ _ _ _)
  (only parsing).

Module Import CatNotations.

Infix "⩯" := eq2 (at level 70) : cat_scope.
Infix ">=>" := cat (at level 50, left associativity) : cat_scope.

End CatNotations.

Local Open Scope cat.

(** ** Derived constructions *)

Definition merge {obj : Type} {C : Hom obj} {bif : binop obj}
           {Id_C : Id_ C} {Coproduct_C : CoprodCase C bif}
  : forall {a : obj}, C (bif a a) a :=
  fun a => case_ (id_ a) (id_ a).

Section CocartesianConstruct.

Context {obj : Type} (C : Hom obj) (Cat_C : Cat C).
Variables (SUM : binop obj) (Coprod_SUM : CoprodCase C SUM)
          (CoprodInl_SUM : CoprodInl C SUM)
          (CoprodInr_SUM : CoprodInr C SUM).

Global Instance Bimap_Coproduct : Bimap C SUM :=
  fun a b c d (f : C a c) (g : C b d) =>
    case_ (f >=> inl_) (g >=> inr_).

Global Instance Swap_Coproduct : Swap C SUM :=
  fun a b => case_ inr_ inl_.

Global Instance AssocR_Coproduct : AssocR C SUM :=
  fun a b c => case_ (case_ inl_ (inl_ >=> inr_))
                    (inr_ >=> inr_).

Global Instance AssocL_Coproduct : AssocL C SUM :=
  fun a b c => case_ (inl_ >=> inl_)
                    (case_ (inr_ >=> inl_) inr_).

Variables (Id_C : Id_ C) (I : obj) (Initial_I : Initial C I).

Global Instance UnitL_Coproduct : UnitL C SUM I :=
  fun a => case_ empty (id_ a).

Global Instance UnitL'_Coproduct : UnitL' C SUM I :=
  fun a => inr_.

Global Instance UnitR_Coproduct : UnitR C SUM I :=
  fun a => case_ (id_ a) empty.

Global Instance UnitR'_Coproduct : UnitR' C SUM I :=
  fun a => inl_.

End CocartesianConstruct.

(** ** Automatic solver of reassociating sums *)

Section RESUM.

Context {obj : Type} (C : Hom obj) (bif : binop obj).
Context `{Id_ _ C} `{Cat _ C}.
Context `{CoprodCase _ C bif} `{CoprodInl _ C bif} `{CoprodInr _ C bif}.

Class ReSum (a b : obj) :=
  resum : C a b.

Global Instance ReSum_id `{Id_ _ C} a : ReSum a a := { resum := id_ a }.
Global Instance ReSum_sum a b c
         `{ReSum a c} `{ReSum b c} : ReSum (bif a b) c :=
  { resum := case_ resum resum }.
Global Instance ReSum_inl a b c `{ReSum a b} : ReSum a (bif b c) :=
  { resum := resum >=> inl_ }.
Global Instance ReSum_inr a b c `{ReSum a b} : ReSum a (bif c b) :=
  { resum := resum >=> inr_ }.

(* Usage template:

[[
Opaque cat.
Opaque id.
Opaque case_.
Opaque inl_.
Opaque inr_.

    (* where the category is (->)  vv *)
Definition f {X Y Z} : complex_sum -> another_complex_sum :=
  Eval compute in resum.

Transparent cat.
Transparent id.
Transparent case_.
Transparent inl_.
Transparent inr_.
]]
*)

End RESUM.
