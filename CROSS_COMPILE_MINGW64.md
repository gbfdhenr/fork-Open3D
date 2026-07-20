# Open3D MinGW-w64 Cross-Compilation Guide

## Prerequisites

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y \
    mingw-w64 \
    mingw-w64-tools \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    libeigen3-dev \
    libfmt-dev \
    libglew-dev \
    libglfw3-dev \
    libjsoncpp-dev \
    libtbb-dev \
    libtinygltf-dev \
    libnanoflann-dev
```

### Fedora/RHEL
```bash
sudo dnf install -y \
    mingw64-gcc \
    mingw64-gcc-c++ \
    mingw64-winpthreads \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    eigen3-devel \
    fmt-devel \
    glew-devel \
    glfw-devel \
    jsoncpp-devel \
    tbb-devel \
    tinygltf-devel \
    nanoflann-devel
```

### Arch Linux
```bash
sudo pacman -S \
    mingw-w64-gcc \
    cmake \
    ninja \
    python \
    python-pip \
    eigen \
    fmt \
    glew \
    glfw \
    jsoncpp \
    tbb \
    tinygltf \
    nanoflann
```

### macOS (Homebrew)
```bash
brew install mingw-w64 cmake ninja python eigen fmt glew glfw jsoncpp tbb tinygltf nanoflann
```

## Quick Start

### Option 1: Using the helper script
```bash
cd /path/to/Open3D
./build-mingw64.sh build-mingw64
cmake --build build-mingw64 --parallel $(nproc)
```

### Option 2: Manual CMake configure
```bash
mkdir build-mingw64 && cd build-mingw64
cmake .. \
    -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchain-mingw64.cmake \
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
    -G Ninja

cmake --build . --parallel $(nproc)
```

## Building Python Module (Advanced)

Cross-compiling Python extension requires a Windows Python installation. Two approaches:

### Approach A: Use a Windows Python via Wine (experimental)
```bash
# Install Wine and Windows Python
# Then set Python3_ROOT_DIR to the Wine prefix Python installation
cmake .. -DPython3_ROOT_DIR=~/.wine/drive_c/Python311 -DBUILD_PYTHON_MODULE=ON
```

### Approach B: Build core library only, build wheel on Windows
1. Cross-compile core library: `./build-mingw64.sh build-mingw64`
2. Copy `build-mingw64/install` to Windows
3. On Windows, build Python wheel using the prebuilt core:
   ```cmd
   cmake -DOPEN3D_USE_INSTALLED_LIBRARY=ON -DBUILD_PYTHON_MODULE=ON ..
   cmake --build . --target pip-package
   ```

## Build Options Reference

| Option | Default | Description |
|--------|---------|-------------|
| `BUILD_SHARED_LIBS` | OFF | Build shared (.dll) vs static (.lib/.a) libraries |
| `BUILD_PYTHON_MODULE` | OFF | Build Python bindings (requires cross-compiled Python) |
| `BUILD_GUI` | OFF | Build GUI (requires prebuilt Filament for MinGW) |
| `BUILD_CUDA_MODULE` | OFF | CUDA not supported in MinGW cross-compile |
| `BUILD_SYCL_MODULE` | OFF | SYCL not supported in MinGW cross-compile |
| `BUILD_ISPC_MODULE` | OFF | ISPC not supported in MinGW cross-compile |
| `STATIC_WINDOWS_RUNTIME` | ON | Use static MSVC runtime (/MT) for standalone distribution |
| `USE_SYSTEM_*` | ON | Use MinGW-w64 system packages where available |

## Output

After successful build:
```
build-mingw64/
├── bin/           # .dll and .exe files
├── lib/           # .a static libraries and .dll.a import libraries
├── include/       # Open3D headers
└── install/       # If you run: cmake --install . --prefix install
```

## Creating Windows Installer (NSIS)

```bash
# Requires NSIS installed
cmake --build build-mingw64 --target package
# Produces: Open3D-<version>-Windows-x64.exe
```

## Troubleshooting

### Missing MinGW-w64 packages
```bash
# Ubuntu: Search for packages
apt search mingw-w64 | grep -E 'lib|dev'

# Install specific package
sudo apt install mingw-w64-libxxx-dev
```

### Threading issues
```bash
# Ensure winpthreads is linked
cmake -DTHREADS_PREFER_PTHREAD_FLAG=ON ..
```

### Python not found
```bash
# Disable Python module if not needed
cmake -DBUILD_PYTHON_MODULE=OFF ..
```

### Linker errors for system libraries
```bash
# Disable problematic system library
cmake -DUSE_SYSTEM_XXX=OFF ..
```

## CI/CD Integration (GitHub Actions)

```yaml
- name: Setup MinGW-w64
  run: sudo apt update && sudo apt install -y mingw-w64 cmake ninja-build

- name: Configure
  run: |
    cmake -B build-mingw64 -S . \
      -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw64.cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
      -DBUILD_PYTHON_MODULE=OFF \
      -DBUILD_GUI=OFF \
      -G Ninja

- name: Build
  run: cmake --build build-mingw64 --parallel

- name: Test on Windows (via Wine)
  run: |
    wine build-mingw64/bin/open3d_example.exe
```

## Files Created

- `cmake/toolchain-mingw64.cmake` - CMake toolchain file for MinGW-w64 cross-compilation
- `build-mingw64.sh` - Helper script for quick setup
- This README: `CROSS_COMPILE_MINGW64.md`