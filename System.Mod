(* begin-documentation-node
#######################
  IO Standard Packages
#######################


.. toctree::
   :maxdepth: 2
   :caption: Development:
   :hidden:

   ../Assist/Assist     [stdlib/Assist.rst]
   ../Attest/Attest     [stdlib/Attest.rst]
   ../Crypto/Crypto     [stdlib/Crypto.rst]
   ../Doc/Doc           [stdlib/Doc.rst]
   ../Draw/Draw         [stdlib/Draw.rst]
   ../Paint/Paint       [stdlib/Paint.rst]
   ../Mod/Mod           [stdlib/Mod.rst]
   ../ArgParse/ArgParse [stdlib/ArgParse.rst]
   ../Test/Test         [stdlib/Test.rst]

Standard Library documentation starts here...

https://github.com/io-core/System/blob/main/System.Mod

end-documentation-node *)
(* begin-package-description
The System package collects the expected set of modules and tools that allows the Oberon user to perform typical computing tasks.


end-package-description *)

(* begin-module-short-description
defines the tiling user interface and inital environment of Oberon.
end-module-short-description *)

(* begin-module-use-description
Module System presents the Oberon user with tools and commands for interacting Displays and Tracks and Files and other miscelaneous features.

end-module-use-description *)
MODULE System; (*JG 3.10.90 / NW 12.10.93 / NW 20.6.2016*)
               (*MS 1.2019 adapted for Unicode*)

  IMPORT SYSTEM, Kernel, FileDir, Files, Modules, Input, Display, Viewers, Fonts, Texts, Oberon, MenuViewers, TextFrames;

  CONST
    StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store";
    LogMenu = "Edit.Locate Edit.Search System.Copy System.Grow System.Clear Halt.Now";

  TYPE

  VAR W: Texts.Writer;
    pat: ARRAY 32 OF CHAR;
    jobV: Viewers.Viewer;
    jobCM: TextFrames.CallMsg;

  PROCEDURE GetArg(VAR S: Texts.Scanner);
    VAR T: Texts.Text; beg, end, time: LONGINT;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.codepoint = ORD("^")) THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S) END
    END
  END GetArg;

  PROCEDURE EndLine;
  BEGIN Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf)
  END EndLine;

  (* ------------- Toolbox for system control ---------------*)

  PROCEDURE SetUser*;
    VAR i, codepoint: INTEGER; ch: CHAR;
      user: ARRAY 8 OF CHAR;
      password: ARRAY 16 OF CHAR;
  BEGIN i := 0; Input.ReadUnicode(codepoint); ch := CHR(codepoint MOD 80H);
    WHILE (ch # "/") & (i < 7) DO user[i] := ch; INC(i); Input.ReadUnicode(codepoint); ch := CHR(codepoint MOD 80H) END;
    user[i] := 0X; i := 0; Input.ReadUnicode(codepoint); ch := CHR(codepoint MOD 80H);
    WHILE (ch > " ") & (i < 15) DO password[i] := ch; INC(i); Input.ReadUnicode(codepoint); ch := CHR(codepoint MOD 80H) END;
    password[i] := 0X; Oberon.SetUser(user, password)
  END SetUser;

  PROCEDURE SetFont*;
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN Oberon.SetFont(Fonts.This(S.s)) END
  END SetFont;

  PROCEDURE SetColor*;
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN Oberon.SetColor(S.i) END
  END SetColor;

  PROCEDURE SetOffset*;
    VAR S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Int THEN Oberon.SetOffset(S.i) END
  END SetOffset;
  
  PROCEDURE Date*;
    VAR S: Texts.Scanner;
      dt, hr, min, sec, yr, mo, day: LONGINT;
  BEGIN Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF S.class = Texts.Int THEN (*set clock*)
      day := S.i; Texts.Scan(S); mo := S.i; Texts.Scan(S); yr := S.i; Texts.Scan(S);
      hr := S.i; Texts.Scan(S); min := S.i; Texts.Scan(S); sec := S.i;
      dt := ((((yr*16 + mo)*32 + day)*32 + hr)*64 + min)*64 + sec;
      Kernel.SetClock(dt)
    ELSE (*read clock*) Texts.WriteString(W, "System.Clock");
      dt := Oberon.Clock(); Texts.WriteClock(W, dt); EndLine
    END
  END Date;

  PROCEDURE Collect*;
  BEGIN Oberon.Collect(0)
  END Collect;

  (* ------------- Toolbox for standard display ---------------*)

  PROCEDURE Open*;  (*open viewer in system track*)
    VAR X, Y: INTEGER;
      V: Viewers.Viewer;
      S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN
      Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
      V := MenuViewers.New(
        TextFrames.NewMenu(S.s, StandardMenu),
        TextFrames.NewText(TextFrames.Text(S.s), 0), TextFrames.menuH, X, Y)
    END
  END Open;

  PROCEDURE Clear*;  (*clear Log*)
    VAR T: Texts.Text; F: Display.Frame; buf: Texts.Buffer;
  BEGIN F := Oberon.Par.frame;
    IF (F # NIL) & (F.next IS TextFrames.Frame) & (F = Oberon.Par.vwr.dsc) THEN
      NEW(buf); Texts.OpenBuf(buf); T := F.next(TextFrames.Frame).text; Texts.Delete(T, 0, T.len, buf)
    END
  END Clear;

  PROCEDURE Close*;
    VAR V: Viewers.Viewer;
  BEGIN
    IF Oberon.Par.frame = Oberon.Par.vwr.dsc THEN V := Oberon.Par.vwr
    ELSE V := Oberon.MarkedViewer()
    END;
    Viewers.Close(V)
  END Close;

  PROCEDURE CloseTrack*;
    VAR V: Viewers.Viewer;
  BEGIN V := Oberon.MarkedViewer(); Viewers.CloseTrack(V.X)
  END CloseTrack;

  PROCEDURE Recall*;
    VAR V: Viewers.Viewer; M: Viewers.ViewerMsg;
  BEGIN Viewers.Recall(V);
    IF (V#NIL) & (V.state = 0) THEN
      Viewers.Open(V, V.X, V.Y + V.H); M.id := Viewers.restore; V.handle(V, M)
    END
  END Recall;

  PROCEDURE Copy*;
    VAR V, V1: Viewers.Viewer; M: Oberon.CopyMsg; N: Viewers.ViewerMsg;
  BEGIN V := Oberon.Par.vwr; V.handle(V, M); V1 := M.F(Viewers.Viewer);
    Viewers.Open(V1, V.X, V.Y + V.H DIV 2);
    N.id := Viewers.restore; V1.handle(V1, N)
  END Copy;

  PROCEDURE Grow*;
    VAR V, V1: Viewers.Viewer; M: Oberon.CopyMsg; N: Viewers.ViewerMsg;
      DW, DH: INTEGER;
  BEGIN V := Oberon.Par.vwr;
    DW := Oberon.DisplayWidth(V.X); DH := Oberon.DisplayHeight(V.X);
    IF V.H < DH - Viewers.minH THEN Oberon.OpenTrack(V.X, V.W)
    ELSIF V.W < DW THEN Oberon.OpenTrack(Oberon.UserTrack(V.X), DW)
    END;
    IF (V.H < DH - Viewers.minH) OR (V.W < DW) THEN
      V.handle(V, M); V1 := M.F(Viewers.Viewer);
      Viewers.Open(V1, V.X, DH);;
      N.id := Viewers.restore; V1.handle(V1, N)
    END
  END Grow;

  (* ------------- Toolbox for module management ---------------*)

  PROCEDURE Free1(VAR S: Texts.Scanner);
  BEGIN Texts.WriteString(W, S.s); Texts.WriteString(W, " unloading");
    Modules.Free(S.s);
    IF Modules.res # 0 THEN Texts.WriteString(W, " failed") END;
    EndLine
  END Free1;

  PROCEDURE Free*;
    VAR T: Texts.Text;
      beg, end, time: LONGINT;
      S: Texts.Scanner;
  BEGIN Texts.WriteString(W, "System.Free"); EndLine;
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.codepoint = ORD("^")) THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S);
        IF S.class = Texts.Name THEN Free1(S) END
      END
    ELSE
      WHILE S.class = Texts.Name DO Free1(S); Texts.Scan(S) END
    END ;
    Oberon.Collect(0)
  END Free;


  PROCEDURE Link*;
    VAR T: Texts.Text;
      beg, end, time, res: INTEGER;
      S: Texts.Scanner;
  BEGIN Texts.WriteString(W, "System.Link linking "); 
    Texts.OpenScanner(S, Oberon.Par.text, Oberon.Par.pos); Texts.Scan(S);
    IF (S.class = Texts.Char) & (S.codepoint = ORD("^")) THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN Texts.OpenScanner(S, T, beg); Texts.Scan(S);
        IF S.class = Texts.Name THEN 
          Texts.WriteString(W, S.s); EndLine;
          Modules.Link(S.s,res);
        END
      END
    ELSIF S.class = Texts.Name THEN
       Texts.WriteString(W, S.s); EndLine;
       Modules.Link(S.s,res);
    ELSE
      Texts.WriteString(W, "???"); EndLine;
      res:=9
    END ;
    IF res # 0 THEN
      Texts.WriteString(W, "Link failed"); EndLine
    ELSE
      Texts.WriteString(W, "Link complete"); EndLine
    END;
    Oberon.Collect(0)
  END Link;



  PROCEDURE FreeFonts*;
  BEGIN Texts.WriteString(W, "System.FreeFonts"); Fonts.Free; EndLine
  END FreeFonts;

  (* ------------- Toolbox of file system ---------------*)

  PROCEDURE List(name: FileDir.FileName; adr: LONGINT; VAR cont: BOOLEAN);
    VAR i0, i, j0, j: INTEGER; hp: FileDir.FileHeader;
  BEGIN
    i := 0;
    WHILE (pat[i] > "*") & (pat[i] = name[i]) DO INC(i) END ;
    IF (pat[i] = 0X) & (name[i] = 0X) THEN i0 := i; j0 := i
    ELSIF pat[i] = "*" THEN
      i0 := i; j0 := i+1;
      WHILE name[i0] # 0X DO
        i := i0; j := j0;
        WHILE (name[i] # 0X) & (name[i] = pat[j]) DO INC(i); INC(j) END ;
        IF pat[j] = 0X THEN
          IF name[i] = 0X THEN (*match*) j0 := j ELSE INC(i0) END
        ELSIF pat[j] = "*" THEN i0 := i; j0 := j+1
        ELSE INC(i0)
        END
      END
    END ;
    IF (name[i0] = 0X) & (pat[j0] = 0X) THEN (*found*)
      Texts.WriteString(W, name);
      IF pat[j0+1] = "!" THEN (*option*)
        Kernel.GetSector(adr, hp);
        Texts.Write(W, 9X); Texts.WriteClock(W, hp.date);
        Texts.WriteInt(W, hp.aleng*FileDir.SectorSize + hp.bleng - FileDir.HeaderSize, 8); (*length*)
        (*Texts.WriteHex(W, adr)*)
      END ;
      Texts.WriteLn(W)
    END
  END List;

  PROCEDURE Directory*;
    VAR X, Y, i: INTEGER; ch: CHAR;
      R: Texts.Reader;
      T, t: Texts.Text;
      V: Viewers.Viewer;
      beg, end, time: LONGINT;
      pre: ARRAY 32 OF CHAR;
  BEGIN Texts.OpenReader(R, Oberon.Par.text, Oberon.Par.pos); Texts.Read(R, ch);
    WHILE ch = " " DO Texts.Read(R, ch) END;
    IF (ch = "^") OR (ch = 0DX) OR (ch = 0AX) THEN
      Oberon.GetSelection(T, beg, end, time);
      IF time >= 0 THEN
        Texts.OpenReader(R, T, beg); Texts.Read(R, ch);
        WHILE ch <= " " DO Texts.Read(R, ch) END
      END
    END ;
    i := 0;
    WHILE ch > "!" DO pat[i] := ch; INC(i); Texts.Read(R, ch) END;
    pat[i] := 0X;
    IF ch = "!" THEN pat[i+1] := "!" END ;  (*directory option*)
    i := 0;
    WHILE pat[i] > "*" DO pre[i] := pat[i]; INC(i) END;
    pre[i] := 0X;
    Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y); t := TextFrames.Text("");
    V := MenuViewers.New(
      TextFrames.NewMenu("System.Directory", StandardMenu),
      TextFrames.NewText(t, 0), TextFrames.menuH, X, Y);
    FileDir.Enumerate(pre, List); Texts.Append(t, W.buf)
  END Directory;

  PROCEDURE CopyFiles*;
    VAR f, g: Files.File; Rf, Rg: Files.Rider; ch: CHAR;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.CopyFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      name := S.s; Texts.Scan(S);
      IF (S.class = Texts.Char) & (S.codepoint = ORD("=")) THEN Texts.Scan(S);
        IF (S.class = Texts.Char) & (S.codepoint = ORD(">")) THEN Texts.Scan(S);
          IF S.class = Texts.Name THEN
            Texts.WriteString(W, name); Texts.WriteString(W, " => "); Texts.WriteString(W, S.s);
            Texts.WriteString(W, " copying"); Texts.Append(Oberon.Log, W.buf);
            f := Files.Old(name);
            IF f # NIL THEN g := Files.New(S.s);
              Files.Set(Rf, f, 0); Files.Set(Rg, g, 0); Files.Read(Rf, ch);
              WHILE ~Rf.eof DO Files.Write(Rg, ch); Files.Read(Rf, ch) END;
              Files.Register(g)
            ELSE Texts.WriteString(W, " failed")
            END ;
            EndLine
          END
        END
      END ;
      Texts.Scan(S)
    END
  END CopyFiles;

  PROCEDURE RenameFiles*;
    VAR res: INTEGER;
      name: ARRAY 32 OF CHAR;
      S: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.RenameFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      name := S.s; Texts.Scan(S);
      IF (S.class = Texts.Char) & (S.codepoint = ORD("=")) THEN Texts.Scan(S);
        IF (S.class = Texts.Char) & (S.codepoint = ORD(">")) THEN Texts.Scan(S);
          IF S.class = Texts.Name THEN
            Texts.WriteString(W, name); Texts.WriteString(W, " => "); Texts.WriteString(W, S.s);
            Texts.WriteString(W, " renaming"); Files.Rename(name, S.s, res);
            IF res > 1 THEN Texts.WriteString(W, " failed") END;
            EndLine
          END
        END
      END ;
      Texts.Scan(S)
    END
  END RenameFiles;

  PROCEDURE DeleteFiles*;
    VAR res: INTEGER; S: Texts.Scanner;
  BEGIN GetArg(S);
    Texts.WriteString(W, "System.DeleteFiles"); EndLine;
    WHILE S.class = Texts.Name DO
      Texts.WriteString(W, S.s); Texts.WriteString(W, " deleting");
      Files.Delete(S.s, res);
      IF res # 0 THEN Texts.WriteString(W, " failed") END;
      EndLine; Texts.Scan(S)
    END
  END DeleteFiles;

  (* ------------- Toolbox for system inspection ---------------*)

  PROCEDURE Watch*;
  BEGIN Texts.WriteString(W, "System.Watch"); Texts.WriteLn(W);
(*  Texts.WriteString(W, "  stackOrg "); Texts.WriteHex(W, Kernel.stackOrg);
    Texts.WriteString(W, "  heapOrg "); Texts.WriteHex(W, Kernel.heapOrg); EndLine; *)
    Texts.WriteString(W, "  Modules space (bytes)"); Texts.WriteInt(W, Modules.AllocPtr, 8);
    Texts.WriteInt(W, Modules.AllocPtr * 100 DIV Kernel.heapOrg, 4); Texts.Write(W, "%"); EndLine;
    Texts.WriteString(W, "  Heap speace"); Texts.WriteInt(W, Kernel.allocated, 8);
    Texts.WriteInt(W, Kernel.allocated * 100 DIV (Kernel.heapLim - Kernel.heapOrg), 4); Texts.Write(W, "%"); EndLine;
    Texts.WriteString(W, "  Disk sectors "); Texts.WriteInt(W, Kernel.NofSectors, 4);
    Texts.WriteInt(W, Kernel.NofSectors * 100 DIV 10000H, 4); Texts.Write(W, "%"); EndLine;
    Texts.WriteString(W, "  Tasks"); Texts.WriteInt(W, Oberon.NofTasks, 4); EndLine
  END Watch;

  PROCEDURE ShowModules*;
    VAR T: Texts.Text;
      V: Viewers.Viewer;
      M: Modules.Module;
      X, Y: INTEGER;
  BEGIN T := TextFrames.Text("");
    Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y);
    V := MenuViewers.New(TextFrames.NewMenu("System.ShowModules", StandardMenu),
        TextFrames.NewText(T, 0), TextFrames.menuH, X, Y);
    M := Modules.root;
    WHILE M # NIL DO
      IF M.name[0] # 0X THEN
        Texts.WriteString(W, M.name); Texts.Write(W, 9X); Texts.WriteHex(W, ORD(M));
        Texts.WriteHex(W, M.code); Texts.WriteInt(W, M.refcnt, 4)
      ELSE Texts.WriteString(W, "---")
      END ;
      Texts.WriteLn(W); M := M.next
    END;
    Texts.Append(T, W.buf)
  END ShowModules;

  PROCEDURE ShowCommands*;
    VAR M: Modules.Module;
      comadr: LONGINT; ch: CHAR;
      T: Texts.Text;
      S: Texts.Scanner;
      V: Viewers.Viewer;
      X, Y, A: INTEGER;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN
      Modules.Load(S.s, M);
      IF M # NIL THEN
        Oberon.AllocateSystemViewer(Oberon.Par.vwr.X, X, Y); T := TextFrames.Text("");
        V := MenuViewers.New(TextFrames.NewMenu("System.Commands", StandardMenu),
            TextFrames.NewText(T, 0), TextFrames.menuH, X, Y);
        comadr := M.cmd; SYSTEM.GET(comadr, ch); INC(comadr);
        WHILE ch # 0X DO
          Texts.WriteString(W, S.s); Texts.Write(W, ".");
          REPEAT Texts.Write(W, ch); SYSTEM.GET(comadr, ch); INC(comadr)
          UNTIL ch = 0X;
          WHILE comadr MOD 4 # 0 DO INC(comadr) END ;
          SYSTEM.GET(comadr, A); IF A MOD 4 # 0 THEN Texts.WriteString(W, " (PROCEDURE)") END;
          Texts.WriteLn(W); INC(comadr, 4); SYSTEM.GET(comadr, ch); INC(comadr)
        END ;
        Texts.Append(T, W.buf)
      END
    END
  END ShowCommands;

  PROCEDURE ShowFonts*;
    VAR fnt: Fonts.Font;
  BEGIN Texts.WriteString(W, "System.ShowFonts"); Texts.WriteLn(W); fnt := Fonts.root;
    WHILE fnt # NIL DO
      Texts.Write(W, 9X); Texts.WriteString(W, fnt.name); Texts.WriteLn(W); fnt := fnt.next
    END ;
    Texts.Append(Oberon.Log, W.buf)
  END ShowFonts;

  PROCEDURE OpenViewers;
    VAR logV, toolV: Viewers.Viewer;
      menu, main: Display.Frame;
      d: LONGINT; X, Y: INTEGER;
  BEGIN d := Kernel.Clock(); Texts.WriteString(W, "Oberon V5  NW 14.4.2013"); EndLine;
    Oberon.AllocateSystemViewer(0, X, Y);
    menu := TextFrames.NewMenu("System.Log", LogMenu);
    main := TextFrames.NewText(Oberon.Log, 0);
    logV := MenuViewers.New(menu, main, TextFrames.menuH, X, Y);
    Oberon.AllocateSystemViewer(0, X, Y);
    menu := TextFrames.NewMenu("System.Tool", StandardMenu);
    main := TextFrames.NewText(TextFrames.Text("System.Tool"), 0);
    toolV := MenuViewers.New(menu, main, TextFrames.menuH, X, Y);
    Oberon.AllocateSystemViewer(0, X, Y);
    menu := TextFrames.NewMenu("Startup.Job", StandardMenu);
    main := TextFrames.NewText(TextFrames.Text("Startup.Job"), 0);
    jobV := MenuViewers.New(menu, main, TextFrames.menuH, X, Y)
  END OpenViewers;

  PROCEDURE ExtendDisplay*;
    VAR V: Viewers.Viewer;
      X, Y, DX, DW, DH: INTEGER;
      S: Texts.Scanner;
  BEGIN GetArg(S);
    IF S.class = Texts.Name THEN
      DX := Viewers.curW; DW := Oberon.DisplayWidth(DX); DH := Oberon.DisplayHeight(DX);
      Oberon.OpenDisplay(DW DIV 8 * 5, DW DIV 8 * 3, DH);
      Oberon.AllocateSystemViewer(DX, X, Y);
      V := MenuViewers.New(
        TextFrames.NewMenu(S.s, StandardMenu),
        TextFrames.NewText(TextFrames.Text(S.s), 0),
        TextFrames.menuH, X, Y)
    END
  END ExtendDisplay;


  PROCEDURE sayWhere(VAR mod: Modules.Module; adr: INTEGER);
    VAR v,w,x,y:INTEGER; ch:CHAR;
  BEGIN
    mod := Modules.root;
    WHILE (mod # NIL) & ((adr < mod.code) OR (adr >= mod.imp)) DO mod := mod.next END ;
    IF mod # NIL THEN 
      Texts.WriteString(W, " in "); Texts.WriteString(W, mod.name);
      v:=mod.cmd; x:=v; y:=x; SYSTEM.GET(v,ch);
      WHILE ch # 0X DO 
        REPEAT INC(v); SYSTEM.GET(v, ch) UNTIL ch = 0X; 
        REPEAT INC(v) UNTIL v MOD 4 = 0;
        SYSTEM.GET(v, w); INC(v, 4); SYSTEM.GET(v,ch);
        IF adr > w + mod.code THEN y:=x; x:=v END
      END;
      Texts.Write(W, ".");
      SYSTEM.GET(y,ch); REPEAT Texts.Write(W, ch); INC(y); SYSTEM.GET(y, ch) UNTIL ch = 0X;
    ELSE
      Texts.WriteString(W, " in unknown procedure")
    END;
  END sayWhere;


  PROCEDURE Trace(a,b,c: INTEGER);
    VAR sp,sz,max,x,e:INTEGER; mod: Modules.Module;
  BEGIN
      sp:=a; sz:=b; max:=c;
      IF sp > Kernel.stackOrg THEN
        Texts.WriteString(W, " (confused stack) "); Texts.Append(Oberon.Log, W.buf);
      ELSE
        Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); 
        e:=1;
        WHILE (sp <= Kernel.stackOrg) & (max > 0) DO
          Texts.WriteString(W, " "); Texts.WriteHex(W, sp); SYSTEM.GET(sp, x); 
          Texts.WriteString(W, " -> "); Texts.WriteHex(W, x); 
          IF e = sz THEN 
            Texts.WriteString(W, " * "); 
            e := 0 
          ELSIF e = 1 THEN
            Texts.WriteInt(W, sz, 4);
	    mod := Modules.root;
            sayWhere(mod,x);
          END;
          Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); INC(sp,4); DEC(max); INC(e);
        END;
      END;
  END Trace;


  PROCEDURE Trap(VAR a: INTEGER; b: INTEGER);
    VAR t, u, v, w, x, y: INTEGER; mod: Modules.Module; ch: CHAR;
  BEGIN u := SYSTEM.REG(15); t:=SYSTEM.REG(14); SYSTEM.GET(u - 4, v); w := v DIV 10H MOD 10H; (*trap number*)
    IF w = 0 THEN Kernel.New(a, b)
