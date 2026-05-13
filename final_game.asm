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

    ; --- Ball trail (last 3 positions for fading trail) ---
    trailX      DW  158, 158, 158    ; X positions [0]=newest [2]=oldest
    trailY      DW  120, 120, 120    ; Y positions
    trailInit   DB  0                ; 0 = trail not yet valid

    ; --- Mouse support ---
    mouseActive DB  0                ; 1 = mouse driver detected
    lastMouseX  DW  160              ; last known mouse X (virtual coords)

    ; --- Paddle state ---
    paddleX     DW  135
    prevPaddleX DW  135         ; previous frame paddleX (for motion influence)
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

    ; --- Level-dependent speed/timing ---
    ballSpeed   DW  2            ; current ball speed (level 1=2, 2=2, 3=3)
    gameDelay   DW  2            ; frame delay (level 1=2, 2=1, 3=1)

    ; --- Brick layouts for all levels ---
    ;   0 = empty, 1 = breakable brick, 2 = indestructible barrier

    ; Level 1: Full grid (65 bricks)
    brickLayout1 DB 1,1,1,1,1,1,1,1,1,1,1,1,1
                 DB 1,1,1,1,1,1,1,1,1,1,1,1,1
                 DB 1,1,1,1,1,1,1,1,1,1,1,1,1
                 DB 1,1,1,1,1,1,1,1,1,1,1,1,1
                 DB 1,1,1,1,1,1,1,1,1,1,1,1,1

    ; Level 2: Checkerboard with barriers (33 bricks + 32 barriers)
    brickLayout2 DB 1,2,1,2,1,2,1,2,1,2,1,2,1
                 DB 0,1,0,1,0,1,0,1,0,1,0,1,0
                 DB 2,1,0,1,2,1,2,1,2,1,0,1,2
                 DB 1,0,1,0,1,0,1,0,1,0,1,0,1
                 DB 2,2,2,1,1,1,1,1,1,1,2,2,2

    ; Level 3: Diamond/fortress pattern (53 bricks)
    brickLayout3 DB 0,0,1,1,1,1,1,1,1,1,1,0,0
                 DB 0,1,2,1,2,1,1,1,2,1,2,1,0
                 DB 1,1,2,1,1,1,2,1,1,1,2,1,1
                 DB 0,1,2,1,2,1,1,1,2,1,2,1,0
                 DB 0,0,1,1,1,1,1,1,1,1,1,0,0

    ; --- HUD caching: draw bar only once, refresh only values ---
    hudDrawn    DB  0           ; 0 = need full redraw, 1 = bar already drawn
    lastScore   DW  0FFFFh      ; Last drawn score (sentinel != 0)
    lastLives   DB  0FFh        ; Last drawn lives (sentinel)

    ; --- Power-up system ---
    puActive    DB  0           ; 0 = no power-up on screen, 1 = falling
    puX         DW  0           ; power-up X position
    puY         DW  0           ; power-up Y position
    puType      DB  0           ; 0=Slow, 1=Fast, 2=ExtraLife, 3=PaddleUp
    puW         EQU 10          ; power-up width
    puH         EQU 6           ; power-up height
    puSpeed     EQU 2           ; fall speed (pixels per frame)
    rngState    DW  12345       ; RNG seed

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
    ; --- High score table: 5 entries, each = 16 bytes name + 2 bytes score (WORD) ---
    ; Total per entry = 18 bytes, table = 90 bytes
    hsNames     DB 'ESHAL FATIMA',0,0,0,0        ; entry 0 (16 bytes)
                DB 'DANIYA JADOON',0,0,0          ; entry 1 (16 bytes)
                DB 'MUNEEB BAIG',0,0,0,0,0        ; entry 2 (16 bytes)
                DB 'RANA HANAN',0,0,0,0,0,0        ; entry 3 (16 bytes)
                DB 'MUHAMMAD BILAL',0,0            ; entry 4 (16 bytes)
    hsScores    DW 50, 40, 30, 20, 10    ; 5 x WORD = 10 bytes

    ; --- File handling ---
    hsFileName  DB 'HIGHSCOR.DAT',0
    fileHandle  DW 0
    hsFileSize  EQU 90          ; 5*(16+2) bytes

    ; --- Validation message ---
    sNameReq    DB 'NAME REQUIRED!',0
    sPaused     DB 'PAUSED',0

    ;==============================================================
    ; STRING CONSTANTS (Iteration 2)
    ;==============================================================
    sGameOver   DB 'GAME OVER',0
    sGameWin   DB 'LEVEL COMPLETE!',0
    sGoPlayer   DB 'PLAYER: ',0
    sGoLevel    DB 'LEVEL: ',0
    sGoFinal    DB 'FINAL SCORE: ',0
    sGoEnter    DB 'PRESS ENTER TO RETURN TO MENU',0
    sFinalWin   DB 'ALL LEVELS COMPLETE!',0
    sCongrats   DB 'CONGRATULATIONS!',0
    sNextLvl    DB 'PRESS ENTER FOR NEXT LEVEL',0
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
; PC SPEAKER SOUND PROCEDURES
;   PLAY_SOUND: AX = frequency divisor, CX = duration loops
;   Uses PIT channel 2 (ports 42h/43h) and speaker gate (port 61h)
;==============================================================
PLAY_SOUND PROC
    PUSH AX
    PUSH CX
    PUSH DX

    MOV DX, AX         ; save freq divisor BEFORE overwriting AL

    ; Set PIT channel 2 to mode 3 (square wave)
    MOV AL, 0B6h
    OUT 43h, AL

    ; Set frequency divisor from DX
    MOV AL, DL
    OUT 42h, AL         ; low byte
    MOV AL, DH
    OUT 42h, AL         ; high byte

    ; Turn speaker ON
    IN  AL, 61h
    OR  AL, 03h
    OUT 61h, AL

    ; Delay loop for duration
PS_DELAY:
    MOV DX, 0FFFFh
PS_INNER:
    DEC DX
    JNZ PS_INNER
    LOOP PS_DELAY

    ; Turn speaker OFF
    IN  AL, 61h
    AND AL, 0FCh
    OUT 61h, AL

    POP DX
    POP CX
    POP AX
    RET
PLAY_SOUND ENDP

;--------------------------------------------------------------
; SND_BRICK — short high-pitched tick when brick breaks
;--------------------------------------------------------------
SND_BRICK PROC
    PUSH AX
    PUSH CX
    MOV AX, 2000       ; ~597 Hz
    MOV CX, 1          ; very short
    CALL PLAY_SOUND
    POP CX
    POP AX
    RET
SND_BRICK ENDP

;--------------------------------------------------------------
; SND_PADDLE — low bounce sound when ball hits paddle
;--------------------------------------------------------------
SND_PADDLE PROC
    PUSH AX
    PUSH CX
    MOV AX, 4000       ; ~298 Hz
    MOV CX, 1
    CALL PLAY_SOUND
    POP CX
    POP AX
    RET
SND_PADDLE ENDP

;--------------------------------------------------------------
; SND_WALL — quick blip for wall bounce
;--------------------------------------------------------------
SND_WALL PROC
    PUSH AX
    PUSH CX
    MOV AX, 3000       ; ~398 Hz
    MOV CX, 1
    CALL PLAY_SOUND
    POP CX
    POP AX
    RET
SND_WALL ENDP

;--------------------------------------------------------------
; SND_LIFE_LOST — descending tone when life is lost
;--------------------------------------------------------------
SND_LIFE_LOST PROC
    PUSH AX
    PUSH CX
    MOV AX, 3000
    MOV CX, 2
    CALL PLAY_SOUND
    MOV AX, 5000
    MOV CX, 2
    CALL PLAY_SOUND
    MOV AX, 8000
    MOV CX, 3
    CALL PLAY_SOUND
    POP CX
    POP AX
    RET
SND_LIFE_LOST ENDP

;--------------------------------------------------------------
; SND_POWERUP — rising chirp when power-up is collected
;--------------------------------------------------------------
SND_POWERUP PROC
    PUSH AX
    PUSH CX
    MOV AX, 4000
    MOV CX, 1
    CALL PLAY_SOUND
    MOV AX, 2000
    MOV CX, 1
    CALL PLAY_SOUND
    MOV AX, 1000
    MOV CX, 1
    CALL PLAY_SOUND
    POP CX
    POP AX
    RET
SND_POWERUP ENDP

;--------------------------------------------------------------
; SND_LEVEL_CLEAR — victory jingle for level complete
;--------------------------------------------------------------
SND_LEVEL_CLEAR PROC
    PUSH AX
    PUSH CX
    MOV AX, 2400
    MOV CX, 2
    CALL PLAY_SOUND
    MOV AX, 1800
    MOV CX, 2
    CALL PLAY_SOUND
    MOV AX, 1200
    MOV CX, 3
    CALL PLAY_SOUND
    POP CX
    POP AX
    RET
SND_LEVEL_CLEAR ENDP

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
    ; Validate: name must not be empty
    CMP nameLen, 0
    JNE NI_VALID

    ; Show error message "NAME REQUIRED!"
    MOV SI, OFFSET sNameReq
    MOV BX, 101
    MOV CX, 145
    MOV DL, 12
    CALL DRAW_STRING

    MOV CX, 15
    CALL DELAY_TICKS

    ; Erase the error message
    MOV rectX, 90
    MOV rectY, 142
    MOV rectW, 150
    MOV rectH, 14
    MOV rectColor, 8         ; match background
    CALL DRAW_RECT

    JMP NI_LOOP

