# Makefile for V8 Integration Examples
#
# Prerequisites:
#   1. V8 installed (see INSTALL_V8.md)
#   2. DOM library built (zig build in parent directory)

# Detect platform and set V8 paths
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    # macOS (Homebrew)
    V8_INCLUDE ?= /opt/homebrew/include
    V8_LIB ?= /opt/homebrew/lib
    V8_LIBS ?= -lv8
else ifeq ($(UNAME_S),Linux)
    # Linux (system packages)
    V8_INCLUDE ?= /usr/include
    V8_LIB ?= /usr/lib/x8 6_64-linux-gnu
    V8_LIBS ?= -lv8
endif

# Compiler settings
CXX := clang++
CXXFLAGS := -std=c++17 -Wall -Wextra
INCLUDES := -I$(V8_INCLUDE) -I..
LDFLAGS := -L$(V8_LIB) -L../../zig-out/lib
LIBS := $(V8_LIBS) -ldom -lpthread

# Targets
EXAMPLES := v8_basic_wrapper
ALL_EXAMPLES := $(EXAMPLES)

.PHONY: all clean check-v8 check-dom

all: check-v8 check-dom $(ALL_EXAMPLES)

# Check V8 installation
check-v8:
	@echo "Checking for V8 headers..."
	@test -f $(V8_INCLUDE)/v8.h || \
		(echo "ERROR: V8 headers not found at $(V8_INCLUDE)/v8.h" && \
		 echo "Please install V8 (see INSTALL_V8.md) or set V8_INCLUDE" && \
		 exit 1)
	@echo "✓ V8 headers found"

# Check DOM library
check-dom:
	@echo "Checking for DOM library..."
	@test -f ../../zig-out/lib/libdom.a || \
		(echo "ERROR: DOM library not found at ../../zig-out/lib/libdom.a" && \
		 echo "Please run 'zig build' in the parent directory" && \
		 exit 1)
	@echo "✓ DOM library found"

# Build basic wrapper example
v8_basic_wrapper: v8_basic_wrapper.cpp
	@echo "Building $@..."
	$(CXX) $(CXXFLAGS) $(INCLUDES) $< $(LDFLAGS) $(LIBS) -o $@
	@echo "✓ Built $@"

# Clean
clean:
	rm -f $(ALL_EXAMPLES)
	@echo "✓ Cleaned"

# Run all examples
run: all
	@echo "\n=== Running v8_basic_wrapper ==="
	./v8_basic_wrapper

# Help
help:
	@echo "V8 Integration Examples - Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all         - Build all examples (default)"
	@echo "  clean       - Remove built binaries"
	@echo "  run         - Build and run all examples"
	@echo "  help        - Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  V8_INCLUDE  - Path to V8 headers (default: $(V8_INCLUDE))"
	@echo "  V8_LIB      - Path to V8 libraries (default: $(V8_LIB))"
	@echo "  V8_LIBS     - V8 library names (default: $(V8_LIBS))"
	@echo ""
	@echo "Examples:"
	@echo "  make                              # Build all examples"
	@echo "  make V8_INCLUDE=/custom/path all  # Use custom V8 location"
	@echo "  make run                          # Build and run all examples"
	@echo ""
	@echo "For V8 installation instructions, see INSTALL_V8.md"
