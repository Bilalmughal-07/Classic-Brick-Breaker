.MODEL SMALL
.386
.STACK 256

.DATA

    ;==============================================================
    ; ITERATION 1 DATA (preserved)
    ;==============================================================
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

    ;==============================================================
    ; ITERATION 2 DATA — Game state
    ;==============================================================
    ; --- Ball state (signed values) ---
    ballX       DW  158
    ballY       DW  120
    ballDX      DW  2           ; FASTER: 2 px/frame instead of 1
    ballDY      DW  -2          ; FASTER: 2 px/frame instead of 1
    ballSize    EQU 4

    ; --- Paddle state ---
    paddleX     DW  135
    paddleY     EQU 185
    paddleW     DW  50
    paddleH     EQU 5
    paddleStep  EQU 6           ; Slightly faster paddle to match ball

    ; --- Game progression ---
    score       DW  0
    lives       DB  3
    level       DB  1
    bricksLeft  DW  65

    ; --- Brick array ---
    BRICK_ROWS  EQU 5
    BRICK_COLS  EQU 13
    bricks      DB  65 DUP(1)

    BRICK_W     EQU 22
    BRICK_H     EQU 8
    BRICK_X0    EQU 11
    BRICK_Y0    EQU 22

    ; --- ITOA buffer ---
    itoaBuf     DB  7 DUP(0)

    ; --- Game state flags ---
    gameRunning DB  1

    ; --- HUD caching: draw bar only once, refresh only values ---
    hudDrawn    DB  0           ; 0 = need full redraw, 1 = bar already drawn
    lastScore   DW  0FFFFh      ; Last drawn score (sentinel != 0)
    lastLives   DB  0FFh        ; Last drawn lives (sentinel)

    ;==============================================================
    ; STRING CONSTANTS (Iteration 1)
    ;==============================================================
    sTitle      DB 'BRICK BREAKER',0
    sSub        DB 'ARCADE CLASSIC',0
    sPress      DB 'PRESS ANY KEY TO CONTINUE',0
    sNameHdr    DB 'NAME INPUT',0
    sEnter      DB 'ENTER YOUR NAME:',0
    sMax15      DB 'MAX 15 CHARS',0
    sConfirm    DB 'PRESS ENTER TO CONFIRM',0
    sUpDown     DB 'UP/DOWN ENTER',0
    sStart      DB 'START GAME',0
    sInstr      DB 'INSTRUCTIONS',0
    sHighSc     DB 'HIGH SCORES',0
    sExit       DB 'EXIT',0
    sCtrl       DB 'CONTROLS',0
    sMove       DB '<-> OR A/D = MOVE PADDLE',0
    sADinst     DB 'A / D OR ARROW = MOVE PADDLE',0
    sObj        DB 'OBJECTIVE',0
    sBreak      DB 'BREAK ALL BRICKS TO ADVANCE',0
    sLivesH     DB 'LIVES $ BALL',0
    sLivesD     DB 'START WITH 3 LIVES',0
    sMS         DB 'MISS BALL = LOSE 1',0
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
    hsN1        DB 'ESHAL FATIMA',0
    hsN2        DB 'DANIYA JADOON',0
    hsN3        DB 'MUNEEB BAIG',0
    hsN4        DB 'RANA HANAN',0
    hsN5        DB 'MUHAMMAD BILAL',0
    hsS1        DB '05000',0
    hsS2        DB '04200',0
    hsS3        DB '03800',0
    hsS4        DB '02500',0
    hsS5        DB '01100',0

    ;==============================================================
    ; STRING CONSTANTS (Iteration 2)
    ;==============================================================
    sGameOver   DB 'GAME OVER',0
    sGoPlayer   DB 'PLAYER: ',0
    sGoLevel    DB 'LEVEL: 1',0
    sGoFinal    DB 'FINAL SCORE: ',0
    sGoEnter    DB 'PRESS ENTER TO RETURN TO MENU',0
    sScLabel    DB 'SC:',0
    sLvLabel    DB 'LV:',0
    sLfLabel    DB 'LF:',0
    sPlLabel    DB 'PL:',0

.CODE

;==============================================================
; INIT_GRAPHICS
;==============================================================
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

;==============================================================
; CLEAR_SCREEN
;==============================================================
CLEAR_SCREEN PROC
    PUSH ES
    PUSH DI
    PUSH CX
    PUSH BX

    MOV BL, AL
    MOV AX, 0A000h
    MOV ES, AX
    XOR DI, DI
    MOV CX, 64000
    MOV AL, BL
    REP STOSB

    POP BX
    POP CX
    POP DI
    POP ES
    RET
CLEAR_SCREEN ENDP

;==============================================================
; DRAW_RECT
;==============================================================
DRAW_RECT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI
    PUSH ES

    MOV AX, 0A000h
    MOV ES, AX

    MOV DX, rectY
    MOV BX, rectY
    ADD BX, rectH

DR_ROW:
    CMP DX, BX
    JGE DR_DONE

    MOV AX, DX
    PUSH DX
    MOV CX, 320
    MUL CX
    POP DX
    MOV DI, AX
    ADD DI, rectX

    MOV CX, rectW
    MOV AL, rectColor
    REP STOSB

    INC DX
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

;==============================================================
; DRAW_RECT_BORDER
;==============================================================
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

