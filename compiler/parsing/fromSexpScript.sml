open preamble match_goal
open simpleSexpTheory astTheory
open monadsyntax

val _ = new_theory "fromSexp";

val _ = temp_overload_on ("return", ``SOME``)
val _ = temp_overload_on ("fail", ``NONE``)
val _ = temp_overload_on ("lift", ``OPTION_MAP``)

val _ = overload_on ("monad_bind", ``OPTION_BIND``)
val _ = overload_on ("monad_unitbind", ``OPTION_IGNORE_BIND``)

val _ = computeLib.add_persistent_funs ["option.OPTION_BIND_def",
                                        "option.OPTION_IGNORE_BIND_def",
                                        "option.OPTION_GUARD_def",
                                        "option.OPTION_CHOICE_def",
                                        "option.OPTION_MAP2_DEF"]

val _ = overload_on ("assert", ``option$OPTION_GUARD : bool -> unit option``)
val _ = overload_on ("++", ``option$OPTION_CHOICE``)

(* TODO: move*)

val OPTION_MAP_INJ = Q.store_thm("OPTION_MAP_INJ",
  `(∀x y. f x = f y ⇒ x = y)
   ⇒ ∀o1 o2.
     OPTION_MAP f o1 = OPTION_MAP f o2 ⇒ o1 = o2`,
  strip_tac \\ Cases \\ Cases \\ simp[]);

val OPTION_CHOICE_NONE = Q.store_thm("OPTION_CHOICE_NONE[simp]",
  `OPTION_CHOICE x NONE = x`,
  Cases_on`x`>>simp[]);

val OPTION_BIND_OPTION_GUARD = Q.store_thm("OPTION_BIND_OPTION_GUARD",
  `OPTION_BIND (OPTION_GUARD b) f = if b then f () else NONE`, rw[])

val OPTION_IGNORE_BIND_OPTION_GUARD = Q.store_thm("OPTION_IGNORE_BIND_OPTION_GUARD",
  `OPTION_IGNORE_BIND (OPTION_GUARD b) f = if b then f else NONE`, rw[])

val OPTION_APPLY_MAP3 = Q.store_thm("OPTION_APPLY_MAP3",
  `OPTION_APPLY (OPTION_APPLY (OPTION_MAP f x) y) z = SOME r ⇔
   ∃a b c. x = SOME a ∧ y = SOME b ∧ z = SOME c ∧ f a b c = r`,
  Cases_on`x`\\simp[] \\ rw[EQ_IMP_THM] \\ rw[]
  \\ Cases_on`y`\\fs[]);

val FOLDR_SX_CONS_INJ = Q.store_thm("FOLDR_SX_CONS_INJ",
  `∀l1 l2. FOLDR SX_CONS nil l1 = FOLDR SX_CONS nil l2 ⇒ l1 = l2`,
  Induct \\ simp[]
  >- ( Induct \\ simp[] )
  \\ gen_tac \\ Induct \\ simp[]);

val strip_sxcons_11 = Q.store_thm("strip_sxcons_11",
  `∀s1 s2 x. strip_sxcons s1 = SOME x ∧ strip_sxcons s2 = SOME x ⇒ s1 = s2`,
  ho_match_mp_tac simpleSexpTheory.strip_sxcons_ind
  \\ ntac 4 strip_tac
  \\ simp[Once simpleSexpTheory.strip_sxcons_def]
  \\ CASE_TAC \\ fs[] \\ strip_tac \\ rveq \\ fs[]
  \\ pop_assum mp_tac
  \\ simp[Once simpleSexpTheory.strip_sxcons_def]
  \\ CASE_TAC \\ fs[] \\ strip_tac \\ rveq \\ fs[]);

val dstrip_sexp_size = store_thm(
  "dstrip_sexp_size",
  ``∀s sym args. dstrip_sexp s = SOME (sym, args) ⇒
                 ∀e. MEM e args ⇒ sexp_size e < sexp_size s``,
  Induct >> simp[dstrip_sexp_def, sexp_size_def] >>
  qcase_tac `sexp_CASE sxp` >> Cases_on `sxp` >> simp[] >> rpt strip_tac >>
  qcase_tac `MEM sxp0 sxpargs` >> qcase_tac `strip_sxcons sxp'` >>
  `sxMEM sxp0 sxp'` by metis_tac[sxMEM_def] >> imp_res_tac sxMEM_sizelt >>
  simp[]);

val dstrip_sexp_SOME = Q.store_thm("dstrip_sexp_SOME",
  `dstrip_sexp s = SOME x ⇔
   ∃sym sa args. s =
     SX_CONS (SX_SYM sym) sa ∧
     strip_sxcons sa = SOME args ∧
     (x = (sym,args))`,
  Cases_on`s`>>simp[dstrip_sexp_def]>>
  every_case_tac>>simp[])

val strip_sxcons_SOME_NIL = Q.store_thm("strip_sxcons_SOME_NIL[simp]",
  `strip_sxcons s = SOME [] ⇔ s = nil`,
  rw[Once strip_sxcons_def] >>
  every_case_tac >> simp[])

val type_ind =
  (TypeBase.induction_of``:t``)
  |> Q.SPECL[`P`,`EVERY P`]
  |> SIMP_RULE list_ss []
  |> UNDISCH_ALL |> CONJUNCT1
  |> DISCH_ALL |> Q.GEN`P`

val pat_ind =
  (TypeBase.induction_of``:pat``)
  |> Q.SPECL[`P`,`EVERY P`]
  |> SIMP_RULE list_ss []
  |> UNDISCH_ALL |> CONJUNCT1
  |> DISCH_ALL |> Q.GEN`P`

val exp_ind =
  (TypeBase.induction_of``:exp``)
  |> Q.SPECL[`P`,`EVERY (P o SND o SND)`,`P o SND o SND`,`EVERY (P o SND)`,`P o SND`,`P o SND`,`EVERY P`]
  |> SIMP_RULE list_ss []
  |> UNDISCH_ALL |> CONJUNCT1
  |> DISCH_ALL |> Q.GEN`P`
(* -- *)


val odestSXSTR_def = Define`
  (odestSXSTR (SX_STR s) = SOME s) ∧
  (odestSXSTR _ = NONE)
`;
val odestSXSYM_def = Define`
  (odestSXSYM (SX_SYM s) = SOME s) ∧
  (odestSXSYM _ = NONE)
`;

val odestSXNUM_def = Define`
  (odestSXNUM (SX_NUM n) = SOME n) ∧
  (odestSXNUM _ = NONE)
`;

val sexpopt_def = Define`
  sexpopt p s =
    do
       nm <- odestSXSYM s ;
       assert(nm = "NONE");
       return NONE
    od ++
    do
      (nm,args) <- dstrip_sexp s;
      assert(nm = "SOME" ∧ LENGTH args = 1);
      lift SOME (p (HD args))
    od
`;

val sexplist_def = Define`
  sexplist p s =
    case s of
      SX_CONS h t =>
        do
          ph <- p h;
          pt <- sexplist p t;
          return (ph::pt)
        od
    | SX_SYM s => if s = "nil" then return [] else fail
    | _ => fail
`;

val sexppair_def = Define`
  sexppair p1 p2 s =
    case s of
      SX_CONS s1 s2 => lift2 (,) (p1 s1) (p2 s2)
    | _ => fail
`;

