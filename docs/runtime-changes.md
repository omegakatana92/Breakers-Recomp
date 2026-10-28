# Runtime changes in the vendored toolkit

`neogeorecomp/` starts from the upstream v0.2.0 tree (commit
`af96b2b4b39b42b392b17bcaa6a74a5f27088202`, see `toolkit.ref`). It carries
generic fixes made in the earlier ports plus two fixes added for this
project. None of them contains a Breakers address, title string or
title-specific branch; the game supplies its own data through `ng_game_t`.

| File | Change | Why it is generic |
|---|---|---|
| `src/video.c` | Allocate the sprite region at the next power of two, zero-filled, matching the tile-number mask | MAME pads the sprite region to the address mask. A set whose C ROMs are not power-of-two sized (the sibling Breakers Revenge port is 24 MB; KOF '97 is 40 MB) read past the allocation and crashed as soon as a tile code used the upper address bit. |
| `src/window_sdl.c` | Open the device at its supported rate/format and convert with `SDL_AudioStream`; start with a 60 ms cushion; never pad silence or drop a whole frame | 55,555 Hz is not a common device rate, and the old queue policy inserted silence or dropped 17 ms frames under normal scheduling jitter, which is audible as clicks/dropouts. |
| `src/audio.c` | M1 bank mask `(size - 1) & 0x3FFFF`, no extra `0x10000` base; `audio_sync()` before taking samples | Matches MAME `init_audio()`; banked music data was read 64 KB too high in older copies and the Z80 could starve when the 68k did not poll a sound port. |
| `src/audio.c` | YM2610 timers/status and the M1 bank select follow MAME's formulas | Hardware behaviour, not cart data. |
| `include/neogeorecomp/neogeo.h`, `src/bus.c` | Optional `bank_map`, `bank_write_addr`, `prot_read_addr`, `rng_read_addr`, NEO-SMA RNG, watchdog | Other NEO-SMA/CMC carts use the same devices; Breakers uses only the plain selector and leaves these zero. |
| `src/video.c` | `NG_FIX_BANK_GAROU` / `NG_FIX_BANK_KOF2000` fixed-layer banking | Late carts bank the S ROM; Breakers has a 128 KB S ROM and uses the plain path. |
| `src/neogeo.c`, `src/window_sdl.c`, `src/platform.c` | `--fullscreen`, 4:3 pillarboxing | Generic presentation option. |
| `CMakeLists.txt` | `/O1` and `/bigobj` for the generated giant functions on MSVC | Build-time workaround, no behaviour change. |

## Sprite-region padding

MAME's sprite address mask is derived from the fitted ROM size rounded up to
a power of two, and the region is zero-filled to that size. The previous
runtime computed the same mask but allocated only the fitted size, so a
tile code in the padding read uninitialised heap or unmapped memory. The
fix allocates `pow2 * 256` bytes with `calloc`.

This was found while bringing up the sibling Breakers Revenge port: its 24 MB
of C data is not a power of two (the mask is `0x3FFFF`, the allocation was
48 MB, the mask addresses up to 64 MB), and the first attract-mode sprite
with an upper tile-code bit crashed in `draw_sprites`.

## Audio output

The old path:

```c
SDL_OpenAudioDevice(NULL, 0, &want /* 55555 Hz */, NULL, 0);
if (queued > 120 ms) return;                   /* drops the frame */
if (queued < 30 ms) queue silence;             /* pads with a gap */
```

Only the exact 55,555 Hz format was requested (`allowed_changes = 0`), so
devices that do not accept it failed to open. When they did open, normal
frame jitter made the queue cross both thresholds, producing periodic
silence and dropped 17 ms chunks.

The replacement requests S16 stereo at 55,555 Hz but allows the device to
choose its rate/format, converts with `SDL_AudioStream`, starts playback
once 60 ms is queued, drains every converted sample, and only clears the
queue after a >150 ms stall. The WAV writer is unchanged, so headless
captures still record the YM2610's native 55,555 Hz output.

## Verification of the changes

* `--verify`: 10,966,716 blocks, 0 mismatches (6,000 frames).
* No-input native and interpreter runs produce the same opening frames.
* Breakers boots, renders and plays with the real BIOS.
* SDL audio opens under Windows (no "no sound" warning) and under Xvfb with
  the dummy driver; the AppImage exits cleanly in windowed and fullscreen
  modes.
