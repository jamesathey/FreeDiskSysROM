#!/usr/bin/env python3
# Scan the current working directory for *.fds files, and count calls
# into the FDS BIOS from PRG code.

import glob
import os
import re
import stat
import string
import struct

apis = {
    0xe149: ['Delay132', 0],
    0xe153: ['Delayms', 0],
    0xe161: ['DisPFObj', 0],
    0xe16b: ['EnPFObj', 0],
    0xe171: ['DisObj', 0],
    0xe178: ['EnObj', 0],
    0xe17e: ['DisPF', 0],
    0xe185: ['EnPF', 0],
    0xe1b2: ['VINTWait', 0],
    0xe1f8: ['LoadFiles', 0],
    0xe237: ['AppendFile', 0],
    0xe239: ['WriteFile', 0],
    0xe2b7: ['CheckFileCount', 0],
    0xe2bb: ['AdjustFileCount', 0],
    0xe301: ['SetFileCount1', 0],
    0xe305: ['SetFileCount', 0],
    0xe32a: ['GetDiskInfo', 0],
    0xe3da: ['AddYtoPtr0A', 0],
    0xe3e7: ['GetHCPwNWPchk', 0],
    0xe3ea: ['GetHCPwWPchk', 0],
    0xe445: ['CheckDiskHeader', 0],
    0xe484: ['GetNumFiles', 0],
    0xe492: ['SetNumFiles', 0],
    0xe4a0: ['FileMatchTest', 0],
    0xe4da: ['SkipFiles', 0],
    0xe4f9: ['LoadData', 0],
    0xe506: ['ReadData', 0],
    0xe5b5: ['SaveData', 0],
    0xe64d: ['WaitForDriveReady', 0],
    0xe685: ['StopMotor', 0],
    0xe68f: ['CheckBlockType', 0],
    0xe6b0: ['WriteBlockType', 0],
    0xe6e3: ['StartXfer', 0],
    0xe706: ['EndOfBlockRead', 0],
    0xe729: ['EndOfBlkWrite', 0],
    0xe7bb: ['VRAMStructWrite', 0],
    0xe778: ['XferDone', 0],
    0xe794: ['Xfer1stByte', 0],
    0xe7a3: ['XferByte', 0],
    0xe844: ['FetchDirectPtr', 0],
    0xe86a: ['WriteVRAMBuffer', 0],
    0xe8b3: ['ReadVRAMBuffer', 0],
    0xe8d2: ['PrepareVRAMString', 0],
    0xe8e1: ['PrepareVRAMStrings', 0],
    0xe94f: ['GetVRAMBufferByte', 0],
    0xe97d: ['Pixel2NamConv', 0],
    0xe997: ['Nam2PixelConv', 0],
    0xe9b1: ['RandomNumberGen', 0],
    0xe9c8: ['SpriteDMA', 0],
    0xe9d3: ['CounterLogic', 0],
    0xe9eb: ['ReadPads', 0],
    0xea1a: ['ReadDownPads', 0],
    0xea1f: ['ReadOrDownPads', 0],
    0xea36: ['ReadDownVerifyPads', 0],
    0xea4c: ['ReadOrDownVerifyPads', 0],
    0xea68: ['ReadDownExpPads', 0],
    0xea84: ['VRAMFill', 0],
    0xead2: ['MemFill', 0],
    0xeaea: ['SetScroll', 0],
    0xeafd: ['JumpEngine', 0],
    0xeb13: ['ReadKeyboard', 0],
    0xeb66: ['LoadTileset', 0],
    0xebaf: ['CPUtoPPUcopy', 0],
    0xec22: ['unk_EC22', 0],
    0xee17: ['StartMotor', 0],
}

unknown_apis = {}

