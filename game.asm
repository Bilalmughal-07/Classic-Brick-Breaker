.MODEL SMALL
.386
.STACK 256

.DATA

    ;================================================================
    ; SECTION 1a: ITERATION 1 — UI STRINGS & VARIABLES
    ;================================================================

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

    ; ---- String Constants (Iteration 1) ----
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

    ;================================================================
    ; SECTION 1b: ITERATION 2 — GAME STATE VARIABLES
    ;================================================================

    ; --- Ball state ---
    ballX       DW  158         ; current ball X (left edge of 4x4 square)
    ballY       DW  120         ; current ball Y (top edge of 4x4 square)
    ballDX      DW  2           ; horizontal direction (+2 or -2)
    ballDY      DW  -2          ; vertical direction (-2 or +2)

    ; --- Paddle state ---
    paddleX     DW  135         ; paddle left-edge X
    oldPaddleX  DW  135         ; previous paddle X (for erase-redraw)

    ; --- Score / Lives / Level ---
    score       DW  0
    lives       DB  3
    level       DB  1
    gameOver    DB  0           ; 0 = playing, 1 = lost all lives

    ; --- Brick grid: 5 rows x 13 cols = 65 bytes ---
    ; 1 = alive, 0 = destroyed
    brickGrid   DB  65 DUP(1)
    bricksLeft  DB  65

    ; --- Brick layout constants (match Iteration 1 visuals) ---
    ; Each brick: 22 wide x 8 tall, column stride = 23, row stride = 9
    ; Grid starts at X=11, Y=22
    BRICK_STARTX EQU 11
    BRICK_STARTY EQU 22
    BRICK_W      EQU 22
    BRICK_H      EQU 8
    BRICK_COLSTR EQU 23         ; column stride (22 + 1 gap)
    BRICK_ROWSTR EQU 9          ; row stride   (8 + 1 gap)
    NUM_ROWS     EQU 5
    NUM_COLS     EQU 13

    ; --- Paddle constants ---
    PADDLE_Y     EQU 185
    PADDLE_W     EQU 50
    PADDLE_H     EQU 5
    PADDLE_STEP  EQU 5

    ; --- Ball constants ---
    BALL_SIZE    EQU 4

    ; --- Play field boundaries ---
    FIELD_TOP    EQU 15         ; Y=15 is top of play field
    FIELD_BOT    EQU 195        ; below this = ball missed
    WALL_LEFT    EQU 3          ; left wall thickness (side walls X 0-2)
    WALL_RIGHT   EQU 317        ; right wall starts at X=317

    ; --- Score display buffer ---
    scoreBuf    DB '00000',0    ; 5-digit ASCII score string

    ; --- Strings for Game Over screen ---
    sGameOver   DB 'GAME OVER',0
    sFinalSc    DB 'FINAL SCORE:',0
    sRetMenu    DB 'PRESS ANY KEY FOR MENU',0
    sReady      DB 'GET READY!',0

    ; --- Flag for HUD dirty tracking ---
    hudDirty    DB  1           ; 1 = need to redraw HUD values

    ; --- Input direction for paddle (per frame) ---
    ; -1 = left, 0 = none, +1 = right
    inputDir    DW  0

.CODE

;================================================================
; SECTION 2: GRAPHICS PRIMITIVES
; (Unchanged from Iteration 1 except minor comments)
;================================================================

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


;================================================================
; SECTION 3: SCREEN PROCEDURES (Iteration 1 — UNCHANGED)
;================================================================

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
    MOV AL, 'C'
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
    MOV AL, 'O'
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


;================================================================
; SECTION 4: GAME ENGINE — ITERATION 2
;================================================================

;--------------------------------------------------------------
; SCORE_TO_ASCII — converts the 16-bit value in 'score' to
; a 5-digit ASCII string in 'scoreBuf'
; Uses repeated division by 10.
;--------------------------------------------------------------
SCORE_TO_ASCII PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV AX, score
    MOV CX, 5              ; 5 digits
    LEA BX, scoreBuf
    ADD BX, 4              ; point to last digit position