;==============================================================
; DRAW_CHAR — AL=char, BX=X, CX=Y, DL=color
;==============================================================
DRAW_CHAR PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH DS
    PUSH ES

    MOV charColor, DL

    MOV AH, 0
    SHL AX, 3
    ADD AX, fontOff
    MOV SI, AX
    MOV AX, fontSeg
    MOV DS, AX

    MOV AX, 0A000h
    MOV ES, AX

    MOV AH, 0

DC_ROW_LOOP:
    CMP AH, 8
    JGE DC_DONE

    MOV AL, [SI]

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

    MOV DH, 7

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

    MOV CX, 7
    MOVZX AX, DH
    SUB CX, AX
    PUSH DI
    ADD DI, CX
    MOV AL, DL
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

;==============================================================
; DRAW_STRING
;==============================================================
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

;==============================================================
; DELAY_TICKS
;==============================================================
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

;==============================================================
; WAIT_KEY
;==============================================================
WAIT_KEY PROC
    PUSH AX
    MOV AH, 00h
    INT 16h
    POP AX
    RET
WAIT_KEY ENDP

;==============================================================
; ITOA — AX (unsigned) -> itoaBuf
;==============================================================
ITOA PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH DI

    MOV DI, OFFSET itoaBuf
    MOV CX, 0

    CMP AX, 0
    JNE ITOA_LOOP
    MOV BYTE PTR [DI], '0'
    MOV BYTE PTR [DI+1], 0
    JMP ITOA_DONE

ITOA_LOOP:
    CMP AX, 0
    JE  ITOA_WRITE
    XOR DX, DX
    MOV BX, 10
    DIV BX
    ADD DL, '0'
    PUSH DX
    INC CX
    JMP ITOA_LOOP

ITOA_WRITE:
ITOA_POP:
    CMP CX, 0
    JE  ITOA_TERM
    POP DX
    MOV [DI], DL
    INC DI
    DEC CX
    JMP ITOA_POP

ITOA_TERM:
    MOV BYTE PTR [DI], 0

ITOA_DONE:
    POP DI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
ITOA ENDP

;==============================================================
; STRLEN — DS:SI -> string. Returns length in CX.
;==============================================================
STRLEN PROC
    PUSH SI
    PUSH AX
    MOV CX, 0
SL_LP:
    MOV AL, [SI]
    CMP AL, 0
    JE  SL_DN
    INC CX
    INC SI
    JMP SL_LP
SL_DN:
    POP AX
    POP SI
    RET
STRLEN ENDP

;==============================================================
; SHOW_HOME_SCREEN (Iter 1, unchanged)
;==============================================================
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

    MOV SI, OFFSET sTitle
    MOV CX, 86
    MOV DL, 14
    MOV BX, 101
    CALL DRAW_STRING

    MOV SI, OFFSET sSub
    MOV CX, 103
    MOV DL, 14
    MOV BX, 97
    CALL DRAW_STRING

HS_FLASH:
    MOV SI, OFFSET sPress
    MOV BX, 54
    MOV CX, 158
    MOV DL, 15
    CALL DRAW_STRING

    MOV CX, 6
    CALL DELAY_TICKS

    MOV AH, 01h
    INT 16h
    JNZ HS_GOT_KEY

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

;==============================================================
; SHOW_NAME_INPUT (Iter 1, unchanged)
;==============================================================
SHOW_NAME_INPUT PROC
    MOV AL, 8
    CALL CLEAR_SCREEN

    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV SI, OFFSET sNameHdr
    MOV CX, 7
    MOV DL, 14
    MOV BX, 115
    CALL DRAW_STRING

    MOV SI, OFFSET sEnter
    MOV CX, 68
    MOV DL, 15
    MOV BX, 90
    CALL DRAW_STRING

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

    MOV SI, OFFSET sMax15
    MOV CX, 115
    MOV DL, 7
    MOV BX, 110
    CALL DRAW_STRING

    MOV SI, OFFSET sConfirm
    MOV CX, 130
    MOV DL, 7
    MOV BX, 60
    CALL DRAW_STRING

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

;==============================================================
; SHOW_MAIN_MENU (Iter 1, unchanged)
;==============================================================
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

    MOV SI, OFFSET sTitle
    MOV CX, 10
    MOV DL, 14
    MOV BX, 99
    CALL DRAW_STRING

    CALL DRAW_MENU_ITEMS

    MOV CX, 188
    MOV DL, 7
    MOV BX, 4
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR
    ADD BX, 8

    MOV SI, 0
    MOV DL, 11
MM_NAME_DRAW:
    MOV AL, playerName[SI]
    CMP AL, 0
    JE  MM_NAME_DONE
    CALL DRAW_CHAR
    ADD BX, 9
    INC SI
    CMP SI, 12
    JL  MM_NAME_DRAW
MM_NAME_DONE:

    MOV SI,OFFSET sUpDown
    MOV CX, 188
    MOV DL, 8
    MOV BX, 200
    CALL DRAW_STRING

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
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH BP
    MOV BP, 0
DMI_LOOP:
    CMP BP, 4
    JGE DMI_DONE
    MOV AX, BP
    IMUL AX, 32
    ADD AX, 38
    MOV rectY, AX
    MOV rectX, 60
    MOV rectW, 200
    MOV rectH, 24
    MOV AL, menuSel
    MOVZX BX, AL
    CMP BP, BX
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
    MOV AX, BP
    IMUL AX, 32
    ADD AX, 38 + 8
    MOV CX, AX
    MOV BX, 66
    MOV AL, '>'
    MOV DL, 14
    CALL DRAW_CHAR
