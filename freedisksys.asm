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

; zero-page registers
ZP_PPUCTRL		EQU $FF; value last written to $2000   $80 on reset.
ZP_PPUMASK		EQU $FE; value last written to $2001   $06 on reset
ZP_PPUSCROLL1	EQU $FD; value last written to $2005/1 $00 on reset.
ZP_PPUSCROLL2	EQU $FC; value last written to $2005/2 $00 on reset.
; [$FB]:  value last written to $4016   $00 on reset.
; [$FA]:  value last written to $4025   $2E on reset.
; [$F9]:  value last written to $4026   $FF on reset.

; PPU registers
PPUCTRL		EQU $2000
PPUMASK		EQU $2001
PPUSTATUS	EQU $2002
OAMADDR		EQU $2003
OAMDATA		EQU $2004
PPUSCROLL	EQU $2005
PPUADDR		EQU $2006
PPUDATA		EQU $2007
OAMDMA		EQU $4014

; undocumented instructions not explicitly supported by asm6f
; TOP (abs)
MACRO TOP address
	DB $0C
	DW #address
ENDM

; Input registers
JOYPAD1 EQU $4016
JOYPAD2 EQU $4017

; Error codes:
OK EQU $00 ; no error
DISK_NOT_SET EQU $01 ; disk set, ($4032.0) disk not set
POWER_SUPPLY_FAILURE EQU $02 ; battery, ($4033.7) power supply failure
WRITE_PROTECTED EQU $03 ; ($4032.2) disk is write protected
WRONG_MAKER_ID EQU $04 ; Wrong maker ID
WRONG_GAME EQU $05 ; Wrong game
WRONG_GAME_VER EQU $06 ; Wrong game version
WRONG_SIDE_NUM EQU $07 ; a,b side, wrong side number
WRONG_DISK_NUM EQU $08 ; disk no., wrong disk number
WRONG_ADDL_DISK_ID1 EQU $09 ; wrong additional disk ID 1
WRONG_ADDL_DISK_ID2 EQU $0a ; wrong additional disk ID 2
APPROVAL_CHECK_FAILED EQU $20 ; disk trouble, approval check failed
WRONG_SIGNATURE EQU $21 ; disk trouble, '*NINTENDO-HVC*' string in block 1 doesn't match
BLOCK_TYPE_1_EXPECTED EQU $22 ; disk trouble, block type 1 expected
BLOCK_TYPE_2_EXPECTED EQU $23 ; disk trouble, block type 2 expected
BLOCK_TYPE_3_EXPECTED EQU $24 ; disk trouble, block type 3 expected
BLOCK_TYPE_4_EXPECTED EQU $25 ; disk trouble, block type 4 expected
BLOCK_FAILED_CRC EQU $27 ;	disk trouble, ($4030.4) block failed CRC
EOF_READ EQU $28 ; disk trouble, ($4030.6) file ends prematurely during read
EOF_WRITE EQU $29 ; disk trouble, ($4030.6) file ends prematurely during write
DISK_FULL EQU $30 ; disk trouble, ($4032.1) disk is full

MACRO API_ENTRYPOINT address
	IF $ > #address
		ERROR "Previous function overflowed into following public API"
	ELSE
		PAD #address
	ENDIF
ENDM

; Fill with a KIL opcode, so we die immediately if we jump into crazytown
FILLVALUE $72

; Start assembling at the beginning of the FDS ROM area
ORG $E000

INCLUDE delay.asm

INCLUDE ppumask.asm

; Wait until next VBlank NMI fires, and return (for programs that do it the
; "everything in main" way). NMI vector selection at $100 is saved to the
; stack, but further VBlanks are disabled. Affects $FF
API_ENTRYPOINT $e1b2
; 70 bytes to work with
VINTWait:
	RTS

; Loads files specified by DiskID into memory from disk. Load addresses are
; decided by the file's header.
; Parameters: Pointer to Disk ID, Pointer to File List
; Returns: A = error #, Y = # of files loaded
API_ENTRYPOINT $e1f8
LoadFiles:
	RTS