STA_LOOP:
    XOR DX, DX
    MOV SI, 10
    DIV SI                  ; AX = quotient, DX = remainder
    ADD DL, '0'
    MOV [BX], DL
    DEC BX
    DEC CX
    JNZ STA_LOOP

    POP DX
    POP CX
    POP BX
    POP AX
    RET
SCORE_TO_ASCII ENDP

;--------------------------------------------------------------
; GET_BRICK_COLOR — given row in AX, returns color in AL
; Matches Iteration 1 layout: red, yellow, green, cyan, magenta
;--------------------------------------------------------------
GET_BRICK_COLOR PROC
    CMP AX, 0
    JE  GBC_R0
    CMP AX, 1
    JE  GBC_R1
    CMP AX, 2
    JE  GBC_R2
    CMP AX, 3
    JE  GBC_R3
    MOV AL, 5              ; row 4 = magenta
    RET
GBC_R0:
    MOV AL, 4              ; red
    RET
GBC_R1:
    MOV AL, 14             ; yellow
    RET
GBC_R2:
    MOV AL, 2              ; green
    RET
GBC_R3:
    MOV AL, 3              ; cyan
    RET
GET_BRICK_COLOR ENDP

;--------------------------------------------------------------
; DRAW_ALL_BRICKS — draws the full brick grid based on brickGrid
; alive bricks are drawn in their row color, dead bricks are
; painted with background color (0 = black).
;--------------------------------------------------------------
DRAW_ALL_BRICKS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV BX, 0              ; BX = row (0..4)
DAB_ROW:
    CMP BX, NUM_ROWS
    JGE DAB_DONE

    MOV CX, 0              ; CX = col (0..12)
DAB_COL:
    CMP CX, NUM_COLS
    JGE DAB_ROW_NEXT

    ; Compute brick X = col * 23 + 11
    MOV AX, CX
    IMUL AX, BRICK_COLSTR
    ADD AX, BRICK_STARTX
    MOV rectX, AX

    ; Compute brick Y = row * 9 + 22
    MOV AX, BX
    IMUL AX, BRICK_ROWSTR
    ADD AX, BRICK_STARTY
    MOV rectY, AX

    MOV rectW, BRICK_W
    MOV rectH, BRICK_H

    ; Compute grid index = row * 13 + col
    MOV AX, BX
    IMUL AX, NUM_COLS
    ADD AX, CX
    MOV SI, AX

    CMP brickGrid[SI], 1
    JNE DAB_DEAD

    ; Alive: draw with row color
    MOV AX, BX
    CALL GET_BRICK_COLOR
    MOV rectColor, AL
    CALL DRAW_RECT
    JMP DAB_NEXT

DAB_DEAD:
    ; Dead: paint black
    MOV rectColor, 0
    CALL DRAW_RECT

DAB_NEXT:
    INC CX
    JMP DAB_COL

DAB_ROW_NEXT:
    INC BX
    JMP DAB_ROW

DAB_DONE:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_ALL_BRICKS ENDP

;--------------------------------------------------------------
; DRAW_PADDLE — draws the paddle at paddleX, PADDLE_Y
;--------------------------------------------------------------
DRAW_PADDLE PROC
    PUSH AX

    ; Main paddle body (grey)
    MOV AX, paddleX
    MOV rectX, AX
    MOV rectY, PADDLE_Y
    MOV rectW, PADDLE_W
    MOV rectH, PADDLE_H
    MOV rectColor, 7
    CALL DRAW_RECT

    ; Highlight strip on top row (white)
    MOV AX, paddleX
    MOV rectX, AX
    MOV rectY, PADDLE_Y
    MOV rectW, PADDLE_W
    MOV rectH, 1
    MOV rectColor, 15
    CALL DRAW_RECT

    POP AX
    RET
DRAW_PADDLE ENDP

;--------------------------------------------------------------
; ERASE_PADDLE — erases paddle at given X position (in AX)
;--------------------------------------------------------------
ERASE_PADDLE PROC
    MOV rectX, AX
    MOV rectY, PADDLE_Y
    MOV rectW, PADDLE_W
    MOV rectH, PADDLE_H
    MOV rectColor, 0
    CALL DRAW_RECT
    RET
ERASE_PADDLE ENDP