val sexppair_CONG = store_thm(
  "sexppair_CONG[defncong]",
  ``∀s1 s2 p1 p1' p2 p2'.
       s1 = s2 ∧
       (∀s. (∃s'. s2 = SX_CONS s s') ⇒ p1 s = p1' s) ∧
       (∀s. (∃s'. s2 = SX_CONS s' s) ⇒ p2 s = p2' s)
      ⇒
       sexppair p1 p2 s1 = sexppair p1' p2' s2``,
  simp[] >> Cases >> simp[sexppair_def])


val strip_sxcons_FAIL_sexplist_FAIL = store_thm(
  "strip_sxcons_FAIL_sexplist_FAIL",
  ``∀s. (strip_sxcons s = NONE) ⇒ (sexplist p s = NONE)``,
  Induct >> simp[Once strip_sxcons_def, Once sexplist_def] >>
  metis_tac[TypeBase.nchotomy_of ``:α option``]);

val monad_bind_FAIL = store_thm(
  "monad_bind_FAIL",
  ``monad_bind m1 (λx. fail) = fail``,
  Cases_on `m1` >> simp[]);

val monad_unitbind_CONG = store_thm(
  "monad_unitbind_CONG[defncong]",
  ``∀m11 m21 m12 m22.
      m11 = m12 ∧ (m12 = SOME () ⇒ m21 = m22) ⇒
      monad_unitbind m11 m21 = monad_unitbind m12 m22``,
  simp[] >> rpt gen_tac >> qcase_tac `m12 = SOME ()` >>
  Cases_on `m12` >> simp[]);

val sexplist_CONG = store_thm(
  "sexplist_CONG[defncong]",
  ``∀s1 s2 p1 p2.
      (s1 = s2) ∧ (∀e. sxMEM e s2 ⇒ p1 e = p2 e) ⇒
      (sexplist p1 s1 = sexplist p2 s2)``,
  simp[sxMEM_def] >> Induct >> dsimp[Once strip_sxcons_def]
  >- (ONCE_REWRITE_TAC [sexplist_def] >> simp[] >>
      qcase_tac `strip_sxcons t` >> Cases_on `strip_sxcons t` >>
      simp[]
      >- (simp[strip_sxcons_FAIL_sexplist_FAIL, monad_bind_FAIL]) >>
      map_every qx_gen_tac [`p1`, `p2`] >> strip_tac >>
      Cases_on `p2 s2` >> simp[] >> fs[] >> metis_tac[]) >>
  simp[sexplist_def]);

val _ = temp_overload_on ("guard", ``λb m. monad_unitbind (assert b) m``)


val sexpid_def = Define`
  sexpid p s =
    do
       (nm, args) <- dstrip_sexp s;
       (guard (nm = "Short" ∧ LENGTH args = 1)
              (lift Short (p (EL 0 args))) ++
        guard (nm = "Long" ∧ LENGTH args = 2)
              (lift2 Long (odestSXSTR (EL 0 args)) (p (EL 1 args))))
    od
`;

val sexptctor_def = Define`
  sexptctor s =
    do
       (nm, args) <- dstrip_sexp s ;
       assert(nm = "TC_name" ∧ LENGTH args = 1);
       lift TC_name (sexpid odestSXSTR (EL 0 args))
    od ++
    do
      nm <- odestSXSYM s ;
      (guard (nm = "TC_int") (return TC_int) ++
       guard (nm = "TC_char") (return TC_char) ++
       guard (nm = "TC_string") (return TC_string) ++
       guard (nm = "TC_ref") (return TC_ref) ++
       guard (nm = "TC_word8") (return TC_word8) ++
       guard (nm = "TC_word64") (return TC_word64) ++
       guard (nm = "TC_word8array") (return TC_word8array) ++
       guard (nm = "TC_fn") (return TC_fn) ++
       guard (nm = "TC_tup") (return TC_tup) ++
       guard (nm = "TC_exn") (return TC_exn) ++
       guard (nm = "TC_vector") (return TC_vector) ++
       guard (nm = "TC_array") (return TC_array))
    od
`;

val sexptype_def = tDefine "sexptype" `
  sexptype s =
    do
       (s, args) <- dstrip_sexp s ;
       (guard (s = "Tvar" ∧ LENGTH args = 1)
              (lift Tvar (odestSXSTR (EL 0 args))) ++
        guard (s = "Tvar_db" ∧ LENGTH args = 1)
              (lift Tvar_db (odestSXNUM (EL 0 args))) ++
        guard (s = "Tapp" ∧ LENGTH args = 2)
              (lift2 Tapp (sexplist sexptype (EL 0 args))
                     (sexptctor (EL 1 args))))
    od
` (WF_REL_TAC `measure sexp_size` >> simp[] >> rpt strip_tac >>
   qcase_tac `sxMEM s0 (HD args)` >>
   `sexp_size s0 < sexp_size (HD args)` by metis_tac[sxMEM_sizelt] >>
   `MEM (HD args) args`
      by metis_tac[DECIDE ``0n < 2``, rich_listTheory.EL_MEM, listTheory.EL] >>
   `sexp_size (HD args) < sexp_size s` by metis_tac[dstrip_sexp_size] >>
   simp[]);

val sexplit_def = Define`
  sexplit s =
    lift (IntLit o (&)) (odestSXNUM s) ++
    lift StrLit (odestSXSTR s) ++
    do
      (nm,args) <- dstrip_sexp s;
      assert(LENGTH args = 1);
      guard (nm = "-") (OPTION_BIND (odestSXNUM (HD args)) (λn. if n = 0 then NONE else SOME (IntLit (-&n)))) ++
      guard (nm = "char")
            do
              cs <- odestSXSTR (HD args);
              assert(LENGTH cs = 1);
              return (Char (HD cs))
            od ++
      guard (nm = "word8")
            do
              n <- odestSXNUM (HD args);
              assert(n < 256);
              return (Word8 (n2w n))
            od ++
      guard (nm = "word64")
            do
              n <- odestSXNUM (HD args);
              assert(n < 2**64);
              return (Word64 (n2w n))
            od
    od
`;

(* don't require Pvar constructors; bare strings can be pattern variables.
   Unclear if this sort of special-casing is ever likely to be helpful *)
val sexppat_def = tDefine "sexppat" `
  sexppat s =
    lift Pvar (odestSXSTR s) ++
    do
      (nm, args) <- dstrip_sexp s;
      guard (nm = "Plit" ∧ LENGTH args = 1)
            (lift Plit (sexplit (EL 0 args))) ++
      guard (nm = "Pcon" ∧ LENGTH args = 2)
            (lift2 Pcon (sexpopt (sexpid odestSXSTR) (EL 0 args))
                        (sexplist sexppat (EL 1 args))) ++
      guard (nm = "Pref" ∧ LENGTH args = 1) (lift Pref (sexppat (EL 0 args)))
    od
`
  (WF_REL_TAC `measure sexp_size` >> simp[] >> rpt strip_tac
   >- metis_tac[arithmeticTheory.LESS_TRANS, rich_listTheory.EL_MEM,
                DECIDE ``1n < 2``, sxMEM_sizelt, dstrip_sexp_size]
   >- metis_tac[rich_listTheory.EL_MEM, DECIDE ``0n < 1``, listTheory.EL,
                dstrip_sexp_size])

val sexpop_def = Define`
  (sexpop (SX_SYM s) =
  if s = "OpnPlus" then SOME (Opn Plus) else
  if s = "OpnMinus" then SOME (Opn Minus) else
  if s = "OpnTimes" then SOME (Opn Times) else
  if s = "OpnDivide" then SOME (Opn Divide) else
  if s = "OpnModulo" then SOME (Opn Modulo) else
  if s = "OpbLt" then SOME (Opb Lt) else
  if s = "OpbGt" then SOME (Opb Gt) else
  if s = "OpbLeq" then SOME (Opb Leq) else
  if s = "OpbGeq" then SOME (Opb Geq) else
  if s = "Opw8Andw" then SOME (Opw W8 Andw) else
  if s = "Opw8Orw" then SOME (Opw W8 Orw) else
  if s = "Opw8Xor" then SOME (Opw W8 Xor) else
  if s = "Opw8Add" then SOME (Opw W8 Add) else
  if s = "Opw8Sub" then SOME (Opw W8 Sub) else
  if s = "Opw64Andw" then SOME (Opw W64 Andw) else
  if s = "Opw64Orw" then SOME (Opw W64 Orw) else
  if s = "Opw64Xor" then SOME (Opw W64 Xor) else
  if s = "Opw64Add" then SOME (Opw W64 Add) else
  if s = "Opw64Sub" then SOME (Opw W64 Sub) else
  if s = "Equality" then SOME Equality else
  if s = "Opapp" then SOME Opapp else
  if s = "Opassign" then SOME Opassign else
  if s = "Opref" then SOME Opref else
  if s = "Opderef" then SOME Opderef else
  if s = "Aw8alloc" then SOME Aw8alloc else
  if s = "Aw8sub" then SOME Aw8sub else
  if s = "Aw8length" then SOME Aw8length else
  if s = "Aw8update" then SOME Aw8update else
  if s = "Ord" then SOME Ord else
  if s = "Chr" then SOME Chr else
  if s = "W8fromInt" then SOME (WordFromInt W8) else
  if s = "W8toInt" then SOME (WordToInt W8) else
  if s = "W64fromInt" then SOME (WordFromInt W64) else
  if s = "W64toInt" then SOME (WordToInt W64) else
  if s = "ChopbLt" then SOME (Chopb Lt) else
  if s = "ChopbGt" then SOME (Chopb Gt) else
  if s = "ChopbLeq" then SOME (Chopb Leq) else
  if s = "ChopbGeq" then SOME (Chopb Geq) else
  if s = "Explode" then SOME Explode else
  if s = "Implode" then SOME Implode else
  if s = "Strlen" then SOME Strlen else
  if s = "VfromList" then SOME VfromList else
  if s = "Vsub" then SOME Vsub else
  if s = "Vlength" then SOME Vlength else
  if s = "Aalloc" then SOME Aalloc else
  if s = "Asub" then SOME Asub else
  if s = "Alength" then SOME Alength else
  if s = "Aupdate" then SOME Aupdate else NONE) ∧
  (sexpop (SX_CONS (SX_SYM s) (SX_NUM n)) =
    if s = "FFI" then SOME (FFI n) else
    if s = "Shift8Lsl" then SOME (Shift W8 Lsl n) else
    if s = "Shift8Lsr" then SOME (Shift W8 Lsr n) else
    if s = "Shift8Asr" then SOME (Shift W8 Asr n) else
    if s = "Shift64Lsl" then SOME (Shift W64 Lsl n) else
    if s = "Shift64Lsr" then SOME (Shift W64 Lsr n) else
    if s = "Shift64Asr" then SOME (Shift W64 Asr n) else NONE) ∧
  (sexpop _ = NONE)`;

val sexplop_def = Define`
  (sexplop (SX_SYM s) =
   if s = "And" then SOME And else
   if s = "Or" then SOME Or else NONE) ∧
  (sexplop _ = NONE)`;

val sexpexp_def = tDefine "sexpexp" `
  sexpexp s =
    do
      (nm, args) <- dstrip_sexp s;
      guard (nm = "Raise" ∧ LENGTH args = 1)
            (lift Raise (sexpexp (EL 0 args))) ++
      guard (nm = "Handle" ∧ LENGTH args = 2)
            (lift2 Handle
                   (sexpexp (EL 0 args))
                   (sexplist (sexppair sexppat sexpexp) (EL 1 args))) ++
      guard (nm = "Lit" ∧ LENGTH args = 1)
            (lift Lit (sexplit (EL 0 args))) ++
      guard (nm = "Con" ∧ LENGTH args = 2)
            (lift2 Con
                   (sexpopt (sexpid odestSXSTR) (EL 0 args))
                   (sexplist sexpexp (EL 1 args))) ++
      guard (nm = "Var" ∧ LENGTH args = 1)
            (lift Var (sexpid odestSXSTR (EL 0 args))) ++
      guard (nm = "Fun" ∧ LENGTH args = 2)
            (lift2 Fun (odestSXSTR (EL 0 args)) (sexpexp (EL 1 args))) ++
      guard (nm = "App" ∧ LENGTH args = 2)
            (lift2 App (sexpop (EL 0 args)) (sexplist sexpexp (EL 1 args))) ++
      guard (nm = "Log" ∧ LENGTH args = 3)
            (lift Log (sexplop (EL 0 args)) <*>
                      (sexpexp (EL 1 args)) <*>
                      (sexpexp (EL 2 args))) ++
      guard (nm = "If" ∧ LENGTH args = 3)
            (lift If (sexpexp (EL 0 args)) <*>
                     (sexpexp (EL 1 args)) <*>
                     (sexpexp (EL 2 args))) ++
      guard (nm = "Mat" ∧ LENGTH args = 2)
            (lift2 Mat
              (sexpexp (EL 0 args))
              (sexplist (sexppair sexppat sexpexp) (EL 1 args))) ++
      guard (nm = "Let" ∧ LENGTH args = 3)
            (lift Let (sexpopt odestSXSTR (EL 0 args)) <*>
                      (sexpexp (EL 1 args)) <*>
                      (sexpexp (EL 2 args))) ++
      guard (nm = "Letrec" ∧ LENGTH args = 2)
            (lift2 Letrec
              (sexplist (sexppair odestSXSTR (sexppair odestSXSTR sexpexp)) (EL 0 args))
              (sexpexp (EL 1 args)))
    od
`
  (WF_REL_TAC `measure sexp_size` >> simp[] >> rpt strip_tac
   >> TRY
     (qcase_tac `sxMEM sx0 (EL 1 args)` >>
       `sexp_size sx0 < sexp_size (EL 1 args)` by simp[sxMEM_sizelt] >>
       rw[] >> fs[sexp_size_def] >>
       `sexp_size (EL 1 args) < sexp_size s`
         by simp[dstrip_sexp_size, rich_listTheory.EL_MEM] >>
       simp[])
   >- (
     rw[] >>
     imp_res_tac dstrip_sexp_size >>
     imp_res_tac sxMEM_sizelt >>
     fs[sexp_size_def] >>
     `sexp_size a < sexp_size (HD args)` by decide_tac >>
     metis_tac[listTheory.EL,rich_listTheory.EL_MEM,DECIDE``0n < 2``,arithmeticTheory.LESS_TRANS])
   >> metis_tac[rich_listTheory.EL_MEM, listTheory.EL,
                DECIDE ``1n < 2 ∧ 0n < 2 ∧ 0n < 1 ∧ 2n < 3 ∧ 0n < 3 ∧ 1n < 3``,
                dstrip_sexp_size, sxMEM_sizelt, arithmeticTheory.LESS_TRANS])

val sexptype_def_def = Define`
  sexptype_def =
  sexplist
    (sexppair (sexplist odestSXSTR)
      (sexppair odestSXSTR
        (sexplist (sexppair odestSXSTR (sexplist sexptype)))))`;

val sexpdec_def = Define`
  sexpdec s =
    do
      (nm, args) <- dstrip_sexp s;
      guard (nm = "Dlet" ∧ LENGTH args = 2)
            (lift2 Dlet (sexppat (EL 0 args)) (sexpexp (EL 1 args))) ++
      guard (nm = "Dletrec" ∧ LENGTH args = 1)
            (lift Dletrec (sexplist (sexppair odestSXSTR (sexppair odestSXSTR sexpexp)) (HD args))) ++
      guard (nm = "Dtype" ∧ LENGTH args = 1)
            (lift Dtype (sexptype_def (HD args))) ++
      guard (nm = "Dtabbrev" ∧ LENGTH args = 3)
            (lift Dtabbrev (sexplist odestSXSTR (EL 0 args)) <*>
                           (odestSXSTR (EL 1 args)) <*>
                           (sexptype (EL 2 args))) ++
      guard (nm = "Dexn" ∧ LENGTH args = 2)
            (lift2 Dexn (odestSXSTR (EL 0 args)) (sexplist sexptype (EL 1 args)))
    od`;

val sexpspec_def = Define`
  sexpspec s =
    do
       (nm, args) <- dstrip_sexp s ;
       if nm = "Sval" then
         guard (LENGTH args = 2)
               (lift2 Sval (odestSXSTR (HD args)) (sexptype (EL 1 args)))
       else if nm = "Stype" then
         guard (LENGTH args = 1)
               (lift Stype (sexptype_def (HD args)))
       else if nm = "Stabbrev" then
         guard (LENGTH args = 3)
               (lift Stabbrev
                       (sexplist odestSXSTR (HD args)) <*>
                       (odestSXSTR (EL 1 args)) <*>
                       (sexptype (EL 2 args)))
       else if nm = "Stype_opq" then
         guard (LENGTH args = 2)
               (lift2 Stype_opq
                      (sexplist odestSXSTR (EL 0 args))
                      (odestSXSTR (EL 1 args)))
       else if nm = "Sexn" then
         guard (LENGTH args = 2)
               (lift2 Sexn (odestSXSTR (EL 0 args))
                      (sexplist sexptype (EL 1 args)))
       else fail
    od
`;

val sexptop_def = Define`
  sexptop s =
    do
        (nm, args) <- dstrip_sexp s ;
        if nm = "Tmod" then
          do
             assert (LENGTH args = 3);
             modN <- odestSXSTR (HD args);
             specopt <- sexpopt (sexplist sexpspec) (EL 1 args);
             declist <- sexplist sexpdec (EL 2 args);
             return (Tmod modN specopt declist)
          od
        else if nm = "Tdec" then
          do
             assert (LENGTH args = 1);
             lift Tdec (sexpdec (HD args))
          od
        else fail
    od
`;

(* now the reverse: toSexp *)

val listsexp_def = Define`
  listsexp = FOLDR SX_CONS nil`;

val listsexp_11 = Q.store_thm("listsexp_11[simp]",
  `∀ l1 l2. listsexp l1 = listsexp l2 ⇔ l1 = l2`,
  Induct >> gen_tac >> cases_on `l2` >> fs[listsexp_def]);

val optsexp_def = Define`
  (optsexp NONE = SX_SYM "NONE") ∧
  (optsexp (SOME x) = listsexp [SX_SYM "SOME"; x])`;

val optsexp_11 = Q.store_thm("optsexp_11[simp]",
  `optsexp o1 = optsexp o2 ⇔ o1 = o2`,
  cases_on `o1` >> cases_on `o2` >> fs[optsexp_def, listsexp_def]);

val idsexp_def = Define`
  (idsexp (Short n) = listsexp [SX_SYM"Short"; SX_STR n]) ∧
  (idsexp (Long ns n) = listsexp [SX_SYM"Long"; SX_STR ns; SX_STR n])`;

val idsexp_11 = Q.store_thm("idsexp_11[simp]",
  `∀ i1 i2. idsexp i1 = idsexp i2 ⇔ i1 = i2`,
  Induct >> gen_tac >> cases_on `i2` >> fs[idsexp_def]);

val tctorsexp_def = Define`
  (tctorsexp (TC_name id) = listsexp [SX_SYM "TC_name"; idsexp id]) ∧
  (tctorsexp TC_int = SX_SYM "TC_int") ∧
  (tctorsexp TC_char = SX_SYM "TC_char") ∧
  (tctorsexp TC_string = SX_SYM "TC_string") ∧
  (tctorsexp TC_ref = SX_SYM "TC_ref") ∧
  (tctorsexp TC_word8 = SX_SYM "TC_word8") ∧
  (tctorsexp TC_word64 = SX_SYM "TC_word64") ∧
  (tctorsexp TC_word8array = SX_SYM "TC_word8array") ∧
  (tctorsexp TC_fn = SX_SYM "TC_fn") ∧
  (tctorsexp TC_tup = SX_SYM "TC_tup") ∧
  (tctorsexp TC_exn = SX_SYM "TC_exn") ∧
  (tctorsexp TC_vector = SX_SYM "TC_vector") ∧
  (tctorsexp TC_array = SX_SYM "TC_array")`;

val tctorsexp_11 = Q.store_thm("tctorsexp_11[simp]",
  `∀ t1 t2. tctorsexp t1 = tctorsexp t2 ⇔ t1 = t2`,
  Induct >> gen_tac >> cases_on `t2` >> fs[tctorsexp_def, listsexp_def]);

val typesexp_def = tDefine"typesexp"`
  (typesexp (Tvar s) = listsexp [SX_SYM "Tvar"; SX_STR s]) ∧
  (typesexp (Tvar_db n) = listsexp [SX_SYM "Tvar_db"; SX_NUM n]) ∧
  (typesexp (Tapp ts ct) = listsexp [SX_SYM "Tapp"; listsexp (MAP typesexp ts); tctorsexp ct])`
  (WF_REL_TAC`measure t_size` >>
   Induct_on`ts` >> simp[t_size_def] >>
   rw[] >> res_tac >> simp[] >>
   first_x_assum(qspec_then`ct`strip_assume_tac)>>
   decide_tac);

val typesexp_11 = Q.store_thm("typesexp_11[simp]",
  `∀t1 t2. typesexp t1 = typesexp t2 ⇔ t1 = t2`,
  ho_match_mp_tac (theorem"typesexp_ind")
  \\ simp[typesexp_def]
  \\ rpt conj_tac \\ simp[PULL_FORALL]
  \\ CONV_TAC(RESORT_FORALL_CONV List.rev)
  \\ Cases \\ simp[typesexp_def]
  \\ srw_tac[ETA_ss][EQ_IMP_THM]
  \\ metis_tac[MAP_EQ_MAP_IMP]);

val litsexp_def = Define`
  (litsexp (IntLit i) =
   if i < 0 then listsexp [SX_SYM "-"; SX_NUM (Num(-i))]
            else SX_NUM (Num i)) ∧
  (litsexp (Char c) = listsexp [SX_SYM "char"; SX_STR [c]]) ∧
  (litsexp (StrLit s) = SX_STR s) ∧
  (litsexp (Word8 w) = listsexp [SX_SYM "word8"; SX_NUM (w2n w)]) ∧
  (litsexp (Word64 w) = listsexp [SX_SYM "word64"; SX_NUM (w2n w)])`;

val litsexp_11 = Q.store_thm("litsexp_11[simp]",
  `∀l1 l2. litsexp l1 = litsexp l2 ⇔ l1 = l2`,
  Cases \\ Cases \\ rw[litsexp_def,EQ_IMP_THM,listsexp_def]
  \\ intLib.COOPER_TAC);

val patsexp_def = tDefine"patsexp"`
  (patsexp (Pvar s) = SX_STR s) ∧
  (patsexp (Plit l) = listsexp [SX_SYM "Plit"; litsexp l]) ∧
  (patsexp (Pcon cn ps) = listsexp [SX_SYM "Pcon"; optsexp (OPTION_MAP idsexp cn); listsexp (MAP patsexp ps)]) ∧
  (patsexp (Pref p) = listsexp [SX_SYM "Pref"; patsexp p])`
  (WF_REL_TAC`measure pat_size` >>
   Induct_on`ps`>>simp[pat_size_def] >>
   rw[] >> simp[] >> res_tac >>
   first_x_assum(qspec_then`cn`strip_assume_tac)>>
   decide_tac )

val patsexp_11 = Q.store_thm("patsexp_11[simp]",
  `∀p1 p2. patsexp p1 = patsexp p2 ⇔ p1 = p2`,
  ho_match_mp_tac (theorem"patsexp_ind")
  \\ rpt conj_tac \\ simp[PULL_FORALL]
  \\ CONV_TAC(RESORT_FORALL_CONV List.rev)
  \\ Cases \\ rw[patsexp_def,listsexp_def]
  \\ rw[EQ_IMP_THM]
  >- ( metis_tac[OPTION_MAP_INJ,idsexp_11] )
  \\ imp_res_tac FOLDR_SX_CONS_INJ
  \\ imp_res_tac (REWRITE_RULE[AND_IMP_INTRO] MAP_EQ_MAP_IMP)
  \\ first_x_assum match_mp_tac
  \\ simp[] \\ metis_tac[]);

val lopsexp_def = Define`
  (lopsexp And = SX_SYM "And") ∧
  (lopsexp Or = SX_SYM "Or")`;

val lopsexp_11 = Q.store_thm("lopsexp_11[simp]",
  `∀l1 l2. lopsexp l1 = lopsexp l2 ⇔ l1 = l2`,
  Cases \\ Cases \\ simp[lopsexp_def]);

val opsexp_def = Define`
  (opsexp (Opn Plus) = SX_SYM "OpnPlus") ∧
  (opsexp (Opn Minus) = SX_SYM "OpnMinus") ∧
  (opsexp (Opn Times) = SX_SYM "OpnTimes") ∧
  (opsexp (Opn Divide) = SX_SYM "OpnDivide") ∧
  (opsexp (Opn Modulo) = SX_SYM "OpnModulo") ∧
  (opsexp (Opb Lt) = SX_SYM "OpbLt") ∧
  (opsexp (Opb Gt) = SX_SYM "OpbGt") ∧
  (opsexp (Opb Leq) = SX_SYM "OpbLeq") ∧
  (opsexp (Opb Geq) = SX_SYM "OpbGeq") ∧
  (opsexp (Opw W8 Andw) = SX_SYM "Opw8Andw") ∧
  (opsexp (Opw W8 Orw) = SX_SYM "Opw8Orw") ∧
  (opsexp (Opw W8 Xor) = SX_SYM "Opw8Xor") ∧
  (opsexp (Opw W8 Add) = SX_SYM "Opw8Add") ∧
  (opsexp (Opw W8 Sub) = SX_SYM "Opw8Sub") ∧
  (opsexp (Opw W64 Andw) = SX_SYM "Opw64Andw") ∧
  (opsexp (Opw W64 Orw) = SX_SYM "Opw64Orw") ∧
  (opsexp (Opw W64 Xor) = SX_SYM "Opw64Xor") ∧
  (opsexp (Opw W64 Add) = SX_SYM "Opw64Add") ∧
  (opsexp (Opw W64 Sub) = SX_SYM "Opw64Sub") ∧
  (opsexp (Shift W8 Lsl n) = SX_CONS (SX_SYM "Shift8Lsl") (SX_NUM n)) ∧
  (opsexp (Shift W8 Lsr n) = SX_CONS (SX_SYM "Shift8Lsr") (SX_NUM n)) ∧
  (opsexp (Shift W8 Asr n) = SX_CONS (SX_SYM "Shift8Asr") (SX_NUM n)) ∧
  (opsexp (Shift W64 Lsl n) = SX_CONS (SX_SYM "Shift64Lsl") (SX_NUM n)) ∧
  (opsexp (Shift W64 Lsr n) = SX_CONS (SX_SYM "Shift64Lsr") (SX_NUM n)) ∧
  (opsexp (Shift W64 Asr n) = SX_CONS (SX_SYM "Shift64Asr") (SX_NUM n)) ∧
  (opsexp Equality = SX_SYM "Equality") ∧
  (opsexp Opapp = SX_SYM "Opapp") ∧
  (opsexp Opassign = SX_SYM "Opassign") ∧
  (opsexp Opref = SX_SYM "Opref") ∧
  (opsexp Opderef = SX_SYM "Opderef") ∧
  (opsexp Aw8alloc = SX_SYM "Aw8alloc") ∧
  (opsexp Aw8sub = SX_SYM "Aw8sub") ∧
  (opsexp Aw8length = SX_SYM "Aw8length") ∧
  (opsexp Aw8update = SX_SYM "Aw8update") ∧
  (opsexp Ord = SX_SYM "Ord") ∧
  (opsexp Chr = SX_SYM "Chr") ∧
  (opsexp (WordFromInt W8) = SX_SYM "W8fromInt") ∧
  (opsexp (WordToInt W8) = SX_SYM "W8toInt") ∧
  (opsexp (WordFromInt W64) = SX_SYM "W64fromInt") ∧
  (opsexp (WordToInt W64) = SX_SYM "W64toInt") ∧
  (opsexp (Chopb Lt) = SX_SYM "ChopbLt") ∧
  (opsexp (Chopb Gt) = SX_SYM "ChopbGt") ∧
  (opsexp (Chopb Leq)= SX_SYM "ChopbLeq") ∧
  (opsexp (Chopb Geq)= SX_SYM "ChopbGeq") ∧
  (opsexp Explode = SX_SYM "Explode") ∧
  (opsexp Implode = SX_SYM "Implode") ∧
  (opsexp Strlen = SX_SYM "Strlen") ∧
  (opsexp VfromList = SX_SYM "VfromList") ∧
  (opsexp Vsub = SX_SYM "Vsub") ∧
  (opsexp Vlength = SX_SYM "Vlength") ∧
  (opsexp Aalloc = SX_SYM "Aalloc") ∧
  (opsexp Asub = SX_SYM "Asub") ∧
  (opsexp Alength = SX_SYM "Alength") ∧
  (opsexp Aupdate = SX_SYM "Aupdate") ∧
  (opsexp (FFI n) = SX_CONS (SX_SYM "FFI") (SX_NUM n))`;

val opsexp_11 = Q.store_thm("opsexp_11[simp]",
  `∀o1 o2. opsexp o1 = opsexp o2 ⇔ o1 = o2`,
  Cases \\ TRY(Cases_on`o'`)
  \\ Cases \\ TRY(Cases_on`o'`)
  \\ simp[opsexp_def]
  \\ TRY (Cases_on`w`)
  \\ simp[opsexp_def]
  \\ TRY (Cases_on`s`)
  \\ simp[opsexp_def]
  \\ TRY (Cases_on`w'`)
  \\ simp[opsexp_def]
  \\ TRY (Cases_on`s'`)
  \\ simp[opsexp_def]);

val expsexp_def = tDefine"expsexp"`
  (expsexp (Raise e) = listsexp [SX_SYM "Raise"; expsexp e]) ∧
  (expsexp (Handle e pes) = listsexp [SX_SYM "Handle"; expsexp e; listsexp (MAP (λ(p,e). SX_CONS (patsexp p) (expsexp e)) pes)]) ∧
  (expsexp (Lit l) = listsexp [SX_SYM "Lit"; litsexp l]) ∧
  (expsexp (Con cn es) = listsexp [SX_SYM "Con"; optsexp (OPTION_MAP idsexp cn); listsexp (MAP expsexp es)]) ∧
  (expsexp (Var id) = listsexp [SX_SYM "Var"; idsexp id]) ∧
  (expsexp (Fun x e) = listsexp [SX_SYM "Fun"; SX_STR x; expsexp e]) ∧
  (expsexp (App op es) = listsexp [SX_SYM "App"; opsexp op; listsexp (MAP expsexp es)]) ∧
  (expsexp (Log lop e1 e2) = listsexp [SX_SYM "Log"; lopsexp lop; expsexp e1; expsexp e2]) ∧
  (expsexp (If e1 e2 e3) = listsexp [SX_SYM "If"; expsexp e1; expsexp e2; expsexp e3]) ∧
  (expsexp (Mat e pes) = listsexp [SX_SYM "Mat"; expsexp e; listsexp (MAP (λ(p,e). SX_CONS (patsexp p) (expsexp e)) pes)]) ∧
  (expsexp (Let so e1 e2) = listsexp [SX_SYM "Let"; optsexp (OPTION_MAP SX_STR so); expsexp e1; expsexp e2]) ∧
  (expsexp (Letrec funs e) = listsexp
    [SX_SYM "Letrec";
     listsexp (MAP (λ(x,y,z). SX_CONS (SX_STR x) (SX_CONS (SX_STR y) (expsexp z))) funs);
     expsexp e])`
  (WF_REL_TAC`measure exp_size` >>
   rpt conj_tac >> simp[] >>
   (Induct_on`pes` ORELSE Induct_on`es` ORELSE Induct_on`funs`) >>
   simp[exp_size_def] >> rw[] >> simp[exp_size_def] >>
   res_tac >>
   first_x_assum(strip_assume_tac o SPEC_ALL) >>
   decide_tac);

val expsexp_11 = Q.store_thm("expsexp_11[simp]",
  `∀e1 e2. expsexp e1 = expsexp e2 ⇒ e1 = e2`,
  ho_match_mp_tac (theorem"expsexp_ind")
  \\ rpt conj_tac \\ simp[PULL_FORALL]
  \\ CONV_TAC(RESORT_FORALL_CONV List.rev)
  \\ Cases \\ rw[expsexp_def]
  \\ imp_res_tac (REWRITE_RULE[AND_IMP_INTRO] MAP_EQ_MAP_IMP)
  \\ TRY(first_x_assum match_mp_tac \\ rw[FORALL_PROD])
  \\ rpt(pairarg_tac \\ fs[])
  \\ metis_tac[OPTION_MAP_INJ,idsexp_11,simpleSexpTheory.sexp_11]);

val type_defsexp_def = Define`
  type_defsexp = listsexp o
    MAP (λ(xs,x,ls).
      SX_CONS (listsexp (MAP SX_STR xs))
        (SX_CONS (SX_STR x)
          (listsexp (MAP (λ(y,ts). SX_CONS (SX_STR y) (listsexp (MAP typesexp ts))) ls))))`;

val type_defsexp_11 = Q.store_thm("type_defsexp_11[simp]",
  `∀t1 t2. type_defsexp t1 = type_defsexp t2 ⇔ t1 = t2`,
  rw[type_defsexp_def,EQ_IMP_THM]
  \\ imp_res_tac (REWRITE_RULE[AND_IMP_INTRO] MAP_EQ_MAP_IMP)
  \\ first_x_assum match_mp_tac
  \\ rw[FORALL_PROD]
  \\ rpt (pairarg_tac \\ fs[]) \\ rveq
  \\ conj_tac
  >- (
    Q.ISPEC_THEN`SX_STR`match_mp_tac INJ_MAP_EQ
    \\ simp[INJ_DEF] )
  \\ imp_res_tac (REWRITE_RULE[AND_IMP_INTRO] MAP_EQ_MAP_IMP)
  \\ first_x_assum match_mp_tac
  \\ rw[FORALL_PROD]
  \\ rpt (pairarg_tac \\ fs[]) \\ rveq
  \\ Q.ISPEC_THEN`typesexp`match_mp_tac INJ_MAP_EQ
  \\ simp[INJ_DEF]);

val decsexp_def = Define`
  (decsexp (Dlet p e) = listsexp [SX_SYM "Dlet"; patsexp p; expsexp e]) ∧
  (decsexp (Dletrec funs) =
     listsexp [SX_SYM "Dletrec";
               listsexp (MAP (λ(f,x,e). SX_CONS (SX_STR f) (SX_CONS (SX_STR x) (expsexp e))) funs)]) ∧
  (decsexp (Dtype td) = listsexp [SX_SYM "Dtype"; type_defsexp td]) ∧
  (decsexp (Dtabbrev ns x t) = listsexp [SX_SYM "Dtabbrev"; listsexp (MAP SX_STR ns); SX_STR x; typesexp t]) ∧
  (decsexp (Dexn x ts) = listsexp [SX_SYM "Dexn"; SX_STR x; listsexp (MAP typesexp ts)])`;

val decsexp_11 = Q.store_thm("decsexp_11[simp]",
  `∀d1 d2. decsexp d1 = decsexp d2 ⇔ d1 = d2`,
  Cases \\ Cases \\ rw[decsexp_def,EQ_IMP_THM]
  \\ imp_res_tac (REWRITE_RULE[AND_IMP_INTRO] MAP_EQ_MAP_IMP)
  \\ TRY (first_x_assum match_mp_tac \\ rw[])
  \\ rpt(pairarg_tac \\ fs[]));

val specsexp_def = Define`
  (specsexp (Sval x t) = listsexp [SX_SYM "Sval"; SX_STR x; typesexp t]) ∧
  (specsexp (Stype t) = listsexp [SX_SYM "Stype"; type_defsexp t]) ∧
  (specsexp (Stabbrev ns x t) = listsexp [SX_SYM "Stabbrev"; listsexp (MAP SX_STR ns); SX_STR x; typesexp t]) ∧
  (specsexp (Stype_opq ns x) = listsexp [SX_SYM "Stype_opq"; listsexp (MAP SX_STR ns); SX_STR x]) ∧
  (specsexp (Sexn x ts) = listsexp [SX_SYM "Sexn"; SX_STR x; listsexp (MAP typesexp ts)])`;

val specsexp_11 = Q.store_thm("specsexp_11[simp]",
  `∀s1 s2. specsexp s1 = specsexp s2 ⇔ s1 = s2`,
  Induct >> gen_tac >> cases_on `s2` >> fs[specsexp_def] >> rpt gen_tac >> simp[]
  \\ rw[EQ_IMP_THM]
  \\ imp_res_tac (REWRITE_RULE[AND_IMP_INTRO] MAP_EQ_MAP_IMP)
  \\ first_x_assum match_mp_tac
  \\ rw[]);

val topsexp_def = Define`
  (topsexp (Tmod modN specopt declist) =
     listsexp [SX_SYM "Tmod"; SX_STR modN; optsexp (OPTION_MAP (listsexp o MAP specsexp) specopt);
               listsexp (MAP decsexp declist)]) ∧
  (topsexp (Tdec dec) =
     listsexp [SX_SYM "Tdec"; decsexp dec])`;

val topsexp_11 = Q.store_thm("topsexp_11[simp]",
  `∀ t1 t2. topsexp t1 = topsexp t2 ⇔ t1 = t2`,
  Induct >> gen_tac >> cases_on `t2`
  \\ rw[topsexp_def,EQ_IMP_THM]
  \\ imp_res_tac(MP_CANON OPTION_MAP_INJ) \\ fs[]
  \\ imp_res_tac (REWRITE_RULE[AND_IMP_INTRO] MAP_EQ_MAP_IMP)
  \\ first_x_assum match_mp_tac \\ rw[]
  \\ imp_res_tac (REWRITE_RULE[AND_IMP_INTRO] MAP_EQ_MAP_IMP)
  \\ first_x_assum match_mp_tac \\ rw[]);

(* round trip *)

val odestSXSTR_SOME = Q.store_thm("odestSXSTR_SOME[simp]",
  `odestSXSTR s = SOME y ⇔ (s = SX_STR y)`,
  Cases_on`s`>>simp[odestSXSTR_def])

val odestSXSTR_SX_STR = Q.store_thm("odestSXSTR_SX_STR[simp]",
  `odestSXSTR (SX_STR s) = SOME s`,
  rw[odestSXSTR_def])

val odestSXNUM_SX_NUM = Q.store_thm("odestSXNUM_SX_NUM[simp]",
  `odestSXNUM (SX_NUM n) = SOME n`,
  EVAL_TAC)

val odestSXSYM_SX_SYM = Q.store_thm("odestSXSYM_SX_SYM[simp]",
  `odestSXSYM (SX_SYM s) = SOME s`,
  EVAL_TAC)

val odestSXNUM_SX_STR = Q.store_thm("odestSXNUM_SX_STR[simp]",
  `odestSXNUM (SX_STR s) = NONE`,
  EVAL_TAC)

val odestSXSTR_listsexp = Q.store_thm("odestSXSTR_listsexp[simp]",
  `odestSXSTR (listsexp l) = NONE`,
  Cases_on`l`>>EVAL_TAC)

val odestSXNUM_listsexp = Q.store_thm("odestSXNUM_listsexp[simp]",
  `odestSXNUM (listsexp l) = NONE`,
  Cases_on`l`>>EVAL_TAC)

val dstrip_sexp_SX_STR = Q.store_thm("dstrip_sexp_SX_STR[simp]",
  `dstrip_sexp (SX_STR s) = NONE`,
  EVAL_TAC)

val strip_sxcons_listsexp = Q.store_thm("strip_sxcons_listsexp[simp]",
  `strip_sxcons (listsexp ls) = SOME ls`,
  Induct_on`ls`>>rw[listsexp_def,Once strip_sxcons_def] >>
  fs[listsexp_def])

val dstrip_sexp_listsexp = Q.store_thm("dstrip_sexp_listsexp[simp]",
  `(dstrip_sexp (listsexp ls) =
    case ls of (SX_SYM x::xs) => SOME (x,xs) | _ => NONE)`,
  BasicProvers.CASE_TAC >> rw[dstrip_sexp_def,listsexp_def] >>
  BasicProvers.CASE_TAC >> rw[GSYM listsexp_def]);

val sexplist_listsexp_matchable = Q.store_thm("sexplist_listsexp_matchable",
  `∀g gl. (∀x. MEM x l ⇒ f (g x) = SOME x) ∧ (gl = MAP g l) ⇒
   sexplist f (listsexp gl) = SOME l`,
  Induct_on`l` >> simp[listsexp_def,Once sexplist_def] >>
  simp[GSYM listsexp_def] >> metis_tac[]);

val sexplist_listsexp_rwt = Q.store_thm("sexplist_listsexp_rwt[simp]",
  `(∀x. MEM x l ⇒ f (g x) = SOME x) ⇒
   (sexplist f (listsexp (MAP g l)) = SOME l)`,
  metis_tac[sexplist_listsexp_matchable]);

val sexplist_listsexp_imp = Q.store_thm("sexplist_listsexp_imp",
  `sexplist f (listsexp l1) = SOME l2 ⇒
   ∀n. n < LENGTH l1 ⇒ f (EL n l1) = SOME (EL n l2)`,
  qid_spec_tac`l2`>>
  Induct_on`l1`>>simp[listsexp_def]>>simp[GSYM listsexp_def] >>
  simp[Once sexplist_def,PULL_EXISTS] >> rw[] >>
  Cases_on`n`>>simp[])

val sexpopt_optsexp = Q.store_thm("sexpopt_optsexp[simp]",
  `(∀y. (x = SOME y) ⇒ (f (g y) = x)) ⇒
   (sexpopt f (optsexp (OPTION_MAP g x)) = SOME x)`,
  Cases_on`x`>>EVAL_TAC >> simp[])

val sexpid_odestSXSTR_idsexp = Q.store_thm("sexpid_odestSXSTR_idsexp[simp]",
  `sexpid odestSXSTR (idsexp i) = SOME i`,
  Cases_on`i` >> EVAL_TAC)

val sexptctor_tctorsexp = Q.store_thm("sexptctor_tctorsexp[simp]",
  `sexptctor (tctorsexp t) = SOME t`,
  Cases_on`t`>>simp[tctorsexp_def,sexptctor_def] >>
  simp[dstrip_sexp_def])

val sexptype_typesexp = Q.store_thm("sexptype_typesexp[simp]",
  `sexptype (typesexp t) = SOME t`,
  qid_spec_tac`t` >>
  ho_match_mp_tac type_ind >>
  conj_tac >- rw[Once sexptype_def,typesexp_def] >>
  conj_tac >- rw[Once sexptype_def,typesexp_def] >>
  Induct_on`l`>>rw[typesexp_def] >- (
    rw[Once sexptype_def,sexplist_listsexp_matchable] ) >> fs[] >>
  rw[Once sexptype_def] >>
  fsrw_tac[boolSimps.ETA_ss][] >>
  match_mp_tac sexplist_listsexp_matchable >>
  fs[typesexp_def] >> rw[] >> rw[] >>
  fs[listTheory.EVERY_MEM] >>
  metis_tac[]);

val exists_g_tac =
  (fn (g as (asl,w)) =>
    let
      val (x,b) = dest_exists w
      val tm = find_term (fn y => type_of x = type_of y andalso not (is_var y)) b
    in EXISTS_TAC tm end g)

val sexptype_def_type_defsexp = Q.store_thm("sexptype_def_type_defsexp[simp]",
  `sexptype_def (type_defsexp l) = SOME l`,
  Induct_on`l` >> rw[type_defsexp_def] >> rw[sexptype_def_def] >>
  match_mp_tac sexplist_listsexp_matchable >> simp[] >>
  exists_g_tac >>
  simp[] >>
  qx_gen_tac`p`>>PairCases_on`p` >> simp[] >>
  strip_tac >- (
    rw[] >>
    simp[sexppair_def] >>
    match_mp_tac sexplist_listsexp_matchable >>
    exists_g_tac >>
    simp[] >>
    qx_gen_tac`p`>>PairCases_on`p` >> simp[] >>
    simp[sexppair_def] ) >>
  fs[sexptype_def_def,type_defsexp_def] >>
  imp_res_tac sexplist_listsexp_imp >>
  fs[listTheory.MEM_EL] >>
  first_x_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
  pop_assum(assume_tac o SYM) >>
  simp[rich_listTheory.EL_MAP])

val sexplit_litsexp = Q.store_thm("sexplit_litsexp[simp]",
  `sexplit (litsexp l) = SOME l`,
  Cases_on`l`>>simp[sexplit_def,litsexp_def] >- (
    rw[] >> intLib.ARITH_TAC ) >>
  ONCE_REWRITE_TAC[GSYM wordsTheory.dimword_8] >>
  ONCE_REWRITE_TAC[GSYM wordsTheory.dimword_64] >>
  ONCE_REWRITE_TAC[wordsTheory.w2n_lt] >>
  rw[])

val sexppat_patsexp = Q.store_thm("sexppat_patsexp[simp]",
  `sexppat (patsexp p) = SOME p`,
  qid_spec_tac`p` >>
  ho_match_mp_tac pat_ind >>
  conj_tac >- simp[patsexp_def,Once sexppat_def] >>
  conj_tac >- simp[patsexp_def,Once sexppat_def] >>
  conj_tac >- (
    Induct >- simp[patsexp_def,Once sexppat_def,sexplist_listsexp_matchable] >>
    rw[] >> fs[] >>
    simp[patsexp_def,Once sexppat_def] >>
    match_mp_tac sexplist_listsexp_matchable >>
    srw_tac[boolSimps.ETA_ss][] >>
    qexists_tac`patsexp`>>simp[] >>
    fs[listTheory.EVERY_MEM] >> metis_tac[]) >>
  rw[] >> simp[patsexp_def,Once sexppat_def]);

val sexpop_opsexp = Q.store_thm("sexpop_opsexp[simp]",
  `sexpop (opsexp op) = SOME op`,
  Cases_on`op`>>rw[sexpop_def,opsexp_def]>>
  TRY(Cases_on`o'`>>rw[sexpop_def,opsexp_def]) >>
  TRY(Cases_on`w`>>rw[sexpop_def,opsexp_def]) >>
  TRY(Cases_on`s`>>rw[sexpop_def,opsexp_def]));

val sexplop_lopsexp = Q.store_thm("sexplop_lopsexp[simp]",
  `sexplop (lopsexp l) = SOME l`,
  Cases_on`l`>>EVAL_TAC)

val sexpexp_expsexp = Q.store_thm("sexpexp_expsexp[simp]",
  `sexpexp (expsexp e) = SOME e`,
  qid_spec_tac`e` >>
  ho_match_mp_tac exp_ind >> rw[] >>
  rw[expsexp_def] >> rw[Once sexpexp_def] >>
  match_mp_tac sexplist_listsexp_matchable >>
  exists_g_tac >> simp[] >>
  fs[listTheory.EVERY_MEM] >>
  qx_gen_tac`p`>>PairCases_on`p` >> simp[] >>
  simp[sexppair_def] >>
  rw[] >> res_tac >> fs[]);

val sexpdec_decsexp = Q.store_thm("sexpdec_decsexp[simp]",
  `sexpdec (decsexp d) = SOME d`,
  Cases_on`d`>>simp[decsexp_def,sexpdec_def]>>
  match_mp_tac sexplist_listsexp_matchable >>
  exists_g_tac >> simp[] >>
  qx_gen_tac`p`>>PairCases_on`p`>>rw[]>>
  simp[sexppair_def])

val sexpspec_specsexp = Q.store_thm("sexpspec_specsexp[simp]",
  `sexpspec (specsexp s) = SOME s`,
  Cases_on`s`>>simp[specsexp_def,sexpspec_def]);

val sexptop_topsexp = Q.store_thm("sexptop_topsexp",
  `sexptop (topsexp t) = SOME t`,
  Cases_on`t` >> simp[topsexp_def,sexptop_def]);

val sexpopt_SOME = Q.store_thm("sexpopt_SOME",
  `sexpopt f s = SOME opt ⇒ ∃x. s = optsexp x ∧ (case x of NONE => opt = NONE | SOME s => IS_SOME opt ∧ opt = f s)`,
  rw[sexpopt_def]
  \\ Cases_on`odestSXSYM s` \\ fs[dstrip_sexp_SOME] \\ rw[]
  \\ fs[OPTION_IGNORE_BIND_OPTION_GUARD] \\ rw[]
  \\ every_case_tac \\ fs[dstrip_sexp_SOME]
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3] \\ rw[] \\ fs[] \\ rw[]
  \\ fs[odestSXSYM_def]
  \\ fs[Once strip_sxcons_def]
  \\ every_case_tac \\ fs[] \\ rw[]
  \\ TRY (
    qexists_tac`NONE` \\ EVAL_TAC
    \\ Cases_on`s` \\ fs[odestSXSYM_def]
    \\ NO_TAC)
  \\ qexists_tac`SOME e1`
  \\ EVAL_TAC \\ simp[]);

val listsexp_MAP_EQ_f = Q.store_thm("listsexp_MAP_EQ_f",
  `(∀x. MEM x ls ⇒ f1 x = f2 x) ⇒
    listsexp (MAP f1 ls) = listsexp (MAP f2 ls)`,
  Induct_on`ls` >> simp[] >> fs[listsexp_def])

val sexplist_SOME = Q.store_thm("sexplist_SOME",
  `sexplist f s = SOME ls ⇒ ∃l. s = listsexp l ∧ MAP f l = MAP SOME ls`,
  map_every qid_spec_tac[`s`,`ls`] >>
  Induct >> rw[] >- (
    fs[Once sexplist_def] >>
    every_case_tac >> fs[listsexp_def] ) >>
  pop_assum mp_tac >>
  simp[Once sexplist_def] >>
  every_case_tac >> fs[] >> rw[] >>
  first_x_assum(fn th => first_x_assum(mp_tac o MATCH_MP th)) >>
  rw[] >>
  rw[listsexp_def,SimpRHS] >>
  simp[GSYM listsexp_def] >>
  qmatch_assum_rename_tac`f a = return h` >>
  qexists_tac`a::l` >> simp[listsexp_def] )

val sexppair_SOME = Q.store_thm("sexppair_SOME",
  `sexppair f1 f2 s = SOME p ⇒ ∃x y. f1 x = SOME (FST p) ∧ f2 y = SOME (SND p) ∧ s = SX_CONS x y`,
  rw[sexppair_def]
  \\ every_case_tac \\ fs[]);

val litsexp_sexplit = Q.store_thm("litsexp_sexplit",
  `∀s l. sexplit s = SOME l ⇒ litsexp l = s`,
  rw[sexplit_def]
  \\ reverse(Cases_on`odestSXNUM s`) \\ fs[]
  >- (
    rw[litsexp_def]
    \\ Cases_on`s` \\ fs[odestSXNUM_def] )
  \\ reverse(Cases_on`odestSXSTR s`) \\ fs[]
  >- ( rw[litsexp_def])
  \\ pairarg_tac \\ fs[OPTION_IGNORE_BIND_OPTION_GUARD]
  \\ every_case_tac \\ fs[] \\ rw[litsexp_def]
  \\ fs[dstrip_sexp_SOME]
  \\ rw[listsexp_def]
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3] \\ rw[]
  \\ fs[]
  \\ fs[Once strip_sxcons_def]
  \\ every_case_tac \\ fs[] \\ rw[]
  \\ Cases_on`e1` \\ fs[odestSXNUM_def]);