NI_VALID:
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
    ; --- Check keyboard (non-blocking) ---
    MOV AH, 01h
    INT 16h
    JZ  MM_CHECK_MOUSE

    MOV AH, 00h
    INT 16h
    CMP AH, 48h
    JE  MM_UP
    CMP AH, 50h
    JE  MM_DOWN
    CMP AL, 0Dh
    JE  MM_ENTER
    JMP MM_CHECK_MOUSE

MM_UP:
    CMP menuSel, 0
    JE  MM_CHECK_MOUSE
    DEC menuSel
    JMP MM_REDRAW

MM_DOWN:
    CMP menuSel, 3
    JE  MM_CHECK_MOUSE
    INC menuSel
    JMP MM_REDRAW

MM_CHECK_MOUSE:
    CMP mouseActive, 0
    JE  MM_KEY_LOOP

    ; Get mouse position and button state
    MOV AX, 3
    INT 33h             ; BX=buttons, CX=X, DX=Y

    ; Check if mouse is within menu item X range (60..260)
    CMP CX, 60
    JL  MM_MOUSE_BTN
    CMP CX, 260
    JG  MM_MOUSE_BTN

    ; Determine which item mouse is over based on Y
    ; Item 0: Y 38..61, Item 1: Y 70..93, Item 2: Y 102..125, Item 3: Y 134..157
    CMP DX, 38
    JL  MM_MOUSE_BTN
    CMP DX, 62
    JL  MM_MSEL0
    CMP DX, 70
    JL  MM_MOUSE_BTN
    CMP DX, 94
    JL  MM_MSEL1
    CMP DX, 102
    JL  MM_MOUSE_BTN
    CMP DX, 126
    JL  MM_MSEL2
    CMP DX, 134
    JL  MM_MOUSE_BTN
    CMP DX, 158
    JL  MM_MSEL3
    JMP MM_MOUSE_BTN

MM_MSEL0:
    CMP menuSel, 0
    JE  MM_MOUSE_BTN
    MOV menuSel, 0
    JMP MM_REDRAW
MM_MSEL1:
    CMP menuSel, 1
    JE  MM_MOUSE_BTN
    MOV menuSel, 1
    JMP MM_REDRAW
MM_MSEL2:
    CMP menuSel, 2
    JE  MM_MOUSE_BTN
    MOV menuSel, 2
    JMP MM_REDRAW
MM_MSEL3:
    CMP menuSel, 3
    JE  MM_MOUSE_BTN
    MOV menuSel, 3
    JMP MM_REDRAW

MM_MOUSE_BTN:
    ; Check left mouse button (bit 0 of BX)
    TEST BX, 1
    JZ  MM_KEY_LOOP
    ; Left button pressed — select current item
    ; Brief delay to debounce
    PUSH CX
    MOV CX, 3
    CALL DELAY_TICKS
MM_WAIT_RELEASE:
    MOV AX, 3
    INT 33h
    TEST BX, 1
    JNZ MM_WAIT_RELEASE
    POP CX
    JMP MM_ENTER

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
; LOAD_HIGH_SCORES — read high score table from HIGHSCOR.DAT
;   If file doesn't exist, keeps default data in memory.
;==============================================================
LOAD_HIGH_SCORES PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Open file for reading
    MOV AH, 3Dh
    MOV AL, 00h             ; read-only
    MOV DX, OFFSET hsFileName
    INT 21h
    JC  LHS_DONE            ; file doesn't exist, use defaults

    MOV fileHandle, AX

    ; Read names (80 bytes = 5 * 16)
    MOV AH, 3Fh
    MOV BX, fileHandle
    MOV CX, 80
    MOV DX, OFFSET hsNames
    INT 21h

    ; Read scores (10 bytes = 5 * 2)
    MOV AH, 3Fh
    MOV BX, fileHandle
    MOV CX, 10
    MOV DX, OFFSET hsScores
    INT 21h

    ; Close file
    MOV AH, 3Eh
    MOV BX, fileHandle
    INT 21h

LHS_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
LOAD_HIGH_SCORES ENDP

;==============================================================
; SAVE_HIGH_SCORES — write high score table to HIGHSCOR.DAT
;==============================================================
SAVE_HIGH_SCORES PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Create/truncate file
    MOV AH, 3Ch
    MOV CX, 0               ; normal attributes
    MOV DX, OFFSET hsFileName
    INT 21h
    JC  SHS_DONE

    MOV fileHandle, AX

    ; Write names (80 bytes)
    MOV AH, 40h
    MOV BX, fileHandle
    MOV CX, 80
    MOV DX, OFFSET hsNames
    INT 21h

    ; Write scores (10 bytes)
    MOV AH, 40h
    MOV BX, fileHandle
    MOV CX, 10
    MOV DX, OFFSET hsScores
    INT 21h

    ; Close file
    MOV AH, 3Eh
    MOV BX, fileHandle
    INT 21h

SHS_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SAVE_HIGH_SCORES ENDP

;==============================================================
; INSERT_HIGH_SCORE — insert current player score into table
;   Checks if score qualifies, shifts lower entries down,
;   copies playerName and score into the right slot.
;==============================================================
INSERT_HIGH_SCORE PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    ; Find insertion position: first entry where score < player score
    MOV CX, 0              ; CX = index (0..4)
IHS_FIND:
    CMP CX, 5
    JGE IHS_DONE            ; score not high enough
    MOV BX, CX
    SHL BX, 1              ; BX = CX * 2 (word offset)
    MOV AX, hsScores[BX]
    CMP score, AX
    JG  IHS_FOUND
    INC CX
    JMP IHS_FIND

IHS_FOUND:
    ; CX = insertion index. Shift entries CX..3 down to CX+1..4
    MOV BX, 3              ; start from entry 3, shift to 4
IHS_SHIFT:
    CMP BX, CX
    JL  IHS_COPY

    ; Shift name: hsNames[BX*16] -> hsNames[(BX+1)*16]
    PUSH CX
    MOV AX, BX
    SHL AX, 4              ; AX = BX * 16 (source offset)
    MOV SI, AX
    ADD AX, 16             ; dest offset
    MOV DI, AX
    MOV CX, 16
IHS_SNAME:
    MOV AL, hsNames[SI]
    MOV hsNames[DI], AL
    INC SI
    INC DI
    LOOP IHS_SNAME
    POP CX

    ; Shift score
    MOV AX, BX
    SHL AX, 1
    MOV SI, AX
    MOV DI, AX
    ADD DI, 2
    MOV AX, hsScores[SI]
    MOV hsScores[DI], AX

    DEC BX
    JMP IHS_SHIFT

IHS_COPY:
    ; Copy playerName into hsNames[CX*16]
    MOV AX, CX
    SHL AX, 4
    MOV DI, AX
    MOV SI, 0
    PUSH CX
    MOV CX, 16
IHS_CNAME:
    CMP SI, 15
    JGE IHS_CPAD
    MOV AL, playerName[SI]
    MOV hsNames[DI], AL
    CMP AL, 0
    JE  IHS_CPAD
    INC SI
    INC DI
    DEC CX
    JMP IHS_CNAME
IHS_CPAD:
    ; Zero-fill remaining bytes
    CMP CX, 0
    JLE IHS_CSCORE
    MOV hsNames[DI], 0
    INC DI
    DEC CX
    JMP IHS_CPAD

IHS_CSCORE:
    POP CX
    ; Copy score into hsScores[CX*2]
    MOV BX, CX
    SHL BX, 1
    MOV AX, score
    MOV hsScores[BX], AX

    ; Save to file
    CALL SAVE_HIGH_SCORES

IHS_DONE:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
INSERT_HIGH_SCORE ENDP

;==============================================================
; SHOW_HIGH_SCORES — display high score table from memory
;==============================================================
SHOW_HIGH_SCORES PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BP

    MOV AL, 0
    CALL CLEAR_SCREEN

    ; Header
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 9
    CALL DRAW_RECT
    MOV SI, OFFSET sHighSc
    MOV BX, 108
    MOV CX, 7
    MOV DL, 15
    CALL DRAW_STRING

    ; Table border
    MOV rectX, 20
    MOV rectY, 32
    MOV rectW, 280
    MOV rectH, 140
    MOV rectColor, 15
    CALL DRAW_RECT_BORDER

    ; Column headers background
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

    ; Column headers text
    MOV SI, OFFSET sRank
    MOV BX, 35
    MOV CX, 36
    MOV DL, 14
    CALL DRAW_STRING
    MOV SI, OFFSET sName
    MOV BX, 130
    MOV CX, 36
    CALL DRAW_STRING
    MOV SI, OFFSET sScoreH
    MOV BX, 230
    MOV CX, 36
    CALL DRAW_STRING

    ; Column separator lines
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

    ; Draw 5 entries
    MOV BP, 0              ; entry index 0..4
