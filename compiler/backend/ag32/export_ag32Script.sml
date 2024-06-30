(*
  Define the format of the compiler-generated output file for ag32
*)
open preamble exportTheory mlstringTheory

val () = new_theory "export_ag32";

val ag32_export_def = Define `
  ag32_export (ffi_names:string list) bytes (data:word32 list)
      (syms: (mlstring # num # num) list) exp ret =
    SmartAppend
     (split16 (words_line (strlit".data_word ") word_to_string) data)
     (split16 (words_line (strlit".code_byte ") byte_to_string) bytes)`;

val _ = export_theory ();
