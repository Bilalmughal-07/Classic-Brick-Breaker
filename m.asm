.MODEL SMALL
.386
.STACK 256

.DATA

    playerName  DB  16 DUP(0)
    nameLen     DB  0

    menuSel     DB  0

    rectX       DW  0
    rectY       DW  0
    rectW       DW  0
    rectH       DW  0
    rectColor   DB  0

    fontSeg     DW  0
    fontOff     DW  0
    charColor   DB  0

    ; ---- String Constants ----
    sTitle      DB 'BRICK BREAKER',0
    sSub        DB 'ARCADE CLASSIC',0
    sPress      DB 'PRESS ANY KEY TO CONTINUE',0
    sNameHdr    DB 'NAME INPUT',0
    sEnter      DB 'ENTER YOUR NAME:',0
    sMax15      DB 'MAX 15 CHARS',0
    sConfirm    DB 'PRESS ENTER TO CONFIRM',0
    sStart      DB 'START GAME',0
    sInstr      DB 'INSTRUCTIONS',0
    sHighSc     DB 'HIGH SCORES',0
    sExit       DB 'EXIT',0
    sCtrl       DB 'CONTROLS',0
    sMove       DB '<-> OR A/D = MOVE PADDLE',0
    sObj        DB 'OBJECTIVE',0
    sBreak      DB 'BREAK ALL BRICKS TO ADVANCE',0
    sLivesH     DB 'LIVES',0
    sLivesD     DB '3 LIVES, MISS BALL = LOSE 1',0
    sBonusH     DB 'BONUSES',0
    sSlow       DB 'SLOW BALL',0
    sExtra      DB 'EXTRA LIFE',0
    sWide       DB 'WIDE PADDLE',0
    sReturn     DB 'PRESS ANY KEY TO RETURN',0
    sRank       DB 'RANK',0
    sName       DB 'NAME',0
    sScoreH     DB 'SCORE',0
    sScore      DB 'Score:',0
    sLives      DB 'Lives:',0
    s0          DB '0',0
    s3          DB '3',0
    sPl         DB 'PL:',0
    hsN1        DB 'ALI',0
    hsN2        DB 'SARA',0
    hsN3        DB 'USMAN',0
    hsN4        DB 'AYESHA',0
    hsN5        DB 'BILAL',0
    hsS1        DB '05000',0
    hsS2        DB '04200',0
    hsS3        DB '03800',0
    hsS4        DB '02500',0
    hsS5        DB '01100',0

.CODE

INIT_GRAPHICS PROC
    MOV AX, 0013h
    INT 10h

    MOV AX, @DATA
    MOV DS, AX

    PUSH ES
    MOV AX, 0
    MOV ES, AX
    MOV BX, 010Ch
    MOV AX, ES:[BX]
    MOV fontOff, AX
    MOV AX, ES:[BX+2]
    MOV fontSeg, AX
    POP ES

    RET
INIT_GRAPHICS ENDP

CLEAR_SCREEN PROC
    PUSH ES
    PUSH DI
    PUSH CX
    PUSH BX

    MOV BL, AL            ; save color before AX is overwritten
    MOV AX, 0A000h
    MOV ES, AX
    XOR DI, DI
    MOV CX, 64000
    MOV AL, BL             ; restore color
    REP STOSB

    POP BX
    POP CX
    POP DI
    POP ES
    RET
CLEAR_SCREEN ENDP

DRAW_RECT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES

    MOV AX, 0A000h
    MOV ES, AX

    MOV DX, rectY          ; DX = current row
    MOV BX, rectY
    ADD BX, rectH           ; BX = end row

DR_ROW:
    CMP DX, BX
    JGE DR_DONE

    MOV AX, DX             ; compute offset = row * 320 + X
    PUSH DX
    MOV CX, 320
    MUL CX
    POP DX
    MOV DI, AX
    ADD DI, rectX

    MOV CX, rectW
    MOV AL, rectColor
    REP STOSB

    INC DX                 ; next row (simple increment)
    JMP DR_ROW

