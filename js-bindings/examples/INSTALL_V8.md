# Installing V8 Headers and Libraries

This guide shows you how to install V8 (Google's JavaScript engine) on various platforms to build the integration examples.

## Quick Install (Recommended)

### macOS (Homebrew)

```bash
brew install v8

# Verify installation
ls /opt/homebrew/include/v8*.h
ls /opt/homebrew/lib/libv8*
```

After installation:
- **Headers:** `/opt/homebrew/include/`
- **Libraries:** `/opt/homebrew/lib/`

### Ubuntu/Debian

```bash
sudo apt-get update
sudo apt-get install libv8-dev

# Verify installation
ls /usr/include/v8*.h
ls /usr/lib/**/libv8*
```

After installation:
- **Headers:** `/usr/include/`
- **Libraries:** `/usr/lib/x86_64-linux-gnu/` (or similar)

### Arch Linux

```bash
sudo pacman -S v8

# Verify installation
ls /usr/include/v8*.h
ls /usr/lib/libv8*
```

## Building from Source (Advanced)

If you need a specific V8 version or want the latest features:

### Prerequisites

```bash
# Install depot_tools (Google's build tool)
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PWD/depot_tools:$PATH"

# Add to your shell RC file for persistence
echo 'export PATH="$HOME/depot_tools:$PATH"' >> ~/.bashrc  # or ~/.zshrc
```

### Fetch and Build V8

```bash
# Create build directory
mkdir v8_build && cd v8_build

# Fetch V8 source (this downloads ~2GB)
fetch v8
cd v8

# Checkout a stable version (optional)
git checkout 10.9.194  # Or any other stable tag

# Sync dependencies
gclient sync

# Configure build (monolithic for easier linking)
gn gen out/release --args='
  is_debug=false
  v8_monolithic=true
  v8_use_external_startup_data=false
  v8_enable_i18n_support=true
  treat_warnings_as_errors=false
'

# Build (this takes 20-60 minutes depending on your machine)
ninja -C out/release v8_monolith

# Verify
ls out/release/obj/libv8_monolith.a
```

After building:
- **Headers:** `v8/include/`
- **Library:** `v8/out/release/obj/libv8_monolith.a`

### Build Configuration Options

For different use cases, you can customize the build:

```bash
# Debug build (includes debugging symbols, slower)
gn gen out/debug --args='
  is_debug=true
  v8_monolithic=true
  v8_enable_i18n_support=true
'

# Optimized build without ICU (smaller binary)
gn gen out/release --args='
  is_debug=false
  v8_monolithic=true
  v8_use_external_startup_data=false
  v8_enable_i18n_support=false
'

# Shared library instead of static
gn gen out/release --args='
  is_debug=false
  v8_monolithic=false
  is_component_build=true
'
```

## Using Pre-built Binaries

### Option 1: Official V8 Releases

V8 doesn't publish official pre-built binaries, but you can find them from:

**jsvu (JavaScript Engine Version Updater):**
```bash
npm install -g jsvu
jsvu --engines=v8

# This installs the v8 binary but NOT headers/libraries
# You'll still need headers from one of the other methods
```

### Option 2: Node.js Headers

Node.js includes V8, and you can use its headers:

```bash
# Install Node.js development headers
npm install -g node-gyp
node-gyp install

# Headers will be in:
# ~/.node-gyp/<version>/include/node/
```

**Note:** Node.js's V8 may have custom patches and may not be API-compatible with standalone V8 examples.

## Verification

After installation, verify everything is working:

```bash
# Create a test file
cat > test_v8.cpp << 'CPP_EOF'
#include <v8.h>
#include <iostream>

int main() {
    std::cout << "V8 version: " << V8_MAJOR_VERSION << "."
              << V8_MINOR_VERSION << "."
              << V8_BUILD_NUMBER << std::endl;
    return 0;
}
CPP_EOF

# Compile (adjust paths based on your installation)
# Homebrew:
clang++ -std=c++17 test_v8.cpp -I/opt/homebrew/include -L/opt/homebrew/lib -lv8 -o test_v8

# Custom build:
clang++ -std=c++17 test_v8.cpp -I$HOME/v8_build/v8/include -L$HOME/v8_build/v8/out/release/obj -lv8_monolith -o test_v8

# Run
./test_v8
# Expected output: V8 version: 10.9.194 (or whatever version you installed)
```

## Troubleshooting

### "v8.h: No such file or directory"

**Problem:** Compiler can't find V8 headers.

**Solution:**
```bash
# Find where headers are installed
find /usr -name "v8.h" 2>/dev/null
find /opt -name "v8.h" 2>/dev/null

# Add -I flag pointing to the directory
clang++ ... -I/path/to/v8/include ...
```

### "undefined reference to v8::..."

**Problem:** Linker can't find V8 libraries.

**Solution:**
```bash
# Find where libraries are installed
find /usr -name "libv8*" 2>/dev/null
find /opt -name "libv8*" 2>/dev/null

# Add -L flag and -l flag
clang++ ... -L/path/to/v8/lib -lv8 ...
```

### "version GLIBCXX_X.X.X not found"

**Problem:** V8 was built with a different C++ standard library version.

**Solution:**
- Build V8 from source with your current toolchain
- Or update your GCC/Clang version
- Or use static linking: `-static-libstdc++`

### Snapshot/ICU data not found

**Problem:** V8 can't find its data files at runtime.

**Solution:**
```bash
# Copy data files to executable directory
cp v8/out/release/icudtl.dat .
cp v8/out/release/snapshot_blob.bin .  # If using external startup data

# Or set environment variables
export V8_ICU_DATA_FILE=/path/to/icudtl.dat
```

### Build from source is too slow

**Solution:**
```bash
# Use ccache for faster rebuilds
gn gen out/release --args='cc_wrapper="ccache" ...'

# Use more CPU cores
ninja -C out/release -j$(nproc)  # Linux
ninja -C out/release -j$(sysctl -n hw.ncpu)  # macOS
```

## Platform-Specific Notes

### macOS

- V8 requires macOS 10.13+ (High Sierra)
- Xcode Command Line Tools must be installed: `xcode-select --install`
- M1/M2 Macs: Homebrew installs to `/opt/homebrew/` instead of `/usr/local/`

### Linux

- V8 requires glibc 2.17+ (Ubuntu 14.04+, Debian 8+, RHEL 7+)
- Install build dependencies: `sudo apt-get install build-essential python3`
- May need to install additional libraries: `libatomic1`, `libicu-dev`

### Windows

V8 on Windows is more complex. Recommended approaches:

1. **WSL2 (Windows Subsystem for Linux)**
   - Install WSL2: https://docs.microsoft.com/en-us/windows/wsl/install
   - Follow Linux instructions inside WSL2

2. **MSYS2/MinGW**
   - Install MSYS2: https://www.msys2.org/
   - Use pacman to install V8 or build from source

3. **Visual Studio**
   - Requires Visual Studio 2019 or later
   - Follow V8 Windows build instructions: https://v8.dev/docs/build

## Next Steps

Once V8 is installed, return to the [main README](README.md) to build the integration examples.
