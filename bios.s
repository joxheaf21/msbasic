.setcpu "65C02"
.debuginfo
.segment "BIOS"

TERMINAL        = $5000
KBD             = $5010         ;  PIA.A keyboard input
KBDCR           = $5011         ;  PIA.A keyboard control register
DSP             = $5012         ;  PIA.B display output register

TERMINIT:
    PHA
    LDA #$0D
    STA TERMINAL
    PLA
    RTS

TERMSTR:
    JSR FRMEVL
    BIT VALTYP
    BMI PRINT_STR
    JSR FOUT
    JSR STRLIT
PRINT_STR:
    JSR FREFAC
    TAX
    LDY     #$00
LOOP:
    LDA (INDEX),y
    STA TERMINAL
    INY
    DEX
    bne LOOP
    LDA #$0D
    STA TERMINAL
    RTS

TERMCHR:
    JSR GETBYT
    TXA
    STA TERMINAL
    RTS

MON:
    JMP RESET

SYS:
    JSR FRMNUM
    JSR GETADR
    JMP (LINNUM)

LOAD:
SAVE:
    RTS

MONCOUT:
    STA DSP
    RTS

MONRDKEY:
    LDA KBDCR       ; Key ready?
    BPL MONRDKEY    ; Loop until ready.
    LDA KBD         ; Load character. B7 should be ‘1’.
;    STA DSP
    RTS

.include "wozmon.s"

.segment "RESETVEC"

; Interrupt Vectors
                .WORD $0000     ; NMI
                .WORD RESET     ; RESET
                .WORD $0000     ; BRK/IRQ