HS_ENTRY:
    CMP BP, 5
    JGE HS_FOOTER

    ; Row Y = 54 + BP * 24
    MOV AX, BP
    IMUL AX, 24
    ADD AX, 54
    MOV DI, AX             ; DI = row Y

    ; Rank number ('1' + BP)
    MOV AX, BP
    ADD AL, '1'
    MOV BX, 45
    MOV CX, DI
    MOV DL, 14
    CALL DRAW_CHAR

    ; Name: hsNames[BP*16]
    MOV AX, BP
    SHL AX, 4              ; AX = BP * 16
    MOV SI, AX
    ADD SI, OFFSET hsNames
    MOV BX, 90
    MOV CX, DI
    MOV DL, 11
    CALL DRAW_STRING

    ; Score: hsScores[BP*2] -> convert to string via ITOA
    MOV AX, BP
    SHL AX, 1
    MOV SI, AX
    MOV AX, hsScores[SI]
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    MOV BX, 232
    MOV CX, DI
    MOV DL, 10
    CALL DRAW_STRING

    ; Row separator line (except after last)
    CMP BP, 4
    JGE HS_NEXT_ENTRY
    MOV AX, DI
    ADD AX, 18
    MOV rectY, AX
    MOV rectX, 21
    MOV rectW, 278
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT

HS_NEXT_ENTRY:
    INC BP
    JMP HS_ENTRY

HS_FOOTER:
    MOV rectX, 0
    MOV rectY, 184
    MOV rectW, 320
    MOV rectH, 16
    MOV rectColor, 1
    CALL DRAW_RECT
    MOV SI, OFFSET sReturn
    MOV BX, 60
    MOV CX, 188
    MOV DL, 15
    CALL DRAW_STRING

    CALL WAIT_KEY

    POP BP
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_HIGH_SCORES ENDP

;==============================================================
;==============================================================
; ITERATION 2 — GAME LOGIC PROCEDURES
;==============================================================
;==============================================================

;==============================================================
; INIT_GAME — called once at game start (resets score/lives/level)
;==============================================================
INIT_GAME PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV score, 0
    MOV lives, 3
    MOV level, 1
    MOV gameRunning, 1
    MOV puActive, 0

    ; Seed RNG with system timer tick count
    MOV AH, 00h
    INT 1Ah                 ; CX:DX = tick count
    MOV rngState, DX

    ; Initialize mouse driver
    MOV AX, 0
    INT 33h
    CMP AX, 0FFFFh
    JNE IG_NO_MOUSE
    MOV mouseActive, 1
    ; Set horizontal range: 3..317 (play area)
    MOV AX, 7              ; function 7: set horizontal range
    MOV CX, 3              ; min X
    MOV DX, 317            ; max X
    INT 33h
    ; Hide mouse cursor (we draw paddle ourselves)
    MOV AX, 2
    INT 33h
    ; Center mouse
    MOV AX, 4              ; function 4: set mouse position
    MOV CX, 160            ; center X
    MOV DX, 100            ; center Y
    INT 33h
    MOV lastMouseX, 160
    JMP IG_MOUSE_DONE
IG_NO_MOUSE:
    MOV mouseActive, 0
IG_MOUSE_DONE:

    ; Reset HUD cache so first frame draws bar fully
    MOV hudDrawn, 0
    MOV lastScore, 0FFFFh
    MOV lastLives, 0FFh

    POP DX
    POP CX
    POP BX
    POP AX
    RET
INIT_GAME ENDP

;==============================================================
; SETUP_LEVEL — called at start of each level
;   Sets ball speed, paddle width, delay based on current level.
;   Loads level-specific brick layout. Preserves score & lives.
;==============================================================
SETUP_LEVEL PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    ; --- Set difficulty based on level ---
    CMP level, 3
    JE  SL_LV3
    CMP level, 2
    JE  SL_LV2

    ; Level 1: easy — full grid, slow ball, wide paddle
    MOV ballSpeed, 2
    MOV paddleW, 50
    MOV gameDelay, 2
    
    MOV bricksLeft, 65
    MOV CX, 65
    MOV SI, 0
SL_FILL1:
    MOV AL, brickLayout1[SI]
    MOV bricks[SI], AL
    INC SI
    LOOP SL_FILL1
    JMP SL_COMMON

SL_LV2:
    ; Level 2: medium — checkerboard layout, faster ball, narrower paddle
    MOV ballSpeed, 2
    MOV paddleW, 40
    MOV gameDelay, 1
    ; Copy checkerboard layout (33 bricks)
    MOV bricksLeft, 33
    MOV CX, 65
    MOV SI, 0
SL_FILL2:
    MOV AL, brickLayout2[SI]
    MOV bricks[SI], AL
    INC SI
    LOOP SL_FILL2
    JMP SL_COMMON

SL_LV3:
    ; Level 3: hard — diamond layout, fast ball, narrow paddle
    MOV ballSpeed, 3
    MOV paddleW, 32
    MOV gameDelay, 1
    ; Copy diamond/fortress layout (42 bricks)
    MOV bricksLeft, 42
    MOV CX, 65
    MOV SI, 0
SL_FILL3:
    MOV AL, brickLayout3[SI]
    MOV bricks[SI], AL
    INC SI
    LOOP SL_FILL3

SL_COMMON:
    ; Deactivate any active power-up
    MOV puActive, 0

    ; Reset ball position and direction using current ballSpeed
    MOV ballX, 158
    MOV ballY, 120
    MOV AX, ballSpeed
    MOV ballDX, AX
    NEG AX
    MOV ballDY, AX

    ; Center paddle: paddleX = (320 - paddleW) / 2
    MOV AX, 320
    SUB AX, paddleW
    SHR AX, 1
    MOV paddleX, AX

    MOV gameRunning, 1

    ; Force HUD redraw
    MOV hudDrawn, 0
    MOV lastScore, 0FFFFh
    MOV lastLives, 0FFh

    ; Flush keyboard buffer to prevent stale keys
SL_FLUSH:
    MOV AH, 01h
    INT 16h
    JZ  SL_FLUSH_DONE
    MOV AH, 00h
    INT 16h
    JMP SL_FLUSH
SL_FLUSH_DONE:

    POP DI
    POP SI
    POP CX
    POP AX
    RET
SETUP_LEVEL ENDP

;==============================================================
; RESET_BALL — recenter ball after life loss
;==============================================================
RESET_BALL PROC
    PUSH AX
    CALL ERASE_TRAIL
    MOV ballX, 158
    MOV ballY, 120
    MOV AX, ballSpeed
    MOV ballDX, AX
    NEG AX
    MOV ballDY, AX
    POP AX
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

    ; Compute brick screen position
    PUSH AX                     ; save brick type (1 or 2)
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
    POP AX                      ; restore brick type

    ; Check if barrier (value 2) → dark gray
    CMP AL, 2
    JNE DB_NORMAL_BRICK
    MOV rectColor, 8            ; barrier = dark gray
    JMP DB_DRAW

DB_NORMAL_BRICK:
    ; Row-based color for breakable bricks
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

    ; Top highlight line (white)
    MOV AX, paddleX
    MOV rectX, AX
    MOV rectY, paddleY
    MOV AX, paddleW
    MOV rectW, AX
    MOV rectH, 1
    MOV rectColor, 15
    CALL DRAW_RECT

    ; Bottom edge line (dark)
    MOV AX, paddleX
    MOV rectX, AX
    MOV AX, paddleY + paddleH - 1
    MOV rectY, AX
    MOV AX, paddleW
    MOV rectW, AX
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT

    POP AX
    RET
DRAW_PADDLE ENDP

;==============================================================
; UPDATE_TRAIL — shift trail positions and draw fading trail
;   Call BEFORE erasing ball at new position
;==============================================================
UPDATE_TRAIL PROC
    PUSH AX

    CMP trailInit, 0
    JE  UT_INIT

    ; Erase oldest trail dot (color 0 = black)
    MOV AX, trailX+4
    MOV rectX, AX
    MOV AX, trailY+4
    MOV rectY, AX
    MOV rectW, ballSize
    MOV rectH, ballSize
    MOV rectColor, 0
    CALL DRAW_RECT

    ; Draw middle trail dot (dark gray)
    MOV AX, trailX+2
    MOV rectX, AX
    MOV AX, trailY+2
    MOV rectY, AX
    MOV rectW, ballSize
    MOV rectH, ballSize
    MOV rectColor, 8
    CALL DRAW_RECT

    ; Draw newest trail dot (light gray)
    MOV AX, trailX
    MOV rectX, AX
    MOV AX, trailY
    MOV rectY, AX
    MOV rectW, ballSize
    MOV rectH, ballSize
    MOV rectColor, 7
    CALL DRAW_RECT

    ; Shift positions: [2] = [1], [1] = [0], [0] = current ball
    MOV AX, trailX+2
    MOV trailX+4, AX
    MOV AX, trailY+2
    MOV trailY+4, AX
    MOV AX, trailX
    MOV trailX+2, AX
    MOV AX, trailY
    MOV trailY+2, AX
    MOV AX, ballX
    MOV trailX, AX
    MOV AX, ballY
    MOV trailY, AX

    POP AX
    RET

UT_INIT:
    ; First frame: initialize all trail positions to current ball
    MOV AX, ballX
    MOV trailX, AX
    MOV trailX+2, AX
    MOV trailX+4, AX
    MOV AX, ballY
    MOV trailY, AX
    MOV trailY+2, AX
    MOV trailY+4, AX
    MOV trailInit, 1
    POP AX
    RET
