# Testing

All commands were run on 2026-10-27. ROMs were the supplied `breakers.zip`
(unzipped to `roms-src/`), BIOS `sp-s2.sp1`.

## ROM validation

* `230-p1.p1` 2,097,152 bytes, SHA1 `3fb77ae696d92d2f9a5d589e08b708545c7cda0a`.
* `230-s1.s1` SHA1 `c166038128d7004f69932141f83b320a35c2b4ca`.
* `230-m1.m1` SHA1 `1e6442a7ea82ada9503d71045dd93e12bd05254f`.
* `230-v1.v1` SHA1 `acd0558960ec29bfc3e3ee99d00e503bebff8513`.
* `230-v2.v2` SHA1 `26d09b8b18b4b802dbda4d6f06626c24d0b7c512`.
* `230-c1..c4` SHA1 values match MAME's CHA42G planes.
* Layout and sizes match MAME `ROM_START( breakers )`.
* `sp-s2.sp1`, `sfix.sfix`, `sm1.sm1` and `000-lo.lo` present.
* The fixed bank has the word-swapped `NEO-GEO` signature at `$100`.

## Interpreter boot

```
Breakers.exe --headless --interp --rom-path roms-src --frames 3600
             --screenshot 600:shots/i600.png --screenshot 2400:shots/i2400.png
```

The BIOS eyecatcher/intro and the BREAKERS title render. The title at 2400
shows "INSERT COIN", "LEVEL-4" and the Visco 1996 notice.

## Native build

MSVC 2022/2026 and gcc 11 both build the player. The recompiler reports:

```
[m68krecomp] breakers: 898706 instructions emitted across routines
[m68krecomp] 16004 routines, 28651 dispatch entries
```

## CPU verification

```
Breakers.exe --headless --verify --rom-path roms-src --frames 6000 --input tests/play.txt
[verify] 10431427 blocks checked, 0 mismatches
[exec] native blocks 10431427, native instructions 118180064,
       interpreted instructions 0 (100.00% native), 0 uncovered entry points
```

## Coverage

```
profile target:  6000 frames no input + 20000 frames tests/play.txt
                 -> 157 runtime-only entry points added
rebuild:         28,808 dispatch entries
20,000 frames:   native blocks 39,454,179, native instructions 386,034,955,
                 interpreted instructions 0 (100.00% native),
                 0 uncovered entry points
```

A 12,000-frame run of the same script reported 150 interpreted instructions
and 3 uncovered entries, which come from an RTC-seeded demo path. They are
correct but not statically known; the 20,000-frame profile run is the
quoted coverage.

## Gameplay

Screenshots taken from the Release executable with `tests/play.txt`:

| Frame | Result |
|---:|---|
| 2400 | BREAKERS title, INSERT COIN, LEVEL-4 |
| 3000 | HOW TO PLAY after coin/start |
| 6000 | CHARACTER SELECT, SHO, timer 00 |
| 8999 | match, 1P SHO vs RILA, timer 74, attacks landing |

No crash over 20,000 frames.

## Audio

```
Breakers.exe --headless --rom-path roms-src --frames 12000 \
             --input tests/play.txt --wav shots/breakers.wav
python tests/check_audio.py shots/breakers.wav --from 10 --max-silence 3
  window 10s..202s  median RMS 1883.8
  longest silent run 0.0s (limit 3.0s)
  result: PASS
```

MAME 0.242 reference: `mame breakers -wavwrite` for 20 s with no input.
Per-second RMS timelines agree with about a one-second boot offset (MAME
13 s: 3335 / ours 12 s: 2297, MAME 14 s: 3470 / ours 13 s: 4151). The
sound ROM banking, FM, SSG and ADPCM-A therefore produce the same music and
effects.

The SDL output path was exercised on Windows in a window with no "no sound"
warning, and in the AppImage under Xvfb with the dummy audio driver
(180 frames, fullscreen, exit 0).

## Windows package

`dist/windows/Breakers-Windows-x64/Breakers.exe` was launched from the
package (`--headless --frames 600`, screenshot written) and in a window
(`--frames 240 --scale 2`). SDL2 and the VC++ runtime DLLs are beside it.

## Steam Deck AppImage

```
APPIMAGE_EXTRACT_AND_RUN=1 ./Breakers-SteamDeck-x86_64.AppImage \
    --headless --rom-path ./roms-src --frames 600
[exec] native blocks 186565, native instructions 11429782,
       interpreted instructions 0 (100.00% native), 0 uncovered entry points
```

Fullscreen 1280x800 under Xvfb + openbox: 180 frames, exit 0. The AppImage
contains the new `SDL_AudioStream` output path (`nm -D` shows
`SDL_NewAudioStream`/`SDL_AudioStreamPut`). `ldd` resolves SDL2 from the
bundle; all other libraries are standard SteamOS glibc/X11/PulseAudio
dependencies.

**Not performed:** physical Steam Deck (LCD/OLED), Gaming Mode, Steam Input
hardware, and subjective listening.
