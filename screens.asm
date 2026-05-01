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

;==============================================================
; SHOW_NAME_INPUT — collects up to 15 characters into playerName
; Backspace deletes last char, Enter confirms and returns.
;==============================================================
SHOW_NAME_INPUT PROC
    MOV AL, 8
    CALL CLEAR_SCREEN

    ; --- Top header bar (blue) ---
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 1
    CALL DRAW_RECT

    ; --- Title "NAME INPUT" ---
    ; N-A-M-E [space] I-N-P-U-T
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
    ADD BX, 15            ; word break: end of "NAME"
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

    ; --- Prompt: "ENTER YOUR NAME:" ---
    MOV CX, 68
    MOV DL, 15
    MOV BX, 75
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
    ADD BX, 15            ; word break: end of "ENTER"
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
    ADD BX, 15            ; word break: end of "YOUR"
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

    ; --- Input box ---
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

    ; --- Hint: "MAX 15 CHARS" ---
    MOV CX, 115
    MOV DL, 7
    MOV BX, 110
    MOV AL, 'M'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'X'
    CALL DRAW_CHAR
    ADD BX, 15            ; word break: end of "MAX"
    MOV AL, '1'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '5'
    CALL DRAW_CHAR
    ADD BX, 15            ; word break: end of "15"
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

    ; --- Hint: "PRESS ENTER TO CONFIRM" ---
    MOV CX, 130
    MOV DL, 7
    MOV BX, 60
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
    ADD BX, 15            ; word break: end of "PRESS"
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
    ADD BX, 15            ; word break: end of "ENTER"
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 15            ; word break: end of "TO"
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

    ; --- Initialize buffer ---
    MOV nameLen, 0
    MOV CX, 16
    MOV SI, 0
NI_CLEAR:
    MOV playerName[SI], 0
    INC SI
    LOOP NI_CLEAR

;-----------------------------------------------------------
; INPUT LOOP — reads one key at a time
;-----------------------------------------------------------
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

    ; Position next typed char inside box
    MOVZX BX, nameLen
    DEC BX
    IMUL BX, 9            ; 9 px per char (consistent with DRAW_CHAR width)
    ADD BX, 63            ; left margin inside box

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
; SHOW_MAIN_MENU — draws the main menu and handles UP/DOWN/ENTER
; Returns selected index in AL (0=Start, 1=Instr, 2=HiScore, 3=Exit)
;==============================================================
SHOW_MAIN_MENU PROC
    MOV menuSel, 0

MM_REDRAW:
    ; --- Background ---
    MOV AL, 0
    CALL CLEAR_SCREEN

    ; --- Top banner bar ---
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 28
    MOV rectColor, 1
    CALL DRAW_RECT

    ; --- Title "BRICK BREAKER" centered in banner ---
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

    ; --- Draw the four menu boxes/options ---
    CALL DRAW_MENU_ITEMS

    ; --- Footer: "PL: <name>" ---
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

    ; Draw player name beside "PL:"
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

    ; --- Footer help text: "UP/DOWN ENTER" ---
    MOV CX, 188
    MOV DL, 8
    MOV BX, 200
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, '/'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 10
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

MM_KEY_LOOP:
    MOV AH, 00h
    INT 16h

    CMP AH, 48h          ; Up arrow scan code
    JE  MM_UP
    CMP AH, 50h          ; Down arrow scan code
    JE  MM_DOWN
    CMP AL, 0Dh          ; Enter
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


;==============================================================
; DRAW_MENU_ITEMS — draws all 4 menu options.
; Uses BP as the loop counter so it is NOT destroyed by the
; many BX/CX/AX changes inside the drawing code.
;==============================================================
DRAW_MENU_ITEMS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH BP

    MOV BP, 0            ; BP = current menu index (0..3)