UPDATE_TRAIL ENDP

;==============================================================
; ERASE_TRAIL — erase all trail dots (called on ball reset)
;==============================================================
ERASE_TRAIL PROC
    PUSH AX
    PUSH CX
    MOV CX, 0
ET_LOOP:
    CMP CX, 3
    JGE ET_DONE
    MOV AX, CX
    SHL AX, 1
    PUSH BX
    MOV BX, AX
    MOV AX, trailX[BX]
    MOV rectX, AX
    MOV AX, trailY[BX]
    MOV rectY, AX
    POP BX
    MOV rectW, ballSize
    MOV rectH, ballSize
    MOV rectColor, 0
    CALL DRAW_RECT
    INC CX
    JMP ET_LOOP
ET_DONE:
    MOV trailInit, 0
    POP CX
    POP AX
    RET
ERASE_TRAIL ENDP

;==============================================================
; BRICK_BREAK_FX — flash effect when a brick is destroyed
;   rectX/rectY/rectW/rectH must already be set to brick position
;==============================================================
BRICK_BREAK_FX PROC
    PUSH AX
    PUSH CX

    ; Flash white
    MOV rectColor, 15
    CALL DRAW_RECT
    MOV CX, 1
    CALL DELAY_TICKS

    ; Flash yellow
    MOV rectColor, 14
    CALL DRAW_RECT
    MOV CX, 1
    CALL DELAY_TICKS

    ; Erase to black
    MOV rectColor, 0
    CALL DRAW_RECT

    POP CX
    POP AX
    RET
BRICK_BREAK_FX ENDP

;==============================================================
; DRAW_WALL_GLOW — draw side walls with gradient effect
;==============================================================
DRAW_WALL_GLOW PROC
    PUSH AX
    PUSH CX

    ; Left wall: outer=dark blue, inner=bright blue
    MOV rectX, 0
    MOV rectY, 15
    MOV rectW, 1
    MOV rectH, 181
    MOV rectColor, 1
    CALL DRAW_RECT
    MOV rectX, 1
    MOV rectW, 1
    MOV rectColor, 9
    CALL DRAW_RECT
    MOV rectX, 2
    MOV rectW, 1
    MOV rectColor, 11
    CALL DRAW_RECT

    ; Right wall: inner=bright blue, outer=dark blue
    MOV rectX, 317
    MOV rectW, 1
    MOV rectColor, 11
    CALL DRAW_RECT
    MOV rectX, 318
    MOV rectW, 1
    MOV rectColor, 9
    CALL DRAW_RECT
    MOV rectX, 319
    MOV rectW, 1
    MOV rectColor, 1
    CALL DRAW_RECT

    ; Top bar: gradient
    MOV rectX, 0
    MOV rectY, 13
    MOV rectW, 320
    MOV rectH, 1
    MOV rectColor, 1
    CALL DRAW_RECT
    MOV rectY, 14
    MOV rectColor, 9
    CALL DRAW_RECT
    MOV rectY, 15
    MOV rectColor, 11
    CALL DRAW_RECT

    POP CX
    POP AX
    RET
DRAW_WALL_GLOW ENDP

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

    CMP AH, 19h
    JE  RI_PAUSE

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

RI_PAUSE:
    ; Draw "PAUSED" text in center of screen
    PUSH DX
    PUSH CX
    PUSH SI
    MOV rectX, 120
    MOV rectY, 93
    MOV rectW, 80
    MOV rectH, 18
    MOV rectColor, 0
    CALL DRAW_RECT
    MOV rectX, 120
    MOV rectY, 93
    MOV rectW, 80
    MOV rectH, 18
    MOV rectColor, 15
    CALL DRAW_RECT_BORDER
    MOV SI, OFFSET sPaused
    MOV BX, 131
    MOV CX, 98
    MOV DL, 14
    CALL DRAW_STRING
    POP SI
    POP CX
    POP DX

    ; Wait for P/p to resume
RI_PAUSE_WAIT:
    MOV AH, 00h
    INT 16h
    CMP AH, 19h
    JE  RI_RESUME
    JMP RI_PAUSE_WAIT

RI_RESUME:
    ; Erase paused overlay
    MOV rectX, 120
    MOV rectY, 93
    MOV rectW, 80
    MOV rectH, 18
    MOV rectColor, 0
    CALL DRAW_RECT
    JMP RI_PEEK

RI_ESC:
    MOV gameRunning, 0
    JMP RI_DONE

RI_DONE:
    ; --- Mouse input ---
    CMP mouseActive, 0
    JE  RI_EXIT

    PUSH CX
    PUSH DX
    MOV AX, 3              ; function 3: get mouse position
    INT 33h                 ; CX = mouse X, DX = mouse Y

    ; Only update if mouse moved
    CMP CX, lastMouseX
    JE  RI_MOUSE_END
    MOV lastMouseX, CX

    ; Target paddle X = mouseX - paddleW/2
    MOV BX, CX
    MOV AX, paddleW
    SHR AX, 1
    SUB BX, AX

    ; Clamp left
    CMP BX, 3
    JGE RI_MC_R
    MOV BX, 3
RI_MC_R:
    ; Clamp right
    MOV AX, 317
    SUB AX, paddleW
    CMP BX, AX
    JLE RI_MC_SET
    MOV BX, AX
RI_MC_SET:
    ; Smooth: move paddle halfway toward target (reduces speed)
    MOV AX, BX             ; AX = target X
    SUB AX, paddleX        ; AX = delta (target - current)
    CMP AX, 0
    JE  RI_MOUSE_END       ; no movement needed
    ; Divide delta by 2 (move half the distance per frame)
    CWD
    MOV CX, 2
    IDIV CX                ; AX = delta / 2
    CMP AX, 0
    JNE RI_MC_APPLY
    ; If delta/2 rounded to 0, move at least 1 pixel in the right direction
    CMP BX, paddleX
    JG  RI_MC_POS
    MOV AX, -1
    JMP RI_MC_APPLY
RI_MC_POS:
    MOV AX, 1
RI_MC_APPLY:
    MOV BX, paddleX
    ADD BX, AX             ; BX = new paddle X
    CALL ERASE_PADDLE
    MOV paddleX, BX
    CALL DRAW_PADDLE

RI_MOUSE_END:
    POP DX
    POP CX

RI_EXIT:
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

    ; HIT — check if barrier (2) or breakable brick (1)
    CMP bricks[SI], 2
    JE  CBC_BARRIER

    ; Breakable brick: destroy it, score, bounce
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
    CALL BRICK_BREAK_FX

    ADD score, 10
    CALL SPAWN_POWERUP      ; try to spawn a power-up at this brick
    CALL SND_BRICK

    ; --- Axis-aware bounce ---
    ; Overlap on Y axis at PREVIOUS frame? -> horizontal hit -> NEG dx
    ; Else -> vertical hit -> NEG dy
    PUSH BP
    MOV AX, BX
    IMUL AX, 9
    ADD AX, 22              ; AX = brickTop
    MOV BP, AX              ; BP = brickTop
    ADD AX, BRICK_H         ; AX = brickBottom

    ; prevBallY = ballY - ballDY
    MOV DX, ballY
    SUB DX, ballDY          ; DX = prevBallY
    ; prevBallY >= brickBottom? -> no overlap -> vertical
    CMP DX, AX
    JGE CBC_BR_VERT
    ; prevBallY + ballSize <= brickTop? -> no overlap -> vertical
    ADD DX, ballSize        ; DX = prevBallY + size
    CMP DX, BP
    JLE CBC_BR_VERT

    ; Otherwise prev Y overlapped -> horizontal hit
    NEG ballDX
    POP BP
    JMP CBC_END

CBC_BR_VERT:
    NEG ballDY
    POP BP
    JMP CBC_END

CBC_BARRIER:
    ; Indestructible barrier: detect collision axis, snap, bounce, redraw
    PUSH BP

    ; Compute barrier rect: barX..barX+BRICK_W, barY..barY+BRICK_H
    MOV AX, CX
    IMUL AX, 23
    ADD AX, 11
    PUSH AX                 ; [SP] = barrier X (barX)
    MOV AX, BX
    IMUL AX, 9
    ADD AX, 22
    MOV DI, AX              ; DI = barrier top Y (barY)

    ; --- Determine collision axis using ball's PREVIOUS position ---
    ; prevBallX = ballX - ballDX, prevBallY = ballY - ballDY
    ; If prev ball already overlapped barrier on Y axis -> horizontal entry
    ; Else -> vertical entry
    MOV AX, ballY
    SUB AX, ballDY          ; AX = prevBallY
    MOV DX, AX
    ADD DX, ballSize        ; DX = prevBallY + ballSize
    ; Check if prevBall Y range overlapped barrier Y range
    ; overlap if prevBallY < barY+BRICK_H AND prevBallY+ballSize > barY
    MOV BP, DI
    ADD BP, BRICK_H         ; BP = barY + BRICK_H
    CMP AX, BP
    JGE CBC_BAR_VERT        ; prevBallY >= barBottom -> no Y overlap -> vertical entry
    CMP DX, DI
    JLE CBC_BAR_VERT        ; prevBallY+size <= barTop -> no Y overlap -> vertical entry

    ; Horizontal entry: snap X and bounce dx
    POP AX                  ; AX = barX
    PUSH AX
    CMP ballDX, 0
    JL  CBC_BAR_FROM_RIGHT
    ; Ball moving right -> snap left of barrier
    SUB AX, ballSize        ; ballX = barX - ballSize
    MOV ballX, AX
    JMP CBC_BAR_HBOUNCE
