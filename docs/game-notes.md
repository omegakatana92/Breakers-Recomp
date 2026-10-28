# Game notes

## Boot/gameplay timeline

Measured on the real BIOS at 59.1856 Hz from power-on:

| Frame | Screen |
|---:|---|
| ~0-120 | BIOS self-test / eyecatcher |
| ~400-900 | BIOS memory check and credit screen |
| ~1000-2000 | attract/intro |
| ~2400 | title / "INSERT COIN" / "LEVEL-4" |
| ~2500 | coin accepted |
| ~2700 | Start enters HOW TO PLAY |
| ~2700-5500 | tutorial pages (they advance on their own) |
| ~6000 | character select; the timer reaches 00 and auto-selects if no button is pressed |
| ~8000 | match begins (1P vs CPU) |

`tests/coin_start.txt` inserts a coin at 2500 and starts at 2700.
`tests/play.txt` continues with an attack sweep from 8500.

## Native coverage

Unlike the later Breakers Revenge, the original Breakers does not copy
helper routines into work RAM in the measured sessions. After one profile
pass the 20,000-frame scripted run reports:

```
[exec] native blocks 39454179, native instructions 386034955,
       interpreted instructions 0 (100.00% native), 0 uncovered entry points
```

A 12,000-frame run with the same script reported 150 interpreted
instructions and 3 uncovered entries, which depend on the RTC-seeded demo
path; they are correct but not statically known. The 20,000-frame profile
run is the coverage figure quoted in the README.

## Sprite data

Breakers has 16 MB of C ROM in four 4 MB files (two odd/even pairs). That is
a power-of-two size, so the hardware tile-number mask does not reach past
the fitted data and the sprite-padding bug found in the 24 MB Breakers
Revenge set is not triggered here. The runtime still pads the region, which
is the correct generic behaviour.

## Audio

The sound program is a standard 128 KB M1 with four banked windows. The M1
bank mask `(size - 1) & 0x3FFFF` with no extra region base (MAME's
`init_audio()`) is in this runtime. A 202 s scripted capture has no silent
run after boot, and MAME 0.242's per-second level timeline for the boot /
intro / title window matches ours with about a one-second boot offset.

## ROM identity

The supplied `breakers.zip` contains the plain MVS set plus a `neogeo` BIOS
collection. `230-p1.p1` SHA1 `3fb77ae6…` matches MAME's `breakers`.
The earlier port in `releases/breakers-revenge` is the separate game
**Breakers Revenge** (`breakrev`, NGM-245); it is kept for reference and is
not used here.
