# Breakers - native Neo Geo recompilation

A native, static recompilation of **Breakers** (Visco, 1996; MAME set
`breakers`, NGM-230) built on [sp00nznet's
NeoGeoRecomp](https://github.com/sp00nznet/neogeorecomp) v0.2.0.

The 68000 program from the cartridge is translated ahead of time into C
(one function per entry point) and compiled into the player. It is not an
emulator wrapper: the game code runs natively. Musashi is linked as the
fallback for addresses the static analysis cannot prove to be code (and as
the `--verify` oracle), but it is not used in the measured sessions below.

## Deliverables

| Platform | File |
|---|---|
| Windows x64 | `dist/windows/Breakers-Windows-x64/Breakers.exe` (and `.zip`) |
| Steam Deck / Linux x86_64 | `dist/steamdeck/Breakers-SteamDeck-x86_64.AppImage` |

No ROMs, BIOS files, recompiled C, entry lists or decrypted data are
distributed. Put your own legally obtained dump in `roms-src/` (or pass
`--rom-path`).

## Status (measured 2026-10-27)

| Check | Result |
|---|---|
| Boot through real `sp-s2.sp1` MVS BIOS | yes: eyecatcher, self-test, title |
| Coin / Start | yes |
| HOW TO PLAY, character select, match | yes |
| Native recompilation | 898,706 instructions, 16,004 routines, 28,651 dispatch entries |
| Profile pass | 157 runtime-only entries added; 28,808 dispatch entries |
| `--verify`, 6,000 frames | **10,431,427 blocks, 0 mismatches** |
| Native coverage, 20,000-frame run | **100.00% native, 0 interpreted, 0 uncovered** |
| Audio continuity, 12,000 frames (202 s) | **0 silent runs** after boot; median RMS 1884 |
| Audio vs MAME 0.242 | matching level/track timeline across boot, intro and title |
| Windowed Windows build | runs, SDL audio device opens with rate conversion |
| Linux AppImage | runs headless and fullscreen 1280x800 under Xvfb; `ldd` has no missing libraries |
| Physical Steam Deck | **not tested** (no hardware available) |

## ROM set

Verified against MAME's `ROM_START( breakers )` (`src/mame/snk/neogeo.cpp`)
and the supplied archive's SHA1 hashes.

| File | Size | Role |
|---|---:|---|
| `230-p1.p1` | 2,097,152 | 68000 program: file `$100000` is the fixed bank, file `$000000` the banked MB |
| `230-c1.c1` .. `230-c4.c4` | 4 MB each | CHA42G sprite planes, odd/even pairs (16 MB total) |
| `230-s1.s1` | 131,072 | fixed layer |
| `230-m1.m1` | 131,072 | Z80 sound driver |
| `230-v1.v1`, `230-v2.v2` | 4 MB each | ADPCM-A samples (8 MB) |
| `sp-s2.sp1` | 131,072 | MVS Asia/Europe BIOS |
| `sfix.sfix`, `sm1.sm1`, `000-lo.lo` | | BIOS fixed layer, sound driver, sprite shrink table |

The P ROM is loaded 16-bit word-swapped, second half first, exactly as
MAME's `ROM_LOAD16_WORD_SWAP` + `ROM_CONTINUE`. The cart is a plain NEO-MVS
PROGBK1 / CHA42G-3B (one 1 MB bank at `$200000`, selector `$2FFFF0`): no
encryption, no CMC/SMA protection, no S-ROM banking.

SHA1 values from the supplied set:

| File | SHA1 |
|---|---|
| `230-p1.p1` | `3fb77ae696d92d2f9a5d589e08b708545c7cda0a` |
| `230-c1.c1` | `2e820067f6963669f104bebf19e865fe4127b4dd` |
| `230-c2.c2` | `efc4ffd790953ac7c25d5f045c64a9b49d24b096` |
| `230-c3.c3` | `0ae74f3b4b3b88f128c6d8c0f35ffa53f5d67ef2` |
| `230-c4.c4` | `9ff6930c0c3d79b46b86356e8565ce4fcd69ac38` |
| `230-s1.s1` | `c166038128d7004f69932141f83b320a35c2b4ca` |
| `230-m1.m1` | `1e6442a7ea82ada9503d71045dd93e12bd05254f` |
| `230-v1.v1` | `acd0558960ec29bfc3e3ee99d00e503bebff8513` |
| `230-v2.v2` | `26d09b8b18b4b802dbda4d6f06626c24d0b7c512` |

All match MAME's `breakers` set.

## Getting started

### Windows

```powershell
# 1. Unzip breakers.zip into roms-src (or use your existing folder).
# 2. Build (Visual Studio 2022/2026 + SDL2 development package):
powershell -ExecutionPolicy Bypass -File scripts\build-windows.ps1 `
    -RomDir .\roms-src `
    -SdlDir C:\path\to\SDL2-2.32.10\cmake

# 3. Play:
build-windows\Release\Breakers.exe --rom-path .\roms-src
```

### Linux / Steam Deck

```bash
sudo apt install build-essential cmake libsdl2-dev
./scripts/build-linux.sh ./roms-src
./build-linux/Breakers --rom-path ./roms-src

# AppImage (appimagetool is downloaded or supplied with APPIMAGETOOL=...)
./packaging/appimage/build-appimage.sh ./roms-src
```

The AppImage looks for ROMs in `~/.local/share/breakers/roms`, a `roms`
folder beside the AppImage, `~/Emulation/roms/breakers`, `~/roms/breakers`
and `~/roms`; `--rom-path` always wins.

## Controls

Keyboard: arrows; **Z X C V** = A B C D; **5/6** = coin 1/2; **1/2** =
start 1P/2P; **3** = select; **9** = service; **F2** = test; **F11** =
fullscreen; **Esc** = quit.

Gamepad (SDL2 GameController, Steam Input friendly): D-pad/left stick;
**A B X Y** = A B C D; Start; Back = coin; left shoulder = select.

Insert a coin before Start, as on the real MVS cabinet.

## Verification

```powershell
# Correctness: every native block replayed in Musashi.
Breakers.exe --headless --verify --rom-path .\roms-src `
    --frames 6000 --input tests\play.txt

# Coverage and profiling.
Breakers.exe --headless --rom-path .\roms-src `
    --frames 20000 --input tests\play.txt
cmake --build build-windows --config Release --target profile
cmake --build build-windows --config Release --target breakers

# Audio continuity (fails on music-sized silence).
Breakers.exe --headless --rom-path .\roms-src --frames 12000 `
    --input tests\play.txt --wav audio.wav
python tests\check_audio.py audio.wav --from 10 --max-silence 3
```

See `docs/testing.md` for the full evidence and `docs/game-notes.md` for the
boot/gameplay timeline used by the scripts.

## Repository layout

```
src/                  game.c/game.h ROM layout, main.c player, recomp_main.c
neogeorecomp/         vendored toolkit (MIT) plus generic fixes
tests/                input scripts and the audio continuity checker
packaging/appimage/   AppRun, desktop file, icon, AppImage builder
scripts/              Windows and Linux build helpers
docs/                 compatibility, notes, testing, runtime changes
dist/                 packaged Windows and Steam Deck builds
```

## Licensing

Original project code: **PolyForm Noncommercial 1.0.0**
(`LICENSE`), confirmed by the repository owner on 2026-10-27. The upstream
`neogeorecomp/` toolkit is MIT; Musashi and superzazu/z80 are MIT; ymfm is
BSD-3-Clause; SDL2 is zlib. Their notices are preserved in
`neogeorecomp/` and `THIRD_PARTY_NOTICES.md`.

PolyForm Noncommercial does not permit commercial redistribution. Breakers
and Neo Geo are trademarks of SNK Corporation; this project is not
affiliated with or endorsed by SNK.

No ROMs, BIOS images, recompiled C or entry lists are distributed. Users
supply their own dumps.