CBC_BAR_FROM_RIGHT:
    ADD AX, BRICK_W         ; ballX = barX + BRICK_W
    MOV ballX, AX
CBC_BAR_HBOUNCE:
    NEG ballDX
    JMP CBC_BAR_REDRAW

CBC_BAR_VERT:
    ; Vertical entry: snap Y and bounce dy
    CMP ballDY, 0
    JL  CBC_BAR_UP
    ; Ball moving DOWN -> snap above
    MOV AX, DI
    SUB AX, ballSize
    MOV ballY, AX
    JMP CBC_BAR_VBOUNCE
CBC_BAR_UP:
    MOV AX, DI
    ADD AX, BRICK_H
    MOV ballY, AX
CBC_BAR_VBOUNCE:
    NEG ballDY

CBC_BAR_REDRAW:
    ; Redraw the barrier fully (repair any erase damage)
    POP AX                  ; AX = barX
    MOV rectX, AX
    MOV rectY, DI
    MOV rectW, BRICK_W
    MOV rectH, BRICK_H
    MOV rectColor, 8
    CALL DRAW_RECT
    POP BP
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
; RANDOM — simple LCG random number generator
;   Returns: AX = pseudo-random 16-bit value
;   Updates rngState
;==============================================================
RANDOM PROC
    PUSH DX
    MOV AX, rngState
    MOV DX, 25173
    MUL DX                  ; DX:AX = rngState * 25173
    ADD AX, 13849           ; AX = low word + 13849
    MOV rngState, AX
    POP DX
    RET
RANDOM ENDP

;==============================================================
; SPAWN_POWERUP — try to spawn a power-up at brick position
;   Input: CX = brick column, BX = brick row
;   Spawns with ~30% probability if no power-up already active
;==============================================================
SPAWN_POWERUP PROC
    PUSH AX
    PUSH DX

    ; Skip if a power-up is already on screen
    CMP puActive, 1
    JE  SP_DONE

    ; Random chance: ~30% (0..99, spawn if < 30)
    CALL RANDOM
    MOV DX, 0
    PUSH BX
    MOV BX, 100
    DIV BX                  ; AX=quotient, DX=remainder (0..99)
    POP BX
    CMP DX, 30
    JGE SP_DONE

    ; Spawn power-up at the brick's center
    MOV AX, CX
    IMUL AX, 23
    ADD AX, BRICK_X0
    ADD AX, (BRICK_W - puW) / 2
    MOV puX, AX

    MOV AX, BX
    IMUL AX, 9
    ADD AX, BRICK_Y0
    ADD AX, BRICK_H
    MOV puY, AX

    ; Random type 0..3
    CALL RANDOM
    AND AX, 03h            ; AX = 0, 1, 2, or 3
    MOV puType, AL

    MOV puActive, 1

SP_DONE:
    POP DX
    POP AX
    RET
SPAWN_POWERUP ENDP

;==============================================================
; ERASE_POWERUP — erase power-up from screen (draw black)
;==============================================================
ERASE_POWERUP PROC
    PUSH AX
    MOV AX, puX
    MOV rectX, AX
    MOV AX, puY
    MOV rectY, AX
    MOV rectW, puW
    MOV rectH, puH
    MOV rectColor, 0
    CALL DRAW_RECT
    ; Redraw any bricks that overlap the erased area
    CALL REDRAW_BRICKS_AT_PU
    POP AX
    RET
ERASE_POWERUP ENDP

;==============================================================
; REDRAW_BRICKS_AT_PU — redraws bricks overlapping power-up pos
;   Checks which brick rows/cols overlap puX,puY area and redraws
;==============================================================
REDRAW_BRICKS_AT_PU PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Only check if power-up is in brick area (Y 22..66)
    MOV AX, puY
    ADD AX, puH
    CMP AX, 22
    JLE RBP_DONE              ; power-up is above bricks
    MOV AX, puY
    CMP AX, 67
    JGE RBP_DONE              ; power-up is below bricks

    ; Find row range: row = (Y - 22) / 9
    ; Start row
    MOV AX, puY
    SUB AX, 22
    JGE RBP_ROW_OK
    XOR AX, AX
RBP_ROW_OK:
    MOV BL, 9
    DIV BL                    ; AL = start row
    MOVZX BX, AL             ; BX = start row

    ; End row: (puY + puH - 22) / 9
    MOV AX, puY
    ADD AX, puH
    SUB AX, 22
    MOV DL, 9
    DIV DL                    ; AL = end row
    MOVZX DX, AL             ; DX = end row
    CMP DX, BRICK_ROWS
    JL  RBP_ER_OK
    MOV DX, BRICK_ROWS - 1
RBP_ER_OK:
    CMP BX, BRICK_ROWS
    JGE RBP_DONE

    ; Find col range: col = (X - 11) / 23
    MOV AX, puX
    SUB AX, 11
    JGE RBP_COL_OK
    XOR AX, AX
RBP_COL_OK:
    PUSH DX
    MOV DL, 23
    DIV DL                    ; AL = start col
    POP DX
    MOVZX CX, AL             ; CX = start col

    MOV AX, puX
    ADD AX, puW
    SUB AX, 11
    PUSH DX
    MOV DL, 23
    DIV DL                    ; AL = end col
    POP DX
    MOVZX SI, AL             ; SI = end col
    CMP SI, BRICK_COLS
    JL  RBP_EC_OK
    MOV SI, BRICK_COLS - 1
RBP_EC_OK:

    ; Loop rows BX..DX, cols CX..SI — redraw active bricks
RBP_ROW:
    CMP BX, DX
    JG  RBP_DONE
    PUSH CX                   ; save start col
RBP_COL:
    CMP CX, SI
    JG  RBP_NEXT_ROW

    ; Check if brick[BX*13 + CX] is active
    MOV AX, BX
    IMUL AX, BRICK_COLS
    ADD AX, CX
    PUSH SI
    MOV SI, AX
    CMP bricks[SI], 0
    POP SI
    JE  RBP_SKIP

    ; Brick is active — redraw it
    PUSH DX
    PUSH CX
    ; rectX = CX * 23 + 11
    MOV AX, CX
    IMUL AX, 23
    ADD AX, 11
    MOV rectX, AX
    ; rectY = BX * 9 + 22
    MOV AX, BX
    IMUL AX, 9
    ADD AX, 22
    MOV rectY, AX
    MOV rectW, BRICK_W
    MOV rectH, BRICK_H

    ; Determine color based on brick type or row
    PUSH SI
    MOV AX, BX
    IMUL AX, BRICK_COLS
    ADD AX, CX
    MOV SI, AX
    CMP bricks[SI], 2
    POP SI
    JE  RBP_BARRIER

    ; Normal brick: color by row (match DRAW_BRICKS colors)
    CMP BX, 0
    JE  RBPC0
    CMP BX, 1
    JE  RBPC1
    CMP BX, 2
    JE  RBPC2
    CMP BX, 3
    JE  RBPC3
    MOV rectColor, 5
    JMP RBP_DRAW
RBPC0: MOV rectColor, 4
    JMP RBP_DRAW
RBPC1: MOV rectColor, 14
    JMP RBP_DRAW
RBPC2: MOV rectColor, 2
    JMP RBP_DRAW
RBPC3: MOV rectColor, 3
    JMP RBP_DRAW
RBP_BARRIER:
    MOV rectColor, 8
RBP_DRAW:
    CALL DRAW_RECT
    POP CX
    POP DX

RBP_SKIP:
    INC CX
    JMP RBP_COL

RBP_NEXT_ROW:
    POP CX                    ; restore start col
    INC BX
    JMP RBP_ROW

RBP_DONE:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
REDRAW_BRICKS_AT_PU ENDP

;==============================================================
; DRAW_POWERUP — draw power-up with type-specific color
;   Colors: 0=Slow(LightBlue/11), 1=Fast(LightRed/12),
;           2=Life(LightGreen/10), 3=Paddle(Yellow/14)
;==============================================================
DRAW_POWERUP PROC
    PUSH AX
    MOV AX, puX
    MOV rectX, AX
    MOV AX, puY
    MOV rectY, AX
    MOV rectW, puW
    MOV rectH, puH

    CMP puType, 0
    JE  DP_SLOW
    CMP puType, 1
    JE  DP_FAST
    CMP puType, 2
    JE  DP_LIFE
    MOV rectColor, 14       ; type 3: Paddle Size (yellow)
    JMP DP_DO
DP_SLOW:
    MOV rectColor, 11       ; Slow Ball (light cyan)
    JMP DP_DO
DP_FAST:
    MOV rectColor, 12       ; Fast Ball (light red)
    JMP DP_DO
DP_LIFE:
    MOV rectColor, 10       ; Extra Life (light green)
DP_DO:
    CALL DRAW_RECT
    POP AX
    RET
DRAW_POWERUP ENDP

