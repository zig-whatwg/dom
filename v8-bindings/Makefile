# V8 DOM Bindings - Build System
# 
# Prerequisites:
#   - V8 installed (see ../js-bindings/examples/INSTALL_V8.md)
#   - DOM library built: cd .. && zig build
#
# Build:
#   make
#
# Clean:
#   make clean

CXX := clang++
CXXFLAGS := -std=c++20 -Wall -Wextra -O2 -fPIC
AR := ar
ARFLAGS := rcs

# V8 paths (adjust for your installation)
# V8 13.5 from Homebrew stores headers in libexec/include
V8_INCLUDE := /opt/homebrew/Cellar/v8/13.5.212.10/libexec/include
V8_LIB := /opt/homebrew/lib

# Project paths
DOM_INCLUDE := ../js-bindings
SRC_DIR := src
OBJ_DIR := obj
LIB_DIR := lib

# Compiler flags
INCLUDES := -I$(DOM_INCLUDE) -I$(V8_INCLUDE)
LDFLAGS := -L$(V8_LIB)
LIBS := -lv8

# Source files
MAIN_SRCS := $(SRC_DIR)/v8_dom.cpp
CORE_SRCS := $(wildcard $(SRC_DIR)/core/*.cpp) $(SRC_DIR)/wrapper_cache.cpp
NODE_SRCS := $(wildcard $(SRC_DIR)/nodes/*.cpp)
COLLECTION_SRCS := $(wildcard $(SRC_DIR)/collections/*.cpp)
EVENT_SRCS := $(wildcard $(SRC_DIR)/events/*.cpp)
RANGE_SRCS := $(wildcard $(SRC_DIR)/ranges/*.cpp)
TRAVERSAL_SRCS := $(wildcard $(SRC_DIR)/traversal/*.cpp)
OBSERVER_SRCS := $(wildcard $(SRC_DIR)/observers/*.cpp)
SHADOW_SRCS := $(wildcard $(SRC_DIR)/shadow/*.cpp)
ABORT_SRCS := $(wildcard $(SRC_DIR)/abort/*.cpp)

ALL_SRCS := $(MAIN_SRCS) $(CORE_SRCS) $(NODE_SRCS) $(COLLECTION_SRCS) $(EVENT_SRCS) \
            $(RANGE_SRCS) $(TRAVERSAL_SRCS) $(OBSERVER_SRCS) $(SHADOW_SRCS) \
            $(ABORT_SRCS)

# Object files
OBJS := $(patsubst $(SRC_DIR)/%.cpp,$(OBJ_DIR)/%.o,$(ALL_SRCS))

# Target library
TARGET := $(LIB_DIR)/libv8dom.a

# Default target
all: $(TARGET)

# Build static library
$(TARGET): $(OBJS)
	@echo "Creating static library..."
	@mkdir -p $(LIB_DIR)
	$(AR) $(ARFLAGS) $@ $^
	@echo "✓ Built $(TARGET)"
	@echo ""
	@echo "To use in your project:"
	@echo "  clang++ your_code.cpp -I./include -L./lib -lv8dom -L../zig-out/lib -ldom -lv8"

# Compile source files
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.cpp
	@echo "Compiling $<..."
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# Clean build artifacts
clean:
	@echo "Cleaning..."
	rm -rf $(OBJ_DIR) $(LIB_DIR)
	@echo "✓ Clean complete"

# Show configuration
config:
	@echo "Build Configuration:"
	@echo "  CXX:          $(CXX)"
	@echo "  CXXFLAGS:     $(CXXFLAGS)"
	@echo "  V8_INCLUDE:   $(V8_INCLUDE)"
	@echo "  V8_LIB:       $(V8_LIB)"
	@echo "  DOM_INCLUDE:  $(DOM_INCLUDE)"
	@echo "  Source files: $(words $(ALL_SRCS))"
	@echo "  Target:       $(TARGET)"

# Help
help:
	@echo "V8 DOM Bindings - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all (default) - Build the static library"
	@echo "  clean         - Remove build artifacts"
	@echo "  config        - Show build configuration"
	@echo "  help          - Show this help"
	@echo ""
	@echo "Prerequisites:"
	@echo "  1. Install V8 (see ../js-bindings/examples/INSTALL_V8.md)"
	@echo "  2. Build DOM library: cd .. && zig build"
	@echo ""
	@echo "Usage:"
	@echo "  make              # Build library"
	@echo "  make clean        # Clean"
	@echo "  make config       # Show configuration"

.PHONY: all clean config help