DR_DONE:
    POP ES
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_RECT ENDP

DRAW_RECT_BORDER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AX, rectX
    MOV BX, rectY
    MOV CX, rectW
    MOV DX, rectH

    MOV rectH, 1
    CALL DRAW_RECT

    PUSH BX
    ADD BX, DX
    DEC BX
    MOV rectY, BX
    MOV rectH, 1
    CALL DRAW_RECT
    POP BX
    MOV rectY, BX

    MOV rectW, 1
    MOV rectH, DX
    CALL DRAW_RECT

    PUSH AX
    ADD AX, CX
    DEC AX
    MOV rectX, AX
    MOV rectW, 1
    CALL DRAW_RECT
    POP AX
    MOV rectX, AX
    MOV rectW, CX
    MOV rectH, DX

    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_RECT_BORDER ENDP

; AL=char, BX=X, CX=Y, DL=color
DRAW_CHAR PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH DS
    PUSH ES

    MOV charColor, DL      ; save color BEFORE any MUL clobbers DX

    MOV AH, 0
    SHL AX, 3              ; AX = char * 8
    ADD AX, fontOff
    MOV SI, AX
    MOV AX, fontSeg
    MOV DS, AX             ; DS:SI -> font bitmap

    MOV AX, 0A000h
    MOV ES, AX

    MOV AH, 0              ; AH = font row counter (0..7)

DC_ROW_LOOP:
    CMP AH, 8
    JGE DC_DONE

    MOV AL, [SI]           ; AL = bitmap byte for this row

    ; screen offset = (CX + row) * 320 + BX
    PUSH AX
    PUSH DX
    MOVZX AX, AH
    ADD AX, CX
    MOV DX, 320
    MUL DX
    MOV DI, AX
    ADD DI, BX
    POP DX
    POP AX

    MOV DH, 7              ; bit position (7=MSB down to 0)

DC_BIT_LOOP:
    CMP DH, 255
    JE  DC_ROW_NEXT

    PUSH AX
    PUSH CX
    MOV CL, DH
    SHR AL, CL
    AND AL, 1
    CMP AL, 1
    JNE DC_BIT_SKIP

    ; pixel column = 7 - bitpos
    MOV CX, 7
    MOVZX AX, DH
    SUB CX, AX             ; CX = column within char (0..7)
    PUSH DI
    ADD DI, CX             ; DI already has BX baked in
    MOV AL, DL              ; DL preserved by PUSH/POP DX around MUL
    MOV ES:[DI], AL
    POP DI

DC_BIT_SKIP:
    POP CX
    POP AX
    DEC DH
    JMP DC_BIT_LOOP

DC_ROW_NEXT:
    INC AH
    INC SI
    JMP DC_ROW_LOOP

DC_DONE:
    POP ES
    POP DS
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_CHAR ENDP

; SI=string ptr, BX=X, CX=Y, DL=color
DRAW_STRING PROC
    PUSH AX
    PUSH BX
    PUSH SI
DST_LP:
    MOV AL, DS:[SI]
    CMP AL, 0
    JE  DST_DN
    CMP AL, ' '
    JE  DST_SP
    CALL DRAW_CHAR
    ADD BX, 9
    JMP DST_NX
DST_SP:
    ADD BX, 6
DST_NX:
    INC SI
    JMP DST_LP
DST_DN:
    POP SI
    POP BX
    POP AX
    RET
DRAW_STRING ENDP

; CX = iterations (bigger = longer wait)
DELAY_TICKS PROC
    PUSH CX
    PUSH DX
DT_O:
    CMP CX, 0
    JE  DT_D
    MOV DX, 0FFFFh
DT_I:
    DEC DX
    JNZ DT_I
    DEC CX
    JMP DT_O
DT_D:
    POP DX
    POP CX
    RET
DELAY_TICKS ENDP

WAIT_KEY PROC
    PUSH AX
    MOV AH, 00h
    INT 16h
    POP AX
    RET
WAIT_KEY ENDP


