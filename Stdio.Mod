(* begin-module-use-description
Module Stdio adapts streaming io to the Oberon text and viewers model.

end-module-use-description *)
(* begin-module-use-description
Module Stdio adapts streaming io to the Oberon text and viewers model.

end-module-use-description *)
MODULE Stdio;
  IMPORT Texts, Viewers, Oberon, TextFrames, MenuViewers, System, Edit;

  CONST

  TYPE

  VAR


  PROCEDURE Open*;
    VAR T: Texts.Text;
    S: Texts.Scanner;
    V: Viewers.Viewer;
    X, Y: INTEGER;
    beg, end, time: LONGINT;
    user: BOOLEAN;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.codepoint = ORD("^")) OR (S.line # 0) THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END;
    IF S.class = Texts.Name THEN
      user:=TRUE;
      IF user THEN
        Oberon.AllocateUserViewer(Oberon.Par.vwr.X, X, Y);
      ELSE
        Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
      END;
      V := MenuViewers.New(
        TextFrames.NewMenu(S.s, "System.Close System.Copy System.Grow Edit.Search Edit.Store"),
        TextFrames.NewText(TextFrames.Text(S.s), 0),
        TextFrames.menuH, X, Y)
    END
  END Open;


BEGIN
END Stdio.