;--------------------------------------------------------------
; DRAW_BALL — draws ball at ballX, ballY as 4x4 white square
;--------------------------------------------------------------
DRAW_BALL PROC
    PUSH AX
    MOV AX, ballX
    MOV rectX, AX
    MOV AX, ballY
    MOV rectY, AX
    MOV rectW, BALL_SIZE
    MOV rectH, BALL_SIZE
    MOV rectColor, 15
    CALL DRAW_RECT
    POP AX
    RET
DRAW_BALL ENDP

;--------------------------------------------------------------
; ERASE_BALL — erases ball at ballX, ballY (paint black)
;--------------------------------------------------------------
ERASE_BALL PROC
    PUSH AX
    MOV AX, ballX
    MOV rectX, AX
    MOV AX, ballY
    MOV rectY, AX
    MOV rectW, BALL_SIZE
    MOV rectH, BALL_SIZE
    MOV rectColor, 0
    CALL DRAW_RECT
    POP AX
    RET
ERASE_BALL ENDP

;--------------------------------------------------------------
; DRAW_HUD — draws the entire HUD bar at top (Y: 0-14)
; Called once at level start and whenever hudDirty = 1
;--------------------------------------------------------------
DRAW_HUD PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Background bar
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

    ; --- "SC:" + score value ---
    MOV BX, 3
    MOV CX, 3
    MOV DL, 14
    MOV AL, 'S'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'C'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR

    ; Convert score to ASCII
    CALL SCORE_TO_ASCII

    MOV BX, 32
    MOV CX, 3
    MOV DL, 15
    MOV SI, OFFSET scoreBuf
    CALL DRAW_STRING

    ; --- "LV:" + level ---
    MOV BX, 90
    MOV CX, 3
    MOV DL, 14
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'V'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR

    MOV BX, 119
    MOV DL, 15
    MOV AL, level
    ADD AL, '0'
    CALL DRAW_CHAR

    ; --- "LF:" + lives ---
    MOV BX, 145
    MOV CX, 3
    MOV DL, 14
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'F'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR

    MOV BX, 174
    MOV DL, 10
    MOV AL, lives
    ADD AL, '0'
    CALL DRAW_CHAR

    ; --- "PL:" + player name ---
    MOV BX, 200
    MOV CX, 3
    MOV DL, 14
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR

    MOV BX, 229
    MOV DL, 11
    MOV SI, 0
DH_NAME:
    MOV AL, playerName[SI]
    CMP AL, 0
    JE  DH_NAME_DONE
    CALL DRAW_CHAR
    ADD BX, 9
    INC SI
    CMP SI, 10
    JL  DH_NAME
DH_NAME_DONE:

    MOV hudDirty, 0

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
DRAW_HUD ENDP

;--------------------------------------------------------------
; DRAW_WALLS — draws the side walls of the play field
;--------------------------------------------------------------
DRAW_WALLS PROC
    MOV rectX, 0
    MOV rectY, 15
    MOV rectW, 3
    MOV rectH, 181         ; Y 15 to 195
    MOV rectColor, 9
    CALL DRAW_RECT

    MOV rectX, 317
    MOV rectY, 15
    MOV rectW, 3
    MOV rectH, 181
    MOV rectColor, 9
    CALL DRAW_RECT
    RET
DRAW_WALLS ENDP

;--------------------------------------------------------------
; LOAD_LEVEL — initializes all game state for Level 1
; Resets ball, paddle, bricks, score, lives
;--------------------------------------------------------------
LOAD_LEVEL PROC
    PUSH AX
    PUSH CX
    PUSH SI

    ; Reset ball to center of play field, heading up-right
    MOV ballX, 158
    MOV ballY, 120
    MOV ballDX, 2
    MOV ballDY, -2

    ; Reset paddle to center
    MOV paddleX, 135
    MOV oldPaddleX, 135

    ; Reset game state
    MOV score, 0
    MOV lives, 3
    MOV level, 1
    MOV gameOver, 0
    MOV hudDirty, 1

    ; Fill all 65 bricks as alive
    MOV CX, 65
    MOV SI, 0