DMI_LOOP:
    CMP BP, 4
    JGE DMI_DONE

    ; --- Compute box rectangle ---
    MOV AX, BP
    IMUL AX, 32
    ADD AX, 38
    MOV rectY, AX
    MOV rectX, 60
    MOV rectW, 200
    MOV rectH, 24

    ; --- Pick colors based on whether this item is selected ---    
    MOV AL, menuSel
    MOVZX BX, AL
    CMP BP, BX
    JE  DMI_SELECTED

    ; --- Unselected: dark grey box, light grey border ---
    MOV rectColor, 8
    CALL DRAW_RECT
    MOV rectColor, 7
    CALL DRAW_RECT_BORDER
    JMP DMI_TEXT

DMI_SELECTED:
    ; --- Selected: brown fill, yellow border ---
    MOV rectColor, 6
    CALL DRAW_RECT
    MOV rectColor, 14
    CALL DRAW_RECT_BORDER

    ; --- Draw '>' arrow indicator on the left ---
    MOV AX, BP
    IMUL AX, 32
    ADD AX, 38 + 8         ; vertical text position inside box
    MOV CX, AX
    MOV BX, 66             ; X position of arrow
    MOV AL, '>'
    MOV DL, 14
    CALL DRAW_CHAR

DMI_TEXT:
    ; --- Compute Y position for option text ---
    MOV AX, BP
    IMUL AX, 32
    ADD AX, 38 + 8
    MOV CX, AX
    MOV DL, 15

    ; --- Dispatch to the correct label-drawing block ---
    CMP BP, 0
    JE  DMI_ITEM0
    CMP BP, 1
    JE  DMI_ITEM1
    CMP BP, 2
    JE  DMI_ITEM2
    JMP DMI_ITEM3

DMI_ITEM0:                 ; "START GAME"
    MOV BX, 110
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
    ADD BX, 8
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

DMI_ITEM1:                 ; "INSTRUCTIONS"
    MOV BX, 102
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

DMI_ITEM2:                 ; "HIGH SCORES"
    MOV BX, 108
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
    ADD BX, 8
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