DMI_TEXT:
    MOV AX, BP
    IMUL AX, 32
    ADD AX, 38 + 8
    MOV CX, AX
    MOV DL, 15
    CMP BP, 0
    JE  DMI_ITEM0
    CMP BP, 1
    JE  DMI_ITEM1
    CMP BP, 2
    JE  DMI_ITEM2
    JMP DMI_ITEM3
DMI_ITEM0:
    MOV SI, OFFSET sStart
    MOV BX, 117
    CALL DRAW_STRING
    JMP DMI_NEXT
DMI_ITEM1:
    MOV SI, OFFSET sInstr
    MOV BX, 107
    CALL DRAW_STRING
    JMP DMI_NEXT
DMI_ITEM2:
    MOV SI, OFFSET sHighSc
    MOV BX, 113
    CALL DRAW_STRING
    JMP DMI_NEXT
DMI_ITEM3:
    MOV SI, OFFSET sExit
    MOV BX, 143
    CALL DRAW_STRING
DMI_NEXT:
    INC BP
    JMP DMI_LOOP
DMI_DONE:
    POP BP
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_MENU_ITEMS ENDP

;==============================================================
; SHOW_INSTRUCTIONS (Iter 1, unchanged)
;==============================================================
SHOW_INSTRUCTIONS PROC
    MOV AL, 0
    CALL CLEAR_SCREEN
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 2
    CALL DRAW_RECT
    MOV rectX, 0
    MOV rectY, 22
    MOV rectW, 320
    MOV rectH, 1
    MOV rectColor, 10
    CALL DRAW_RECT
    MOV SI, OFFSET sInstr
    MOV BX, 102
    MOV CX, 7
    MOV DL, 15
    CALL DRAW_STRING
    MOV rectX, 12
    MOV rectY, 33
    MOV rectW, 4
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT
    MOV SI,OFFSET sCtrl
    MOV BX, 22
    MOV CX, 33
    MOV DL, 14
    CALL DRAW_STRING
    MOV SI,OFFSET sADinst
    MOV BX, 30
    MOV CX, 47
    MOV DL, 7
    CALL DRAW_STRING
    MOV rectX, 12
    MOV rectY, 65
    MOV rectW, 4
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT
    MOV SI,OFFSET sObj
    MOV BX, 22
    MOV CX, 65
    MOV DL, 14
    CALL DRAW_STRING
    MOV SI,OFFSET sBreak
    MOV BX, 30
    MOV CX, 79
    MOV DL, 7
    CALL DRAW_STRING
    MOV rectX, 12
    MOV rectY, 97
    MOV rectW, 4
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT
    MOV SI,OFFSET sLivesH
    MOV BX, 22
    MOV CX, 97
    MOV DL, 14
    CALL DRAW_STRING
    MOV SI,OFFSET sLivesD
    MOV BX, 30
    MOV CX, 111
    MOV DL, 7
    CALL DRAW_STRING
    MOV SI,OFFSET sMS
    MOV BX, 30
    MOV CX, 125
    MOV DL, 7
    CALL DRAW_STRING
    MOV rectX, 12
    MOV rectY, 138
    MOV rectW, 4
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT
    MOV SI,OFFSET sBonusH
    MOV BX, 22
    MOV CX, 138
    MOV DL, 14
    CALL DRAW_STRING
    MOV rectX, 30
    MOV rectY, 152
    MOV rectW, 8
    MOV rectH, 8
    MOV rectColor, 3
    CALL DRAW_RECT
    MOV SI,OFFSET sSlow
    MOV BX, 44
    MOV CX, 152
    MOV DL, 7
    CALL DRAW_STRING
    MOV rectX, 165
    MOV rectY, 152
    MOV rectW, 8
    MOV rectH, 8
    MOV rectColor, 2
    CALL DRAW_RECT
    MOV SI,OFFSET sExtra
    MOV BX, 179
    MOV CX, 152
    MOV DL, 7
    CALL DRAW_STRING
    MOV rectX, 95
    MOV rectY, 166
    MOV rectW, 8
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT
    MOV SI,OFFSET sWide
    MOV BX, 109
    MOV CX, 166
    MOV DL, 7
    CALL DRAW_STRING
    MOV rectX, 0
    MOV rectY, 184
    MOV rectW, 320
    MOV rectH, 16
    MOV rectColor, 1
    CALL DRAW_RECT
    MOV SI,OFFSET sReturn
    MOV BX, 60
    MOV CX, 188
    MOV DL, 15
    CALL DRAW_STRING
    CALL WAIT_KEY
    RET
SHOW_INSTRUCTIONS ENDP

