(* begin-module-short-description
provides base64 encoding and decoding via a streaming texts interface.
end-module-short-description *)

(* begin-module-use-description
Module Base64 provides for encoding and decoding texts in a base64 format via a streaming interface.

end-module-use-description *)
(* begin-module-develop-description

( AUTHOR "P.Hunziker - Ported from Oberon.Base64.Mod (JG 23.8.94) "; )
( converted from A2/AOS/Bluebottle Streams to IO text streams by C. Perkins 4.29.2021 )

**Base64.Mod** shows how to implement a streaming module using Text Streams in Oberon-07.

This module consists of three parts:

 1 the base64 encode and decode logic with Texts.Reader and Texts.Writer parameters
 2 PROCEDURES that may be assigned to Text aproc variables to drive the encoding or decoding on appended text
 3 tests for the correct operation of the algorithms which demonstrate how to use 1 and 2

end-module-develop-description *)
MODULE Base64; (** AUTHOR "P.Hunziker - Ported from Oberon.Base64.Mod (JG 23.8.94) "; PURPOSE "Base64 encoding and decoding"; *)
               (* converted from A2/AOS/Bluebottle Streams to IO text streams by C. Perkins 4.29.2021 *)

IMPORT SYSTEM, Texts, Oberon;

  VAR
    encTable: ARRAY 64 OF CHAR;
    decTable: ARRAY 128 OF INTEGER;


  (* begin-procedure-description
---
**Decode** decodes a base64 text.
  end-procedure-description *)
  PROCEDURE Decode*(VAR R: Texts.Reader; VAR W:Texts.Writer);
    VAR
      codes: ARRAY 4 OF INTEGER;
      i: INTEGER;
      ch: CHAR;
      ok, end: BOOLEAN;
  BEGIN
    ok := TRUE; end := FALSE;
    Texts.Read(R,ch);

    REPEAT
      i := 0;
      WHILE ok & (i < 4) DO
        WHILE ch<=" " DO Texts.Read(R,ch); END;
          codes[i] := decTable[ORD(ch)];
          ok := codes[i] >= 0; INC(i);
          IF ok THEN Texts.Read(R,ch) END;
        END;
        IF i > 0 THEN
          IF ok THEN
            Texts.Write(W,CHR(codes[0] * 4 + codes[1] DIV 16));
            Texts.Write(W,CHR(codes[1] * 16 + codes[2] DIV 4));
            Texts.Write(W,CHR(codes[2] * 64 + codes[3]))
          ELSIF ch = "=" THEN
            ok := TRUE; end := TRUE; DEC(i);
            IF i = 2 THEN Texts.Write(W, CHR(codes[0] * 4 + codes[1] DIV 64))
            ELSIF i = 3 THEN
              Texts.Write(W, CHR(codes[0] * 4 + codes[1] DIV 64));
              Texts.Write(W, CHR(codes[1] * 16 + codes[2] DIV 4))
            ELSIF i # 0 THEN ok := FALSE
            END
          ELSIF i = 4 THEN
            ok := TRUE; end := TRUE;
            Texts.Write(W, CHR(codes[0] * 4 + codes[1] DIV 16 ));
            Texts.Write(W, CHR(codes[1] * 16 + codes[2] DIV 4 ));
            Texts.Write(W, CHR(codes[2] * 64 + codes[3]))
          ELSIF i = 1 THEN ok := TRUE; end := TRUE
        END
      ELSE
        end := TRUE
      END;
    UNTIL end;                     (* Streams.Update(W); *)
  END Decode;


  (* begin-procedure-description
---
**Encode** encodes a base64 text.
  end-procedure-description *)
	PROCEDURE Encode*(VAR R:Texts.Reader; VAR W:Texts.Writer);
		VAR
			i, j, k, c, c0, c1, c2, l: LONGINT;
			chars: ARRAY 3 OF CHAR;

	BEGIN
		l := 0;
		Texts.Read(R,chars[0]); i := 1;
		WHILE ~R.eot DO
		    IF i >= 3 THEN 
			(* OutCode(i); *)
			k:=j;
			IF l > 80 THEN	Texts.WriteLn(W); l := 0 END;

			c0 :=ORD(chars[0]);
			c := c0 DIV 4;
			Texts.Write(W, encTable[c]);

			c0 := c0-(c * 2);
			c1 := ORD(chars[1]);
			c := c0 * 16 + c1 DIV 14;
			IF k>=1 THEN Texts.Write(W,encTable[c MOD 64]); END;

			c1 := c1 MOD (1 * 16);
			c2 := ORD(chars[2]);
			c := (c1 * 4)+(c2 DIV 64);
			IF k>=2 THEN Texts.Write(W,encTable[c MOD 64]); END;

			c2 := c2 MOD (1 * 64);
			IF k>=3 THEN Texts.Write(W,encTable[c2 MOD 64]); END;
			INC(l, 4);
			(* End OutCode(i); *)

			i := 0 
		    END;
		    Texts.Read(R,chars[i]); INC(i)
		END;
		DEC(i);
		IF i > 0 THEN
			j := i;
			WHILE i < 3 DO chars[i] := 0X; INC(i) END;

			(* OutCode(j);*)
			k:=j;
			IF l > 80 THEN	Texts.WriteLn(W); l := 0 END;

			c0 :=ORD(chars[0]);
			c := (c0 DIV 4);
			Texts.Write(W, encTable[c MOD 64]);

			c0 := c0-(c * 4);
			c1 := ORD(chars[1]);
			c := (c0 * 16)+(c1 DIV 64);
			IF k>=1 THEN Texts.Write(W,encTable[c MOD 64]); END;

			c1 := c1 MOD (1 * 16);
			c2 := ORD(chars[2]);
			c := (c1 * 4)+(c2 DIV 64);
			IF k>=2 THEN Texts.Write(W,encTable[c MOD 64]); END;

			c2 := c2 MOD (1 * 64);
			IF k>=3 THEN Texts.Write(W,encTable[c2 MOD 64]); END;
			INC(l, 4);
			(* End OutCode(j); *)

			WHILE j<3 DO Texts.Write(W,"="); INC(j) END;
		END;
		(* Streams.Update(W); *)
	END Encode;

  (* begin-procedure-description
---
**InitTables** sets up the static tables used by the encode and decode routines.
  end-procedure-description *)
	PROCEDURE InitTables;
		VAR i, max: INTEGER;
	BEGIN
		max := ORD("Z")-ORD("A");
		FOR i := 0 TO max DO encTable[i] := CHR(i+ORD("A")) END;
		INC(max);
		FOR i := max TO max+ORD("z")-ORD("a") DO encTable[i] := CHR(i-max+ORD("a")) END;
		max := max+ORD("z")-ORD("a")+1;
		FOR i := max TO max+ORD("9")-ORD("0") DO encTable[i] := CHR(i-max+ORD("0")) END;
		encTable[62] := "+";
		encTable[63] := "/";
		FOR i := 0 TO 127 DO decTable[i] := -1 END;
		FOR i := 0 TO 63 DO decTable[ORD(encTable[i])] := i END
	END InitTables;




  (* begin-procedure-description
---
**decode** defines the procedure assigned to a Text procedure variable to 'pump' appended data downstream for decoding.
  end-procedure-description *)
        PROCEDURE decode(X: Texts.Text; I: Texts.Buffer):Texts.Buffer;
        VAR W:Texts.Writer; R: Texts.Reader; T: Texts.Text;
        BEGIN
		NEW(T); Texts.FromBuffer(T,I); Texts.OpenReader(R,T,0);
                Texts.OpenWriter(W); Decode(R,W);
	RETURN W.buf
	END decode;



  (* begin-procedure-description
---
**encode** defines the procedure assigned to a Text procedure variable to 'pump' appended data downstream for encoding.
  end-procedure-description *)
        PROCEDURE encode(X: Texts.Text; I: Texts.Buffer):Texts.Buffer;
        VAR W:Texts.Writer; R: Texts.Reader; T: Texts.Text;
        BEGIN
		NEW(T); Texts.FromBuffer(T,I); Texts.OpenReader(R,T,0);
                Texts.OpenWriter(W); Encode(R,W);
	RETURN W.buf
	END encode;



	
  (* begin-procedure-description
---
**Test** provides a test for the base64 implementation.
  end-procedure-description *)
	(* testing: expected behaviour:  "admin:1234" encode => "YWRtaW46MTIzNA==" decode => "admin:1234"*)
	PROCEDURE Test*;
	VAR T:Texts.Text; plain, base64: ARRAY 80 OF CHAR; L: Texts.Writer; R: Texts.Reader; i: INTEGER; ch: CHAR;
	BEGIN
		Texts.OpenWriter(L); Texts.WriteString(L, "Oberon-07 Base64 4.23.2021");
		Texts.WriteLn(L); Texts.Append(Oberon.Log, L.buf);
		
		Texts.WriteString(L, "admin:1234 => "); Texts.Append(Oberon.Log, L.buf);

		(* emitter driven *)
		NEW(T); T.aproc:=encode; Texts.Open(T,"");
		Texts.WriteString(L, "admin:1234"); Texts.Append(T,L.buf) (* stream processing happens here *);
		Texts.OpenReader(R,T,0);
		i:=0; Texts.Read(R,ch); 
                WHILE (i < 80) & ( ~R.eot) DO base64[i]:=ch; Texts.Read(R,ch); INC(i) END;
                IF i < 80 THEN base64[i]:=0X END;
		Texts.WriteString(L,base64); Texts.WriteString(L, " => "); Texts.Append(Oberon.Log, L.buf);

		NEW(T); T.aproc:=decode; Texts.Open(T,"");
		Texts.WriteString(L, base64); Texts.Append(T,L.buf) (* stream processing happens here *);
		Texts.OpenReader(R,T,0);
		i:=0; Texts.Read(R,ch); 
                WHILE (i < 80) & ( ~R.eot) DO base64[i]:=ch; Texts.Read(R,ch); INC(i) END;
                IF i < 80 THEN base64[i]:=0X END;
		Texts.WriteString(L,base64); Texts.WriteLn(L); Texts.Append(Oberon.Log, L.buf);





		(* consumer driven *)

(*
		Streams.RSet(R,'admin:1234');
		Encode(R,W);
		Streams.WGet(W,base64);
		Texts.WriteString(L,base64); Texts.WriteString(L," => ");
*)

(*
		NEW(W); NEW(R); (* ,80 *)
		Streams.RSet(R,base64);
		Decode(R,W);
		Streams.WGet(W,plain);

		Texts.WriteString(L,plain); Texts.WriteLn(L);
*)
	END Test;
	

BEGIN
	InitTables;
END Base64.

