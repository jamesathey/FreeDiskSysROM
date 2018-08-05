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

### Disk I/O

### Joypad Input

### VRAM Routines

## Initialization

## Extras

# Contributing

Rules:

1. Do not even look at a disassembly of the original FDS BIOS.
1. Only contribute code to which you hold the copyright or which is already under a compatible license.

# License

FreeDiskSysROM is licensed under the GNU LGPL v3. The intent in using this license is to allow anyone to replace the 8 KiB official FDS BIOS with FreeDiskSysROM, whether for commerical or non-commercial purposes, so long as the source of FreeDiskSysROM (including any modifications) is made available to the end-user under the same license.

Although the Famicom does not have an OS or any concept of dynamic linking, the FDS BIOS is analogous to a system library in practice. FDS titles, FDS emulators, and FDS clone systems are all permitted to utilize FreeDiskSysROM without regard to or changes to the licenses of their own code.