LL_FILL:
    MOV brickGrid[SI], 1
    INC SI
    LOOP LL_FILL

    MOV bricksLeft, 65

    POP SI
    POP CX
    POP AX
    RET
LOAD_LEVEL ENDP

;--------------------------------------------------------------
; DRAW_INITIAL_SCREEN — draws the static elements of the game
; screen: HUD, walls, bricks, paddle, ball.
; Called once when the level starts.
;--------------------------------------------------------------
DRAW_INITIAL_SCREEN PROC
    MOV AL, 0
    CALL CLEAR_SCREEN

    CALL DRAW_HUD
    CALL DRAW_WALLS
    CALL DRAW_ALL_BRICKS
    CALL DRAW_PADDLE
    CALL DRAW_BALL
    RET
DRAW_INITIAL_SCREEN ENDP

;--------------------------------------------------------------
; READ_INPUT — non-blocking keyboard read.
; Sets inputDir: -1=left, +1=right, 0=none.
; Also checks for ESC to abort game.
; Uses INT 16h AH=01h (peek) then AH=00h (consume).
;--------------------------------------------------------------
READ_INPUT PROC
    PUSH AX

    MOV inputDir, 0         ; default: no input

    MOV AH, 01h            ; check keyboard buffer (non-blocking)
    INT 16h
    JZ  RI_DONE             ; ZF=1 means no key available

    ; Key is available — consume it
    MOV AH, 00h
    INT 16h

    ; Check arrow keys (scan codes in AH)
    CMP AH, 4Bh            ; left arrow
    JE  RI_LEFT
    CMP AH, 4Dh            ; right arrow
    JE  RI_RIGHT

    ; Check A/D keys (ASCII in AL)
    CMP AL, 'a'
    JE  RI_LEFT
    CMP AL, 'A'
    JE  RI_LEFT
    CMP AL, 'd'
    JE  RI_RIGHT
    CMP AL, 'D'
    JE  RI_RIGHT

    ; Check ESC (scan code 01h) — abort game
    CMP AH, 01h
    JE  RI_ESC

    JMP RI_DONE

RI_LEFT:
    MOV inputDir, -1
    JMP RI_DONE

RI_RIGHT:
    MOV inputDir, 1
    JMP RI_DONE

RI_ESC:
    MOV gameOver, 1         ; signal game loop to exit
    JMP RI_DONE

RI_DONE:
    POP AX
    RET
READ_INPUT ENDP

;--------------------------------------------------------------
; MOVE_PADDLE — applies inputDir to paddleX, clamps to walls,
; erases old position, draws new position.
;--------------------------------------------------------------
MOVE_PADDLE PROC
    PUSH AX
    PUSH BX

    ; Save old position for erasing
    MOV AX, paddleX
    MOV oldPaddleX, AX

    ; Apply input direction
    MOV BX, inputDir
    CMP BX, 0
    JE  MP_NO_MOVE

    CMP BX, -1
    JE  MP_LEFT
    ; else right
    ADD paddleX, PADDLE_STEP
    JMP MP_CLAMP

MP_LEFT:
    SUB paddleX, PADDLE_STEP

MP_CLAMP:
    ; Clamp left boundary: paddleX >= WALL_LEFT (3)
    CMP paddleX, WALL_LEFT
    JGE MP_CHK_RIGHT
    MOV paddleX, WALL_LEFT
    JMP MP_CHECK_CHANGED

MP_CHK_RIGHT:
    ; Clamp right boundary: paddleX <= WALL_RIGHT - PADDLE_W (317 - 50 = 267)
    MOV AX, WALL_RIGHT
    SUB AX, PADDLE_W
    CMP paddleX, AX
    JLE MP_CHECK_CHANGED
    MOV paddleX, AX

MP_CHECK_CHANGED:
    ; Only redraw if position actually changed
    MOV AX, oldPaddleX
    CMP AX, paddleX
    JE  MP_NO_MOVE

    ; Erase old paddle
    MOV AX, oldPaddleX
    CALL ERASE_PADDLE

    ; Draw new paddle
    CALL DRAW_PADDLE

MP_NO_MOVE:
    POP BX
    POP AX
    RET
MOVE_PADDLE ENDP

