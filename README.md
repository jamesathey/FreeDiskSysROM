# FreeDiskSysROM

This project has one goal - a compatible re-implementation of the Famicom Disk System BIOS under an OSS license. Unlike the Famicom console itself, which has no program ROM built-in, the Famicom Disk System includes an 8 KiB PRG-ROM containing disk I/O routines, VRAM transfer routines, joypad reading code, and an animation featuring Mario and Luigi when no disk is present in the drive, and more. The code, data, graphics, music, and animation contained in the original BIOS are copyrighted by Nintendo.

FreeDiskSysROM aims to provide a replacement for the original FDS BIOS that can be freely redistributed and that is capable of running all published FDS software.

# Audience

## Emulators

Famicom and NES emulators historically require a dump of the Famicom Disk System BIOS to be able to emulate FDS titles. Emulators can ship FreeDiskSysROM with their installers instead of requiring end-users to either copy the ROM out of their own FDS hardware or breaking copyright law by downloading a BIOS rip from elsewhere on the Internet.

## Clone hardware

Modern hardware clones of the FDS RAM Adapter or FPGA re-implementations of the entire Famicom Disk System also need a BIOS.

# Status

## APIs

| Address | Name | # of Games | Implemented |
| ------- | ---- | ------- | ----------- |
| $e149 | Delay131 | | :white_check_mark: |
| $e153 | Delayms | | :white_check_mark: |
| $e161 | DisPFObj | | :white_check_mark: |
| $e16b | EnPFObj | | :white_check_mark: |
| $e171 | DisObj | | :white_check_mark: |
| $e178 | EnObj | | :white_check_mark: |
| $e17e | DisPF | | :white_check_mark: |
| $e185 | EnPF | | :white_check_mark: |
| $e1b2 | VINTWait | | |
| $e1f8 | LoadFiles | | |
| $e237 | AppendFile | | |
| $e239 | WriteFile | | |
| $e2b7 | CheckFileCount | | |
| $e2bb | AdjustFileCount | | |
| $e301 | SetFileCount1 | | |
| $e305 | SetFileCount | | |
| $e32a | GetDiskInfo | | |
| $e3da | AddYtoPtr0A | | |
| $e3e7 | GetHCPwNWPchk | | |
| $e3ea | GetHCPwWPchk | | |
| $e445 | CheckDiskHeader | | |
| $e484 | GetNumFiles | | |
| $e492 | SetNumFiles | | |
| $e4a0 | FileMatchTest | 0 | |
| $e4da | SkipFiles | 0 | |
| $e4f9 | LoadData | | |
| $e506 | ReadData | | |
| $e5b5 | SaveData | | |
| $e64d | WaitForDriveReady | | |
| $e685 | StopMotor | | |
| $e68f | CheckBlockType | | |
| $e6b0 | WriteBlockType | | |
| $e6e3 | StartXfer | | |
| $e706 | EndOfBlockRead | | |
| $e729 | EndOfBlkWrite | | |
| $e778 | XferDone | | |
| $e794 | Xfer1stByte | | |
| $e7a3 | XferByte | | |
| $e7bb | VRAMStructWrite | | |
| $e844 | FetchDirectPtr | | |
| $e86a | WriteVRAMBuffer | | |
| $e8b3 | ReadVRAMBuffer | | |
| $e8d2 | PrepareVRAMString | | |
| $e8e1 | PrepareVRAMStrings | | |
| $e94f | GetVRAMBufferByte | | |
| $e97d | Pixel2NamConv | | :white_check_mark: |
| $e997 | Nam2PixelConv | | :white_check_mark: |
| $e9b1 | Random | | :white_check_mark: |
| $e9c8 | SpriteDMA | | :white_check_mark: |
| $e9d3 | CounterLogic | | :white_check_mark: |
| $e9eb | ReadPads | | :white_check_mark: |
| $ea1a | ReadDownPads | | :white_check_mark: |
| $ea1f | ReadOrDownPads | | :white_check_mark: |
| $ea36 | ReadDownVerifyPads | | :white_check_mark: |
| $ea4c | ReadOrDownVerifyPads | | :white_check_mark: |
| $ea68 | ReadDownExpPads | | :white_check_mark: |
| $ea84 | VRAMFill | | :white_check_mark: |
| $ead2 | MemFill | | :white_check_mark: |
| $eaea | SetScroll | | :white_check_mark: |
| $eafd | JumpEngine | | :white_check_mark: |
| $eb13 | ReadKeyboard | 0 | |
| $eb66 | LoadTileset | | |
| $ebaf | CPUtoPPUcopy | | |
| $ec22 | unk_EC22 | | |
| $ee17 | StartMotor | | |

## Initialization

# Contributing

Rules:

1. Do not even look at a disassembly of the original FDS BIOS.
1. Only contribute code to which you hold the copyright or which is already under a compatible license.

# License

FreeDiskSysROM is licensed under the GNU LGPL v3. The intent in using this license is to allow anyone to replace the 8 KiB official FDS BIOS with FreeDiskSysROM, whether for commerical or non-commercial purposes, so long as the source of FreeDiskSysROM (including any modifications) is made available to the end-user under the same license.

Although the Famicom does not have an OS or any concept of dynamic linking, the FDS BIOS is analogous to a system library in practice. FDS titles, FDS emulators, and FDS clone systems are all permitted to utilize FreeDiskSysROM without regard to or changes to the licenses of their own code.
