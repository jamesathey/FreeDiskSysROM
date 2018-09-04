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

; Fetch a direct pointer located at the apparent return address of the routine
; that calls this one, save the pointer at ($00), and fix the return address.
; Assumes nothing more was pushed onto the stack by the caller.
; Affects: A, X, Y, $05, $06
; Returns: $00, $01 = pointer fetched
API_ENTRYPOINT $e844
FetchDirectPtr:
	; The stack pointer is currently 1 below the return address of the caller.
	; We need the return address of the caller's caller, three bytes later.
	TSX
	LDA $103,X
	STA $05
	LDY $104,X
	STY $06
	CLC
	ADC #2 ; fix return address of caller's caller (it's the fetched pointer + 2)
	BCC @storeFixedPointer
	INY ; add the carry
@storeFixedPointer:
	STA $103,X  ; write low byte of fixed return address to stack
	TYA         ; no abs,x addressing mode for STY, so transfer Y to A
	STA $104,X  ; write high byte of fixed return address to stack
	LDY #1      ; the return address is always 1 less than the real location
	LDA ($05),Y ; get low byte of direct pointer
	STA $00     ; store low byte of direct pointer
	INY
	LDA ($05),Y ; get high byte of direct pointer
	STA $01     ; store high byte of direct pointer
	RTS