val idsexp_sexpid_odestSXSTR = Q.store_thm("idsexp_sexpid_odestSXSTR",
  `sexpid odestSXSTR x = SOME y ⇒ x = idsexp y`,
  rw[sexpid_def]
  \\ fs[dstrip_sexp_SOME] \\ rw[]
  \\ fs[]
  \\ fs[OPTION_IGNORE_BIND_OPTION_GUARD]
  \\ every_case_tac \\ fs[] \\ rw[]
  \\ rw[idsexp_def,listsexp_def]
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3] \\ rw[]
  \\ fs[]
  \\ fs[Once strip_sxcons_def]
  \\ every_case_tac \\ fs[]
  \\ fs[Once strip_sxcons_def]
  \\ every_case_tac \\ fs[]);

val patsexp_sexppat = Q.store_thm("patsexp_sexppat",
  `∀s p. sexppat s = SOME p ⇒ patsexp p = s`,
  ho_match_mp_tac (theorem"sexppat_ind")
  \\ rw[]
  \\ pop_assum mp_tac
  \\ rw[Once sexppat_def]
  \\ fs[OPTION_IGNORE_BIND_OPTION_GUARD]
  \\ reverse(Cases_on`odestSXSTR s`) \\ fs[]
  >- ( rw[patsexp_def] )
  \\ pairarg_tac \\ fs[]
  \\ every_case_tac \\ fs[] \\ rw[]
  \\ rw[patsexp_def]
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3]
  \\ rw[] \\ fs[]
  \\ fs[dstrip_sexp_SOME]
  \\ rw[listsexp_def]
  \\ fs[Once strip_sxcons_def]
  \\ every_case_tac \\ fs[] \\ rw[]
  \\ imp_res_tac litsexp_sexplit
  \\ imp_res_tac sexpopt_SOME
  \\ rveq \\ fs[]
  >- (
    Cases_on`x`\\fs[optsexp_def,sexpopt_def,odestSXSYM_def,listsexp_def,dstrip_sexp_SOME]
    \\ rveq \\ fs[OPTION_IGNORE_BIND_OPTION_GUARD]
    \\ imp_res_tac idsexp_sexpid_odestSXSTR )
  \\ fs[Once strip_sxcons_def]
  \\ every_case_tac \\ fs[] \\ rw[]
  \\ imp_res_tac sexplist_SOME \\ rw[]
  \\ rw[listsexp_def] \\ AP_TERM_TAC
  \\ fs[LIST_EQ_REWRITE,EL_MAP]
  \\ rfs[EL_MAP] \\ rw[]
  \\ first_x_assum(match_mp_tac o MP_CANON)
  \\ simp[]
  \\ simp[sxMEM_def]
  \\ metis_tac[MEM_EL]);