;--------------------------------------------------------------
; MOVE_BALL — adds ballDX to ballX, ballDY to ballY.
; Ball is erased BEFORE this call, drawn AFTER collision checks.
;--------------------------------------------------------------
MOVE_BALL PROC
    PUSH AX

    MOV AX, ballDX
    ADD ballX, AX

    MOV AX, ballDY
    ADD ballY, AX

    POP AX
    RET
MOVE_BALL ENDP

;--------------------------------------------------------------
; CHECK_WALL_COLLISION — checks ball against left, right, and
; top walls. Reverses dX or dY as needed.
; Bottom miss is handled separately in the game loop.
;--------------------------------------------------------------
CHECK_WALL_COLLISION PROC
    PUSH AX

    ; --- Left wall: if ballX < WALL_LEFT ---
    MOV AX, ballX
    CMP AX, WALL_LEFT
    JGE CWC_CHK_RIGHT
    MOV ballX, WALL_LEFT
    NEG ballDX              ; reverse horizontal direction
    JMP CWC_CHK_TOP

CWC_CHK_RIGHT:
    ; --- Right wall: if ballX + BALL_SIZE > WALL_RIGHT ---
    MOV AX, ballX
    ADD AX, BALL_SIZE
    CMP AX, WALL_RIGHT
    JLE CWC_CHK_TOP
    MOV AX, WALL_RIGHT
    SUB AX, BALL_SIZE
    MOV ballX, AX
    NEG ballDX

CWC_CHK_TOP:
    ; --- Top wall: if ballY < FIELD_TOP ---
    MOV AX, ballY
    CMP AX, FIELD_TOP
    JGE CWC_DONE
    MOV ballY, FIELD_TOP
    NEG ballDY              ; reverse vertical direction

CWC_DONE:
    POP AX
    RET
CHECK_WALL_COLLISION ENDP

;--------------------------------------------------------------
; CHECK_PADDLE_COLLISION — checks if ball overlaps the paddle
; rectangle. If so, reverses dY (ball bounces up).
; Also adjusts dX based on where the ball hits the paddle
; (left third = force left, right third = force right).
;--------------------------------------------------------------
CHECK_PADDLE_COLLISION PROC
    PUSH AX
    PUSH BX
    PUSH CX

    ; Only check if ball is moving downward
    CMP ballDY, 0
    JL  CPC_DONE           ; ball going up, skip

    ; Check vertical overlap:
    ; Ball bottom (ballY + BALL_SIZE) must reach paddle top (PADDLE_Y)
    ; and ball top (ballY) must be above paddle bottom (PADDLE_Y + PADDLE_H)
    MOV AX, ballY
    ADD AX, BALL_SIZE
    CMP AX, PADDLE_Y
    JL  CPC_DONE            ; ball above paddle

    MOV AX, ballY
    MOV BX, PADDLE_Y
    ADD BX, PADDLE_H
    CMP AX, BX
    JG  CPC_DONE            ; ball below paddle

    ; Check horizontal overlap:
    ; Ball right (ballX + BALL_SIZE) > paddle left (paddleX)
    ; Ball left (ballX) < paddle right (paddleX + PADDLE_W)
    MOV AX, ballX
    ADD AX, BALL_SIZE
    CMP AX, paddleX
    JLE CPC_DONE            ; ball entirely to left of paddle

    MOV AX, ballX
    MOV BX, paddleX
    ADD BX, PADDLE_W
    CMP AX, BX
    JGE CPC_DONE            ; ball entirely to right of paddle

    ; --- COLLISION CONFIRMED ---
    ; Place ball just above paddle to prevent re-triggering
    MOV AX, PADDLE_Y
    SUB AX, BALL_SIZE
    MOV ballY, AX

    ; Reverse vertical direction (bounce up)
    NEG ballDY

    ; --- Angle adjustment based on hit position ---
    ; hitPos = ballX + BALL_SIZE/2 - paddleX (center of ball relative to paddle left)
    MOV AX, ballX
    ADD AX, BALL_SIZE / 2
    SUB AX, paddleX         ; AX = relative hit position (0 to PADDLE_W)

    ; Divide paddle into thirds:
    ; Left third: 0 to PADDLE_W/3 (~16) -> force dX = -2
    ; Middle third: 17 to 33 -> keep dX
    ; Right third: 34 to 50 -> force dX = +2

    MOV BX, PADDLE_W
    MOV CX, 3
    PUSH DX
    XOR DX, DX
    PUSH AX
    MOV AX, BX
    DIV CX                  ; AX = PADDLE_W / 3
    MOV BX, AX              ; BX = one-third width
    POP AX
    POP DX

    CMP AX, BX
    JL  CPC_FORCE_LEFT      ; hit left third

    ; Check if in right third (hit > 2 * one-third)
    PUSH BX
    SHL BX, 1               ; BX = 2/3 of paddle width
    CMP AX, BX
    POP BX
    JG  CPC_FORCE_RIGHT

    ; Middle third — keep existing dX
    JMP CPC_DONE