(*    ELSIF w = 8 THEN Kernel.Interface(a, b) *)
    ELSE (*trap*) 
      Texts.WriteLn(W); Texts.WriteString(W, "  pos "); Texts.WriteInt(W, v DIV 100H MOD 10000H, 4);
      Texts.WriteString(W, "  TRAP"); Texts.WriteInt(W, w, 4); mod := Modules.root;
      sayWhere(mod,u);
(*
      v:=mod.cmd; x:=v; y:=x; SYSTEM.GET(v,ch);
      WHILE ch # 0X DO 
        REPEAT INC(v); SYSTEM.GET(v, ch) UNTIL ch = 0X; 
        REPEAT INC(v) UNTIL v MOD 4 = 0;
        SYSTEM.GET(v, w); INC(v, 4); SYSTEM.GET(v,ch);
        IF u > w + mod.code THEN y:=x; x:=v END
      END;
      Texts.Write(W, ".");
      SYSTEM.GET(y,ch); REPEAT Texts.Write(W, ch); INC(y); SYSTEM.GET(y, ch) UNTIL ch = 0X;
*)
      Texts.WriteString(W, " at"); Texts.WriteHex(W, u); Texts.WriteLn(W); 
      Texts.WriteString(W, "  sp"); Texts.WriteHex(W, t); Texts.WriteString(W, " tos"); Texts.WriteHex(W, Kernel.stackOrg);
      Trace(t,11,200);
      Oberon.Reset
    END
  END Trap;

  PROCEDURE Abort;
    VAR n: INTEGER;
  BEGIN n := SYSTEM.REG(15); Texts.WriteString(W, "  ABORT  "); Texts.WriteHex(W, n);
    Texts.WriteLn(W); Texts.Append(Oberon.Log, W.buf); Oberon.Reset
  END Abort;
  
BEGIN (* OUCH(83);  OUCH(89);  OUCH(83);  OUCH(84);  OUCH(69);  OUCH(77);  OUCH(10);   *)
  Texts.OpenWriter(W);
  Oberon.OpenLog(TextFrames.Text("")); OpenViewers;
  Kernel.Install(SYSTEM.ADR(Trap), 20H); Kernel.Install(SYSTEM.ADR(Abort), 0);
  jobCM.offset := 0;
  jobV.dsc.next.handle(jobV.dsc.next,jobCM);
  Viewers.Close(jobV)  
END System.
