(* begin-module-use-description
Module StdioTest exercises the Stdio module.

end-module-use-description *)
(* begin-module-use-description
Module StdioTest exercises the Stdio module.

end-module-use-description *)
MODULE StdioTest;
  IMPORT Stdio;

  CONST

  TYPE

  VAR

  PROCEDURE Run*;
  VAR F: Stdio.Flow;
  BEGIN 
    NEW(F);
    NEW(F.T);
    F.user := FALSE;

    Stdio.Open(F)

  END Run;


BEGIN
END StdioTest.