CPC_FORCE_LEFT:
    CMP ballDX, 0
    JL  CPC_DONE            ; already going left
    NEG ballDX              ; force leftward
    JMP CPC_DONE

CPC_FORCE_RIGHT:
    CMP ballDX, 0
    JG  CPC_DONE            ; already going right
    NEG ballDX              ; force rightward

CPC_DONE:
    POP CX
    POP BX
    POP AX
    RET
CHECK_PADDLE_COLLISION ENDP

;--------------------------------------------------------------
; CHECK_BRICK_COLLISION — checks if ball overlaps any alive brick.
; Uses rectangle math: maps ball center to a (row, col) in the
; brick grid, then checks neighbors to handle edge cases.
; On hit: destroys brick, reverses dY, updates score.
;--------------------------------------------------------------
CHECK_BRICK_COLLISION PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; Compute ball center
    MOV AX, ballX
    ADD AX, BALL_SIZE / 2   ; ball center X
    MOV BX, ballY
    ADD AX, 0               ; keep in AX
    ADD BX, BALL_SIZE / 2   ; ball center Y in BX

    ; Check if ball center is within the brick area at all
    ; Brick area X: BRICK_STARTX to BRICK_STARTX + NUM_COLS * BRICK_COLSTR
    ; Brick area Y: BRICK_STARTY to BRICK_STARTY + NUM_ROWS * BRICK_ROWSTR
    CMP AX, BRICK_STARTX
    JL  CBC_NONE
    CMP BX, BRICK_STARTY
    JL  CBC_NONE

    MOV CX, BRICK_STARTX
    ADD CX, NUM_COLS * BRICK_COLSTR
    CMP AX, CX
    JGE CBC_NONE

    MOV CX, BRICK_STARTY
    ADD CX, NUM_ROWS * BRICK_ROWSTR
    CMP BX, CX
    JGE CBC_NONE

    ; Map to column: col = (ballCenterX - BRICK_STARTX) / BRICK_COLSTR
    SUB AX, BRICK_STARTX
    XOR DX, DX
    MOV CX, BRICK_COLSTR
    DIV CX                  ; AX = col, DX = remainder
    MOV DI, AX              ; DI = col

    ; Map to row: row = (ballCenterY - BRICK_STARTY) / BRICK_ROWSTR
    MOV AX, BX
    SUB AX, BRICK_STARTY
    XOR DX, DX
    MOV CX, BRICK_ROWSTR
    DIV CX                  ; AX = row, DX = remainder
    MOV SI, AX              ; SI = row

    ; Bounds check
    CMP SI, NUM_ROWS
    JGE CBC_NONE
    CMP DI, NUM_COLS
    JGE CBC_NONE

    ; Compute grid index = row * NUM_COLS + col
    MOV AX, SI
    IMUL AX, NUM_COLS
    ADD AX, DI
    MOV BX, AX              ; BX = grid index

    ; Check if brick is alive
    CMP brickGrid[BX], 1
    JNE CBC_NONE

    ; --- BRICK HIT ---
    ; Mark as dead
    MOV brickGrid[BX], 0
    DEC bricksLeft

    ; Add 10 points
    ADD score, 10
    MOV hudDirty, 1

    ; Erase the brick from screen
    MOV AX, DI              ; col
    IMUL AX, BRICK_COLSTR
    ADD AX, BRICK_STARTX
    MOV rectX, AX

    MOV AX, SI              ; row
    IMUL AX, BRICK_ROWSTR
    ADD AX, BRICK_STARTY
    MOV rectY, AX

    MOV rectW, BRICK_W
    MOV rectH, BRICK_H
    MOV rectColor, 0
    CALL DRAW_RECT

    ; Reverse vertical direction
    NEG ballDY