val opsexp_sexpop = Q.store_thm("opsexp_sexpop",
  `sexpop s = SOME p ⇒ opsexp p = s`,
  Cases_on`s` \\ rw[sexpop_def] \\ rw[opsexp_def]
  \\ match1_tac(mg.aub`s_:sexp`,(fn(a,t)=>if is_var(t"s") then Cases_on`^(t"s")`\\fs[sexpop_def] else NO_TAC))
  \\ match1_tac(mg.aub`s_:sexp`,(fn(a,t)=>if is_var(t"s") then Cases_on`^(t"s")`\\fs[sexpop_def] else NO_TAC))
  \\ pop_assum mp_tac
  \\ rpt IF_CASES_TAC \\ rw[]
  \\ rw[opsexp_def]);

val lopsexp_sexplop = Q.store_thm("lopsexp_sexplop",
  `sexplop s = SOME z ⇒ lopsexp z = s`,
  Cases_on`s` \\ rw[sexplop_def] \\ rw[lopsexp_def]);

val (strip_sxcons_mtac:matcher*mg_tactic) =
  (mg.a"h"`strip_sxcons _ = SOME _`,
    (fn(a,t)=>
     strip_assume_tac(ONCE_REWRITE_RULE[strip_sxcons_def](a"h"))
     \\ kill_asm(a"h")
     \\ every_case_tac \\ fs[]
     \\ rveq))