;==============================================================
; SHOW_HIGH_SCORES (Iter 1, unchanged)
;==============================================================
SHOW_HIGH_SCORES PROC
    MOV AL, 0
    CALL CLEAR_SCREEN
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 9
    CALL DRAW_RECT
    MOV SI,OFFSET sHighSc
    MOV BX, 108
    MOV CX, 7
    MOV DL, 15
    CALL DRAW_STRING
    MOV rectX, 20
    MOV rectY, 32
    MOV rectW, 280
    MOV rectH, 140
    MOV rectColor, 15
    CALL DRAW_RECT_BORDER
    MOV rectX, 21
    MOV rectY, 33
    MOV rectW, 278
    MOV rectH, 14
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV rectX, 20
    MOV rectY, 47
    MOV rectW, 280
    MOV rectH, 1
    MOV rectColor, 15
    CALL DRAW_RECT
    MOV SI,OFFSET sRank
    MOV BX, 35
    MOV CX, 36
    MOV DL, 14
    CALL DRAW_STRING
    MOV SI,OFFSET sName
    MOV BX, 130
    MOV CX, 36
    CALL DRAW_STRING
    MOV SI,OFFSET sScoreH
    MOV BX, 230
    MOV CX, 36
    CALL DRAW_STRING
    MOV rectX, 80
    MOV rectY, 32
    MOV rectW, 1
    MOV rectH, 140
    MOV rectColor, 15
    CALL DRAW_RECT
    MOV rectX, 215
    MOV rectY, 32
    MOV rectW, 1
    MOV rectH, 140
    MOV rectColor, 15
    CALL DRAW_RECT
    MOV BX, 45
    MOV CX, 54
    MOV DL, 14
    MOV AL, '1'
    CALL DRAW_CHAR
    MOV SI,OFFSET hsN1
    MOV BX, 90
    MOV DL, 11
    CALL DRAW_STRING
    MOV SI,OFFSET hsS1
    MOV BX, 232
    MOV DL, 10
    CALL DRAW_STRING
    MOV rectX, 21
    MOV rectY, 72
    MOV rectW, 278
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV BX, 45
    MOV CX, 78
    MOV DL, 14
    MOV AL, '2'
    CALL DRAW_CHAR
    MOV SI,OFFSET hsN2
    MOV BX, 90
    MOV DL, 11
    CALL DRAW_STRING
    MOV SI,OFFSET hsS2
    MOV BX, 232
    MOV DL, 10
    CALL DRAW_STRING
    MOV rectX, 21
    MOV rectY, 96
    MOV rectW, 278
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV BX, 45
    MOV CX, 102
    MOV DL, 14
    MOV AL, '3'
    CALL DRAW_CHAR
    MOV SI,OFFSET hsN3
    MOV BX, 90
    MOV DL, 11
    CALL DRAW_STRING
    MOV SI,OFFSET hsS3
    MOV BX, 232
    MOV DL, 10
    CALL DRAW_STRING
    MOV rectX, 21
    MOV rectY, 120
    MOV rectW, 278
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV BX, 45
    MOV CX, 126
    MOV DL, 14
    MOV AL, '4'
    CALL DRAW_CHAR
    MOV SI,OFFSET hsN4
    MOV BX, 90
    MOV DL, 11
    CALL DRAW_STRING
    MOV SI,OFFSET hsS4
    MOV BX, 232
    MOV DL, 10
    CALL DRAW_STRING
    MOV rectX, 21
    MOV rectY, 144
    MOV rectW, 278
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV BX, 45
    MOV CX, 150
    MOV DL, 14
    MOV AL, '5'
    CALL DRAW_CHAR
    MOV SI,OFFSET hsN5
    MOV BX, 90
    MOV DL, 11
    CALL DRAW_STRING
    MOV SI,OFFSET hsS5
    MOV BX, 232
    MOV DL, 10
    CALL DRAW_STRING
    MOV rectX, 0
    MOV rectY, 184
    MOV rectW, 320
    MOV rectH, 16
    MOV rectColor, 1
    CALL DRAW_RECT
    MOV SI,OFFSET sReturn
    MOV BX, 60
    MOV CX, 188
    MOV DL, 15
    CALL DRAW_STRING
    CALL WAIT_KEY
    RET
SHOW_HIGH_SCORES ENDP

;==============================================================
;==============================================================
; ITERATION 2 — GAME LOGIC PROCEDURES
;==============================================================
;==============================================================

;==============================================================
; INIT_LEVEL — fresh state for Level 1
;==============================================================
INIT_LEVEL PROC
    PUSH AX
    PUSH CX
    PUSH SI

    MOV ballX, 158
    MOV ballY, 120
    MOV ballDX, 2              ; FAST horizontal
    MOV ballDY, -2             ; FAST vertical (up)

    MOV paddleX, 135
    MOV paddleW, 50

    MOV score, 0
    MOV lives, 3
    MOV level, 1
    MOV bricksLeft, 65
    MOV gameRunning, 1

    ; Reset HUD cache so first frame draws bar fully
    MOV hudDrawn, 0
    MOV lastScore, 0FFFFh
    MOV lastLives, 0FFh

    MOV CX, 65
    MOV SI, 0
IL_FILL:
    MOV bricks[SI], 1
    INC SI
    LOOP IL_FILL

    POP SI
    POP CX
    POP AX
    RET
INIT_LEVEL ENDP

;==============================================================
; RESET_BALL — recenter ball after life loss
;==============================================================
RESET_BALL PROC
    MOV ballX, 158
    MOV ballY, 120
    MOV ballDX, 2
    MOV ballDY, -2
    RET
RESET_BALL ENDP

;==============================================================
; DRAW_BRICKS
;==============================================================
DRAW_BRICKS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV BX, 0
DB_ROW:
    CMP BX, BRICK_ROWS
    JGE DB_END

    MOV CX, 0
