(*
  Apply cv translator to standard theories list, pair, sptree, etc.
*)
open HolKernel Parse boolLib bossLib;
open cv_typeTheory cvTheory cv_typeLib cv_repLib;
open arithmeticTheory wordsTheory cv_repTheory cv_primTheory cv_transLib;
open pairTheory listTheory optionTheory sumTheory alistTheory indexedListsTheory;
open rich_listTheory;

val _ = new_theory "cv_std";

(*----------------------------------------------------------*
   pair
 *----------------------------------------------------------*)

val _ = cv_rep_for [] “(x:'a, y:'b)”

Theorem cv_FST[cv_rep]:
  f_a (FST v) = cv_fst ((from_pair f_a f_b) (v: 'a # 'b))
Proof
  Cases_on ‘v’ \\ gvs [from_pair_def]
QED

Theorem cv_SND[cv_rep]:
  f_b (SND v) = cv_snd ((from_pair f_a f_b) (v: 'a # 'b))
Proof
  Cases_on ‘v’ \\ gvs [from_pair_def]
QED

(*----------------------------------------------------------*
   option
 *----------------------------------------------------------*)

val _ = cv_rep_for [] “SOME (x:'a)”

Theorem cv_THE[cv_rep]:
  v ≠ NONE ⇒ f_a (THE v) = cv_snd ((from_option f_a) (v:'a option))
Proof
  Cases_on ‘v’ \\ gvs [from_option_def]
QED

Theorem cv_IS_SOME[cv_rep]:
  b2c (IS_SOME v) = cv_ispair ((from_option f_a) (v:'a option))
Proof
  Cases_on ‘v’ \\ gvs [from_option_def]
QED

Theorem cv_IS_NONE[cv_rep]:
  b2c (IS_NONE v) = cv_sub (Num 1) (cv_ispair ((from_option f_a) (v:'a option)))
Proof
  Cases_on ‘v’ \\ gvs [from_option_def]
QED

(*----------------------------------------------------------*
   sum
 *----------------------------------------------------------*)

val res = cv_trans ISL;
val res = cv_trans ISR;

val res = cv_trans_pre OUTL;

Theorem OUTL_pre[cv_pre]:
  OUTL_pre x ⇔ ISL x
Proof
  Cases_on ‘x’ \\ fs [res]
QED

val res = cv_trans_pre OUTR;

Theorem OUTR_pre[cv_pre]:
  OUTR_pre x ⇔ ISR x
Proof
  Cases_on ‘x’ \\ fs [res]
QED

(*----------------------------------------------------------*
   list
 *----------------------------------------------------------*)

Theorem cv_HD[cv_rep]:
  v ≠ [] ⇒ f_a (HD v) = cv_fst ((from_list f_a) (v:'a list))
Proof
  Cases_on ‘v’ \\ fs [from_list_def]
QED

Theorem cv_TL[cv_rep]:
  (from_list f_a) (TL v) = cv_snd ((from_list f_a) (v:'a list))
Proof
  Cases_on ‘v’ \\ fs [from_list_def]
QED

val res = cv_trans oHD_def;
val res = cv_trans NULL_DEF;
val res = cv_trans oEL_def;

val res = cv_trans SNOC;
val res = cv_trans APPEND;

val res = cv_trans FLAT;

val res = cv_trans TAKE_def;

val res = cv_trans DROP_def;

val res = cv_trans_pre EL;

val res = cv_trans LEN_DEF;
val res = cv_trans LENGTH_LEN;

val res = cv_trans REV_DEF;
val res = cv_trans REVERSE_REV;

val res = cv_trans SUM_ACC_DEF;
val res = cv_trans SUM_SUM_ACC;

Theorem FRONT[local]:
  FRONT (x::xs) = case xs of [] => [] | _ => x :: FRONT xs
Proof
  Cases_on ‘xs’ \\ gvs [FRONT_DEF]
QED

val res = cv_trans_pre FRONT;

Theorem FRONT_pre[cv_pre]:
  ∀xs. FRONT_pre xs ⇔ xs ≠ []
Proof
  Induct_on ‘xs’
  \\ once_rewrite_tac [res] \\ gvs []
  \\ Cases_on ‘xs’ \\ gvs []
QED

Theorem LAST[local]:
  LAST (x::xs) = case xs of [] => x | _ => LAST xs
Proof
  Cases_on ‘xs’ \\ gvs [LAST_DEF]
QED

val res = cv_trans_pre LAST;

Theorem LAST_pre[cv_pre]:
  ∀xs. LAST_pre xs ⇔ xs ≠ []
Proof
  Induct_on ‘xs’
  \\ once_rewrite_tac [res] \\ gvs []
  \\ Cases_on ‘xs’ \\ gvs []
QED

Definition list_mem_def:
  list_mem y [] = F ∧
  list_mem y (x::xs) = if x = y then T else list_mem y xs
End

val res = cv_trans list_mem_def;

val lemma = cv_rep_for [] “list_mem x xs” |> DISCH_ALL

Theorem cv_rep_MEM[cv_rep]:
  from_to f_a t_a ⇒
  cv_rep T (cv_list_mem (f_a x) (from_list f_a xs)) b2c (MEM (x:'a) xs)
Proof
  qsuff_tac ‘MEM x xs = list_mem x xs’
  >- (simp [] \\ mp_tac lemma \\ fs [])
  \\ Induct_on ‘xs’ \\ gvs [list_mem_def] \\ metis_tac []
QED

Triviality conj_eq_if:
  x ∧ y ⇔ if x then y else F
Proof
  Cases_on ‘x’ \\ gvs []
QED

Triviality if_not:
  (if ~b then x else y) = if b then y else x
Proof
  Cases_on ‘b’ \\ gvs []
QED

val all_distinct =
  ALL_DISTINCT |> DefnBase.one_line_ify NONE |> PURE_REWRITE_RULE [conj_eq_if,if_not]

val res = cv_trans_pre all_distinct;

val is_prefix =
  isPREFIX |> DefnBase.one_line_ify NONE |> PURE_REWRITE_RULE [conj_eq_if,if_not]

val res = cv_trans_pre is_prefix;

val res = cv_trans LUPDATE_DEF;

Triviality index_of:
  INDEX_OF x [] = NONE ∧
  INDEX_OF x (y::ys) =
    if x = y then SOME 0 else
      case INDEX_OF x ys of
      | NONE => NONE
      | SOME n => SOME (n+1)
Proof
  gvs [INDEX_OF_def,INDEX_FIND_def]
  \\ rw [] \\ gvs []
  \\ simp [Once listTheory.INDEX_FIND_add]
  \\ Cases_on ‘INDEX_FIND 0 ($= x) ys’ \\ gvs []
  \\ rename [‘_ = SOME y’] \\ PairCases_on ‘y’ \\ gvs []
QED

val res = cv_trans_pre index_of

Definition replicate_acc_def:
  replicate_acc n x acc =
    if n = 0:num then acc else replicate_acc (n-1) x (x::acc)
End

val res = cv_trans replicate_acc_def;

Theorem REPLICATE:
  REPLICATE n c = replicate_acc n c []
Proof
  qsuff_tac ‘∀n c acc. replicate_acc n c acc = REPLICATE n c ++ acc’ >- gvs []
  \\ Induct \\ gvs [] \\ simp [Once replicate_acc_def]
  \\ rewrite_tac [GSYM SNOC_APPEND,SNOC_REPLICATE] \\ gvs []
QED

val res = cv_trans REPLICATE;
val res = cv_trans (PAD_LEFT |> REWRITE_RULE [GSYM REPLICATE_GENLIST]);
val res = cv_trans (PAD_RIGHT |> REWRITE_RULE [GSYM REPLICATE_GENLIST]);

val res = cv_trans nub_def;

val res = cv_trans_pre ALOOKUP_def

val res = cv_trans findi_def (* TODO: improve *)

val res = cv_trans_pre ZIP_def (* TODO: improve *)

Theorem UNZIP_eq:
  UNZIP ts =
    case ts of
    | [] => ([],[])
    | (x::xs) => let (t1,t2) = UNZIP xs in (FST x :: t1, SND x :: t2)
Proof
  Cases_on ‘ts’ \\ gvs []
  \\ gvs [UNZIP] \\ Cases_on ‘UNZIP t’ \\ gvs []
QED

val res = cv_trans_pre UNZIP_eq

Definition genlist_def:
  genlist i f 0 = [] ∧
  genlist i f (SUC n) = f i :: genlist (i+1:num) f n
End

Theorem genlist_eq_GENLIST[cv_inline]:
  GENLIST = genlist 0
Proof
  qsuff_tac ‘∀i f n. genlist i f n = GENLIST (f o (λk. k + i)) n’
  >- (gvs [FUN_EQ_THM] \\ rw [] \\ AP_THM_TAC \\ AP_TERM_TAC \\ gvs [FUN_EQ_THM])
  \\ Induct_on ‘n’ \\ gvs [genlist_def]
  \\ rewrite_tac [listTheory.GENLIST_CONS] \\ gvs []
  \\ rw [] \\ AP_THM_TAC \\ AP_TERM_TAC \\ gvs [FUN_EQ_THM,arithmeticTheory.ADD1]
QED

Theorem K_THM[cv_inline] = combinTheory.K_THM;
Theorem I_THM[cv_inline] = combinTheory.I_THM;
Theorem o_THM[cv_inline] = combinTheory.o_THM;

(*----------------------------------------------------------*
   sptree / num_map / num_set
 *----------------------------------------------------------*)

val res = cv_trans sptreeTheory.insert_def;
val res = cv_trans sptreeTheory.lookup_def;

val def = sptreeTheory.fromList_def;
val res = cv_auto_trans sptreeTheory.fromList_def;

val res = cv_trans sptreeTheory.mk_BN_def;
val res = cv_trans sptreeTheory.mk_BS_def;
val res = cv_trans sptreeTheory.delete_def;

val res = cv_trans sptreeTheory.union_def;
val res = cv_trans sptreeTheory.inter_def;
val res = cv_trans sptreeTheory.difference_def;

val res = cv_auto_trans sptreeTheory.toList_def;
val res = cv_auto_trans sptreeTheory.mk_wf_def;
val res = cv_auto_trans sptreeTheory.size_def;

(*
val res = cv_trans sptreeTheory.list_to_num_set_def;
val res = cv_trans sptreeTheory.list_insert_def;
*)
val res = cv_trans sptreeTheory.alist_insert_def;

val res = cv_trans sptreeTheory.lrnext_def;

(* val res = cv_auto_trans sptreeTheory.toAList_def; *)

val res = cv_trans sptreeTheory.spt_center_def
val res = cv_auto_trans sptreeTheory.apsnd_cons_def;
val res = cv_auto_trans_pre sptreeTheory.spt_centers_def;

Theorem spt_centers_pre[cv_pre,local]:
  ∀x y. spt_centers_pre x y
Proof
  ho_match_mp_tac sptreeTheory.spt_centers_ind
  \\ rpt strip_tac \\ once_rewrite_tac [res] \\ fs []
QED

val res = cv_trans sptreeTheory.spt_left_def
val res = cv_trans sptreeTheory.spt_right_def

(*
val res = cv_auto_trans sptreeTheory.spts_to_alist_def
val res = cv_auto_trans sptreeTheory.toSortedAList_def
*)

val _ = export_theory();