DMI_ITEM3:                 ; "EXIT"
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
; SHOW_INSTRUCTIONS — explains controls, objective, lives, bonuses
; Returns to caller (Main Menu) when any key is pressed
;==============================================================
SHOW_INSTRUCTIONS PROC
    ; --- Background ---
    MOV AL, 0
    CALL CLEAR_SCREEN

    ; --- Top header bar (green) ---
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 2
    CALL DRAW_RECT

    ; --- Header underline ---
    MOV rectX, 0
    MOV rectY, 22
    MOV rectW, 320
    MOV rectH, 1
    MOV rectColor, 10
    CALL DRAW_RECT

    ; --- Title "INSTRUCTIONS" ---
    MOV BX, 102
    MOV CX, 7
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

    ;-----------------------------------------------------------
    ; SECTION 1: CONTROLS (yellow heading)
    ;-----------------------------------------------------------
    ; Yellow bullet square
    MOV rectX, 12
    MOV rectY, 33
    MOV rectW, 4
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT

    MOV BX, 22
    MOV CX, 33
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

    ; Body: "A / D OR ARROW = MOVE PADDLE"
    MOV BX, 30
    MOV CX, 47
    MOV DL, 7
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, '/'
    CALL DRAW_CHAR
    ADD BX, 10
    MOV AL, 'D'
    CALL DRAW_CHAR
    ADD BX, 12
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 12
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
    ADD BX, 12
    MOV AL, '='
    CALL DRAW_CHAR
    ADD BX, 12
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
    ADD BX, 12
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'D'
    CALL DRAW_CHAR

    ;-----------------------------------------------------------
    ; SECTION 2: OBJECTIVE
    ;-----------------------------------------------------------
    MOV rectX, 12
    MOV rectY, 65
    MOV rectW, 4
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT

    MOV BX, 22
    MOV CX, 65
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

    ; Body: "BREAK ALL BRICKS TO ADVANCE"
    MOV BX, 30
    MOV CX, 79
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
    ADD BX, 11
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 11
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
    ADD BX, 11
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 11
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

    ;-----------------------------------------------------------
    ; SECTION 3: LIVES & BALL RULES
    ;-----------------------------------------------------------
    MOV rectX, 12
    MOV rectY, 97
    MOV rectW, 4
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT

    MOV BX, 22
    MOV CX, 97
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
    ADD BX, 11
    MOV AL, '&'
    CALL DRAW_CHAR
    ADD BX, 11
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

    ; Body line 1: "START WITH 3 LIVES"
    MOV BX, 30
    MOV CX, 111
    MOV DL, 7
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
    ADD BX, 11
    MOV AL, 'W'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'H'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, '3'
    CALL DRAW_CHAR
    ADD BX, 11
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

    ; Body line 2: "MISS BALL = LOSE 1 LIFE"
    MOV BX, 30
    MOV CX, 122
    MOV DL, 7
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
    ADD BX, 11
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
    ADD BX, 11
    MOV AL, '='
    CALL DRAW_CHAR
    ADD BX, 11
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
    ADD BX, 11
    MOV AL, '1'
    CALL DRAW_CHAR

    ;-----------------------------------------------------------
    ; SECTION 4: BONUSES (with colored sample squares)
    ;-----------------------------------------------------------
    MOV rectX, 12
    MOV rectY, 138
    MOV rectW, 4
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT

    MOV BX, 22
    MOV CX, 138
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

    ; Cyan square + "SLOW BALL"
    MOV rectX, 30
    MOV rectY, 152
    MOV rectW, 8
    MOV rectH, 8
    MOV rectColor, 3
    CALL DRAW_RECT

    MOV BX, 44
    MOV CX, 152
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
    ADD BX, 11
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

    ; Green square + "EXTRA LIFE"
    MOV rectX, 165
    MOV rectY, 152
    MOV rectW, 8
    MOV rectH, 8
    MOV rectColor, 2
    CALL DRAW_RECT

    MOV BX, 179
    MOV CX, 152
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
    ADD BX, 11
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

    ; Yellow square + "WIDE PADDLE" (centered below)
    MOV rectX, 95
    MOV rectY, 166
    MOV rectW, 8
    MOV rectH, 8
    MOV rectColor, 14
    CALL DRAW_RECT

    MOV BX, 109
    MOV CX, 166
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
    ADD BX, 11
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

    ;-----------------------------------------------------------
    ; FOOTER: "PRESS ANY KEY TO RETURN"
    ;-----------------------------------------------------------
    MOV rectX, 0
    MOV rectY, 184
    MOV rectW, 320
    MOV rectH, 16
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV BX, 60
    MOV CX, 188
    MOV DL, 15
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
    ADD BX, 11
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'Y'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, 'K'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'Y'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR

    CALL WAIT_KEY
    RET
SHOW_INSTRUCTIONS ENDP


