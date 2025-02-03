.setcpu "65C02"
.debuginfo
.segment "BIOS"

KBD             = $5010         ;  PIA.A keyboard input
KBDCR           = $5011         ;  PIA.A keyboard control register
DSP             = $5012         ;  PIA.B display output register

SYS:
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
    STA DSP
    RTS

.include "wozmon.s"

.segment "RESETVEC"

; Interrupt Vectors
                .WORD $0F00     ; NMI
                .WORD RESET     ; RESET
                .WORD $0000     ; BRK/IRQ
