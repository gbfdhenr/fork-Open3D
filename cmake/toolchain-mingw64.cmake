# MinGW-w64 Cross-Compilation Toolchain for Windows x64
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=cmake/toolchain-mingw64.cmake -B build-mingw64

cmake_minimum_required(VERSION 3.24)

# =============================================================================
# Target Platform
# =============================================================================
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_VERSION 10.0)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# =============================================================================
# Cross-Compiler Detection
# =============================================================================
set(MINGW_PREFIX "x86_64-w64-mingw32")

# Try to find compiler in PATH
find_program(MINGW_GCC NAMES ${MINGW_PREFIX}-gcc x86_64-w64-mingw32-gcc)
find_program(MINGW_GXX NAMES ${MINGW_PREFIX}-g++ x86_64-w64-mingw32-g++)
find_program(MINGW_WINDRES NAMES ${MINGW_PREFIX}-windres x86_64-w64-mingw32-windres)
find_program(MINGW_DLLTOOL NAMES ${MINGW_PREFIX}-dlltool x86_64-w64-mingw32-dlltool)
find_program(MINGW_AR NAMES ${MINGW_PREFIX}-ar x86_64-w64-mingw32-ar)
find_program(MINGW_RANLIB NAMES ${MINGW_PREFIX}-ranlib x86_64-w64-mingw32-ranlib)
find_program(MINGW_STRIP NAMES ${MINGW_PREFIX}-strip x86_64-w64-mingw32-strip)

if(NOT MINGW_GCC OR NOT MINGW_GXX)
    message(FATAL_ERROR "
MinGW-w64 cross-compiler not found in PATH.
Install it:
  Ubuntu/Debian: sudo apt install mingw-w64 g++-mingw-w64
  Fedora:        sudo dnf install mingw64-gcc mingw64-gcc-c++
  Arch:          sudo pacman -S mingw-w64-gcc
  macOS (brew):  brew install mingw-w64

Or set MINGW_PREFIX if using a different triplet (e.g., x86_64-w64-mingw32).
")
endif()

# Derive prefix from compiler path
get_filename_component(MINGW_BIN_DIR ${MINGW_GCC} DIRECTORY)
get_filename_component(MINGW_ROOT_DIR ${MINGW_BIN_DIR} DIRECTORY)

message(STATUS "MinGW-w64 root: ${MINGW_ROOT_DIR}")
message(STATUS "MinGW-w64 bin:  ${MINGW_BIN_DIR}")
message(STATUS "C Compiler:     ${MINGW_GCC}")
message(STATUS "C++ Compiler:   ${MINGW_GXX}")
message(STATUS "Windres:        ${MINGW_WINDRES}")
message(STATUS "DLLTool:        ${MINGW_DLLTOOL}")

# =============================================================================
# Compiler Configuration
# =============================================================================
set(CMAKE_C_COMPILER    ${MINGW_GCC})
set(CMAKE_CXX_COMPILER  ${MINGW_GXX})
set(CMAKE_RC_COMPILER   ${MINGW_WINDRES})
set(CMAKE_DLLTOOL       ${MINGW_DLLTOOL})
set(CMAKE_AR            ${MINGW_AR})
set(CMAKE_RANLIB        ${MINGW_RANLIB})
set(CMAKE_STRIP         ${MINGW_STRIP})

# Force C++17 standard (matches Open3D requirement)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# =============================================================================
# Target Environment for FindXXX Modules
# =============================================================================
set(CMAKE_FIND_ROOT_PATH ${MINGW_ROOT_DIR})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# pkg-config for cross-compilation
set(ENV{PKG_CONFIG_LIBDIR} "${MINGW_ROOT_DIR}/lib/pkgconfig:${MINGW_ROOT_DIR}/share/pkgconfig")
set(ENV{PKG_CONFIG_SYSROOT_DIR} "${MINGW_ROOT_DIR}")

# =============================================================================
# Windows-Specific Definitions
# =============================================================================
add_compile_definitions(
    WINVER=0x0A00
    _WIN32_WINNT=0x0A00
    NTDDI_VERSION=0x0A000000
    WIN32_LEAN_AND_MEAN
    NOMINMAX
    _CRT_SECURE_NO_WARNINGS
)

# Enable all symbols export (Windows DLL behavior)
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

# =============================================================================
# Linker Flags
# =============================================================================
# Use static runtime by default for standalone distribution
if(NOT DEFINED STATIC_WINDOWS_RUNTIME)
    set(STATIC_WINDOWS_RUNTIME ON CACHE BOOL "Use static runtime (-static-libgcc -static-libstdc++)")
endif()

if(STATIC_WINDOWS_RUNTIME)
    set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -static-libgcc -static-libstdc++")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -static-libgcc -static-libstdc++")
    add_link_options(-static)
    message(STATUS "Using static Windows runtime (-static-libgcc -static-libstdc++)")
else()
    message(STATUS "Using dynamic Windows runtime (requires MSVC runtime DLLs on target)")