;==============================================================
; APPLY_POWERUP — apply the collected power-up effect
;==============================================================
APPLY_POWERUP PROC
    PUSH AX

    CMP puType, 0
    JE  AP_SLOW
    CMP puType, 1
    JE  AP_FAST
    CMP puType, 2
    JE  AP_LIFE
    JMP AP_PADDLE

AP_SLOW:
    ; Slow Ball: reduce speed (min 1)
    CMP ballSpeed, 1
    JLE AP_DONE
    DEC ballSpeed
    ; Update ball velocity magnitude
    MOV AX, ballDX
    CMP AX, 0
    JL  AP_SLOW_NEG
    MOV AX, ballSpeed
    MOV ballDX, AX
    JMP AP_SLOW_Y
AP_SLOW_NEG:
    MOV AX, ballSpeed
    NEG AX
    MOV ballDX, AX
AP_SLOW_Y:
    MOV AX, ballDY
    CMP AX, 0
    JL  AP_SLOW_YNEG
    MOV AX, ballSpeed
    MOV ballDY, AX
    JMP AP_DONE
AP_SLOW_YNEG:
    MOV AX, ballSpeed
    NEG AX
    MOV ballDY, AX
    JMP AP_DONE

AP_FAST:
    ; Fast Ball: increase speed (max 4)
    CMP ballSpeed, 4
    JGE AP_DONE
    INC ballSpeed
    ; Update ball velocity magnitude
    MOV AX, ballDX
    CMP AX, 0
    JL  AP_FAST_NEG
    MOV AX, ballSpeed
    MOV ballDX, AX
    JMP AP_FAST_Y
AP_FAST_NEG:
    MOV AX, ballSpeed
    NEG AX
    MOV ballDX, AX
AP_FAST_Y:
    MOV AX, ballDY
    CMP AX, 0
    JL  AP_FAST_YNEG
    MOV AX, ballSpeed
    MOV ballDY, AX
    JMP AP_DONE
AP_FAST_YNEG:
    MOV AX, ballSpeed
    NEG AX
    MOV ballDY, AX
    JMP AP_DONE

AP_LIFE:
    ; Extra Life: +1 life (max 5)
    CMP lives, 5
    JGE AP_DONE
    INC lives
    JMP AP_DONE

AP_PADDLE:
    ; Paddle Size Increase: +12 pixels (max 70)
    MOV AX, paddleW
    ADD AX, 12
    CMP AX, 70
    JLE AP_PAD_OK
    MOV AX, 70
AP_PAD_OK:
    MOV paddleW, AX

AP_DONE:
    POP AX
    RET
APPLY_POWERUP ENDP

;==============================================================
; UPDATE_POWERUP — move power-up down, check paddle collision
;   Called once per frame from game loop
;==============================================================
UPDATE_POWERUP PROC
    PUSH AX
    PUSH BX

    CMP puActive, 0
    JE  UP_DONE

    ; Erase at old position
    CALL ERASE_POWERUP

    ; Move down
    MOV AX, puY
    ADD AX, puSpeed
    MOV puY, AX

    ; Check if fell off bottom of screen
    CMP AX, 196
    JGE UP_DEACTIVATE

    ; Check paddle collision
    ; puY + puH > paddleY?
    MOV AX, puY
    ADD AX, puH
    CMP AX, paddleY
    JLE UP_DRAW

    ; puY < paddleY + paddleH?
    MOV AX, puY
    CMP AX, paddleY + paddleH
    JGE UP_DEACTIVATE

    ; puX + puW > paddleX?
    MOV AX, puX
    ADD AX, puW
    CMP AX, paddleX
    JLE UP_DRAW

    ; puX < paddleX + paddleW?
    MOV AX, paddleX
    ADD AX, paddleW
    MOV BX, puX
    CMP BX, AX
    JGE UP_DRAW

    ; Collected! Apply effect and deactivate
    CALL APPLY_POWERUP
    CALL SND_POWERUP
    MOV puActive, 0
    JMP UP_DONE

UP_DEACTIVATE:
    MOV puActive, 0
    JMP UP_DONE

UP_DRAW:
    CALL DRAW_POWERUP

UP_DONE:
    POP BX
    POP AX
    RET
UPDATE_POWERUP ENDP

;==============================================================
; CHECK_PADDLE_COLLISION
;==============================================================
CHECK_PADDLE_COLLISION PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; --- AABB overlap test with extended Y detection (anti-tunnel) ---
    MOV AX, ballY
    ADD AX, ballSize
    CMP AX, paddleY
    JLE CPC_NO

    MOV AX, paddleY + paddleH
    ADD AX, ballSpeed
    MOV BX, ballY
    CMP BX, AX
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

    ; --- Snap ball above paddle (prevent clipping) ---
    MOV AX, paddleY
    SUB AX, ballSize
    MOV ballY, AX

    CALL SND_PADDLE

    ; --- Curved-paddle reflection (9-zone angular fan) ---
    ; The paddle acts like a CURVED surface: normals fan outward
    ; from the center. Center -> straight up. Edges -> wide angle.
    ;
    ; relPos = ballCenterX - paddleX        (range 0..paddleW-1)
    ; zone   = relPos * 9 / paddleW         (range 0..8)
    ; tilt   = zone - 4                     (range -4..+4, 0=center)
    ; absT   = |tilt|, sign = sign(tilt)
    ;
    ; Reflection table (per |tilt|):
    ;   0 (center) -> dx = 0,            dy = -(speed+1)   straight up
    ;   1          -> dx = sign*1,       dy = -(speed+1)   slight tilt
    ;   2          -> dx = sign*2,       dy = -speed       moderate
    ;   3          -> dx = sign*(speed+1), dy = -speed     wide
    ;   4 (edge)   -> dx = sign*(speed+1), dy = -1         very wide
    ;
    MOV AX, ballX
    ADD AX, ballSize/2
    SUB AX, paddleX            ; AX = relPos
    CMP AX, 0
    JGE CPC_RP_OK
    XOR AX, AX
CPC_RP_OK:
    MOV BX, paddleW
    DEC BX
    CMP AX, BX
    JLE CPC_RP_OK2
    MOV AX, BX
CPC_RP_OK2:
    MOV CX, 9
    MUL CX                     ; DX:AX = relPos * 9
    DIV paddleW                ; AX = zone (0..8)

    ; tilt = zone - 4
    SUB AX, 4                  ; AX = signed tilt (-4..+4)
    MOV CX, AX                 ; CX = tilt (signed)

    ; sign in DX (+1 or -1), absT in CX
    MOV DX, 1
    CMP CX, 0
    JGE CPC_ABS_DONE
    NEG CX                     ; CX = |tilt|
    MOV DX, -1
CPC_ABS_DONE:
    ; CX = absT (0..4), DX = sign

    ; --- Compute ballDX magnitude based on absT ---
    CMP CX, 0
    JE  CPC_T0
    CMP CX, 1
    JE  CPC_T1
    CMP CX, 2
    JE  CPC_T2
    CMP CX, 3
    JE  CPC_T3
    ; |tilt|=4 (edge): dx mag = speed+1, dy = -1
    MOV AX, ballSpeed
    INC AX
    IMUL AX, DX
    MOV ballDX, AX
    MOV ballDY, -1
    JMP CPC_KICK_PREP
CPC_T3:
    ; |tilt|=3: dx mag = speed+1, dy = -speed
    MOV AX, ballSpeed
    INC AX
    IMUL AX, DX
    MOV ballDX, AX
    MOV AX, ballSpeed
    NEG AX
    MOV ballDY, AX
    JMP CPC_KICK_PREP
CPC_T2:
    ; |tilt|=2: dx mag = 2, dy = -speed
    MOV AX, 2
    IMUL AX, DX
    MOV ballDX, AX
    MOV AX, ballSpeed
    NEG AX
    MOV ballDY, AX
    JMP CPC_KICK_PREP
CPC_T1:
    ; |tilt|=1: dx mag = 1, dy = -(speed+1)
    MOV AX, 1
    IMUL AX, DX
    MOV ballDX, AX
    MOV AX, ballSpeed
    INC AX
    NEG AX
    MOV ballDY, AX
    JMP CPC_KICK_PREP
CPC_T0:
    ; |tilt|=0 (center): dx = 0, dy = -(speed+1)
    MOV ballDX, 0
    MOV AX, ballSpeed
    INC AX
    NEG AX
    MOV ballDY, AX

CPC_KICK_PREP:

    ; --- Paddle motion influence: add kick if paddle moved this frame ---
    ; delta = paddleX - prevPaddleX
    MOV AX, paddleX
    SUB AX, prevPaddleX
    CMP AX, 0
    JE  CPC_KICK_DONE
    JG  CPC_KICK_R
    ; Paddle moved LEFT -> push ball left
    MOV BX, ballDX
    DEC BX
    MOV ballDX, BX
    JMP CPC_KICK_DONE
CPC_KICK_R:
    ; Paddle moved RIGHT -> push ball right
    MOV BX, ballDX
    INC BX
    MOV ballDX, BX

CPC_KICK_DONE:
    ; --- Clamp ballDX to ±(ballSpeed+1) so ball doesn't get too horizontal ---
    MOV AX, ballSpeed
    INC AX                     ; AX = max |dx|
    MOV BX, ballDX
    CMP BX, AX
    JLE CPC_CLAMP_NEG
    MOV ballDX, AX
    JMP CPC_NO