DB_COL:
    CMP CX, BRICK_COLS
    JGE DB_NEXTROW

    MOV AX, BX
    IMUL AX, BRICK_COLS
    ADD AX, CX
    MOV SI, AX

    MOV AL, bricks[SI]
    CMP AL, 0
    JE  DB_SKIP

    MOV AX, CX
    IMUL AX, 23
    ADD AX, BRICK_X0
    MOV rectX, AX

    MOV AX, BX
    IMUL AX, 9
    ADD AX, BRICK_Y0
    MOV rectY, AX

    MOV rectW, BRICK_W
    MOV rectH, BRICK_H

    CMP BX, 0
    JE  DBC0
    CMP BX, 1
    JE  DBC1
    CMP BX, 2
    JE  DBC2
    CMP BX, 3
    JE  DBC3
    MOV rectColor, 5
    JMP DB_DRAW
DBC0: MOV rectColor, 4
    JMP DB_DRAW
DBC1: MOV rectColor, 14
    JMP DB_DRAW
DBC2: MOV rectColor, 2
    JMP DB_DRAW
DBC3: MOV rectColor, 3
DB_DRAW:
    CALL DRAW_RECT

DB_SKIP:
    INC CX
    JMP DB_COL

DB_NEXTROW:
    INC BX
    JMP DB_ROW

DB_END:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_BRICKS ENDP

;==============================================================
; ERASE_BALL / DRAW_BALL
;==============================================================
ERASE_BALL PROC
    PUSH AX
    MOV AX, ballX
    MOV rectX, AX
    MOV AX, ballY
    MOV rectY, AX
    MOV rectW, ballSize
    MOV rectH, ballSize
    MOV rectColor, 0
    CALL DRAW_RECT
    POP AX
    RET
ERASE_BALL ENDP

DRAW_BALL PROC
    PUSH AX
    MOV AX, ballX
    MOV rectX, AX
    MOV AX, ballY
    MOV rectY, AX
    MOV rectW, ballSize
    MOV rectH, ballSize
    MOV rectColor, 15
    CALL DRAW_RECT
    POP AX
    RET
DRAW_BALL ENDP

;==============================================================
; ERASE_PADDLE / DRAW_PADDLE
;==============================================================
ERASE_PADDLE PROC
    PUSH AX
    MOV AX, paddleX
    MOV rectX, AX
    MOV rectY, paddleY
    MOV AX, paddleW
    MOV rectW, AX
    MOV rectH, paddleH
    MOV rectColor, 0
    CALL DRAW_RECT
    POP AX
    RET
ERASE_PADDLE ENDP

DRAW_PADDLE PROC
    PUSH AX
    MOV AX, paddleX
    MOV rectX, AX
    MOV rectY, paddleY
    MOV AX, paddleW
    MOV rectW, AX
    MOV rectH, paddleH
    MOV rectColor, 7
    CALL DRAW_RECT

    MOV AX, paddleX
    MOV rectX, AX
    MOV rectY, paddleY
    MOV AX, paddleW
    MOV rectW, AX
    MOV rectH, 1
    MOV rectColor, 15
    CALL DRAW_RECT

    POP AX
    RET
DRAW_PADDLE ENDP

;==============================================================
; READ_INPUT — non-blocking
;==============================================================
READ_INPUT PROC
    PUSH AX
    PUSH BX

RI_PEEK:
    MOV AH, 01h
    INT 16h
    JZ  RI_DONE

    MOV AH, 00h
    INT 16h

    CMP AL, 1Bh
    JE  RI_ESC

    CMP AH, 4Bh
    JE  RI_LEFT
    CMP AL, 'a'
    JE  RI_LEFT
    CMP AL, 'A'
    JE  RI_LEFT

    CMP AH, 4Dh
    JE  RI_RIGHT
    CMP AL, 'd'
    JE  RI_RIGHT
    CMP AL, 'D'
    JE  RI_RIGHT

    JMP RI_PEEK

RI_LEFT:
    MOV BX, paddleX
    SUB BX, paddleStep
    CMP BX, 3
    JGE RI_SET_LEFT
    MOV BX, 3
RI_SET_LEFT:
    CALL ERASE_PADDLE
    MOV paddleX, BX
    CALL DRAW_PADDLE
    JMP RI_PEEK

RI_RIGHT:
    MOV BX, paddleX
    ADD BX, paddleStep
    MOV AX, 317
    SUB AX, paddleW
    CMP BX, AX
    JLE RI_SET_RIGHT
    MOV BX, AX
RI_SET_RIGHT:
    CALL ERASE_PADDLE
    MOV paddleX, BX
    CALL DRAW_PADDLE
    JMP RI_PEEK

RI_ESC:
    MOV gameRunning, 0
    JMP RI_DONE

RI_DONE:
    POP BX
    POP AX
    RET
READ_INPUT ENDP

;==============================================================
; CHECK_BRICK_COLLISION — AABB scan
;==============================================================
CHECK_BRICK_COLLISION PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV BX, 0
CBC_ROW:
    CMP BX, BRICK_ROWS
    JGE CBC_END

    MOV CX, 0
