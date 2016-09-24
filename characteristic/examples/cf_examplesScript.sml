open preamble
open ml_translatorTheory cfTacticsBaseLib cfTacticsLib
local open ml_progLib basisProgTheory in end

val _ = new_theory "cf_examples";

val basis_st =
  ml_progLib.unpack_ml_prog_state
    basisProgTheory.basis_prog_state

val example_let0 = process_topdecl
  "fun example_let0 n = let val a = 3; in a end"

val st0 = ml_progLib.add_prog example_let0 pick_name basis_st

val example_let0_spec = Q.prove (
  `!nv. app (p:'ffi ffi_proj) ^(fetch_v "example_let0" st0) [nv]
          emp (POSTv v. & INT 3 v)`,
  xcf "example_let0" st0 \\ xlet `POSTv a. & INT 3 a`
  THEN1 (xret \\ xsimpl) \\
  xret \\ xsimpl
)

val example_let1 = process_topdecl
  "fun example_let1 _ = let val a = (); in a end"

val st1 = ml_progLib.add_prog example_let1 pick_name basis_st

val example_let1_spec = Q.prove (
  `!uv. app (p:'ffi ffi_proj) ^(fetch_v "example_let1" st1) [uv]
          emp (POSTv v. & UNIT_TYPE () v)`,
  xcf "example_let1" st1 \\ xlet `POSTv a. & UNIT_TYPE () a`
  THEN1 (xret \\ xsimpl) \\
  xret \\ xsimpl
)

val example_let2 = process_topdecl
  "fun example_let2 u = let val a = u; in a end"

val st2 = ml_progLib.add_prog example_let2 pick_name basis_st

val example_let2_spec = Q.prove (
  `!uv. app (p:'ffi ffi_proj) ^(fetch_v "example_let2" st2) [uv]
          emp (POSTv v. & (v = uv))`,
  xcf "example_let2" st2 \\ xlet `POSTv v. & (v = uv)`
  THEN1 (xret \\ xsimpl) \\
  xret \\ xsimpl
)

val example_let = process_topdecl
  "fun example_let n = let val a = n + 1; val b = n - 1; in a+b end"

val st = ml_progLib.add_prog example_let pick_name basis_st

val example_let_spec = Q.prove (
  `!n nv.
     INT n nv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "example_let" st) [nv]
       emp (POSTv v. & INT (2 * n) v)`,

  xcf "example_let" st \\
  xlet `POSTv a. & INT (n+1) a`
  THEN1 (xapp \\ fs []) \\
  xlet `POSTv b. & INT (n-1) b`
  THEN1 (xapp \\ fs []) \\
  xapp \\ xsimpl \\ fs [INT_def] \\ intLib.ARITH_TAC
)

val alloc_ref2 = process_topdecl
  "fun alloc_ref2 a b = (ref a, ref b);"

val st = ml_progLib.add_prog alloc_ref2 pick_name basis_st

val alloc_ref2_spec = Q.prove (
  `!av bv a b r1v r2v r1 r2.
     INT a av /\ INT b bv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "alloc_ref2" st) [av; bv]
       emp
       (POSTv p. SEP_EXISTS r1 r2.
                 & PAIR_TYPE (=) (=) (r1, r2) p *
                 REF r1 av * REF r2 bv)`,
  xcf "alloc_ref2" st \\
  xlet `POSTv r2. REF r2 bv` THEN1 xapp \\
  xlet `POSTv r1. REF r1 av * REF r2 bv` THEN1 (xapp \\ xsimpl) \\
  xret \\ fs [PAIR_TYPE_def] \\ xsimpl
)

val swap = process_topdecl
  "fun swap r1 r2 = let val x1 = !r1 in r1 := !r2; r2 := x1 end"

val st2 = ml_progLib.add_prog swap pick_name st

val swap_spec = Q.prove (
  `!xv yv r1v r2v.
     app (p:'ffi ffi_proj) ^(fetch_v "swap" st2) [r1v; r2v]
       (REF r1v xv * REF r2v yv)
       (POSTv v. & UNIT_TYPE () v * REF r1v yv * REF r2v xv)`,
  xcf "swap" st2 \\
  xlet `POSTv xv'. & (xv' = xv) * r1v ~~> xv * r2v ~~> yv`
    THEN1 (xapp \\ xsimpl) \\
  xlet `POSTv yv'. & (yv' = yv) * r1v ~~> xv * r2v ~~> yv`
    THEN1 (xapp \\ xsimpl) \\
  xlet `POSTv u. r1v ~~> yv * r2v ~~> yv`
    THEN1 (xapp \\ xsimpl) \\
  xapp \\ xsimpl
)

val example_if = process_topdecl
  "fun example_if n = if n > 0 then 1 else 2"

val st = ml_progLib.add_prog example_if pick_name basis_st

val example_if_spec = Q.prove (
  `!n nv.
     INT n nv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "example_if" st) [nv]
       emp (POSTv v. &(if n > 0 then INT 1 v else INT 2 v))`,

  xcf "example_if" st \\ xlet `POSTv bv. & BOOL (n > 0) bv`
  THEN1 (xapp \\ fs []) \\
  xif \\ xret \\ xsimpl
)

val is_nil = process_topdecl
  "fun is_nil l = case l of [] => true | x::xs => false"

val st = ml_progLib.add_prog is_nil pick_name basis_st