;==============================================================
; SHOW_HIGH_SCORES — displays top 5 static high scores in a
; clean tabular format with borders and column separators
;==============================================================
SHOW_HIGH_SCORES PROC
    MOV AL, 0
    CALL CLEAR_SCREEN

    ; --- Top header bar (blue) ---
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 9
    CALL DRAW_RECT

    ; --- Title "HIGH SCORES" ---
    MOV BX, 108
    MOV CX, 7
    MOV DL, 15
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
    ADD BX, 11
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

    ;-----------------------------------------------------------
    ; TABLE OUTER BORDER (white box around full table)
    ;-----------------------------------------------------------
    MOV rectX, 20
    MOV rectY, 32
    MOV rectW, 280
    MOV rectH, 140
    MOV rectColor, 15
    CALL DRAW_RECT_BORDER

    ;-----------------------------------------------------------
    ; HEADER ROW (dark grey background)
    ;-----------------------------------------------------------
    MOV rectX, 21
    MOV rectY, 33
    MOV rectW, 278
    MOV rectH, 14
    MOV rectColor, 8
    CALL DRAW_RECT

    ; Header underline
    MOV rectX, 20
    MOV rectY, 47
    MOV rectW, 280
    MOV rectH, 1
    MOV rectColor, 15
    CALL DRAW_RECT

    ; "RANK" header
    MOV BX, 35
    MOV CX, 36
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

    ; "NAME" header
    MOV BX, 130
    MOV CX, 36
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

    ; "SCORE" header
    MOV BX, 230
    MOV CX, 36
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

    ;-----------------------------------------------------------
    ; VERTICAL COLUMN SEPARATORS
    ;-----------------------------------------------------------
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

    ;-----------------------------------------------------------
    ; ROW 1: ALI - 05000  (Y=50)
    ;-----------------------------------------------------------
    MOV BX, 45
    MOV CX, 54
    MOV DL, 14
    MOV AL, '1'
    CALL DRAW_CHAR

    MOV BX, 100
    MOV DL, 11
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'I'
    CALL DRAW_CHAR

    MOV BX, 232
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

    ; Row separator
    MOV rectX, 21
    MOV rectY, 72
    MOV rectW, 278
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT

    ;-----------------------------------------------------------
    ; ROW 2: SARA - 04200  (Y=78)
    ;-----------------------------------------------------------
    MOV BX, 45
    MOV CX, 78
    MOV DL, 14
    MOV AL, '2'
    CALL DRAW_CHAR

    MOV BX, 100
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

    MOV BX, 232
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

    MOV rectX, 21
    MOV rectY, 96
    MOV rectW, 278
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT

    ;-----------------------------------------------------------
    ; ROW 3: USMAN - 03800  (Y=102)
    ;-----------------------------------------------------------
    MOV BX, 45
    MOV CX, 102
    MOV DL, 14
    MOV AL, '3'
    CALL DRAW_CHAR

    MOV BX, 100
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

    MOV BX, 232
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

    MOV rectX, 21
    MOV rectY, 120
    MOV rectW, 278
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT

    ;-----------------------------------------------------------
    ; ROW 4: AYESHA - 02500  (Y=126)
    ;-----------------------------------------------------------
    MOV BX, 45
    MOV CX, 126
    MOV DL, 14
    MOV AL, '4'
    CALL DRAW_CHAR

    MOV BX, 100
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

    MOV BX, 232
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

    MOV rectX, 21
    MOV rectY, 144
    MOV rectW, 278
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT

    ;-----------------------------------------------------------
    ; ROW 5: BILAL - 01100  (Y=150)
    ;-----------------------------------------------------------
    MOV BX, 45
    MOV CX, 150
    MOV DL, 14
    MOV AL, '5'
    CALL DRAW_CHAR

    MOV BX, 100
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

    MOV BX, 232
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

    ;-----------------------------------------------------------
    ; FOOTER: "PRESS ANY KEY TO RETURN"
    ;-----------------------------------------------------------
    MOV rectX, 0
    MOV rectY, 184
    MOV rectW, 320
    MOV rectH, 16
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV BX, 60
    MOV CX, 188
    MOV DL, 15
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
    ADD BX, 11
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'Y'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, 'K'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'Y'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR

    CALL WAIT_KEY
    RET
SHOW_HIGH_SCORES ENDP


;==============================================================
; SHOW_GAME_SCREEN — static layout for Iteration 1.
; Shows HUD bar, brick grid, paddle, and ball. Non-interactive
; placeholder; in Iteration 2 this becomes the live game loop.
;==============================================================
SHOW_GAME_SCREEN PROC
    MOV AL, 0
    CALL CLEAR_SCREEN

    ;-----------------------------------------------------------
    ; HUD BAR (Y: 0-14, separated from play field by line at Y=14)
    ;-----------------------------------------------------------
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 14
    MOV rectColor, 1
    CALL DRAW_RECT

    ; HUD/Play-field separator
    MOV rectX, 0
    MOV rectY, 14
    MOV rectW, 320
    MOV rectH, 1
    MOV rectColor, 9
    CALL DRAW_RECT

    ; --- "SC:" label + "0" value (score, leftmost) ---
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

    MOV BX, 32
    MOV DL, 15
    MOV AL, '0'
    CALL DRAW_CHAR

    ; --- "LV:" label + "1" value (level) ---
    MOV BX, 75
    MOV DL, 14
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'V'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR

    MOV BX, 104
    MOV DL, 15
    MOV AL, '1'
    CALL DRAW_CHAR

    ; --- "LF:" label + "3" value (lives) ---
    MOV BX, 135
    MOV DL, 14
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'F'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR

    MOV BX, 164
    MOV DL, 10
    MOV AL, '3'
    CALL DRAW_CHAR

    ; --- "PL:" label + player name (right side) ---
    MOV BX, 195
    MOV DL, 14
    MOV AL, 'P'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'L'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, ':'
    CALL DRAW_CHAR

    MOV BX, 224
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

    ;-----------------------------------------------------------
    ; PLAY FIELD SIDE WALLS (Y: 15-180, X: 0-2 and 317-319)
    ;-----------------------------------------------------------
    MOV rectX, 0
    MOV rectY, 15
    MOV rectW, 3
    MOV rectH, 166
    MOV rectColor, 9
    CALL DRAW_RECT

    MOV rectX, 317
    MOV rectY, 15
    MOV rectW, 3
    MOV rectH, 166
    MOV rectColor, 9
    CALL DRAW_RECT

    ;-----------------------------------------------------------
    ; BRICK GRID — 5 rows × 13 columns
    ; Brick: 22 wide × 8 tall, 1px gap, starts at (5, 22)
    ;-----------------------------------------------------------
    MOV BX, 0                  ; BX = current row (0..4)