CBC_NONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CHECK_BRICK_COLLISION ENDP

;--------------------------------------------------------------
; CHECK_BALL_MISS — checks if ball has fallen below FIELD_BOT.
; If so: decrements lives, resets ball, shows brief pause.
; Sets gameOver=1 if lives reach 0.
;--------------------------------------------------------------
CHECK_BALL_MISS PROC
    PUSH AX
    PUSH CX

    MOV AX, ballY
    CMP AX, FIELD_BOT
    JL  CBM_DONE            ; ball still in play

    ; --- Ball missed ---
    DEC lives
    MOV hudDirty, 1

    CMP lives, 0
    JLE CBM_GAME_OVER

    ; Reset ball to center, heading up
    MOV ballX, 158
    MOV ballY, 120
    MOV ballDX, 2
    MOV ballDY, -2

    ; Brief "GET READY!" message
    MOV SI, OFFSET sReady
    MOV BX, 120
    MOV CX, 100
    MOV DL, 14
    CALL DRAW_STRING

    ; Update HUD immediately to show new lives count
    CALL DRAW_HUD

    ; Pause so player can prepare
    MOV CX, 30
    CALL DELAY_TICKS

    ; Erase the message
    MOV rectX, 110
    MOV rectY, 98
    MOV rectW, 120
    MOV rectH, 12
    MOV rectColor, 0
    CALL DRAW_RECT

    ; Draw ball at new position
    CALL DRAW_BALL

    JMP CBM_DONE

CBM_GAME_OVER:
    MOV gameOver, 1

CBM_DONE:
    POP CX
    POP AX
    RET
CHECK_BALL_MISS ENDP

;--------------------------------------------------------------
; FRAME_DELAY — controls game speed. Tunable delay loop.
; Adjust the outer count to speed up or slow down the game.
;--------------------------------------------------------------
FRAME_DELAY PROC
    PUSH CX
    PUSH DX

    MOV CX, 1              ; outer loop count — increase to slow down
FD_OUTER:
    CMP CX, 0
    JE  FD_DONE
    MOV DX, 0C000h         ; inner loop — tune this value
FD_INNER:
    DEC DX
    JNZ FD_INNER
    DEC CX
    JMP FD_OUTER

FD_DONE:
    POP DX
    POP CX
    RET
FRAME_DELAY ENDP

;--------------------------------------------------------------
; GAME_LOOP — the main gameplay loop for Level 1.
; Follows the mandatory architecture from the project spec:
;   1. Read input
;   2. Update paddle
;   3. Erase ball
;   4. Move ball
;   5. Check collisions: walls -> paddle -> bricks
;   6. Handle ball miss (life loss)
;   7. Draw ball
;   8. Update HUD if dirty
;   9. Frame delay
;  10. Check game-end conditions
;  11. Loop back
;--------------------------------------------------------------
GAME_LOOP PROC

GL_FRAME:
    ; Step 1: Read keyboard input (non-blocking)
    CALL READ_INPUT

    ; Step 2: Update paddle position
    CALL MOVE_PADDLE

    ; Check if game was aborted (ESC pressed)
    CMP gameOver, 1
    JE  GL_EXIT

    ; Step 3: Erase ball at current position
    CALL ERASE_BALL

    ; Step 4: Compute new ball position
    CALL MOVE_BALL

    ; Step 5: Check collisions in order: walls, paddle, bricks
    CALL CHECK_WALL_COLLISION
    CALL CHECK_PADDLE_COLLISION
    CALL CHECK_BRICK_COLLISION

    ; Step 6: Check if ball fell below paddle
    CALL CHECK_BALL_MISS

    ; Check if game ended (lives = 0)
    CMP gameOver, 1
    JE  GL_EXIT

    ; Step 7: Draw ball at new position
    CALL DRAW_BALL

    ; Step 8: Update HUD if needed
    CMP hudDirty, 1
    JNE GL_SKIP_HUD
    CALL DRAW_HUD