CBC_COL:
    CMP CX, BRICK_COLS
    JGE CBC_NEXTROW

    MOV AX, BX
    IMUL AX, BRICK_COLS
    ADD AX, CX
    MOV SI, AX

    MOV AL, bricks[SI]
    CMP AL, 0
    JE  CBC_SKIP

    ; AABB tests
    MOV AX, CX
    IMUL AX, 23
    ADD AX, 11 + 22
    MOV DI, AX
    MOV DX, ballX
    CMP DX, DI
    JGE CBC_SKIP

    MOV AX, CX
    IMUL AX, 23
    ADD AX, 11
    MOV DI, AX
    MOV DX, ballX
    ADD DX, ballSize
    CMP DX, DI
    JLE CBC_SKIP

    MOV AX, BX
    IMUL AX, 9
    ADD AX, 22 + 8
    MOV DI, AX
    MOV DX, ballY
    CMP DX, DI
    JGE CBC_SKIP

    MOV AX, BX
    IMUL AX, 9
    ADD AX, 22
    MOV DI, AX
    MOV DX, ballY
    ADD DX, ballSize
    CMP DX, DI
    JLE CBC_SKIP

    ; HIT
    MOV bricks[SI], 0
    DEC bricksLeft

    MOV AX, CX
    IMUL AX, 23
    ADD AX, 11
    MOV rectX, AX
    MOV AX, BX
    IMUL AX, 9
    ADD AX, 22
    MOV rectY, AX
    MOV rectW, BRICK_W
    MOV rectH, BRICK_H
    MOV rectColor, 0
    CALL DRAW_RECT

    ADD score, 10
    NEG ballDY
    JMP CBC_END

CBC_SKIP:
    INC CX
    JMP CBC_COL

CBC_NEXTROW:
    INC BX
    JMP CBC_ROW

CBC_END:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CHECK_BRICK_COLLISION ENDP

;==============================================================
; CHECK_PADDLE_COLLISION
;==============================================================
CHECK_PADDLE_COLLISION PROC
    PUSH AX
    PUSH BX
    PUSH DX

    MOV AX, ballY
    ADD AX, ballSize
    CMP AX, paddleY
    JLE CPC_NO

    MOV AX, ballY
    CMP AX, paddleY + paddleH
    JGE CPC_NO

    MOV AX, ballX
    ADD AX, ballSize
    CMP AX, paddleX
    JLE CPC_NO

    MOV AX, paddleX
    ADD AX, paddleW
    MOV BX, ballX
    CMP BX, AX
    JGE CPC_NO

    CMP ballDY, 0
    JLE CPC_NO

    MOV AX, paddleY
    SUB AX, ballSize
    MOV ballY, AX

    NEG ballDY

    ; angle: based on which half of paddle was hit
    MOV AX, paddleW
    SHR AX, 1
    ADD AX, paddleX

    MOV BX, ballX
    ADD BX, ballSize/2
    CMP BX, AX
    JL  CPC_LEFT

    MOV ballDX, 2
    JMP CPC_NO

CPC_LEFT:
    MOV ballDX, -2

CPC_NO:
    POP DX
    POP BX
    POP AX
    RET
CHECK_PADDLE_COLLISION ENDP

;==============================================================
; MOVE_BALL
;==============================================================
MOVE_BALL PROC
    PUSH AX
    PUSH BX

    CALL ERASE_BALL

    MOV AX, ballX
    ADD AX, ballDX
    MOV ballX, AX

    MOV AX, ballY
    ADD AX, ballDY
    MOV ballY, AX

    ; Left wall
    CMP ballX, 3
    JGE MB_NOL
    MOV ballX, 3
    NEG ballDX
MB_NOL:

    ; Right wall
    MOV AX, ballX
    ADD AX, ballSize
    CMP AX, 317
    JLE MB_NOR
    MOV AX, 317
    SUB AX, ballSize
    MOV ballX, AX
    NEG ballDX
MB_NOR:

    ; Top wall
    CMP ballY, 15
    JGE MB_NOT
    MOV ballY, 15
    NEG ballDY
MB_NOT:

    ; Bottom (life loss)
    CMP ballY, 196
    JL  MB_ALIVE

    DEC lives
    CMP lives, 0
    JLE MB_DEAD

    MOV CX, 8
    CALL DELAY_TICKS

    CALL RESET_BALL
    JMP MB_FINISH

MB_DEAD:
    MOV lives, 0
    MOV gameRunning, 0
    JMP MB_FINISH

MB_ALIVE:
    CALL CHECK_PADDLE_COLLISION
    CALL CHECK_BRICK_COLLISION

MB_FINISH:
    CALL DRAW_BALL

    POP BX
    POP AX
    RET
MOVE_BALL ENDP

;==============================================================
; DRAW_HUD_STATIC — paint HUD bar background AND static labels
;   Called only ONCE per level (not every frame).
;   This stops the flicker.
;==============================================================
DRAW_HUD_STATIC PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; HUD background bar
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 14
    MOV rectColor, 1
    CALL DRAW_RECT

    ; Separator line
    MOV rectX, 0
    MOV rectY, 14
    MOV rectW, 320
    MOV rectH, 1
    MOV rectColor, 9
    CALL DRAW_RECT

    ; --- Static labels ---
    MOV SI, OFFSET sScLabel
    MOV BX, 3
    MOV CX, 3
    MOV DL, 14
    CALL DRAW_STRING

    MOV SI, OFFSET sLvLabel
    MOV BX, 90
    MOV CX, 3
    MOV DL, 14
    CALL DRAW_STRING

    MOV SI, OFFSET sLfLabel
    MOV BX, 140
    MOV CX, 3
    MOV DL, 14
    CALL DRAW_STRING

    MOV SI, OFFSET sPlLabel
    MOV BX, 190
    MOV CX, 3
    MOV DL, 14
    CALL DRAW_STRING

    ; --- Static values that never change: Level + Player Name ---
    MOV AL, level
    MOV AH, 0
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    MOV BX, 119
    MOV CX, 3
    MOV DL, 15
    CALL DRAW_STRING

    ; Player name
    MOV SI, 0
    MOV BX, 219
    MOV CX, 3
    MOV DL, 11