SHOW_HOME_SCREEN PROC
    MOV AL, 1
    CALL CLEAR_SCREEN

    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 15
    MOV rectColor, 9
    CALL DRAW_RECT

    MOV rectY, 185
    CALL DRAW_RECT

    MOV CX, 0
HS_BRICK1:
    CMP CX, 16
    JGE HS_BRICK1_DONE

    MOV AX, CX
    IMUL AX, 20
    ADD AX, 4
    MOV rectX, AX
    MOV rectY, 45
    MOV rectW, 18
    MOV rectH, 9

    MOV AX, CX
    AND AX, 3
    CMP AX, 0
    JE H_C0
    CMP AX, 1
    JE H_C1
    CMP AX, 2
    JE H_C2
    MOV rectColor, 3
    JMP H_DRAW1
    H_C0: MOV rectColor, 4
    JMP H_DRAW1
    H_C1: MOV rectColor, 14
    JMP H_DRAW1
H_C2: MOV rectColor, 2
H_DRAW1:
    CALL DRAW_RECT
    INC CX
    JMP HS_BRICK1
HS_BRICK1_DONE:

    MOV CX, 0
HS_BRICK2:
    CMP CX, 16
    JGE HS_BRICK2_DONE

    MOV AX, CX
    IMUL AX, 20
    ADD AX, 14
    MOV rectX, AX
    MOV rectY, 57
    MOV rectW, 18
    MOV rectH, 9

    MOV AX, CX
    AND AX, 1
    CMP AX, 0
    JE H_D0
    MOV rectColor, 5
    JMP H_DRAW2
H_D0: MOV rectColor, 3
H_DRAW2:
    CALL DRAW_RECT
    INC CX
    JMP HS_BRICK2
HS_BRICK2_DONE:

    MOV rectX, 25
    MOV rectY, 72
    MOV rectW, 270
    MOV rectH, 52
    MOV rectColor, 15
    CALL DRAW_RECT_BORDER

    MOV rectX, 26
    MOV rectY, 73
    MOV rectW, 268
    MOV rectH, 50
    MOV rectColor, 0
    CALL DRAW_RECT

    MOV CX, 86
    MOV DL, 14

    MOV BX, 101
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'K'
    CALL DRAW_CHAR
    ADD BX, 14
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'K'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR

    MOV CX, 103
    MOV DL, 7
    MOV BX, 75
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 14
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR

    ; --- Flashing "PRESS ANY KEY TO CONTINUE" ---
HS_FLASH:
    MOV SI, OFFSET sPress
    MOV BX, 43
    MOV CX, 158
    MOV DL, 15
    CALL DRAW_STRING

    MOV CX, 6
    CALL DELAY_TICKS

    MOV AH, 01h
    INT 16h
    JNZ HS_GOT_KEY

    ; Erase text area
    MOV rectX, 40
    MOV rectY, 156
    MOV rectW, 240
    MOV rectH, 12
    MOV rectColor, 0
    CALL DRAW_RECT

    MOV CX, 4
    CALL DELAY_TICKS

    MOV AH, 01h
    INT 16h
    JNZ HS_GOT_KEY
    JMP HS_FLASH

HS_GOT_KEY:
    MOV AH, 00h
    INT 16h
    RET
SHOW_HOME_SCREEN ENDP

SHOW_NAME_INPUT PROC
    MOV AL, 8
    CALL CLEAR_SCREEN

    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV CX, 7
    MOV DL, 14
    MOV BX, 115
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'M'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR

    MOV CX, 68
    MOV DL, 15
    MOV BX, 83
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'Y'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'M'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR

    MOV rectX, 58
    MOV rectY, 83
    MOV rectW, 204
    MOV rectH, 22
    MOV rectColor, 15
    CALL DRAW_RECT_BORDER

    MOV rectX, 59
    MOV rectY, 84
    MOV rectW, 202
    MOV rectH, 20
    MOV rectColor, 0
    CALL DRAW_RECT

    MOV CX, 115
    MOV DL, 7
    MOV BX, 85
    MOV AL, 'M'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'X'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, '1'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '5'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'H'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR

    MOV CX, 128
    MOV DL, 7
    MOV BX, 85
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'F'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'M'
    CALL DRAW_CHAR

    MOV nameLen, 0
    MOV CX, 16
    MOV SI, 0
