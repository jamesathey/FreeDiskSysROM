; FreeDiskSysROM
; Copyright (c) 2018 James Athey
;
; This program is free software: you can redistribute it and/or modify it under
; the terms of the GNU Lesser General Public License version 3 as published by
; the Free Software Foundation.
;
; This program is distributed in the hope that it will be useful, but WITHOUT
; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
; FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
; details.
;
; You should have received a copy of the GNU Lesser General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.

; Bits 6 and 7 of NMI_ACTION choose which of the disk's 3 NMI vectors to use,
; or '0' to indicate the use of VINTWait. The three vectors are stored in
; order starting at $DFF6. Set to $C0 on reset, aka NMI vector 3.
NMI_ACTION	EQU $0100
NMI_VEC1    EQU $DFF6
NMI_VEC2    EQU $DFF8
NMI_VEC3    EQU $DFFA

; The BIOS NMI provides programs the choice of up to 3 user-selectable NMI
; vectors, or using VINTWait (the "everything in main" way.) If VINTWait
; was used, then the BIOS NMI does the following:
; * Clears the VBlank flag in $2002.
; * Disables future NMIs, assuming that the program will just call VINTWait
;   again.
; * Manipulates the stack to make the NMI behave as a subroutine call instead
;   of an ISR.
; * Pulls the NMI vector selection and accumulator from the stack, then RTS
;   to return to the caller of VINTWait.
; Affects: A
API_ENTRYPOINT $e18b
NMI:
    BIT NMI_ACTION
    BMI @vecs2and3
    BVS @vec1

    ; value was 0, assuming VINTWait was used
    LDA PPUSTATUS  ; clear the VBlank flag
    LDA ZP_PPUCTRL
    AND #%01111111 ; clear NMI enable flag
    STA PPUCTRL
    STA ZP_PPUCTRL    
    PLA            ; discard the saved processor flags
    PLA            ; discard the return address pushed onto the stack by the interrupt
    PLA            ; (presumably it pointed to the infinite loop in VINTWait)
    PLA            ; restore NMI_ACTION
    STA NMI_ACTION
    PLA            ; restore VINTWait's caller's accumulator
    RTS            ; return to VINTWait's caller

@vec1:
    JMP (NMI_VEC1)
@vecs2and3:
    BVS @vec3
    JMP (NMI_VEC2)
@vec3:
    JMP (NMI_VEC3)
    
; Spin until next VBlank NMI fires, for programs that do it the "everything in
; main" way. The accumulator and the NMI vector selection at $100 are saved to
; the stack, and further VBlanks are disabled. 
; Affects: $FF
API_ENTRYPOINT $e1b2
VINTWait:
	PHA            ; save current A
	LDA NMI_ACTION ; get current NMI selection
	PHA            ; and save it on the stack
	LDA #0
	STA NMI_ACTION ; tell the BIOS to disable NMIs
	LDA ZP_PPUCTRL ; but make sure the next NMI happens
	ORA #%10000000 ; so the spinning stops when the NMI fires
	STA PPUCTRL
	STA ZP_PPUCTRL
@spin:
	BNE @spin      ; now nothing left to do but wait