; Appends the file data given by DiskID to the disk. This means that the file
; is tacked onto the end of the disk, and the disk file count is incremented.
; The file is then read back to verify the write. If an error occurs during
; verification, the disk's file count is decremented (logically hiding the
; written file).
; Parameters: Pointer to Disk ID, Pointer to File Header
; Returns: A = error #
API_ENTRYPOINT $e237
AppendFile:
	RTS

; Same as "Append File", but instead of writing the file to the end of the
; disk, A specifies the sequential position on the disk to write the file (0
; is the first). This also has the effect of setting the disk's file count to
; the A value, therefore logically hiding any other files that may reside after
; the written one.
; Parameters: Pointer to Disk ID, Pointer to File Header, A = file #
; Returns: A = error #
API_ENTRYPOINT $e239
WriteFile:
	RTS

; Reads in disk's file count, compares it to A, then sets the disk's file count
; to A.
; Parameters: Pointer to Disk ID, A = # to set file count to
; Returns: A = error #
API_ENTRYPOINT $e2b7
CheckFileCount:
	RTS

; Reads in disk's file count, decrements it by A, then writes the new value
; back.
; Parameters: Pointer to Disk ID, A = number to reduce current file count by
; Returns: A = error #
API_ENTRYPOINT $e2bb
AdjustFileCount:
	RTS

; Set the file count to A + 1
; Parameters: Pointer to Disk ID, A = file count minus one = # of the last file
; Returns: A = error #
API_ENTRYPOINT $e301
SetFileCount1:
	RTS

; Set the file count to A
; Parameters: Pointer to Disk ID, A = file count
; Returns: A = error #
API_ENTRYPOINT $e305
SetFileCount:
	RTS

; Fills provided DiskInfo structure with data read off the current disk.
; Parameters: Pointer to Disk Info
; Returns: A = error #
API_ENTRYPOINT $e32a
GetDiskInfo:
	RTS

API_ENTRYPOINT $e3da
AddYtoPtr0A:
	RTS

API_ENTRYPOINT $e3e7
GetHCPwNWPchk:
	RTS

API_ENTRYPOINT $e3ea
GetHCPwWPchk:
	RTS

; Compares the first 10 bytes on the disk coming after the FDS string, to 10
; bytes pointed to by Ptr($00). To bypass the checking of any byte, a -1 can be
; placed in the equivelant place in the compare string. Otherwise, if the
; comparison fails, an appropriate error will be generated.
; Parameters: Pointer to 10 byte string at $00
API_ENTRYPOINT $e445
CheckDiskHeader:
	RTS

; Reads number of files stored on disk, stores the result in $06
API_ENTRYPOINT $e484
GetNumFiles:
	RTS

; Writes new number of files to disk header.
; Parameters: A = number of files
API_ENTRYPOINT $e492
SetNumFiles:
	RTS

; Uses a byte string pointed at by Ptr($02) to tell the disk system which files
; to load. The file ID's number is searched for in the string. If an exact
; match is found, [$09] is 0'd, and [$0E] is incremented. If no matches are
; found after 20 bytes, or a -1 entry is encountered, [$09] is set to -1. If
; the first byte in the string is -1, the BootID number is used for matching
; files (any FileID that is not greater than the BootID qualifies as a match).
; Parameters: Pointer to FileID list at $02
API_ENTRYPOINT $e4a0
FileMatchTest:
	RTS

; Skips over specified number of files.
; Parameters: Number of files to skip in $06
API_ENTRYPOINT $e4da
SkipFiles:
	RTS

API_ENTRYPOINT $e4f9
LoadData:
	RTS

API_ENTRYPOINT $e506
ReadData:
	RTS

API_ENTRYPOINT $e5b5
SaveData:
	RTS

API_ENTRYPOINT $e64d
WaitForDriveReady:
	RTS

API_ENTRYPOINT $e685
StopMotor:
	RTS

API_ENTRYPOINT $e68f
CheckBlockType:
	RTS

API_ENTRYPOINT $e6b0
WriteBlockType:
	RTS

API_ENTRYPOINT $e6e3
StartXfer:
	RTS

API_ENTRYPOINT $e706
EndOfBlockRead:
	RTS