val is_nil_spec = Q.prove (
  `!lv a l.
     LIST_TYPE a l lv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "is_nil" st) [lv]
       emp (POSTv bv. & BOOL (l = []) bv)`,

  xcf "is_nil" st \\ Cases_on `l` \\ fs [LIST_TYPE_def] \\
  xmatch \\ xret \\ xsimpl
)

val example_eq = process_topdecl
  "fun example_eq x = (x = 3)"

val st = ml_progLib.add_prog example_eq pick_name basis_st

val example_eq_spec = Q.prove (
  `!x xv.
     INT x xv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "example_eq" st) [xv]
       emp (POSTv bv. & BOOL (x = 3) bv)`,
  xcf "example_eq" st \\ xapp \\
  (* instantiate *) qexists_tac `INT` \\ fs [] \\
  fs [EqualityType_NUM_BOOL]
)

val example_and = process_topdecl
  "fun example_and u = true andalso false"

val st = ml_progLib.add_prog example_and pick_name basis_st

val example_and_spec = Q.prove (
  `!uv.
     UNIT_TYPE () uv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "example_and" st) [uv]
       emp (POSTv bv. & BOOL F bv)`,
  xcf "example_and" st \\ xlet `POSTv b. & BOOL T b`
  THEN1 (xret \\ xsimpl) \\
  xlog \\ xret \\ xsimpl
)

val list_length = process_topdecl
  "fun length l = \
 \    case l of \
 \      [] => 0 \
 \    | x::xs => (length xs) + 1"

val bytearray_fromlist = process_topdecl
  "fun fromList ls = \
 \    let val a = Word8Array.array (length ls) (Word8.fromInt 0) \
 \        fun f ls i = \
 \          case ls of \
 \            [] => a \
 \          | h::t => (Word8Array.update a i h; f t (i+1)) \
 \    in f ls 0 end"

val st = basis_st
  |> ml_progLib.add_prog list_length pick_name
  |> ml_progLib.add_prog bytearray_fromlist pick_name

val list_length_spec = store_thm ("list_length_spec",
  ``!a l lv.
     LIST_TYPE a l lv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "length" st) [lv]
       emp (POSTv v. & NUM (LENGTH l) v)``,
  Induct_on `l`
  THEN1 (
    xcf "length" st \\ fs [LIST_TYPE_def] \\
    xmatch \\ xret \\ xsimpl
  )
  THEN1 (
    xcf "length" st \\ fs [LIST_TYPE_def] \\
    rename1 `a x xv` \\ rename1 `LIST_TYPE a xs xvs` \\
    xmatch \\ xlet `POSTv xs_len. & NUM (LENGTH xs) xs_len`
    THEN1 (xapp \\ metis_tac []) \\
    xapp \\ xsimpl \\ fs [NUM_def] \\ asm_exists_tac \\ fs [] \\
    (* meh? *) fs [INT_def] \\ intLib.ARITH_TAC
  )
)

val bytearray_fromlist_spec = Q.prove (
  `!l lv.
     LIST_TYPE WORD l lv ==>
     app (p:'ffi ffi_proj) ^(fetch_v "fromList" st) [lv]
       emp (POSTv av. W8ARRAY av l)`,
  xcf "fromList" st \\
  xlet `POSTv w8z. & WORD (n2w 0: word8) w8z` THEN1 (xapp \\ fs []) \\
  xlet `POSTv len_v. & NUM (LENGTH l) len_v` THEN1 (xapp \\ metis_tac []) \\
  xlet `POSTv av. W8ARRAY av (REPLICATE (LENGTH l) 0w)`
    THEN1 (xapp \\ fs []) \\
  xfun_spec `f`
    `!ls lvs i iv l_pre rest.
       NUM i iv /\ LIST_TYPE WORD ls lvs /\
       LENGTH rest = LENGTH ls /\ i = LENGTH l_pre
        ==>
       app p f [lvs; iv]
         (W8ARRAY av (l_pre ++ rest))
         (POSTv ret. & (ret = av) * W8ARRAY av (l_pre ++ ls))`
  THEN1 (
    Induct_on `ls` \\ fs [LIST_TYPE_def, LENGTH_NIL] \\ rpt strip_tac
    THEN1 (xapp \\ xmatch \\ xret \\ xsimpl)
    THEN1 (
      fs [] \\ last_assum xapp_spec \\ xmatch \\ fs [LENGTH_CONS] \\
      rename1 `rest = rest_h :: rest_t` \\ rw [] \\
      xlet `POSTv _. W8ARRAY av (l_pre ++ h :: rest_t)` THEN1 (
        xapp \\ xsimpl \\ fs [UNIT_TYPE_def] \\ instantiate \\
        fs [lupdate_append]
      ) \\
      xlet `POSTv ippv. & NUM (LENGTH l_pre + 1) ippv * W8ARRAY av (l_pre ++ h::rest_t)`
      THEN1 (
        xapp \\ xsimpl \\ fs [NUM_def] \\ instantiate \\
        fs [INT_def] \\ intLib.ARITH_TAC
      ) \\
      once_rewrite_tac [
        Q.prove(`l_pre ++ h::ls = (l_pre ++ [h]) ++ ls`, fs [])
      ] \\ xapp \\ fs []
    )
  ) \\
  xapp \\ fs [] \\ xsimpl \\ fs [LENGTH_NIL_SYM, LENGTH_REPLICATE]
)

val _ = export_theory();
