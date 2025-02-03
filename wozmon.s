;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak in 1976

; Page 0 Variables

.segment "WOZMON"

XAML            = $24           ;  Last "opened" location Low
XAMH            = $25           ;  Last "opened" location High
STL             = $26           ;  Store address Low
STH             = $27           ;  Store address High
L               = $28           ;  Hex value parsing Low
H               = $29           ;  Hex value parsing High
YSAV            = $2A           ;  Used to see if hex value is given
MODE            = $2B           ;  $00=XAM, $7F=STOR, $AE=BLOCK XAM

; Other Variables

IN              = $0200         ;  Input buffer to $027F

RESET:          CLD             ; Clear decimal arithmetic mode.
                CLI
                LDY #$7F
NOTCR:          CMP #'_'        ; "_"?
                BEQ BACKSPACE   ; Yes.
                CMP #$1B        ; ESC?
                BEQ ESCAPE      ; Yes.
                INY             ; Advance text index.
                BPL NEXTCHAR    ; Auto ESC if > 127.
ESCAPE:         LDA #'\'        ; "\".
                JSR ECHO_N        ; Output it.
GETLINE:        LDA #$0D        ; CR.
                JSR ECHO_N        ; Output it.
                LDA #$0A        ; LF.
                JSR ECHO_N
                LDY #$01        ; Initialize text index.
BACKSPACE:      DEY             ; Back up text index.
                BMI GETLINE     ; Beyond start of line, reinitialize.
NEXTCHAR:       LDA KBDCR       ; Key ready?
                BPL NEXTCHAR    ; Loop until ready.
                LDA KBD         ; Load character. B7 should be ‘1’.
                STA IN,Y        ; Add to text buffer.
                JSR ECHO_N        ; Display character.
                CMP #$0D        ; CR?
                BNE NOTCR       ; No.
                LDY #$FF        ; Reset text index.
                LDA #$00        ; For XAM mode.
                TAX             ; 0->X.
SETBLOCK:       ASL
SETSTOR:        ASL             ; Leaves $7B if setting STOR mode.
SETMODE:        STA MODE        ; $00=XAM, $7B=STOR, $AE=BLOCK XAM.
BLSKIP:         INY             ; Advance text index.
NEXTITEM:       LDA IN,Y        ; Get character.
                CMP #$0D        ; CR?
                BEQ GETLINE     ; Yes, done this line.
                CMP #'.'        ; "."?
                BCC BLSKIP      ; Skip delimiter.
                BEQ SETBLOCK    ; Set BLOCK XAM mode.
                CMP #':'        ; ":"?
                BEQ SETSTOR     ; Yes. Set STOR mode.
                CMP #'R'        ; "R"?
                BEQ RUNPROG     ; Yes. RUN user program.
                STX L           ; $00->L.
                STX H           ;  and H.
                STY YSAV        ; Save Y for comparison.
NEXTHEX:        LDA IN,Y        ; Get character for hex test.
                EOR #$30        ; Map digits to $0-9.
                CMP #$0D        ; Digit?
                BCC DIG         ; Yes.
                ADC #$88        ; Map letter "A"-"F" to $FA-FF.
                CMP #$FA        ; Hex letter?
                BCC NOTHEX      ; No, character not hex.
DIG:            ASL
                ASL             ; Hex digit to MSD of A.
                ASL
                ASL
                LDX #$04        ; Shift count.
HEXSHIFT:       ASL             ; Hex digit left, MSB to carry.
                ROL L           ; Rotate into LSD.
                ROL H           ; Rotate into MSD’s.
                DEX             ; Done 4 shifts?
                BNE HEXSHIFT    ; No, loop.
                INY             ; Advance text index.
                BNE NEXTHEX     ; Always taken. Check next character for hex.
NOTHEX:         CPY YSAV        ; Check if L, H empty (no hex digits).
                BEQ ESCAPE      ; Yes, generate ESC sequence.
                BIT MODE        ; Test MODE byte.
                BVC NOTSTOR     ; B6=0 STOR, 1 for XAM and BLOCK XAM
                LDA L           ; LSD’s of hex data.
                STA (STL,X)     ; Store at current ‘store index’.
                INC STL         ; Increment store index.
                BNE NEXTITEM    ; Get next item. (no carry).
                INC STH         ; Add carry to ‘store index’ high order.
TONEXTITEM:     JMP NEXTITEM    ; Get next command item.
RUNPROG:        JMP (XAML)      ; Run at current XAM index.
NOTSTOR:        BMI XAMNEXT     ; B7=0 for XAM, 1 for BLOCK XAM.
                LDX #$02        ; Byte count.
SETADR:         LDA L-1,X       ; Copy hex data to
                STA STL-1,X     ;  ‘store index’.
                STA XAML-1,X    ; And to ‘XAM index’.
                DEX             ; Next of 2 bytes.
                BNE SETADR      ; Loop unless X=0.
NXTPRNT:        BNE PRDATA      ; NE means no address to print.
                LDA #$0D        ; CR.
                JSR ECHO_N        ; Output it.
                LDA #$0A        ; LF.
                JSR ECHO_N        ; Output it.
                LDA XAMH        ; ‘Examine index’ high-order byte.
                JSR PRBYTE_N      ; Output it in hex format.
                LDA XAML        ; Low-order ‘examine index’ byte.
                JSR PRBYTE_N      ; Output it in hex format.
                LDA #':'        ; ":".
                JSR ECHO_N        ; Output it.
PRDATA:         LDA #$20        ; Blank.
                JSR ECHO_N        ; Output it.
                LDA (XAML,X)    ; Get data byte at ‘examine index’.
                JSR PRBYTE_N      ; Output it in hex format.
XAMNEXT:        STX MODE        ; 0->MODE (XAM mode).
                LDA XAML
                CMP L           ; Compare ‘examine index’ to hex data.
                LDA XAMH
                SBC H
                BCS TONEXTITEM  ; Not less, so no more data to output.
                INC XAML
                BNE MOD8CHK     ; Increment ‘examine index’.
                INC XAMH
MOD8CHK:        LDA XAML        ; Check low-order ‘examine index’ byte
                AND #$07        ;  For MOD 8=0
                BPL NXTPRNT     ; Always taken.
PRBYTE_N:         PHA             ; Save A for LSD.
                LSR
                LSR
                LSR             ; MSD to LSD position.
                LSR
                JSR PRHEX_N     ; Output hex digit.
                PLA             ; Restore A.
PRHEX_N:        AND #$0F        ; Mask LSD for hex print.
                ORA #'0'        ; Add "0".
                CMP #$3A        ; Digit?
                BCC ECHO_N        ; Yes, output it.
                ADC #$06        ; Add offset for letter.
ECHO_N:           STA DSP         ; Output character. Sets DA.
                RTS             ; Return.