GL_SKIP_HUD:

    ; Step 9: Frame delay
    CALL FRAME_DELAY

    ; Step 10: Check if all bricks are gone (level cleared)
    CMP bricksLeft, 0
    JE  GL_EXIT

    ; Step 11: Loop back
    JMP GL_FRAME

GL_EXIT:
    RET
GAME_LOOP ENDP

;--------------------------------------------------------------
; SHOW_GAME_OVER — displays Game Over screen with final score.
; Waits for a keypress, then returns (caller sends to menu).
;--------------------------------------------------------------
SHOW_GAME_OVER PROC
    MOV AL, 0
    CALL CLEAR_SCREEN

    ; Red banner at top
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 28
    MOV rectColor, 4
    CALL DRAW_RECT

    ; "GAME OVER" title
    MOV SI, OFFSET sGameOver
    MOV BX, 117
    MOV CX, 10
    MOV DL, 15
    CALL DRAW_STRING

    ; Box around score area
    MOV rectX, 60
    MOV rectY, 60
    MOV rectW, 200
    MOV rectH, 60
    MOV rectColor, 15
    CALL DRAW_RECT_BORDER

    MOV rectX, 61
    MOV rectY, 61
    MOV rectW, 198
    MOV rectH, 58
    MOV rectColor, 0
    CALL DRAW_RECT

    ; "FINAL SCORE:" label
    MOV SI, OFFSET sFinalSc
    MOV BX, 90
    MOV CX, 75
    MOV DL, 14
    CALL DRAW_STRING

    ; Score value
    CALL SCORE_TO_ASCII
    MOV SI, OFFSET scoreBuf
    MOV BX, 130
    MOV CX, 95
    MOV DL, 15
    CALL DRAW_STRING

    ; Player name
    MOV BX, 110
    MOV CX, 140
    MOV DL, 11
    MOV SI, 0
SGO_NAME:
    MOV AL, playerName[SI]
    CMP AL, 0
    JE  SGO_NAME_DONE
    CALL DRAW_CHAR
    ADD BX, 9
    INC SI
    CMP SI, 15
    JL  SGO_NAME
SGO_NAME_DONE:

    ; Footer
    MOV rectX, 0
    MOV rectY, 184
    MOV rectW, 320
    MOV rectH, 16
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV SI, OFFSET sRetMenu
    MOV BX, 54
    MOV CX, 188
    MOV DL, 15
    CALL DRAW_STRING

    CALL WAIT_KEY
    RET
SHOW_GAME_OVER ENDP


;================================================================
; SECTION 5: RUN_GAME — orchestrates level load + game loop
; + game over / level complete handling.
; For Iteration 2: only Level 1 is implemented.
;================================================================

RUN_GAME PROC
    ; Initialize all game state for Level 1
    CALL LOAD_LEVEL

    ; Draw the full initial screen (HUD, walls, bricks, paddle, ball)
    CALL DRAW_INITIAL_SCREEN

    ; Run the game loop until game ends
    CALL GAME_LOOP

    ; --- Game loop has exited ---
    ; Determine why: game over (lives=0) or all bricks cleared

    CMP lives, 0
    JLE RG_GAME_OVER

    ; Bricks cleared or ESC pressed — for Iteration 2, show game over
    ; (Win screen is Iteration 3)
    JMP RG_GAME_OVER

RG_GAME_OVER:
    CALL SHOW_GAME_OVER

    RET
RUN_GAME ENDP


;================================================================
; SECTION 6: EXIT & MAIN
;================================================================

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
    CALL RUN_GAME           ; <<< Iteration 2: launches actual gameplay
    JMP MAIN_LOOP

DO_INSTR:
    CALL SHOW_INSTRUCTIONS
    JMP MAIN_LOOP

DO_HI:
    CALL SHOW_HIGH_SCORES
    JMP MAIN_LOOP

MAIN ENDP

END MAIN