NI_CLEAR:
    MOV playerName[SI], 0
    INC SI
    LOOP NI_CLEAR

NI_LOOP:
    MOV AH, 00h
    INT 16h

    CMP AL, 0Dh
    JE  NI_CONFIRM

    CMP AL, 08h
    JE  NI_BACKSPACE

    CMP AL, 32
    JL  NI_LOOP
    CMP AL, 126
    JG  NI_LOOP

    MOV BL, nameLen
    CMP BL, 15
    JGE NI_LOOP

    MOVZX SI, nameLen
    MOV playerName[SI], AL
    INC nameLen

    MOVZX BX, nameLen
    DEC BX
    IMUL BX, 9
    ADD BX, 63

    MOV CX, 88
    MOV DL, 11

    MOVZX SI, nameLen
    DEC SI
    MOV AL, playerName[SI]

    CALL DRAW_CHAR
    JMP NI_LOOP

NI_BACKSPACE:
    MOV BL, nameLen
    CMP BL, 0
    JE  NI_LOOP

    DEC nameLen
    MOVZX SI, nameLen
    MOV playerName[SI], 0

    MOVZX BX, nameLen
    IMUL BX, 9
    ADD BX, 63
    MOV rectX, BX
    MOV rectY, 85
    MOV rectW, 9
    MOV rectH, 18
    MOV rectColor, 0
    CALL DRAW_RECT
    JMP NI_LOOP

NI_CONFIRM:
    MOVZX SI, nameLen
    MOV playerName[SI], 0
    RET
SHOW_NAME_INPUT ENDP

SHOW_MAIN_MENU PROC
    MOV menuSel, 0

MM_REDRAW:
    MOV AL, 0
    CALL CLEAR_SCREEN

    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 28
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV CX, 10
    MOV DL, 14
    MOV BX, 87
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'K'
    CALL DRAW_CHAR
    ADD BX, 14
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'K'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR

    CALL DRAW_MENU_ITEMS

    MOV CX, 190
    MOV DL, 7
    MOV BX, 2
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR
    ADD BX, 4

    MOV SI, 0
    MOV DL, 11
MM_NAME_DRAW:
    MOV AL, playerName[SI]
    CMP AL, 0
    JE  MM_NAME_DONE
    CALL DRAW_CHAR
    ADD BX, 9
    INC SI
    CMP SI, 10
    JL  MM_NAME_DRAW
MM_NAME_DONE:

MM_KEY_LOOP:
    MOV AH, 00h
    INT 16h

    CMP AH, 48h
    JE  MM_UP
    CMP AH, 50h
    JE  MM_DOWN
    CMP AL, 0Dh
    JE  MM_ENTER
    JMP MM_KEY_LOOP

MM_UP:
    CMP menuSel, 0
    JE  MM_KEY_LOOP
    DEC menuSel
    JMP MM_REDRAW

MM_DOWN:
    CMP menuSel, 3
    JE  MM_KEY_LOOP
    INC menuSel
    JMP MM_REDRAW

MM_ENTER:
    MOV AL, menuSel
    RET
SHOW_MAIN_MENU ENDP

DRAW_MENU_ITEMS PROC
    PUSH BX
    PUSH CX

    MOV BL, 0

DMI_LOOP:
    CMP BL, 4
    JL  DMI_LOOP_BODY
    JMP DMI_DONE
DMI_LOOP_BODY:

    MOVZX AX, BL
    IMUL AX, 35
    ADD AX, 40
    MOV rectY, AX
    MOV rectX, 60
    MOV rectW, 200
    MOV rectH, 26

    CMP BL, menuSel
    JE  DMI_SELECTED

    MOV rectColor, 8
    CALL DRAW_RECT
    MOV rectColor, 7
    CALL DRAW_RECT_BORDER
    JMP DMI_TEXT

DMI_SELECTED:
    MOV rectColor, 6
    CALL DRAW_RECT
    MOV rectColor, 14
    CALL DRAW_RECT_BORDER

    PUSH BX                 ; save BL (loop counter) before BX changes
    MOVZX AX, BL
    IMUL AX, 35
    ADD AX, 40
    MOV CX, AX
    ADD CX, 9
    MOV BX, 64
    MOV AL, '>'
    MOV DL, 14
    CALL DRAW_CHAR
    POP BX                  ; restore BL loop counter

DMI_TEXT:
    MOVZX AX, BL
    IMUL AX, 35
    ADD AX, 49
    MOV CX, AX

    MOV DL, 15

    CMP BL, 0
    JE  DMI_ITEM0
    CMP BL, 1
    JE  DMI_ITEM1
    CMP BL, 2
    JNE DMI_SKIP2
    JMP DMI_ITEM2
DMI_SKIP2:
    JMP DMI_ITEM3

DMI_ITEM0:
    MOV BX, 115
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'G'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'M'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    JMP DMI_NEXT

DMI_ITEM1:
    MOV BX, 106
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    JMP DMI_NEXT

DMI_ITEM2:
    MOV BX, 110
    MOV AL, 'H'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'G'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'H'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    JMP DMI_NEXT

DMI_ITEM3:
    MOV BX, 142
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'X'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR

DMI_NEXT:
    INC BL
    JMP DMI_LOOP

DMI_DONE:
    POP CX
    POP BX
    RET
DRAW_MENU_ITEMS ENDP

SHOW_INSTRUCTIONS PROC
    MOV AL, 0
    CALL CLEAR_SCREEN

    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 20
    MOV rectColor, 2
    CALL DRAW_RECT

    MOV BX, 94
    MOV CX, 6
    MOV DL, 15
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR

    MOV BX, 15
    MOV CX, 28
    MOV DL, 14
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR

    MOV BX, 25
    MOV CX, 40
    MOV DL, 7
    MOV AL, '<'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '-'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '>'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'W'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '/'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, '='
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'M'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'V'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR

    MOV BX, 15
    MOV CX, 58
    MOV DL, 14
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'J'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'V'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR

    MOV BX, 25
    MOV CX, 70
    MOV DL, 7
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'K'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'K'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'V'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR

    MOV BX, 15
    MOV CX, 88
    MOV DL, 14
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'V'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR

    MOV BX, 25
    MOV CX, 100
    MOV DL, 7
    MOV AL, '3'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'V'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, ','
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'M'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, '='
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, '1'
    CALL DRAW_CHAR

    MOV BX, 15
    MOV CX, 118
    MOV DL, 14
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR

    MOV rectX, 25
    MOV rectY, 130
    MOV rectW, 14
    MOV rectH, 9
    MOV rectColor, 3
    CALL DRAW_RECT
    MOV BX, 45
    MOV CX, 130
    MOV DL, 7
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'W'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR

    MOV rectX, 25
    MOV rectY, 143
    MOV rectW, 14
    MOV rectH, 9
    MOV rectColor, 2
    CALL DRAW_RECT
    MOV BX, 45
    MOV CX, 143
    MOV DL, 7
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'X'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'F'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR

    MOV rectX, 25
    MOV rectY, 156
    MOV rectW, 14
    MOV rectH, 9
    MOV rectColor, 14
    CALL DRAW_RECT
    MOV BX, 45
    MOV CX, 156
    MOV DL, 7
    MOV AL, 'W'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR

    MOV SI, OFFSET sReturn
    MOV BX, 68
    MOV CX, 188
    MOV DL, 7
    CALL DRAW_STRING

    CALL WAIT_KEY
    RET
SHOW_INSTRUCTIONS ENDP