CPC_CLAMP_NEG:
    NEG AX                     ; AX = -(ballSpeed+1)
    CMP BX, AX
    JGE CPC_NO
    MOV ballDX, AX

CPC_NO:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
CHECK_PADDLE_COLLISION ENDP

;==============================================================
; REPAIR_WALLS — redraw wall pixels damaged by ball/trail erase
;==============================================================
REPAIR_WALLS PROC
    PUSH AX

    ; Always redraw top HUD gradient (3 horizontal lines, cheap)
    ; This guarantees the boundary is never visually broken even
    ; if ball/trail erases damaged a pixel earlier
    MOV rectX, 0
    MOV rectW, 320
    MOV rectH, 1
    MOV rectY, 13
    MOV rectColor, 1
    CALL DRAW_RECT
    MOV rectY, 14
    MOV rectColor, 9
    CALL DRAW_RECT
    MOV rectY, 15
    MOV rectColor, 11
    CALL DRAW_RECT

RW_LEFT:
    ; Check left wall: if ball overlaps X <= 2
    MOV AX, ballX
    CMP AX, 3
    JG  RW_RIGHT
    MOV rectY, 13
    MOV rectH, 183
    MOV rectW, 1
    MOV rectX, 0
    MOV rectColor, 1
    CALL DRAW_RECT
    MOV rectX, 1
    MOV rectColor, 9
    CALL DRAW_RECT
    MOV rectX, 2
    MOV rectColor, 11
    CALL DRAW_RECT

RW_RIGHT:
    ; Check right wall: if ball overlaps X >= 313 (317 - ballSize)
    MOV AX, ballX
    ADD AX, ballSize
    CMP AX, 317
    JL  RW_DONE
    MOV rectY, 13
    MOV rectH, 183
    MOV rectW, 1
    MOV rectX, 317
    MOV rectColor, 11
    CALL DRAW_RECT
    MOV rectX, 318
    MOV rectColor, 9
    CALL DRAW_RECT
    MOV rectX, 319
    MOV rectColor, 1
    CALL DRAW_RECT

RW_DONE:
    POP AX
    RET
REPAIR_WALLS ENDP

;==============================================================
; REDRAW_BARRIERS_NEAR_BALL — repair any barrier (grey) bricks
;   damaged by ball/trail erase. Scans bricks in a bounding box
;   that covers ballX/Y plus all 3 trail positions.
;==============================================================
REDRAW_BARRIERS_NEAR_BALL PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BP

    ; Build bbox: minX, minY, maxX, maxY across ball + 3 trail dots
    MOV AX, ballX
    MOV BX, AX             ; minX
    MOV CX, AX             ; maxX
    MOV AX, ballY
    MOV DX, AX             ; minY
    MOV SI, AX             ; maxY

    ; trail[0]
    MOV AX, trailX
    CMP AX, BX
    JGE RB_SK_X0
    MOV BX, AX
RB_SK_X0:
    CMP AX, CX
    JLE RB_SK_X0B
    MOV CX, AX
RB_SK_X0B:
    MOV AX, trailY
    CMP AX, DX
    JGE RB_SK_Y0
    MOV DX, AX
RB_SK_Y0:
    CMP AX, SI
    JLE RB_SK_Y0B
    MOV SI, AX
RB_SK_Y0B:

    ; trail[1]
    MOV AX, trailX+2
    CMP AX, BX
    JGE RB_SK_X1
    MOV BX, AX
RB_SK_X1:
    CMP AX, CX
    JLE RB_SK_X1B
    MOV CX, AX
RB_SK_X1B:
    MOV AX, trailY+2
    CMP AX, DX
    JGE RB_SK_Y1
    MOV DX, AX
RB_SK_Y1:
    CMP AX, SI
    JLE RB_SK_Y1B
    MOV SI, AX
RB_SK_Y1B:

    ; trail[2]
    MOV AX, trailX+4
    CMP AX, BX
    JGE RB_SK_X2
    MOV BX, AX
RB_SK_X2:
    CMP AX, CX
    JLE RB_SK_X2B
    MOV CX, AX
RB_SK_X2B:
    MOV AX, trailY+4
    CMP AX, DX
    JGE RB_SK_Y2
    MOV DX, AX
RB_SK_Y2:
    CMP AX, SI
    JLE RB_SK_Y2B
    MOV SI, AX
RB_SK_Y2B:

    ; Now bbox = [BX..CX+ballSize, DX..SI+ballSize]
    ADD CX, ballSize        ; maxX
    ADD SI, ballSize        ; maxY

    ; Quick reject: if entirely below brick area or above
    CMP SI, 22
    JL  RBN_DONE
    CMP DX, 67              ; brick area Y goes 22..66
    JGE RBN_DONE

    ; Convert bbox to brick row/col range
    ; startRow = max(0, (DX-22)/9), endRow = min(4, (SI-22)/9)
    MOV AX, DX
    SUB AX, 22
    JGE RBN_R_OK
    XOR AX, AX
RBN_R_OK:
    MOV BP, 9
    XOR DX, DX
    DIV BP                  ; AX = startRow (DX clobbered as remainder)
    PUSH AX                 ; [SP] = startRow

    MOV AX, SI
    SUB AX, 22
    XOR DX, DX
    DIV BP                  ; AX = endRow
    CMP AX, BRICK_ROWS
    JL  RBN_ER_OK
    MOV AX, BRICK_ROWS - 1
RBN_ER_OK:
    MOV DI, AX              ; DI = endRow

    ; startCol = max(0, (BX-11)/23), endCol = min(12, (CX-11)/23)
    MOV AX, BX
    SUB AX, 11
    JGE RBN_C_OK
    XOR AX, AX
RBN_C_OK:
    MOV BP, 23
    XOR DX, DX
    DIV BP                  ; AX = startCol
    MOV BX, AX              ; BX = startCol

    MOV AX, CX
    SUB AX, 11
    XOR DX, DX
    DIV BP                  ; AX = endCol
    CMP AX, BRICK_COLS
    JL  RBN_EC_OK
    MOV AX, BRICK_COLS - 1
RBN_EC_OK:
    MOV CX, AX              ; CX = endCol

    POP AX                  ; AX = startRow
    MOV DX, AX              ; DX = current row

RBN_ROW:
    CMP DX, DI
    JG  RBN_DONE
    PUSH BX                 ; save startCol
    MOV BP, BX              ; BP = current col
RBN_COL:
    CMP BP, CX
    JG  RBN_NEXT_ROW

    ; idx = row*BRICK_COLS + col
    MOV AX, DX
    IMUL AX, BRICK_COLS
    ADD AX, BP
    MOV SI, AX
    CMP bricks[SI], 2
    JNE RBN_SKIP

    ; Redraw barrier brick
    MOV AX, BP
    IMUL AX, 23
    ADD AX, 11
    MOV rectX, AX
    MOV AX, DX
    IMUL AX, 9
    ADD AX, 22
    MOV rectY, AX
    MOV rectW, BRICK_W
    MOV rectH, BRICK_H
    MOV rectColor, 8
    CALL DRAW_RECT

RBN_SKIP:
    INC BP
    JMP RBN_COL

RBN_NEXT_ROW:
    POP BX                  ; restore startCol
    INC DX
    JMP RBN_ROW

RBN_DONE:
    POP BP
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
REDRAW_BARRIERS_NEAR_BALL ENDP

;==============================================================
; MOVE_BALL
;==============================================================
MOVE_BALL PROC
    PUSH AX
    PUSH BX

    CALL UPDATE_TRAIL
    CALL ERASE_BALL
    CALL REPAIR_WALLS
    CALL REDRAW_BARRIERS_NEAR_BALL

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
    CALL SND_WALL
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
    CALL SND_WALL
MB_NOR:

    ; Top wall: wall occupies Y=13..15. Snap ball to Y=16 so
    ; it sits fully BELOW the wall (same idea as paddle collision
    ; snapping ball fully above the paddle). Prevents ERASE_BALL
    ; from ever drawing black over wall pixels.
    CMP ballY, 16
    JGE MB_NOT
    MOV ballY, 16
    NEG ballDY
    CALL SND_WALL
MB_NOT:

    ; Bottom (life loss)
    CMP ballY, 196
    JL  MB_ALIVE

    DEC lives
    CALL SND_LIFE_LOST
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

    ; Save paddleX for next frame's motion-influence calculation
    PUSH AX
    MOV AX, paddleX
    MOV prevPaddleX, AX
    POP AX

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

    ; Gradient walls
    CALL DRAW_WALL_GLOW

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
; SHOW_GAME_SCREEN — main game loop (supports 3 levels)
;==============================================================
SHOW_GAME_SCREEN PROC
    CALL INIT_GAME
    CALL SETUP_LEVEL
    CALL DRAW_GAME_FRAME

    ; Brief pause before ball starts moving
    MOV CX, 15
    CALL DELAY_TICKS

GL_LOOP:
    CALL READ_INPUT
    CALL MOVE_BALL
    CALL UPDATE_POWERUP        ; move/check power-up each frame
    CALL UPDATE_HUD            ; only updates if values changed

    ; Frame delay (level-dependent: slower = easier)
    MOV CX, gameDelay
    CALL DELAY_TICKS

    CMP gameRunning, 0
    JE  GL_END
    CMP lives, 0
    JLE GL_END
    CMP bricksLeft, 0
    JLE GL_LEVEL_CLEAR

    JMP GL_LOOP