HUDS_NAME:
    MOV AL, playerName[SI]
    CMP AL, 0
    JE  HUDS_NAME_DN
    CALL DRAW_CHAR
    ADD BX, 9
    INC SI
    CMP SI, 11
    JL  HUDS_NAME
HUDS_NAME_DN:

    MOV hudDrawn, 1

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_HUD_STATIC ENDP

;==============================================================
; UPDATE_HUD — repaint ONLY the values that have changed.
;
;   To eliminate flicker, we do NOT redraw the full HUD bar each
;   frame. Instead:
;     - The bar + static labels are drawn ONCE by DRAW_HUD_STATIC
;     - This proc only repaints the small region behind the
;       score/lives values, AND only when those values changed.
;     - That region is overwritten with the bar color (1) before
;       drawing new text, so old digits do not bleed through.
;==============================================================
UPDATE_HUD PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; --- Score: only redraw if changed ---
    MOV AX, score
    CMP AX, lastScore
    JE  UH_NO_SCORE

    ; Clear old score region (X 32..86, Y 2..11) with bar color
    MOV rectX, 32
    MOV rectY, 2
    MOV rectW, 55
    MOV rectH, 10
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV AX, score
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    MOV BX, 32
    MOV CX, 3
    MOV DL, 15
    CALL DRAW_STRING

    MOV AX, score
    MOV lastScore, AX

UH_NO_SCORE:

    ; --- Lives: only redraw if changed ---
    MOV AL, lives
    CMP AL, lastLives
    JE  UH_NO_LIVES

    MOV rectX, 169
    MOV rectY, 2
    MOV rectW, 18
    MOV rectH, 10
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV AL, lives
    MOV AH, 0
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    MOV BX, 169
    MOV CX, 3
    MOV DL, 10
    CALL DRAW_STRING

    MOV AL, lives
    MOV lastLives, AL

UH_NO_LIVES:

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
UPDATE_HUD ENDP

;==============================================================
; DRAW_GAME_FRAME — one-time setup
;==============================================================
DRAW_GAME_FRAME PROC
    PUSH AX

    MOV AL, 0
    CALL CLEAR_SCREEN

    ; Side walls
    MOV rectX, 0
    MOV rectY, 15
    MOV rectW, 3
    MOV rectH, 181
    MOV rectColor, 9
    CALL DRAW_RECT

    MOV rectX, 317
    MOV rectY, 15
    MOV rectW, 3
    MOV rectH, 181
    MOV rectColor, 9
    CALL DRAW_RECT

    CALL DRAW_BRICKS
    CALL DRAW_PADDLE
    CALL DRAW_BALL

    ; Static HUD: drawn ONCE here, never repainted whole.
    CALL DRAW_HUD_STATIC

    ; Force first UPDATE_HUD call to render values
    CALL UPDATE_HUD

    POP AX
    RET
DRAW_GAME_FRAME ENDP

;==============================================================
; SHOW_GAME_SCREEN — main game loop
;==============================================================
SHOW_GAME_SCREEN PROC
    CALL INIT_LEVEL
    CALL DRAW_GAME_FRAME

GL_LOOP:
    CALL READ_INPUT
    CALL MOVE_BALL
    CALL UPDATE_HUD            ; only updates if values changed

    ; Frame delay (smaller -> faster ball)
    MOV CX, 1
    CALL DELAY_TICKS

    CMP gameRunning, 0
    JE  GL_END
    CMP lives, 0
    JLE GL_END
    CMP bricksLeft, 0
    JLE GL_WIN_L1

    JMP GL_LOOP

GL_WIN_L1:
GL_END:
    CALL SHOW_GAME_OVER
    RET
SHOW_GAME_SCREEN ENDP

;==============================================================
; SHOW_GAME_OVER — styled to match Iteration 1 screens
;
; Layout:
;   - Top header bar (dark red, full width 320 x 22) with
;     "GAME OVER" centered in white — matches the Iteration 1
;     "NAME INPUT" / "INSTRUCTIONS" / "HIGH SCORES" header style.
;   - A bordered information box (white border on black fill)
;     that holds the player, level, and final score lines.
;   - A bottom blue footer bar with the blinking
;     "PRESS ENTER TO RETURN TO MENU" prompt — same pattern as
;     Iteration 1 footer bars.
;==============================================================
SHOW_GAME_OVER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; --- Black background ---
    MOV AL, 0
    CALL CLEAR_SCREEN

    ;----------------------------------------------------------
    ; HEADER BAR (red, like Iteration 1 colored headers)
    ;----------------------------------------------------------
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 4              ; red
    CALL DRAW_RECT

    ; Header underline (light red)
    MOV rectX, 0
    MOV rectY, 22
    MOV rectW, 320
    MOV rectH, 1
    MOV rectColor, 12
    CALL DRAW_RECT

    ; Title "GAME OVER" centered.
    ; Width: G A M E (sp) O V E R = 8 letters * 9 + 6 = 78
    ; X = (320 - 78)/2 = 121
    MOV SI, OFFSET sGameOver
    MOV BX, 121
    MOV CX, 7
    MOV DL, 15                    ; white on red header
    CALL DRAW_STRING

    ;----------------------------------------------------------
    ; INFO BOX (bordered rectangle that holds the entries)
    ; Outer:  X=30, Y=45, W=260, H=110  (white border)
    ; Inner:  X=31, Y=46, W=258, H=108  (black fill)
    ;----------------------------------------------------------
    MOV rectX, 30
    MOV rectY, 45
    MOV rectW, 260
    MOV rectH, 110
    MOV rectColor, 15
    CALL DRAW_RECT_BORDER

    MOV rectX, 32
    MOV rectY, 47
    MOV rectW, 256
    MOV rectH, 106
    MOV rectColor, 0
    CALL DRAW_RECT

    ; Optional inner accent line under top of box
    MOV rectX, 32
    MOV rectY, 67
    MOV rectW, 256
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT

    ;----------------------------------------------------------
    ; LINE A (Y=53): "PLAYER: <name>" — Yellow
    ;   prefix actual width:
    ;     P L A Y E R :  -> 7 letters * 9 = 63
    ;     + 1 space      -> + 6           = 69
    ;   total width = 69 + nameLen*9
    ;----------------------------------------------------------
    MOV AL, nameLen
    MOV AH, 0
    MOV BX, AX
    IMUL BX, 9
    ADD BX, 69                    ; total pixel width
    MOV AX, 320
    SUB AX, BX
    SHR AX, 1                     ; AX = start X

    MOV SI, OFFSET sGoPlayer
    MOV BX, AX
    MOV CX, 53
    MOV DL, 14                    ; yellow
    CALL DRAW_STRING

    ; Append name
    ADD BX, 69
    MOV SI, 0