API_ENTRYPOINT $e729
EndOfBlkWrite:
	RTS

API_ENTRYPOINT $e778
XferDone:
	RTS

API_ENTRYPOINT $e794
Xfer1stByte:
	RTS

API_ENTRYPOINT $e7a3
XferByte:
	RTS

; VRAM Buffers
;  The structure of VRAM buffers are as follows:
;
; SIZE   CONTENTS
; 2      VRAM Address (big endian)
; 1      bit 0-5 length of data ($0 means a length of 64)
;        bit 6 : 0 = copy, 1 = fill
;        bit 7 : 0 = increment by 1, 1 = increment by 32
; n      Data to copy to VRAM
; .....  repeated as many times as needed
; 1      $ff
;
; * The main structure is terminated by a $ff byte (High address is always
;   supposed to be in $00..$3f range)
; * $4c is a "call" command. The 2 bytes that follow is the address of a sub-
;   VRAM structure. The sub-structure can call another sub-structure and so on.
; * $60 is a "return" command. It will terminate a sub-structure.
; * If Fill mode is used, the routine takes only 1 byte of data which is
;   repeated.
;
; The VRAM buffer is located at $300-$3xx. $300 holds the size of the buffer
; (maximum), and $301 holds the end index of the buffer. The actual buffer lies
; at $302-$3xx, and is of variable length.
;
; * $300 is initialized to the value $7d, effectively making the buffer lie at
;   $300-$37f. It's possible to change the value here to make it bigger or
;   smaller, but the biggest possible value is $fd, making the buffer lie at
;   $300-$3ff.
; * Format of the buffer is equivalent to the VRAM structure above, except that
;   there are no sub-structures, no increment by 32 flag and no fill flag.
; * For this reason, the VRAM buffer at $302 can be used as a sub-structure.
; * A call to WriteVRAMBuffer will execute faster than a call to
;   VRAMStructWrite with $302 as an argument, but both will have the same
;   effect.
;
; The structure of the VRAM read buffer itself is trivial - only single bytes
; are read (there's no runs of data). All reads are mapped to a structure of 3
; bytes in the read buffer:
;
; SIZE   CONTENTS
; 2      VRAM Address (big endian)
; 1      data
;
; Therfore, for each byte which is read from VRAM, 3 bytes have to be reserved
; in the read buffer. Once data from VRAM has been read, if it must be written
; back after a modification, the user need to copy it to the write buffer
; manually.

; Set VRAM increment to 1 (clear PPUCTRL/$ff bit 2), and write a VRAM buffer to
; VRAM.
; Affects: A, X, Y, $00, $01, $ff
; Parameters: Pointer to VRAM buffer to be written
API_ENTRYPOINT $e7bb
VRAMStructWrite:
	RTS

; Fetch a direct pointer from the stack (the pointer should be placed after the
; return address of the routine that calls this one (see "important notes"
; above)), save the pointer at ($00) and fix the return address.
; Affects: A, X, Y, $05, $06
; Returns: $00, $01 = pointer fetched
API_ENTRYPOINT $e844
FetchDirectPtr:
	RTS

; Write the VRAM Buffer at $302 to VRAM.
; Affects: A, X, Y, $301, $302
API_ENTRYPOINT $e86a
WriteVRAMBuffer:
	RTS

; Read individual bytes from VRAM to the VRAMBuffer.
; Affects A, X, Y
; X = start address of read buffer, Y = # of bytes to read
API_ENTRYPOINT $e8b3
ReadVRAMBuffer:
	RTS

; Copy pointed data into the VRAM buffer.
; Parameters: A = High VRAM address, X = Low VRAM address, Y = string length, Direct Pointer = data to be written to VRAM
; Returns: A = $ff : no error, A = $01 : string didn't fit in buffer
; Affects: A, X, Y, $00, $01, $02, $03, $04, $05, $06
API_ENTRYPOINT $e8d2
PrepareVRAMString:
	RTS

; Copy a 2D string into the VRAM buffer. The first byte of the data determines
; the width and height of the following string (in tiles):
; Upper nybble = height, lower nybble = width.
; Parameters: A = High VRAM address, X = Low VRAM address, Direct pointer = data to be written to VRAM
; Returns: A = $ff : no error, A = $01 : data didn't fit in buffer
; Affects: A, X, Y, $00, $01, $02, $03, $04, $05, $06
API_ENTRYPOINT $e8e1
PrepareVRAMStrings:
	RTS

; This routine was likely planned to be used in order to avoid useless latency
; on VRAM reads (see notes below). It compares the VRAM address in ($00) with
; the Yth (starting at 1) address of the read buffer. If both addresses match,
; the corresponding data byte is returned exit with c clear. If the addresses
; are different, the buffer address is overwritten by the address in ($00) and
; the routine exit with c set.
; Parameters: X = starting index of read buffer, Y = # of address to compare (starting at 1), $00, $01 = address to read from
; Returns: carry clear : a previously read byte was returned, carry set : no byte was read, should wait next call to ReadVRAMBuffer
; Affects: A, X, Y
API_ENTRYPOINT $e94f
GetVRAMBufferByte:
	RTS

INCLUDE nametable.asm

; Shift-register based random number generator, normally takes 2 bytes (using
; more won't affect random sequence). On reset the program is supposed to
; write some non-zero values here (BIOS uses writes $d0, $d0), and call this
; routine several times before the data is actually random. Each call of this
; routine will shift the bytes right.
; Parameters: X = Zero Page address where the random bytes are placed, Y = # of shift register bytes (normally $02)
; Affects: A, X, Y, $00
API_ENTRYPOINT $e9b1
RandomNumberGen:
	RTS

; Run Sprite DMA from RAM $200-$2FF
; Affects: A
API_ENTRYPOINT $e9c8
SpriteDMA:
	LDA #0
	STA OAMADDR
	LDA #$02
	STA OAMDMA
	RTS

; Decrement several counters in Zeropage. The first counter is a decimal
; counter 9 -> 8 -> 7 -> ... -> 1 -> 0 -> 9 -> ... Counters 1...A are simply
; decremented and stays at 0. Counters A+1...Y are decremented when the first
; counter does a 0 -> 9 transition, and stays at 0.
; Parameters: A, Y = end Zeropage address of counters, X = start zeropage address of counters
; Affects: A, X, $00
API_ENTRYPOINT $e9d3
CounterLogic:
	STX $00 ; 2 bytes
	DEC 0,X ; 2 bytes
	; if negative, set the first counter to 9, otherwise continue
	BPL @countersToA ; 2 bytes
	LDA #$09 ; 2 bytes
	STA 0,X ; 2 bytes
	; Do the A+1...Y counters now, since we know that the first counter rolled over
@countersAplus1toY:
	; there's no zp,y addressing mode, only zp,x so copy Y to X through A
	TYA ; 1 byte
@countersToA:
	TAX ; 1 byte
@loop:
	LDA 0,X ; 2 bytes
	; skip counters that are already 0
	BEQ @looptest ; 2 bytes
	DEC 0,X ; 2 bytes
@looptest:
	DEX ; 1 byte
	CPX $00 ; 2 bytes
	BNE @loop ; 2 bytes
	RTS ; 1 byte

INCLUDE gamepads.asm

INCLUDE vramfill.asm

; Fill RAM pages with specified value.
; Parameters: A = fill value, X = first page #, Y = last page #
; Affects: A, X, Y, $00, $01
API_ENTRYPOINT $ead2
MemFill:
	; Start from the high end and count down
	; The address of the start of the last page is just the Y register in the high byte of the pointer and 0 in the low byte
	STY $01
@outerloop:
	LDY #0
	STY $00
@loop:
	STA ($00),Y
	INY
	BNE @loop
	DEC $01 ; work on the next page down
	CPX $01
	BMI @outerloop ; cover the X < $01 case
	BEQ @outerloop ; cover the X == $01 case
	RTS

; This routine set scroll registers according to values in $fc, $fd and $ff.
; Should typically be called in VBlank after VRAM updates
; Parameters: $FC, $FD, $FF
; Affects: A
API_ENTRYPOINT $eaea
SetScroll:
	LDA PPUSTATUS ; reset PPU's "w" register to 0
	LDA ZP_PPUSCROLL1
	STA PPUSCROLL
	LDA ZP_PPUSCROLL2
	STA PPUSCROLL
	LDA ZP_PPUCTRL
	STA PPUCTRL
	RTS

; The instruction calling this is supposed to be followed by a jump table
; (16-bit pointers little endian, up to 128 pointers). A is the entry # to jump
; to, return address on stack is used to get jump table entries.
; Parameters: A = Jump table entry
; Affects: A, X, Y, $00, $01
API_ENTRYPOINT $eafd
JumpEngine:
	RTS

; Read Family Basic Keyboard expansion
API_ENTRYPOINT $eb13
ReadKeyboard:
	RTS

; This routine can read and write 2BP and 1BP tilesets to/from VRAM.
; The flags parameters are as follows:
;
; 7  bit  0
; ---------
; AAAA MMIT
; |||| ||||
; |||| |||+- Fill bit
; |||| ||+-- Transfer direction (0 = Write tiles, 1 = Read tiles)
; |||| ++--- Bitplane type (see below)
; ++++------ Low VRAM Address (aka tile # within a row)
;
;         1st bitplane	2nd bitplane     Description
;         -----------	-----------      -----------
;     0:  data           data+8           Normal 2-bitplane graphics
;     1:  data           fill bit         Single bitplane graphics. Fill bit clear : Use colors 0&1  Fill bit set : Use colors 2&3
;     2:  fill bit       data             Single bitplane graphics. Fill bit clear : Use colors 0&2  Fill bit set : Use colors 1&3
;     3:  data^fill bit  data             Single bitplane graphics. Fill bit clear : Use colors 0&3  Fill bit set : Use colors 1&2
; This makes it possible for single bitplane tiles to take all possible color
; schemes when they end up in VRAM. However, it is not possible to (natively)
; load single bitplane graphics directly from the disk into VRAM; it should be
; loaded into PRG-RAM before transferring the data into VRAM. In read mode, all
; non "data" bitplanes are replaced by dummy reads.
; Parameters: A = Low VRAM Address & Flags, Y = Hi VRAM Address, X = # of tiles to transfer to/from VRAM
; Affects: A, X, Y, $00, $01, $02, $03, $04
API_ENTRYPOINT $eb66
LoadTileset:
	RTS

API_ENTRYPOINT $ebaf
CPUtoPPUcopy:
	RTS

; Some kind of logic that some games use. (detail is under analysis)
; Parameters: $00-$01 Pointer to structure... ?
; Affects: A, X, Y, $02, $03, $04, $05, $06, $07, $08, $09
API_ENTRYPOINT $ec22
unk_EC22:
	RTS

API_ENTRYPOINT $ee17
StartMotor:
	RTS

;[$0102]/[$0103]: PC action on reset
;[$0101]:         PC action on IRQ. set to $80 on reset
;[$0100]:         PC action on NMI. set to $C0 on reset
;RESET:
;($DFFC):         disk game reset vector     (if [$0102] = $35, and [$0103] = $53 or $AC)
;IRQ:
;($DFFE):         disk game IRQ vector       (if [$0101] = %11xxxxxx)
; $E1EF :         BIOS acknowledge and delay (if [$0101] = %10xxxxxx)
; $E1CE :         BIOS disk transfer         (if [$0101] = %01xxxxxx)
; $E1D9 :         BIOS disk skip bytes       (if [$0101] = %00xxxxxx)
;NMI:
;($DFFA):         disk game NMI vector #3    (if [$0100] = %11xxxxxx)
;($DFF8):         disk game NMI vector #2    (if [$0100] = %10xxxxxx)
;($DFF6):         disk game NMI vector #1    (if [$0100] = %01xxxxxx)
; $E19D :         BIOS disable NMI           (if [$0100] = %00xxxxxx)

NMI:


RESET:

IRQ:
	JMP ($DFFE) ; game's IRQ vector

API_ENTRYPOINT $fffa
NMI_VEC:

RESET_VEC:

IRQ_VEC:
