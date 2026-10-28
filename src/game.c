/*
 * game.c - Breakers (MAME set "breakers", NGM-230), the verified ROM layout
 * shared by the player and the recompiler.
 *
 * The supplied archive is the plain MVS release.  Every file's SHA1 was
 * checked against MAME's ROM_START( breakers ) in src/mame/snk/neogeo.cpp,
 * so there is no decryption, no protection device and no S-ROM extraction:
 *
 *   230-p1.p1   2 MB   TC5316200 program, stored 16-bit word-swapped.
 *                      MAME loads file offset $100000 at dest $000000
 *                      (the fixed bank with the NEO-GEO header) and then
 *                      ROM_CONTINUE at dest $100000 from file offset 0.
 *   230-c1..c4  4 x 4 MB CHA42G graphics, odd/even bitplane pairs
 *                      (planes 0/1 and 2/3), 16 MB total.
 *   230-s1.s1   128 KB fixed-layer tiles
 *   230-m1.m1   128 KB Z80 sound driver (NEO-ZMC banking)
 *   230-v1/v2   8 MB ADPCM-A samples (V1 then V2)
 *
 * The cart is a standard NEO-MVS PROGBK1: one 1 MB bank behind the $200000
 * window, selected by a write to $2FFFF0-$2FFFFF.  No bank map, no CMC
 * protection, no S-ROM banking, no SMA.
 */
#include "game.h"

const ng_game_t k_breakers = {
    .name = "breakers",
    .title = "Breakers",
    .prom_size = 0x200000,          /* 1 MB fixed + 1 MB banked */
    .prom = {
        /* file          file offset  dest       length    swap */
        {"230-p1.p1",  0x100000,    0x000000,  0x100000, 1},
        {"230-p1.p1",  0x000000,    0x100000,  0x100000, 1},
    },
    .crom_size = 0x1000000,         /* 16 MB after pairing */
    .crom_pairs = {
        {"230-c1.c1", "230-c2.c2"},
        {"230-c3.c3", "230-c4.c4"},
    },
    .srom = "230-s1.s1",
    .m1 = "230-m1.m1",
    .vrom = {"230-v1.v1", "230-v2.v2"},
};
