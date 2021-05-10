DECLARE SUB printsample ()
DECLARE SUB putchar (char AS INTEGER, startx AS INTEGER, starty AS INTEGER)
DECLARE SUB readfont ()
DECLARE SUB readligatures ()
' variable-width text renderer

DEFINT A-Z

' file to read sample text from (must have DOS newlines)
CONST SAMPLEFILE = "sample.txt"

CONST CHARHEIGHT = 9

DIM SHARED font(256 * CHARHEIGHT - 1)  ' pixel rows (little endian bit order)
DIM SHARED charwidths(255)
DIM SHARED ligatures$(199)  ' 2 characters each
DIM SHARED ligaturecount
DIM SHARED pow2(7)

FOR i = 0 TO 7: pow2(i) = 2 ^ i: NEXT
CALL readfont
CALL readligatures

SCREEN 1
CALL printsample
SLEEP

SUB printsample
' print sample text from SAMPLEFILE

OPEN SAMPLEFILE FOR INPUT AS #1

y = 0

WHILE NOT EOF(1)
    LINE INPUT #1, line$
    prevchr = -1
    x = 0

    FOR i = 1 TO LEN(line$)
        char = ASC(MID$(line$, i, 1))

        ' if non-first character and not a ligature, add one pixel of letter
        ' spacing
        IF prevchr <> -1 THEN
            twochars$ = CHR$(prevchr) + CHR$(char)
            isligature = 0
            FOR j = 0 TO ligaturecount - 1
                IF ligatures$(j) = twochars$ THEN isligature = 1: EXIT FOR
            NEXT
            IF isligature = 0 THEN x = x + 1
        END IF

        CALL putchar(char, x, y)
        x = x + charwidths(char)
        prevchr = char
    NEXT

    y = y + CHARHEIGHT + 1
WEND

CLOSE

END SUB

SUB putchar (char AS INTEGER, startx AS INTEGER, starty AS INTEGER)
' draw a character on screen

charwidth = charwidths(char)
datastart = char * CHARHEIGHT

FOR y = 0 TO CHARHEIGHT - 1
    pixelrow = font(datastart + y)
    FOR x = 0 TO charwidth - 1
        IF pixelrow AND pow2(x) THEN PSET (startx + x, starty + y), 3
    NEXT
NEXT

END SUB

SUB readfont
' read font from "font.txt" to font() and charwidths()
' lines for each character:
' - a colon followed by the character and its width (e.g. ":a5")
' - CHARHEIGHT lines that describe the character (up to width asterisks or
'   spaces each)
' the file must have DOS newlines

OPEN "font.txt" FOR INPUT AS #1

WHILE NOT EOF(1)
    LINE INPUT #1, line$
   
    IF LEFT$(line$, 1) = ":" THEN
        char = ASC(MID$(line$, 2, 1))
        charwidth = VAL(MID$(line$, 3, 1))
        charwidths(char) = charwidth
        y = 0
    ELSE
        line$ = LEFT$(line$ + SPACE$(charwidth), charwidth)
        byte = 0
        FOR x = 0 TO charwidth - 1
            IF MID$(line$, x + 1, 1) = "*" THEN byte = byte OR pow2(x)
        NEXT
        font(char * CHARHEIGHT + y) = byte
        y = y + 1
    END IF
WEND

CLOSE

END SUB

SUB readligatures
' read ligatures from "ligature.txt" to ligatures()
' each line consists of two characters (e.g. "fj")
' the file must have DOS newlines

OPEN "ligature.txt" FOR INPUT AS #1

WHILE NOT EOF(1)
    LINE INPUT #1, line$
    IF LEN(line$) >= 2 THEN
        ligatures$(ligaturecount) = LEFT$(line$, 2)
        ligaturecount = ligaturecount + 1
    END IF
WEND

CLOSE

END SUB

