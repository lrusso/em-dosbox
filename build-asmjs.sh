#!/bin/bash
set -e

echo "=== em-dosbox asm.js build ==="

# Check that Emscripten is available
if ! command -v emcc &> /dev/null; then
    echo "Error: emcc not found. Please activate the Emscripten SDK first:"
    echo "  source /path/to/emsdk/emsdk_env.sh"
    exit 1
fi

echo "Using emcc: $(which emcc)"
emcc --version | head -1

# Clean previous build
if [ -f Makefile ]; then
    echo "=== Cleaning previous build ==="
    make clean || true
    make distclean || true
fi

# Generate build system
echo "=== Running autogen.sh ==="
./autogen.sh

# Configure for Emscripten with asm.js (--disable-wasm)
echo "=== Configuring for asm.js ==="
emconfigure ./configure \
    --enable-emscripten \
    --disable-wasm \
    --with-sdl2 \
    --disable-dynamic-x86 \
    --disable-dynrec

# Build
echo "=== Building ==="
emmake make -j$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo ""
echo "=== Build complete ==="
echo "Output files in src/:"
ls -lh src/dosbox.js src/dosbox.html 2>/dev/null || true