GS_BROW:
    CMP BX, 5
    JGE GS_BRICKS_DONE

    MOV CX, 0                  ; CX = current column (0..12)
GS_BCOL:
    CMP CX, 13
    JGE GS_BROW_NEXT

    ; rectX = column * 23 + 5
    MOV AX, CX
    IMUL AX, 23
    ADD AX, 5
    MOV rectX, AX

    ; rectY = row * 9 + 22
    MOV AX, BX
    IMUL AX, 9
    ADD AX, 22
    MOV rectY, AX

    MOV rectW, 22
    MOV rectH, 8

    ; Color depends on row: red, yellow, green, cyan, magenta
    MOV AX, BX
    CMP AX, 0
    JE  GS_BC0
    CMP AX, 1
    JE  GS_BC1
    CMP AX, 2
    JE  GS_BC2
    CMP AX, 3
    JE  GS_BC3
    MOV rectColor, 5
    JMP GS_BDRAW
GS_BC0: MOV rectColor, 4       ; red
    JMP GS_BDRAW
GS_BC1: MOV rectColor, 14      ; yellow
    JMP GS_BDRAW
GS_BC2: MOV rectColor, 2       ; green
    JMP GS_BDRAW
GS_BC3: MOV rectColor, 3       ; cyan
GS_BDRAW:
    CALL DRAW_RECT

    INC CX
    JMP GS_BCOL

GS_BROW_NEXT:
    INC BX
    JMP GS_BROW
GS_BRICKS_DONE:

    ;-----------------------------------------------------------
    ; BALL — 4×4 white square in mid play field
    ;-----------------------------------------------------------
    MOV rectX, 158
    MOV rectY, 120
    MOV rectW, 4
    MOV rectH, 4
    MOV rectColor, 15
    CALL DRAW_RECT

    ;-----------------------------------------------------------
    ; PADDLE — 50×5 grey rectangle near bottom (Y: 185-189)
    ;-----------------------------------------------------------
    MOV rectX, 135
    MOV rectY, 185
    MOV rectW, 50
    MOV rectH, 5
    MOV rectColor, 7
    CALL DRAW_RECT

    ; Highlight strip on top of paddle
    MOV rectX, 135
    MOV rectY, 185
    MOV rectW, 50
    MOV rectH, 1
    MOV rectColor, 15
    CALL DRAW_RECT

    ;-----------------------------------------------------------
    ; FOOTER: "PRESS ANY KEY TO RETURN"
    ;-----------------------------------------------------------
    MOV BX, 60
    MOV CX, 194
    MOV DL, 7
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
    ADD BX, 11
    MOV AL, 'A'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'Y'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, 'K'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'Y'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'O'
    CALL DRAW_CHAR
    ADD BX, 11
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'E'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'T'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'U'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'R'
    CALL DRAW_CHAR
    ADD BX, 9
    MOV AL, 'N'
    CALL DRAW_CHAR

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