val expsexp_sexpexp = Q.store_thm("expsexp_sexpexp",
  `∀s e. sexpexp s = SOME e ⇒ expsexp e = s`,
  ho_match_mp_tac (theorem"sexpexp_ind")
  \\ rpt gen_tac \\ strip_tac \\ gen_tac
  \\ rw[Once sexpexp_def]
  \\ pairarg_tac \\ rveq
  \\ pop_assum mp_tac \\ simp[]
  \\ full_simp_tac std_ss [PULL_EXISTS]
  \\ simp[OPTION_IGNORE_BIND_OPTION_GUARD]
  \\ rpt (
    IF_CASES_TAC >|[
      pop_assum strip_assume_tac \\ rveq
      \\ rpt (pop_assum mp_tac)
      \\ CONV_TAC(DEPTH_CONV stringLib.string_EQ_CONV)
      \\ rw[] \\ fs[],
      ALL_TAC])
  \\ rw[expsexp_def]
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3,dstrip_sexp_SOME]
  \\ rveq \\ fs[listsexp_def] \\ fs[GSYM listsexp_def]
  \\ rpt(match1_tac strip_sxcons_mtac)
  \\ imp_res_tac litsexp_sexplit
  \\ imp_res_tac idsexp_sexpid_odestSXSTR
  \\ imp_res_tac opsexp_sexpop
  \\ imp_res_tac sexplist_SOME
  \\ imp_res_tac sexpopt_SOME
  \\ rw[]
  \\ TRY (
    fs[LIST_EQ_REWRITE,EL_MAP]
    \\ rw[] \\ rfs[EL_MAP]
    \\ res_tac
    \\ imp_res_tac sexppair_SOME
    \\ imp_res_tac patsexp_sexppat
    \\ TRY pairarg_tac \\ fs[]
    \\ imp_res_tac sexppair_SOME
    \\ imp_res_tac patsexp_sexppat
    \\ TRY pairarg_tac \\ fs[]
    \\ first_x_assum (match_mp_tac o MP_CANON)
    \\ simp[sxMEM_def]
    \\ metis_tac[MEM_EL] )
  \\ every_case_tac \\ fs[] \\ rw[]
  \\ fs[IS_SOME_EXISTS]
  \\ imp_res_tac idsexp_sexpid_odestSXSTR
  \\ fs[OPTION_APPLY_MAP2,OPTION_APPLY_MAP3]
  \\ fs[] \\ rveq
  \\ rw[expsexp_def,listsexp_def]
  \\ imp_res_tac sexpopt_SOME
  \\ every_case_tac \\ fs[IS_SOME_EXISTS]
  \\ rw[] \\ fs[odestSXSTR_def]
  \\ imp_res_tac lopsexp_sexplop);

