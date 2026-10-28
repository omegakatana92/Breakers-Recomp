cmake_minimum_required(VERSION 3.21)
project(breakers VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# The neogeorecomp toolkit: the vendored copy, or a checkout next to this
# repo.  The vendored copy is upstream v0.2.0 plus the generic runtime
# fixes recorded in docs/runtime-changes.md (no title-specific code).
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/neogeorecomp/CMakeLists.txt)
    set(ng_default ${CMAKE_CURRENT_SOURCE_DIR}/neogeorecomp)
else()
    set(ng_default ${CMAKE_CURRENT_SOURCE_DIR}/../neogeorecomp)
endif()
set(NEOGEORECOMP_DIR ${ng_default} CACHE PATH "neogeorecomp checkout")
add_subdirectory(${NEOGEORECOMP_DIR} neogeorecomp_build)

# Your ROM files (the "breakers" set plus the "neogeo" system ROMs,
# unzipped).  Without it the player builds interpreter-only, which is also
# the quickest way to check a dump and the BIOS before recompiling.
set(BREAKERS_ROM_DIR "" CACHE PATH "Directory with your breakers and Neo Geo BIOS ROM files")
# Optional: entry points a previous run found at runtime (--dump-misses).
set(BREAKERS_ENTRIES "${CMAKE_BINARY_DIR}/entries.txt" CACHE FILEPATH "Extra entry points for the recompiler")

# Stage 1: the generator.
add_executable(breakers_recomp src/recomp_main.c src/game.c)
target_link_libraries(breakers_recomp PRIVATE m68krecomp_core)
target_include_directories(breakers_recomp PRIVATE src)

# Stage 2: the player, with the generated C when ROMs are available.
set(GAME_SOURCES src/main.c)
set(GEN_DIR ${CMAKE_BINARY_DIR}/generated)
set(GEN_FILES 16)
if(BREAKERS_ROM_DIR)
    set(GEN_SOURCES ${GEN_DIR}/recomp_table.c)
    math(EXPR last "${GEN_FILES} - 1")
    foreach(i RANGE ${last})
        if(i LESS 10)
            list(APPEND GEN_SOURCES ${GEN_DIR}/recomp_0${i}.c)
        else()
            list(APPEND GEN_SOURCES ${GEN_DIR}/recomp_${i}.c)
        endif()
    endforeach()
    # The entry list starts empty.  The `profile` target fills it from
    # scripted sessions; the next build regenerates with it.
    if(NOT EXISTS ${BREAKERS_ENTRIES})
        file(WRITE ${BREAKERS_ENTRIES} "")
    endif()
    file(MAKE_DIRECTORY ${GEN_DIR})
    add_custom_command(
        OUTPUT ${GEN_SOURCES} ${GEN_DIR}/recomp_common.h
        COMMAND breakers_recomp --rom-path ${BREAKERS_ROM_DIR} --out ${GEN_DIR} --files ${GEN_FILES}
                --entries ${BREAKERS_ENTRIES}
        DEPENDS breakers_recomp ${BREAKERS_ENTRIES}
        COMMENT "Recompiling breakers from ${BREAKERS_ROM_DIR}")
    list(APPEND GAME_SOURCES ${GEN_SOURCES})
endif()

add_executable(breakers ${GAME_SOURCES} src/game.c)
set_target_properties(breakers PROPERTIES OUTPUT_NAME "Breakers")
target_link_libraries(breakers PRIVATE neogeorecomp)
target_include_directories(breakers PRIVATE src ${GEN_DIR})
if(BREAKERS_ROM_DIR)
    # Play scripted sessions and record the entry points that only show up
    # at runtime (computed jumps into unrolled code), then rebuild.
    add_custom_target(profile
        COMMAND $<TARGET_FILE:breakers> --headless --rom-path ${BREAKERS_ROM_DIR} --frames 6000
                --dump-misses ${BREAKERS_ENTRIES}
        COMMAND $<TARGET_FILE:breakers> --headless --rom-path ${BREAKERS_ROM_DIR} --frames 20000
                --input ${CMAKE_CURRENT_SOURCE_DIR}/tests/play.txt --dump-misses ${BREAKERS_ENTRIES}
        DEPENDS breakers
        COMMENT "Profiling scripted Breakers sessions for runtime-only entry points")
    target_compile_definitions(breakers PRIVATE BREAKERS_HAVE_RECOMP)
    if(MSVC)
        # Generated routines are large; /bigobj lifts the section limit and
        # /O1 keeps the optimizer from taking tens of minutes per file.
        set_source_files_properties(${GEN_SOURCES} PROPERTIES COMPILE_OPTIONS "/bigobj;/O1")
    else()
        # Same trade-off with gcc: the generated C is large.  -O1 keeps
        # compile time and memory within reach of a small build machine.
        set_source_files_properties(${GEN_SOURCES} PROPERTIES COMPILE_OPTIONS "-O1")
    endif()
endif()
if(MSVC)
    target_compile_definitions(breakers PRIVATE _CRT_SECURE_NO_WARNINGS)
    target_compile_definitions(breakers_recomp PRIVATE _CRT_SECURE_NO_WARNINGS)
endif()

# Audio regression: capture a scripted session and fail on music-sized
# silent runs.  Requires Python 3 and the user's ROMs.
find_package(Python3 COMPONENTS Interpreter QUIET)
if(BREAKERS_ROM_DIR AND Python3_Interpreter_FOUND)
    add_custom_target(audio-check
        COMMAND $<TARGET_FILE:breakers> --headless --rom-path ${BREAKERS_ROM_DIR}
                --frames 12000 --input ${CMAKE_CURRENT_SOURCE_DIR}/tests/play.txt
                --wav ${CMAKE_BINARY_DIR}/audio-check.wav
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/tests/check_audio.py
                ${CMAKE_BINARY_DIR}/audio-check.wav --from 10 --max-silence 3
        DEPENDS breakers
        COMMENT "Checking Breakers audio continuity")
endif()

# Ship the SDL2 DLL (when the window is built) next to the executable.
if(WIN32 AND TARGET SDL2::SDL2)
    add_custom_command(TARGET breakers POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different $<TARGET_RUNTIME_DLLS:breakers> $<TARGET_FILE_DIR:breakers>
        COMMAND_EXPAND_LISTS)
endif()
