(*exh_Init_global_var special case for Uapp_exh*)
temp_add_user_printer("exh_initglobal",``Uapp_exh (Init_global_var_i2 n) x``,genPrint i2_initglobalPrint);

(*reuse i2 extend global*)
temp_add_user_printer("exh_extendglobal",``Extend_global_exh n``,genPrint i2_extendglobalPrint);

(*exh_Pvar*)
temp_add_user_printer ("exh_pvarprint", ``Pvar_exh x``, genPrint pvarPrint);

(*exh_Plit*)
temp_add_user_printer("exh_plitprint", ``Plit_exh x``, genPrint plitPrint);


(*exh_Nested mutually recursive letrec*)
temp_add_user_printer ("exh_letrecprint", ``Letrec_exh x y``,genPrint letrecPrint);

(*exh_Lambdas varN*expr *)
temp_add_user_printer ("exh_lambdaprint", ``Fun_exh x y``,genPrint lambdaPrint);

(*exh_Inner Let SOME*)
temp_add_user_printer ("exh_letvalprint", ``Let_exh (SOME x) y z``,genPrint letvalPrint);

(*exh_Inner Let NONE*)
temp_add_user_printer ("exh_letnoneprint",``Let_exh NONE y z ``,genPrint letnonePrint);

(*Prints all constructor args in a list comma separated*)
temp_add_user_printer ("exh_conprint", ``Con_exh x y``,genPrint i2_pconPrint);
temp_add_user_printer ("exh_pconprint", ``Pcon_exh x y``,genPrint i2_pconPrint);

(*exh_Literals*)
(*exh_Pattern lit*)
temp_add_user_printer ("exh_litprint", ``Lit_exh x``, genPrint plitPrint);
temp_add_user_printer ("exh_unitprint", ``Lit_exh Unit``,genPrint unitPrint);

(*exh local Var name, no more long names*)
temp_add_user_printer ("exh_varlocalprint", ``Var_local_exh x``,genPrint i1_varlocalPrint);

(*exh global Var name*)
temp_add_user_printer ("exh_varglobalprint", ``Var_global_exh n``,genPrint i1_varglobalPrint);

(*exh_Matching*)
temp_add_user_printer ("exh_matprint", ``Mat_exh x y``,genPrint matPrint);

(*exh_Apply*)
temp_add_user_printer ("exh_oppappprint", ``App_exh Opapp f x``, genPrint oppappPrint);

(*exh_raise expr*) 
temp_add_user_printer ("exh_raiseprint", ``Raise_exh x``,genPrint raisePrint);

(*exh_handle expr * list (pat*expr)*)
temp_add_user_printer ("exh_handleprint", ``Handle_exh x y``,genPrint handlePrint);

(*exh_If-then-else*)
temp_add_user_printer("exh_ifthenelseprint", ``If_exh x y z``,genPrint ifthenelsePrint);


