#!/bin/bash
# MinGW-w64 Cross-Compilation Helper Script for Open3D
# Usage: ./build-mingw64.sh [build_dir] [cmake_args...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"
DEFAULT_BUILD_DIR="${PROJECT_ROOT}/build-mingw64"

BUILD_DIR="${1:-${DEFAULT_BUILD_DIR}}"
shift || true

# Check for MinGW-w64
if ! command -v x86_64-w64-mingw32-gcc &> /dev/null; then
    echo "Error: MinGW-w64 not found in PATH"
    echo "Install with:"
    echo "  Ubuntu/Debian: sudo apt install mingw-w64"
    echo "  Fedora:        sudo dnf install mingw64-gcc mingw64-gcc-c++ mingw64-winpthreads"
    echo "  Arch:          sudo pacman -S mingw-w64-gcc"
    echo "  macOS (brew):  brew install mingw-w64"
    exit 1
fi

echo "=== MinGW-w64 Cross-Compilation Setup ==="
echo "Project root: ${PROJECT_ROOT}"
echo "Build dir:    ${BUILD_DIR}"
echo "Compiler:     $(x86_64-w64-mingw32-gcc --version | head -1)"
echo ""

# Install required MinGW-w64 packages (Ubuntu/Debian)
if command -v apt &> /dev/null; then
    echo "Installing MinGW-w64 dependencies via apt..."
    sudo apt update -qq
    sudo apt install -y -qq \
        mingw-w64 \
        mingw-w64-tools \
        mingw-w64-common \
        libeigen3-dev \
        libfmt-dev \
        libglew-dev \
        libglfw3-dev \
        libjsoncpp-dev \
        libtbb-dev \
        libtinygltf-dev \
        libnanoflann-dev \
        2>/dev/null || true
fi

# Create build directory
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Configure with CMake
echo "=== Configuring with CMake ==="
cmake "${PROJECT_ROOT}" \
    -DCMAKE_TOOLCHAIN_FILE="${PROJECT_ROOT}/cmake/toolchain-mingw64.cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_PYTHON_MODULE=OFF \
    -DBUILD_GUI=OFF \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_UNIT_TESTS=OFF \
    -DBUILD_BENCHMARKS=OFF \
    -DBUILD_CUDA_MODULE=OFF \
    -DBUILD_SYCL_MODULE=OFF \
    -DBUILD_ISPC_MODULE=OFF \
    -DBUILD_WEBRTC=OFF \
    -DBUILD_JUPYTER_EXTENSION=OFF \
    -DBUILD_TENSORFLOW_OPS=OFF \
    -DBUILD_PYTORCH_OPS=OFF \
    -DBUNDLE_OPEN3D_ML=OFF \
    -DUSE_BLAS=ON \
    -DUSE_SYSTEM_BLAS=ON \
    -DUSE_SYSTEM_EIGEN3=ON \
    -DUSE_SYSTEM_FMT=ON \
    -DUSE_SYSTEM_GLEW=ON \
    -DUSE_SYSTEM_GLFW=ON \
    -DUSE_SYSTEM_IMGUI=ON \
    -DUSE_SYSTEM_JSONCPP=ON \
    -DUSE_SYSTEM_TBB=ON \
    -DUSE_SYSTEM_TINYGLTF=ON \
    -DUSE_SYSTEM_TINYOBJLOADER=ON \
    -DUSE_SYSTEM_NANOFLANN=ON \
    -DUSE_SYSTEM_STDGPU=ON \
    -DSTATIC_WINDOWS_RUNTIME=ON \
    "$@"

echo ""
echo "=== Configuration Complete ==="
echo "Build directory: ${BUILD_DIR}"
echo ""
echo "To build, run:"
echo "  cmake --build ${BUILD_DIR} --parallel $(nproc)"
echo ""
echo "To install to a staging directory:"
echo "  cmake --install ${BUILD_DIR} --prefix ${BUILD_DIR}/install"
echo ""
echo "To create a Windows installer package (requires NSIS):"
echo "  cmake --build ${BUILD_DIR} --target package"