opcodeUnofficialTable = [
	False, False,  True,  True,	 True, False, False,  True,
	False, False, False,  True,  True, False, False,  True,

	False, False,  True,  True,  True, False, False,  True,
	False, False,  True,  True,  True, False, False,  True,

	False, False,  True,  True, False, False, False,  True,
	False, False, False,  True, False, False, False,  True,

	False, False,  True,  True,  True, False, False,  True,
	False, False,  True,  True,  True, False, False,  True,

	False, False,  True,  True,  True, False, False,  True,
	False, False, False,  True, False, False, False,  True,

	False, False,  True,  True,  True, False, False,  True,
	False, False,  True,  True,  True, False, False,  True,

	False, False,  True,  True,  True, False, False,  True,
	False, False, False,  True, False, False, False,  True,

	False, False,  True,  True,  True, False, False,  True,
	False, False,  True,  True,  True, False, False,  True,

	 True, False,  True,  True, False, False, False,  True,
	False,  True, False,  True, False, False, False,  True,

	False, False,  True,  True, False, False, False,  True,
	False, False, False,  True,  True, False,  True,  True,

	False, False, False,  True, False, False, False,  True,
	False, False, False,  True, False, False, False,  True,

	False, False,  True,  True, False, False, False,  True,
	False, False, False,  True, False, False, False,  True,

	False, False,  True,  True, False, False, False,  True,
	False, False, False,  True, False, False, False,  True,

	False, False,  True,  True,  True, False, False,  True,
	False, False,  True,  True,  True, False, False,  True,

	False, False,  True,  True, False, False, False,  True,
	False, False, False,  True, False, False, False,  True,

	False, False,  True,  True,  True, False, False,  True,
	False, False,  True,  True,  True, False, False,  True,
]

roms = glob.glob("*.fds")

for r in roms:
    info = os.stat(r)
    disks = []
    counts = {}

    with open(r, 'rb') as f:
        print(r + ':')

        if info.st_size % 65500 == 16:
            # skip optional FDS header
            f.seek(16)

        for side in range(info.st_size // 65500):
            disks.append(f.read(65500))

    try:
        for disk in disks:
            # skip blocks 1 and 2
            if disk[0] != 1:
                raise Exception('Expected block 1, got {}'.format(disk[0]))

            if disk[56] != 2:
                raise Exception('Expected block 2, got {}'.format(disk[56]))

            num_files = disk[57]
            current_file = 0

            pos = 58
            while pos < 65500:
                # Now, read blocks 3 and 4 until the end of the disk
                header = disk[pos:pos+16]
                pos += 16

                # all zeroes at the end of the disk
                if header[0] == 0:
                    break

                header_fields = struct.unpack('<BBB8sHHB', header)

                current_file += 1

                if header_fields[0] != 3:
                    if current_file > num_files:
                        # Disk side should end with all zeroes, but this one doesn't. Move on.
                        break
                    else:
                        raise Exception('Expected a block 3, got {} before file {} of {}'.format(header_fields[0], current_file, num_files))

                filesize = header_fields[5]
                filetype = header_fields[6]

                if disk[pos] != 4:
                    raise Exception('Expected a block 4, got {} before file {} of {}'.format(disk[pos], current_file, num_files))

                pos += 1

                contents = disk[pos:pos+filesize]
                pos += filesize

                if filetype != 0:
                    continue

                # $20 == JSR, then low byte and high byte of absolute address, then following opcode
                matches = re.findall(b'\x20(.)([\xe0-\xff])(.)', contents)

                for m in matches:
                    pieces = struct.unpack('<HB', m[0] + m[1] + m[2])
                    addr = pieces[0]
                    nextopcode = pieces[1]

                    # reject matches that start before the first API
                    if addr < 0xe149:
                        continue

                    # reject matches followed by an invalid opcode, to cut down on some False positives
                    if opcodeUnofficialTable[nextopcode]:
                        continue

                    # TODO reject addresses in the middle of APIs (requires API length)
                    if addr not in counts:
                        counts[addr] = 1
                    else:
                        counts[addr] = counts[addr] + 1

        for addr in sorted(counts):
            if addr in apis:
                print('| ${:04x} | {} | {} |'.format(addr, apis[addr][0], counts[addr]))
                apis[addr][1] = apis[addr][1] + 1
            else:
                print('| ${:04x} | | {} |'.format(addr, counts[addr]))
                if addr in unknown_apis:
                    unknown_apis[addr] = unknown_apis[addr] + 1
                else:
                    unknown_apis[addr] = 1
    except Exception as err:
        print(err)

print('Totals:')
print('Known APIs:')
for addr in sorted(apis):
    print('| ${:04x} | {} | {} |'.format(addr, apis[addr][0], apis[addr][1]))
print('Unknown APIs and false positives:')
for addr in sorted(unknown_apis):
    print('| ${:04x} | | {} |'.format(addr, unknown_apis[addr]))