endif()

# Thread model: posix (for C++11 thread support)
add_link_options(-pthread)

# =============================================================================
# Build Type Defaults
# =============================================================================
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

# Release optimizations
set(CMAKE_C_FLAGS_RELEASE   "-O3 -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
set(CMAKE_C_FLAGS_RELWITHDEBINFO   "-O2 -g -DNDEBUG")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-O2 -g -DNDEBUG")
set(CMAKE_C_FLAGS_MINSIZEREL   "-Os -DNDEBUG")
set(CMAKE_CXX_FLAGS_MINSIZEREL "-Os -DNDEBUG")

# =============================================================================
# Output Directories
# =============================================================================
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# =============================================================================
# Position Independent Code
# =============================================================================
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# =============================================================================
# rpath - not applicable for Windows, but set for consistency
# =============================================================================
set(CMAKE_SKIP_BUILD_RPATH TRUE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH "")
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH FALSE)

# =============================================================================
# System Libraries
# =============================================================================
# Link against MinGW-w64 system libraries
link_libraries(
    ${CMAKE_DL_LIBS}
    -lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32
    -luuid -lcomdlg32 -ladvapi32 -lws2_32 -liphlpapi -lversion
)

# =============================================================================
# Python Support (Cross-compiled) - Disabled by default
# =============================================================================
if(NOT BUILD_PYTHON_MODULE)
    set(BUILD_PYTHON_MODULE OFF CACHE BOOL "Build Python module" FORCE)
endif()

# =============================================================================
# Open3D-Specific Defaults for Cross-Compile
# =============================================================================
# Disable modules not supported in MinGW cross-compile
set(BUILD_CUDA_MODULE     OFF CACHE BOOL "CUDA not supported in MinGW cross-compile" FORCE)
set(BUILD_SYCL_MODULE     OFF CACHE BOOL "SYCL not supported in MinGW cross-compile" FORCE)
set(BUILD_ISPC_MODULE     OFF CACHE BOOL "ISPC not supported in MinGW cross-compile" FORCE)
set(BUILD_WEBRTC          OFF CACHE BOOL "WebRTC not supported in MinGW cross-compile" FORCE)

# GUI requires Filament prebuilt for MinGW - disable by default
if(NOT BUILD_GUI)
    set(BUILD_GUI OFF CACHE BOOL "GUI requires MinGW-compatible Filament" FORCE)
endif()

# Use system dependencies where available in MinGW-w64
set(USE_SYSTEM_EIGEN3     ON CACHE BOOL "Use system Eigen3")
set(USE_SYSTEM_FMT        ON CACHE BOOL "Use system fmt")
set(USE_SYSTEM_GLEW       ON CACHE BOOL "Use system GLEW")
set(USE_SYSTEM_GLFW       ON CACHE BOOL "Use system GLFW")
set(USE_SYSTEM_IMGUI      ON CACHE BOOL "Use system imgui")
set(USE_SYSTEM_JSONCPP    ON CACHE BOOL "Use system jsoncpp")
set(USE_SYSTEM_TBB        ON CACHE BOOL "Use system TBB")
set(USE_SYSTEM_TINYGLTF   ON CACHE BOOL "Use system tinygltf")
set(USE_SYSTEM_TINYOBJLOADER ON CACHE BOOL "Use system tinyobjloader")
set(USE_SYSTEM_NANOFLANN  ON CACHE BOOL "Use system nanoflann")
set(USE_SYSTEM_STDGPU     ON CACHE BOOL "Use system stdgpu")

# BLAS/LAPACK - use MinGW-w64 OpenBLAS
if(NOT USE_BLAS)
    set(USE_BLAS ON CACHE BOOL "Use BLAS/LAPACK (OpenBLAS via MinGW-w64)")
endif()
if(NOT USE_SYSTEM_BLAS)
    set(USE_SYSTEM_BLAS ON CACHE BOOL "Use system OpenBLAS")
endif()

# VTK - disable by default for cross-compile (complex dependencies)
set(BUILD_VTK_FROM_SOURCE OFF CACHE BOOL "Build VTK from source" FORCE)
set(USE_SYSTEM_VTK OFF CACHE BOOL "Use system VTK" FORCE)

# =============================================================================
# Verification
# =============================================================================
execute_process(
    COMMAND ${CMAKE_C_COMPILER} --version
    OUTPUT_VARIABLE GCC_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "Cross-compiler version: ${GCC_VERSION}")

# Verify target is Windows
execute_process(
    COMMAND ${CMAKE_C_COMPILER} -dumpmachine
    OUTPUT_VARIABLE TARGET_TRIPLET
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
if(NOT TARGET_TRIPLET MATCHES "w64-mingw32")
    message(WARNING "Target triplet (${TARGET_TRIPLET}) doesn't appear to be MinGW-w64")
endif()

message(STATUS "MinGW-w64 toolchain configured successfully for Windows x64")