Breakers - Steam Deck / Linux x86_64 AppImage
============================================

This is a native static recompilation of Breakers (Neo Geo MVS, MAME set
"breakers", NGM-230).  The game's 68000 program runs as C compiled ahead of
time by NeoGeoRecomp; it is not an emulator wrapper.  Musashi remains as the
fallback for code the recompiler could not cover and as the correctness
oracle.

No game or BIOS data is included.  You must supply your own legally obtained
ROM files.

ROM files
---------
Put the unzipped MAME "breakers" set and the Neo Geo BIOS files in:

    ~/.local/share/breakers/roms/

or beside the AppImage in a "roms" directory, or pass --rom-path DIR.

The launcher also checks:
    ~/Emulation/roms/breakers, ~/roms/breakers, ~/roms

Expected game files (SHA1 in README.md of the source project):
    230-p1.p1  230-c1.c1 .. 230-c4.c4  230-s1.s1  230-m1.m1
    230-v1.v1  230-v2.v2

Expected system files (from the "neogeo" set):
    sp-s2.sp1  sfix.sfix  sm1.sm1  000-lo.lo

Controls (keyboard)
-------------------
    Arrows      move
    Z X C V     Neo Geo A B C D
    5 / 6       coin 1 / coin 2
    1 / 2       start 1P / 2P
    3           select
    F2          test switch
    F11         fullscreen toggle
    Esc         quit

Gamepad (SDL2 GameController, Steam Input friendly)
---------------------------------------------------
    D-pad / left stick   move
    A B X Y              Neo Geo A B C D
    Start                start
    Back                 coin
    Left shoulder        select

On a first Steam Deck launch, Steam Input's default gamepad layout works as
above.  The AppRun launcher adds --fullscreen (4:3 pillarboxed into the
16:10 panel) unless you pass --headless, --fullscreen or --scale yourself.

Options
-------
    --rom-path DIR   --bios-path DIR   --bios FILE
    --fullscreen     --scale N         --headless
    --frames N       --input FILE      --wav FILE
    --verify         --interp          --dump-misses FILE

Licensing
---------
The original project code is licensed under PolyForm Noncommercial 1.0.0
(see LICENSE.txt), confirmed by the repository owner on 2026-10-27.
NeoGeoRecomp is MIT; Musashi and superzazu/z80 are MIT; ymfm is
BSD-3-Clause; SDL2 is zlib.  Their notices are in LICENSES/ and
THIRD_PARTY_NOTICES.txt.  Breakers and Neo Geo are trademarks of SNK
Corporation; this project is not affiliated with or endorsed by SNK.

No ROMs, BIOS images, recompiled C or entry-point lists are distributed.