val tctorsexp_sexptctor = Q.store_thm("tctorsexp_sexptctor",
  `sexptctor s = SOME t ⇒ tctorsexp t = s`,
  rw[sexptctor_def]
  \\ qmatch_assum_abbrev_tac`OPTION_CHOICE o1 o2 = _`
  \\ Cases_on`o1` \\ fs[markerTheory.Abbrev_def]
  >- (
    rfs[]
    \\ fs[OPTION_IGNORE_BIND_OPTION_GUARD]
    \\ every_case_tac \\ fs[] \\ rw[tctorsexp_def]
    \\ Cases_on`s` \\ fs[odestSXSYM_def])
  \\ fs[dstrip_sexp_SOME]
  \\ rveq \\ fs[]
  \\ fs[OPTION_IGNORE_BIND_OPTION_GUARD]
  \\ fs[odestSXSYM_def]
  \\ rveq
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3]
  \\ rveq \\ fs[]
  \\ match1_tac strip_sxcons_mtac
  \\ simp[tctorsexp_def,listsexp_def]
  \\ imp_res_tac idsexp_sexpid_odestSXSTR
  \\ rw[]);

val typesexp_sexptype = Q.store_thm("typesexp_sexptype",
  `∀s t. sexptype s = SOME t ⇒ typesexp t = s`,
  ho_match_mp_tac(theorem"sexptype_ind")
  \\ rw[]
  \\ pop_assum mp_tac
  \\ rw[Once sexptype_def]
  \\ fs[dstrip_sexp_SOME,PULL_EXISTS]
  \\ rw[]
  \\ pairarg_tac \\ fs[]
  \\ fs[OPTION_IGNORE_BIND_OPTION_GUARD]
  \\ every_case_tac \\ fs[] \\ rw[]
  \\ rw[typesexp_def]
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3]
  \\ rw[] \\ fs[] \\ rw[listsexp_def] \\ fs[GSYM listsexp_def]
  \\ rpt(match1_tac strip_sxcons_mtac)
  \\ TRY(Cases_on`e1`\\fs[odestSXNUM_def]\\NO_TAC)
  \\ imp_res_tac tctorsexp_sexptctor \\ simp[]
  \\ imp_res_tac sexplist_SOME \\ rw[]
  \\ fs[LIST_EQ_REWRITE,EL_MAP]
  \\ rw[]
  \\ first_x_assum(MATCH_MP_TAC o MP_CANON)
  \\ simp[Once strip_sxcons_def]
  \\ simp[Once strip_sxcons_def]
  \\ simp[Once strip_sxcons_def]
  \\ simp[EL_MAP]
  \\ simp[sxMEM_def]
  \\ metis_tac[MEM_EL]);