SHOW_HIGH_SCORES PROC
    MOV AL, 0
    CALL CLEAR_SCREEN

    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 9
    CALL DRAW_RECT

    MOV BX, 106
    MOV CX, 7
    MOV DL, 0
    MOV AL, 'H'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'G'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'H'
    CALL DRAW_CHAR
    ADD BX, 6
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR

    MOV rectX, 10
    MOV rectY, 28
    MOV rectW, 300
    MOV rectH, 1
    MOV rectColor, 7
    CALL DRAW_RECT

    MOV BX, 20
    MOV CX, 30
    MOV DL, 14
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'K'
    CALL DRAW_CHAR

    MOV BX, 90
    MOV CX, 30
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'M'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR

    MOV BX, 220
    MOV CX, 30
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR

    MOV rectX, 10
    MOV rectY, 40
    MOV rectW, 300
    MOV rectH, 1
    MOV rectColor, 14
    CALL DRAW_RECT

    MOV rectX, 70
    MOV rectY, 28
    MOV rectW, 1
    MOV rectH, 135
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV rectX, 200
    CALL DRAW_RECT

    MOV rectX, 10
    MOV rectY, 46
    MOV rectW, 300
    MOV rectH, 20
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV BX, 25
    MOV CX, 51
    MOV DL, 14
    MOV AL, '1'
    CALL DRAW_CHAR
    MOV BX, 80
    MOV DL, 11
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    MOV BX, 215
    MOV DL, 10
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '5'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR

    MOV rectX, 10
    MOV rectY, 69
    MOV rectW, 300
    MOV rectH, 20
    MOV rectColor, 0
    CALL DRAW_RECT
    MOV BX, 25
    MOV CX, 74
    MOV DL, 14
    MOV AL, '2'
    CALL DRAW_CHAR
    MOV BX, 80
    MOV DL, 11
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    MOV BX, 215
    MOV DL, 10
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '4'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '2'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR

    MOV rectX, 10
    MOV rectY, 92
    MOV rectW, 300
    MOV rectH, 20
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV BX, 25
    MOV CX, 97
    MOV DL, 14
    MOV AL, '3'
    CALL DRAW_CHAR
    MOV BX, 80
    MOV DL, 11
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'M'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    MOV BX, 215
    MOV DL, 10
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '3'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '8'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR

    MOV rectX, 10
    MOV rectY, 115
    MOV rectW, 300
    MOV rectH, 20
    MOV rectColor, 0
    CALL DRAW_RECT
    MOV BX, 25
    MOV CX, 120
    MOV DL, 14
    MOV AL, '4'
    CALL DRAW_CHAR
    MOV BX, 80
    MOV DL, 11
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'Y'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'H'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    MOV BX, 215
    MOV DL, 10
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '2'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '5'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR

    MOV rectX, 10
    MOV rectY, 138
    MOV rectW, 300
    MOV rectH, 20
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV BX, 25
    MOV CX, 143
    MOV DL, 14
    MOV AL, '5'
    CALL DRAW_CHAR
    MOV BX, 80
    MOV DL, 11
    MOV AL, 'B'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    MOV BX, 215
    MOV DL, 10
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '1'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '1'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '0'
    CALL DRAW_CHAR

    MOV rectX, 10
    MOV rectY, 161
    MOV rectW, 300
    MOV rectH, 1
    MOV rectColor, 7
    CALL DRAW_RECT

    MOV SI, OFFSET sReturn
    MOV BX, 68
    MOV CX, 185
    MOV DL, 7
    CALL DRAW_STRING

    CALL WAIT_KEY
    RET
SHOW_HIGH_SCORES ENDP

SHOW_GAME_SCREEN PROC
    MOV AL, 0
    CALL CLEAR_SCREEN

    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 15
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV rectY, 14
    MOV rectH, 1
    MOV rectColor, 9
    CALL DRAW_RECT

    ; HUD: "Score: 0"
    MOV SI, OFFSET sScore
    MOV BX, 2
    MOV CX, 4
    MOV DL, 14
    CALL DRAW_STRING
    MOV SI, OFFSET s0
    MOV BX, 56
    MOV DL, 15
    CALL DRAW_STRING

    ; HUD: "Lives: 3"
    MOV SI, OFFSET sLives
    MOV BX, 115
    MOV CX, 4
    MOV DL, 14
    CALL DRAW_STRING
    MOV SI, OFFSET s3
    MOV BX, 170
    MOV DL, 10
    CALL DRAW_STRING

    ; HUD: Player name (right side)
    MOV BX, 220
    MOV CX, 4
    MOV DL, 11
    MOV SI, 0
