(*
  Relate top-level semantics for function big-step / relational big-step /
  small-step semantics.
*)
open preamble semanticsTheory bigStepTheory smallStepTheory
     semanticPrimitivesPropsTheory bigClockTheory
     funBigStepEquivTheory bigSmallEquivTheory

val _ = new_theory "alt_semantics";

Theorem big_step_semantics:
  st.eval_state = NONE ⇒ (
  (semantics_prog st env prog (Terminate outcome io_list) ⇔
    ∃st' res ex env'.
      evaluate_decs F env st prog (st', res) ∧
      st'.ffi.io_events = io_list ∧
      if outcome = Success then
        res = Rval env' ∨ res = Rerr (Rraise ex)
      else ∃f. outcome = FFI_outcome f ∧ res = Rerr (Rabort $ Rffi_error f)) ∧
   (semantics_prog st env prog (Diverge io_trace) ⇔
      (∀k. ∃st'.
        evaluate_decs T env (st with clock := k) prog
          (st',Rerr (Rabort Rtimeout_error))) ∧
      lprefix_lub
        { fromList s.ffi.io_events |
            ∃k r. evaluate_decs T env (st with clock := k) prog (s,r) }
        io_trace) ∧
  (semantics_prog st env prog Fail ⇔
    ∃st'.
      evaluate_decs F env st prog (st', Rerr (Rabort Rtype_error)))
  )
Proof
  strip_tac >> rpt conj_tac
  >- (
    rw[semantics_prog_def] >> eq_tac >> rw[] >> gvs[]
    >- (
      every_case_tac >> gvs[] >>
      gvs[evaluate_prog_with_clock_def] >> pairarg_tac >> gvs[] >>
      drule_at (Pos last) $ iffLR functional_evaluate_decs >> rw[] >>
      drule $ cj 2 evaluate_decs_clocked_to_unclocked >> simp[] >>
      disch_then $ qspec_then `st.clock` mp_tac >> rw[with_same_clock] >>
      goal_assum drule >> simp[]
      ) >>
    simp[evaluate_prog_with_clock_def] >>
    drule $ cj 2 evaluate_decs_unclocked_to_clocked >>
    simp[GSYM functional_evaluate_decs] >> strip_tac >> gvs[] >>
    qexists_tac `c` >> simp[] >> every_case_tac >> gvs[]
    )
  >- (
    simp[semantics_prog_def, evaluate_prog_with_clock_def] >>
    simp[GSYM functional_evaluate_decs] >>
    qmatch_goalsub_abbrev_tac `lprefix_lub foo` >>
    qmatch_goalsub_abbrev_tac `_ ⇔ _ ∧ lprefix_lub bar _` >>
    `foo = bar` by (
      unabbrev_all_tac >> rw[EXTENSION, SF DNF_ss] >> eq_tac >> rw[]
      >- ( pairarg_tac >> gvs[] >> metis_tac[])
      >- (qexists_tac `k` >> simp[])) >>
    gvs[] >> eq_tac >> rw[] >>
    last_x_assum $ qspec_then `k` assume_tac >> gvs[] >> pairarg_tac >> gvs[]
    )
  >- (
    rw[semantics_prog_def] >> eq_tac >> rw[] >>
    gvs[evaluate_prog_with_clock_def]
    >- (
      pairarg_tac >> gvs[] >>
      drule_at (Pos last) $ iffLR functional_evaluate_decs >> rw[] >>
      drule $ cj 2 evaluate_decs_clocked_to_unclocked >> simp[] >>
      disch_then $ qspec_then `st.clock` mp_tac >> rw[with_same_clock] >>
      goal_assum drule >> simp[]
      ) >>
    simp[evaluate_prog_with_clock_def] >>
    drule $ cj 2 evaluate_decs_unclocked_to_clocked >>
    simp[GSYM functional_evaluate_decs] >> strip_tac >> gvs[] >>
    qexists_tac `c` >> simp[]
    )
QED

Theorem small_step_semantics:
  st.eval_state = NONE ⇒ (
  (semantics_prog st env prog (Terminate outcome io_list) ⇔
    ∃st' res ex env'.
      small_eval_decs env st prog (st', res) ∧
      st'.ffi.io_events = io_list ∧
      if outcome = Success then
        res = Rval env' ∨ res = Rerr (Rraise ex)
      else ∃f. outcome = FFI_outcome f ∧ res = Rerr (Rabort $ Rffi_error f)) ∧
  (semantics_prog st env prog (Diverge io_trace) ⇔
    small_decl_diverges env (st, Decl (Dlocal [] prog), []) ∧
    lprefix_lub
      { fromList (FST s).ffi.io_events |
          (decl_step_reln env)꙳ (st, Decl (Dlocal [] prog), []) s }
      io_trace) ∧
  (semantics_prog st env prog Fail ⇔
    ∃st'.
      small_eval_decs env st prog (st', Rerr (Rabort Rtype_error)))
  )
Proof
  rw[big_step_semantics, small_big_decs_equiv] >>
  simp[GSYM small_big_decs_equiv_diverge, GSYM decs_diverges_big_clocked] >>
  Cases_on `decs_diverges env st prog` >> gvs[] >>
  simp[lprefix_lub_big_small]
QED

val _ = export_theory();