val type_defsexp_sexptype_def = Q.store_thm("type_defsexp_sexptype_def",
  `sexptype_def s = SOME x ⇒ type_defsexp x = s`,
  rw[sexptype_def_def,type_defsexp_def]
  \\ imp_res_tac sexplist_SOME \\ rw[]
  \\ fs[LIST_EQ_REWRITE,EL_MAP]
  \\ rw[] \\ rfs[EL_MAP]
  \\ res_tac
  \\ imp_res_tac sexppair_SOME
  \\ imp_res_tac sexppair_SOME
  \\ fs[] \\ rveq \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ imp_res_tac sexplist_SOME \\ rw[]
  \\ fs[LIST_EQ_REWRITE,EL_MAP]
  \\ rw[] \\ rfs[EL_MAP]
  \\ res_tac
  \\ imp_res_tac sexppair_SOME
  \\ fs[] \\ rveq \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ imp_res_tac sexplist_SOME \\ rw[]
  \\ fs[LIST_EQ_REWRITE,EL_MAP]
  \\ rw[] \\ rfs[EL_MAP]
  \\ metis_tac[typesexp_sexptype]);

val decsexp_sexpdec = Q.store_thm("decsexp_sexpdec",
  `sexpdec s = SOME d ⇒ decsexp d = s`,
  rw[sexpdec_def]
  \\ pairarg_tac \\ fs[]
  \\ fs[dstrip_sexp_SOME]
  \\ rpt var_eq_tac
  \\ fs[OPTION_IGNORE_BIND_OPTION_GUARD]
  \\ every_case_tac \\ fs[decsexp_def]
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3]
  \\ rw[] \\ fs[]
  \\ rpt(match1_tac strip_sxcons_mtac)
  \\ fs[OPTION_APPLY_MAP3]
  \\ rw[decsexp_def]
  \\ rveq \\ fs[listsexp_def] \\ fs[GSYM listsexp_def]
  \\ imp_res_tac patsexp_sexppat
  \\ imp_res_tac expsexp_sexpexp
  \\ imp_res_tac sexplist_SOME
  \\ imp_res_tac type_defsexp_sexptype_def
  \\ imp_res_tac typesexp_sexptype
  \\ rw[]
  \\ fs[LIST_EQ_REWRITE,EL_MAP]
  \\ rw[] \\ rfs[EL_MAP]
  \\ res_tac
  \\ imp_res_tac sexppair_SOME
  \\ imp_res_tac typesexp_sexptype
  \\ fs[] \\ rveq \\ fs[]
  \\ pairarg_tac \\ fs[]
  \\ imp_res_tac sexppair_SOME
  \\ fs[] \\ rveq \\ fs[]
  \\ imp_res_tac expsexp_sexpexp);