GS_NAME:
    MOV AL, playerName[SI]
    CMP AL, 0
    JE  GS_NAME_DONE
    CALL DRAW_CHAR
    ADD BX, 9
    INC SI
    CMP SI, 10
    JL  GS_NAME
GS_NAME_DONE:

    MOV rectX, 0
    MOV rectY, 15
    MOV rectW, 3
    MOV rectH, 185
    MOV rectColor, 9
    CALL DRAW_RECT

    MOV rectX, 317
    CALL DRAW_RECT

    MOV BX, 0
GS_BROW:
    CMP BX, 6
    JGE GS_BRICKS_DONE

    MOV CX, 0
GS_BCOL:
    CMP CX, 14
    JGE GS_BROW_NEXT

    MOV AX, CX
    IMUL AX, 22
    ADD AX, 4
    MOV rectX, AX

    MOV AX, BX
    IMUL AX, 11
    ADD AX, 20
    MOV rectY, AX

    MOV rectW, 20
    MOV rectH, 9

    MOV AX, BX
    CMP AX, 0
    JE GS_BC0
    CMP AX, 1
    JE GS_BC1
    CMP AX, 2
    JE GS_BC2
    CMP AX, 3
    JE GS_BC3
    CMP AX, 4
    JE GS_BC4
    MOV rectColor, 15
    JMP GS_BDRAW
    GS_BC0: MOV rectColor, 4
    JMP GS_BDRAW
    GS_BC1: MOV rectColor, 14
    JMP GS_BDRAW
    GS_BC2: MOV rectColor, 2
    JMP GS_BDRAW
    GS_BC3: MOV rectColor, 3
    JMP GS_BDRAW
GS_BC4: MOV rectColor, 5
GS_BDRAW:
    CALL DRAW_RECT

    INC CX
    JMP GS_BCOL

GS_BROW_NEXT:
    INC BX
    JMP GS_BROW

GS_BRICKS_DONE:

    MOV rectX, 135
    MOV rectY, 185
    MOV rectW, 50
    MOV rectH, 5
    MOV rectColor, 7
    CALL DRAW_RECT
    MOV rectY, 185
    MOV rectH, 1
    MOV rectColor, 15
    CALL DRAW_RECT

    MOV rectX, 158
    MOV rectY, 100
    MOV rectW, 4
    MOV rectH, 4
    MOV rectColor, 15
    CALL DRAW_RECT

    MOV SI, OFFSET sReturn
    MOV BX, 55
    MOV CX, 193
    MOV DL, 7
    CALL DRAW_STRING

    CALL WAIT_KEY
    RET
SHOW_GAME_SCREEN ENDP

EXIT_GAME PROC
    MOV AX, 0003h
    INT 10h
    MOV AX, 4C00h
    INT 21h
EXIT_GAME ENDP

MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    CALL INIT_GRAPHICS

    CALL SHOW_HOME_SCREEN

    CALL SHOW_NAME_INPUT

MAIN_LOOP:
    CALL SHOW_MAIN_MENU

    CMP AL, 0
    JE  DO_GAME

    CMP AL, 1
    JE  DO_INSTR

    CMP AL, 2
    JE  DO_HI

    CALL EXIT_GAME

DO_GAME:
    CALL SHOW_GAME_SCREEN
    JMP MAIN_LOOP

DO_INSTR:
    CALL SHOW_INSTRUCTIONS
    JMP MAIN_LOOP

DO_HI:
    CALL SHOW_HIGH_SCORES
    JMP MAIN_LOOP

MAIN ENDP

END MAIN