GO_PNAME:
    MOV AL, playerName[SI]
    CMP AL, 0
    JE  GO_PNAME_DN
    CALL DRAW_CHAR
    ADD BX, 9
    INC SI
    CMP SI, 15
    JL  GO_PNAME
GO_PNAME_DN:

    ;----------------------------------------------------------
    ; LINE B (Y=85): "LEVEL: 1" — Light Blue
    ; Width: 7 chars*9 + 6 = 69
    ; X = (320-69)/2 = 125
    ;----------------------------------------------------------
    MOV SI, OFFSET sGoLevel
    MOV BX, 125
    MOV CX, 85
    MOV DL, 9
    CALL DRAW_STRING

    ;----------------------------------------------------------
    ; LINE C (Y=120): "FINAL SCORE: <score>" — Light Green
    ;   "FINAL SCORE:" = 11 letters*9 + 6 (space) = 105
    ;   plus trailing space (6) plus digits = 111 + digits*9
    ;----------------------------------------------------------
    MOV AX, score
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    CALL STRLEN
    MOV AX, CX
    IMUL AX, 9
    ADD AX, 111
    MOV BX, 320
    SUB BX, AX
    SHR BX, 1

    MOV SI, OFFSET sGoFinal
    MOV CX, 120
    MOV DL, 10
    CALL DRAW_STRING

    ; Advance past prefix "FINAL SCORE: "  -> 105 + 6 = 111
    ADD BX, 111
    MOV SI, OFFSET itoaBuf
    MOV DL, 10
    CALL DRAW_STRING

    ;----------------------------------------------------------
    ; FOOTER BAR (blue, just like Iteration 1 footers)
    ;----------------------------------------------------------
    MOV rectX, 0
    MOV rectY, 178
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 1
    CALL DRAW_RECT

    ;----------------------------------------------------------
    ; BLINKING PROMPT inside footer
    ;
    ;   "PRESS ENTER TO RETURN TO MENU"
    ;   29 chars: 24 letters + 4 spaces + 1 ':' (none here)
    ;   Letters = 24, spaces = 4
    ;   Pixel width = 24*9 + 4*6 = 216 + 24 = 240
    ;   X = (320-240)/2 = 40
    ;
    ;   We use a generously wide erase rect (X=20..299, full
    ;   footer height) so NO part of any glyph (including 'U' tail)
    ;   can survive between blink cycles. Previous bug: erase
    ;   region was too small/short and clipped low-pixel parts of
    ;   tall glyphs.
    ;----------------------------------------------------------
GO_BLINK:
    ; Draw the prompt
    MOV SI, OFFSET sGoEnter
    MOV BX, 40
    MOV CX, 186
    MOV DL, 7
    CALL DRAW_STRING

    ; ON delay
    MOV CX, 10
    CALL DELAY_TICKS

    ; Check ENTER
    MOV AH, 01h
    INT 16h
    JZ  GO_DO_ERASE
    MOV AH, 00h
    INT 16h
    CMP AL, 0Dh
    JE  GO_DONE
    JMP GO_BLINK

GO_DO_ERASE:
    ; --- ERASE the WHOLE prompt line so blink is uniform ---
    ; Width 280, height 14 covers all 8 font rows + safety
    MOV rectX, 20
    MOV rectY, 184
    MOV rectW, 280
    MOV rectH, 14
    MOV rectColor, 1              ; same as footer bg
    CALL DRAW_RECT

    ; OFF delay
    MOV CX, 7
    CALL DELAY_TICKS

    ; Check ENTER
    MOV AH, 01h
    INT 16h
    JZ  GO_BLINK
    MOV AH, 00h
    INT 16h
    CMP AL, 0Dh
    JE  GO_DONE
    JMP GO_BLINK

GO_DONE:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_GAME_OVER ENDP

;==============================================================
; EXIT_GAME
;==============================================================
EXIT_GAME PROC
    MOV AX, 0003h
    INT 10h
    MOV AX, 4C00h
    INT 21h
EXIT_GAME ENDP

;==============================================================
; MAIN
;==============================================================
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