val specsexp_sexpspec = Q.store_thm("specsexp_sexpspec",
  `sexpspec s = SOME z ⇒ specsexp z = s`,
  rw[sexpspec_def]
  \\ fs[dstrip_sexp_SOME]
  \\ rw[] \\ fs[]
  \\ every_case_tac \\ fs[] \\ rw[]
  \\ fs[OPTION_APPLY_MAP3,OPTION_IGNORE_BIND_OPTION_GUARD]
  \\ fs[quantHeuristicsTheory.LIST_LENGTH_3]
  \\ rw[] \\ fs[]
  \\ rpt (match1_tac strip_sxcons_mtac)
  \\ rw[specsexp_def,listsexp_def]
  \\ rw[GSYM listsexp_def]
  \\ imp_res_tac typesexp_sexptype
  \\ imp_res_tac type_defsexp_sexptype_def
  \\ imp_res_tac sexplist_SOME \\ rw[]
  \\ fs[LIST_EQ_REWRITE]
  \\ rw[] \\ rfs[EL_MAP]
  \\ metis_tac[typesexp_sexptype]);

val topsexp_sexptop = Q.store_thm("topsexp_sexptop",
  `sexptop s = SOME t ⇒ topsexp t = s`,
  Cases_on`t` >> simp[topsexp_def,sexptop_def,dstrip_sexp_SOME,PULL_EXISTS] >> rw[] >>
  fs[OPTION_BIND_OPTION_GUARD,OPTION_IGNORE_BIND_OPTION_GUARD] >>
  Cases_on`args`>>fs[listTheory.LENGTH_NIL] >>
  simp[Once listsexp_def] >>
  fs[Once strip_sxcons_def] >>
  every_case_tac >> fs[] >> rw[decsexp_sexpdec] >>
  Cases_on`t`>>fs[] >>
  fs[Once strip_sxcons_def] >>
  every_case_tac >> fs[] >>
  Cases_on`t'`>>fs[]>>
  fs[Once strip_sxcons_def] >>
  every_case_tac >> fs[] >>
  Cases_on`t`>>fsrw_tac[ARITH_ss][] >>
  rpt var_eq_tac >>
  imp_res_tac sexplist_SOME >>
  rveq
  \\ imp_res_tac sexpopt_SOME
  \\ rveq
  \\ reverse conj_tac
  >- (
    AP_TERM_TAC
    \\ fs[LIST_EQ_REWRITE]
    \\ rw[] \\ rfs[EL_MAP]
    \\ metis_tac[decsexp_sexpdec] )
  \\ every_case_tac \\ fs[]
  \\ rw[]
  \\ fs[IS_SOME_EXISTS]
  \\ imp_res_tac sexplist_SOME
  \\ rw[]
  \\ fs[LIST_EQ_REWRITE]
  \\ rw[] \\ rfs[EL_MAP]
  \\ fs[EL_MAP]
  \\ metis_tac[specsexp_sexpspec]);

val _ = export_theory();
