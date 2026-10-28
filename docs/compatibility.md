# Compatibility

Game: **Breakers** (MAME `breakers`, NGM-230, Visco 1996)
Toolkit: NeoGeoRecomp v0.2.0 + the generic fixes in
`docs/runtime-changes.md`
Board model: MVS (real `sp-s2.sp1` system ROM, no BIOS HLE)

| Area | Implemented | Verified |
|---|---|---|
| 68000 execution | full 68000 decoder/emitter, flat dispatch, Musashi fallback | `--verify`, 10.43M blocks, 0 mismatches |
| BIOS boot | real MVS system ROM: memory test, eyecatcher, calendar, coin/credit | screenshots at frames 600 and 2400 |
| P ROM banking | PROGBK1 one-MB window at `$200000`, selector `$2FFFF0` | boot + gameplay |
| Sprite rendering | per-scanline, sticky chains, L0 shrink, 96/line, auto-animation | attract and match screenshots |
| Fixed layer | 128 KB `230-s1.s1` | title, HUD, how-to-play, character select |
| Palette | both banks, backdrop | all screenshots |
| Raster IRQ | timer IRQ per scanline | gameplay timing |
| Z80 sound CPU | real `230-m1.m1` driver, NMI/reply latches, M1 banking | audio capture vs MAME 0.242 |
| YM2610 | FM, SSG, ADPCM-A from `230-v1/v2` through ymfm | WAV captured and compared with MAME 0.242 |
| SDL2 input | keyboard + two GameControllers | keyboard scripted; pad path exercised at startup |
| SDL2 audio | device-rate conversion, 60 ms cushion | Windows windowed run, Xvfb AppImage run |
| Fullscreen | 1280x800 fullscreen desktop, 4:3 pillarbox | Xvfb 1280x800 run |
| ROM validation | MAME layout and SHA1 values | match |

## Native coverage

* 6,000 frames `--verify`: 10,431,427 blocks, 0 mismatches.
* 20,000 frames with `tests/play.txt`: **100.00% native, 0 interpreted,
  0 uncovered entries** after the profile pass.
* A 12,000-frame run reports 150 interpreted instructions / 3 uncovered
  entries on an RTC-dependent demo path; the game code itself is 100%
  recompiled.

## Not verified

* Physical Steam Deck LCD/OLED, Gaming Mode or Steam Input hardware.
* Subjective listening on real speakers; audio is validated by waveform
  continuity and a MAME level/timeline comparison.
* Two-player versus and mahjong-panel DIP settings.

## Hardware notes

Breakers is a plain NEO-MVS PROGBK1 / CHA42G-3B cart. It does not use the
NEO-SMA protection device, CMC42/CMC50 graphics encryption, a banked S ROM,
or a separate ADPCM-B ROM. The generic runtime paths for those devices are
present (shared with the other ports) but are not exercised by this game
except for the standard Z80 M1 banking.