GL_LEVEL_CLEAR:
    CALL SND_LEVEL_CLEAR
    ; Check if this was the final level (3)
    CMP level, 3
    JGE GL_FINAL_WIN

    ; Not final level: show level complete, advance to next
    CALL SHOW_LEVEL_CLEAR
    INC level
    CALL SETUP_LEVEL
    CALL DRAW_GAME_FRAME

    ; Brief pause so player can see new level layout
    MOV CX, 15
    CALL DELAY_TICKS

    MOV gameRunning, 1
    JMP GL_LOOP

GL_FINAL_WIN:
    ; Beat all 3 levels!
    CALL SHOW_FINAL_WIN
    RET

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

    ; Save score to high score table
    CALL INSERT_HIGH_SCORE

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
    ; LINE B (Y=85): "LEVEL: <n>" — Light Blue
    ; "LEVEL: " = 6 chars * 9 + 1 space * 6 = 60 px
    ;----------------------------------------------------------
    MOV SI, OFFSET sGoLevel
    MOV BX, 125
    MOV CX, 85
    MOV DL, 9
    CALL DRAW_STRING

    ; Append level number
    MOV AL, level
    MOV AH, 0
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    MOV BX, 185
    MOV CX, 85
    MOV DL, 9
    CALL DRAW_STRING

    ;----------------------------------------------------------
    ; LINE C (Y=120): "FINAL SCORE: <score>" — Light Green
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

    ADD BX, 111
    MOV SI, OFFSET itoaBuf
    MOV DL, 10
    CALL DRAW_STRING

    ;----------------------------------------------------------
    ; FOOTER BAR
    ;----------------------------------------------------------
    MOV rectX, 0
    MOV rectY, 178
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 1
    CALL DRAW_RECT

    ;----------------------------------------------------------
    ; BLINKING PROMPT inside footer
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
; SHOW_LEVEL_CLEAR — shown between levels (not final level)
;   Displays "LEVEL COMPLETE!" and current score, waits for Enter
;==============================================================
SHOW_LEVEL_CLEAR PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    MOV AL, 0
    CALL CLEAR_SCREEN

    ; Header bar (green for success)
    MOV rectX, 0
    MOV rectY, 0
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 2
    CALL DRAW_RECT

    ; Header underline
    MOV rectX, 0
    MOV rectY, 22
    MOV rectW, 320
    MOV rectH, 1
    MOV rectColor, 10
    CALL DRAW_RECT

    ; Title "LEVEL COMPLETE!"
    ; 14 letters + 0 spaces = 14*9 = 126 px. X=(320-126)/2=97
    MOV SI, OFFSET sGameWin
    MOV BX, 97
    MOV CX, 7
    MOV DL, 15
    CALL DRAW_STRING

    ; Info box
    MOV rectX, 30
    MOV rectY, 45
    MOV rectW, 260
    MOV rectH, 100
    MOV rectColor, 15
    CALL DRAW_RECT_BORDER

    MOV rectX, 32
    MOV rectY, 47
    MOV rectW, 256
    MOV rectH, 96
    MOV rectColor, 0
    CALL DRAW_RECT

    ; "LEVEL: <n>" at Y=60
    MOV SI, OFFSET sGoLevel
    MOV BX, 115
    MOV CX, 60
    MOV DL, 9
    CALL DRAW_STRING

    MOV AL, level
    MOV AH, 0
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    MOV BX, 175
    MOV CX, 60
    MOV DL, 9
    CALL DRAW_STRING

    ; "Score: <n>" at Y=85
    MOV SI, OFFSET sScore
    MOV BX, 115
    MOV CX, 85
    MOV DL, 14
    CALL DRAW_STRING

    MOV AX, score
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    MOV BX, 175
    MOV CX, 85
    MOV DL, 15
    CALL DRAW_STRING

    ; "Lives: <n>" at Y=105
    MOV SI, OFFSET sLives
    MOV BX, 115
    MOV CX, 105
    MOV DL, 14
    CALL DRAW_STRING

    MOV AL, lives
    MOV AH, 0
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    MOV BX, 175
    MOV CX, 105
    MOV DL, 10
    CALL DRAW_STRING

    ; Footer bar
    MOV rectX, 0
    MOV rectY, 178
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 1
    CALL DRAW_RECT

    ; Blinking "PRESS ENTER FOR NEXT LEVEL"
SLC_BLINK:
    MOV SI, OFFSET sNextLvl
    MOV BX, 44
    MOV CX, 186
    MOV DL, 15
    CALL DRAW_STRING

    MOV CX, 10
    CALL DELAY_TICKS

    MOV AH, 01h
    INT 16h
    JZ  SLC_ERASE
    MOV AH, 00h
    INT 16h
    CMP AL, 0Dh
    JE  SLC_DONE
    JMP SLC_BLINK

SLC_ERASE:
    MOV rectX, 20
    MOV rectY, 184
    MOV rectW, 280
    MOV rectH, 14
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV CX, 7
    CALL DELAY_TICKS

    MOV AH, 01h
    INT 16h
    JZ  SLC_BLINK
    MOV AH, 00h
    INT 16h
    CMP AL, 0Dh
    JE  SLC_DONE
    JMP SLC_BLINK

SLC_DONE:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_LEVEL_CLEAR ENDP

;==============================================================
; SHOW_FINAL_WIN — shown after beating all 3 levels
;==============================================================
SHOW_FINAL_WIN PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Save score to high score table
    CALL INSERT_HIGH_SCORE

    MOV AL, 0
    CALL CLEAR_SCREEN

    ; Header bar (green for victory)
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

    ; Title "CONGRATULATIONS!"
    ; 16 letters * 9 = 144 px. X=(320-144)/2=88
    MOV SI, OFFSET sCongrats
    MOV BX, 88
    MOV CX, 7
    MOV DL, 15
    CALL DRAW_STRING

    ; Info box
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

    ; Accent line
    MOV rectX, 32
    MOV rectY, 67
    MOV rectW, 256
    MOV rectH, 1
    MOV rectColor, 8
    CALL DRAW_RECT

    ; "ALL LEVELS COMPLETE!" at Y=53
    ; 18 letters + 2 spaces = 18*9 + 2*6 = 174 px. X=(320-174)/2=73
    MOV SI, OFFSET sFinalWin
    MOV BX, 73
    MOV CX, 53
    MOV DL, 10
    CALL DRAW_STRING

    ; "PLAYER: <name>" at Y=80
    MOV AL, nameLen
    MOV AH, 0
    MOV BX, AX
    IMUL BX, 9
    ADD BX, 69
    MOV AX, 320
    SUB AX, BX
    SHR AX, 1

    MOV SI, OFFSET sGoPlayer
    MOV BX, AX
    MOV CX, 80
    MOV DL, 14
    CALL DRAW_STRING

    ADD BX, 69
    MOV SI, 0
FW_PNAME:
    MOV AL, playerName[SI]
    CMP AL, 0
    JE  FW_PNAME_DN
    CALL DRAW_CHAR
    ADD BX, 9
    INC SI
    CMP SI, 15
    JL  FW_PNAME
FW_PNAME_DN:

    ; "LEVEL: 3" at Y=100
    MOV SI, OFFSET sGoLevel
    MOV BX, 125
    MOV CX, 100
    MOV DL, 9
    CALL DRAW_STRING

    MOV AL, level
    MOV AH, 0
    CALL ITOA
    MOV SI, OFFSET itoaBuf
    MOV BX, 185
    MOV CX, 100
    MOV DL, 9
    CALL DRAW_STRING

    ; "FINAL SCORE: <n>" at Y=120
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

    ADD BX, 111
    MOV SI, OFFSET itoaBuf
    MOV DL, 10
    CALL DRAW_STRING

    ; Footer bar
    MOV rectX, 0
    MOV rectY, 178
    MOV rectW, 320
    MOV rectH, 22
    MOV rectColor, 1
    CALL DRAW_RECT

    ; Blinking "PRESS ENTER TO RETURN TO MENU"
FW_BLINK:
    MOV SI, OFFSET sGoEnter
    MOV BX, 40
    MOV CX, 186
    MOV DL, 7
    CALL DRAW_STRING

    MOV CX, 10
    CALL DELAY_TICKS

    MOV AH, 01h
    INT 16h
    JZ  FW_ERASE
    MOV AH, 00h
    INT 16h
    CMP AL, 0Dh
    JE  FW_DONE
    JMP FW_BLINK

FW_ERASE:
    MOV rectX, 20
    MOV rectY, 184
    MOV rectW, 280
    MOV rectH, 14
    MOV rectColor, 1
    CALL DRAW_RECT

    MOV CX, 7
    CALL DELAY_TICKS

    MOV AH, 01h
    INT 16h
    JZ  FW_BLINK
    MOV AH, 00h
    INT 16h
    CMP AL, 0Dh
    JE  FW_DONE
    JMP FW_BLINK

FW_DONE:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_FINAL_WIN ENDP

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
    CALL LOAD_HIGH_SCORES
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
