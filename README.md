# Yuzu Ebuild Notes
This is a gentoo overlay that currently provides the [Yuzu Emulator](https://yuzu-emu.org/) and some of its dependencies.

## How to use
To install this overlay check it out -> https://wiki.gentoo.org/wiki/Project:Overlays/Overlays_guide

Most of the Yuzu flags are not tested because it would take forever and the feature creep is already bad enough. Default flags should work without issue (as long as your system is x86 or amd64). All other configurations are use at your own risk.

This yuzu is stable masked (as it is very very unstable). If this statement confuses you read all about it -> https://wiki.gentoo.org/wiki/KEYWORDS

## Bug-like things:
- httplib AND libressl are still required even when ENABLE_WEB_SERVICE=OFF. I've exposed the webservice use flag but disabling it will cause the compilation to fail.
Example when webservice off and libressl block left in the libressl conditional (at this point i had already removed httplib from the block). 
: && /usr/bin/x86_64-pc-linux-gnu-g++  -O2 -pipe  -Wl,-O1 -Wl,--as-needed src/yuzu_tester/CMakeFiles/yuzu-tester.dir/config.cpp.o src/yuzu_tester/CMakeFiles/yuzu-tester.dir/emu_window/emu_window_sdl2_hide.cpp.o src/yuzu_tester/CMakeFiles/yuzu-tester.dir/service/yuzutest.cpp.o src/yuzu_tester/CMakeFiles/yuzu-tester.dir/yuzu.cpp.o  -o bin/yuzu-tester  src/common/libcommon.a  src/core/libcore.a  src/input_common/libinput_common.a  externals/inih/libinih.a  externals/glad/libglad.a  -lrt  src/core/libcore.a  src/audio_core/libaudio_core.a  src/video_core/libvideo_core.a  src/core/libcore.a  src/audio_core/libaudio_core.a  src/video_core/libvideo_core.a  externals/mbedtls/library/libmbedtls.a  externals/mbedtls/library/libmbedx509.a  externals/mbedtls/library/libmbedcrypto.a  /usr/lib64/libopus.so  /var/tmp/portage/games-emulation/yuzu-9999/work/yuzu-9999/externals/unicorn/libunicorn.a  -lzip  externals/dynarmic/src/libdynarmic.a  -lrt  externals/soundtouch/libSoundTouch.a  externals/cubeb/libcubeb.a  -lpthread  src/common/libcommon.a  /usr/lib64/libboost_context-mt.so  /usr/lib64/libfmt.so.7.0.1  -Wl,--as-needed  /usr/lib64/liblz4.so  /usr/lib64/libzstd.so  externals/glad/libglad.a  -ldl  -L/usr/lib64  -lSDL2  -lusb-1.0  -pthread && :
/usr/lib/gcc/x86_64-pc-linux-gnu/10.1.0/../../../../x86_64-pc-linux-gnu/bin/ld: src/core/CMakeFiles/core.dir/hle/service/bcat/backend/boxcat.cpp.o: undefined reference to symbol 'GENERAL_NAMES_free@@OPENSSL_1_1_0'


- CMAKE_PREFIX_PATH seems to be ignored by find_package (even when no find.cmake file is provided for the target and explicitly told CONFIG)
- CMAKE_SYSTEM_PREFIX_PATH should be semicolon delimited but seems have no delimiters.
- the Findopus.cmake module complains about capitalization mismatch when used.
- unicorn dir needs to be clean to be build from scratch
- yuzu-emu/yuzu (ad0b2951250979549082fdef3ba4fd93a720b5df) fails on game load with "Trace/breakpoint trap" but mainline (ad71d9033502d9019b76231528d07bb0845631e0) does not.

## SECURITY: 
- because libressl's asm files don't include .note.GNU-stack they are creating writable and executable mem sections. I could fix this with patches but should be fixed upstream. How to fix https://wiki.gentoo.org/wiki/Hardened/GNU_stack_quickstart
List of offenders:
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/whrlpool/wp-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/cpuid-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/aes/bsaes-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/aes/aesni-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/aes/aes-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/aes/aesni-sha1-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/aes/vpaes-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/rc4/rc4-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/rc4/rc4-md5-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/modes/ghash-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/camellia/cmll-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/bn/modexp512-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/bn/gf2m-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/bn/mont5-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/bn/mont-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/sha/sha512-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/sha/sha1-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/sha/sha256-elf-x86_64.S.o
!WX --- ---  ./work/yuzu-9999_build/externals/libressl/crypto/CMakeFiles/crypto.dir/md5/md5-elf-x86_64.S.o

## Conan dependancies
- All conan deps were able to be subbed for system libs.
- the ebuild does not (and cannot easily) use conan
- catch-2.11.3 provided in overlay. It is possible that the overlay could be removed if 2.5.0 (2.9.1 testing) is good enough. Have not tested with lower version numbers.

## Externals that could be subbed for system libs:
- system opus linked without issue
- system xbyak linked. provided 5.911 and 5.92 in overlay

## Externals that could not be subbed:
- opus 1.3.1 allows installation but fails on loading a game once executed. didn't try with flag custom-modes
- libressl is custom don't link system
- soundtouch is custom don't link
- mbedtls seems to need older version than gentoo supports. Github is at 2.12 gentoo is at 2.23
- no microprofile gentoo package
- no gentoo glad
- no gentoo inih
- no gentoo dynarmic
- no gentoo cubeb
- no gentoo discord-rpc
- no gentoo sirit

(disclaimer, i've got no idea what's going on with cmake and that's probably 80% of my propblems)

## Questions:
- How do you build docs? Is doxygen required to build without docs?

