#!/bin/bash

# Builds DOSBox as asm.js (pure JavaScript, no WebAssembly) for the browser. The Emscripten
# SDK has to be set up already (emsdk_env), this script doesn't install or update it. The
# output is src/dosbox.js (plus src/dosbox.html).

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JOBS="$(sysctl -n hw.ncpu 2> /dev/null || nproc)"
OUTPUT="src/dosbox.js"

if ! command -v emcc > /dev/null; then
    echo "emcc not found, set up the Emscripten SDK environment first (emsdk_env)"
    exit 1
fi

echo "Using $(emcc --version | head -n1)"

cd "${SCRIPT_DIR}"

# A clean build, so the objects and the output always come from these settings.
if [ -f Makefile ]; then
    make distclean
fi

./autogen.sh
emconfigure ./configure \
    --enable-emscripten \
    --disable-wasm \
    --with-sdl2 \
    --disable-dynamic-x86 \
    --disable-dynrec

# ENVIRONMENT=web leaves out the code that only runs in Node. It goes in LDFLAGS when
# building (configure leaves it empty), not when configuring, because configure runs its
# test programs with Node. The link already has -O3 from CXXFLAGS.
emmake make -j"${JOBS}" LDFLAGS="-s ENVIRONMENT=web"

# The output is meant for browsers, so it must not load anything with require.
if grep -qE '\brequire\(' "${OUTPUT}"; then
    echo "Error: ${OUTPUT} still has a require"
    exit 1
fi

echo "Done: ${SCRIPT_DIR}/${OUTPUT}"
