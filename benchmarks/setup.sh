#!/bin/bash
#
# One-time setup for browser benchmarks
#
# Installs Playwright and downloads browser binaries
#

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Browser Benchmark Setup${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

cd "$(dirname "$0")/js"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found${NC}"
    echo ""
    echo "Please install Node.js first:"
    echo "  macOS:        brew install node"
    echo "  Ubuntu/Debian: sudo apt install nodejs npm"
    echo ""
    exit 1
fi

echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo ""

# Install dependencies
echo -e "${YELLOW}Step 1/2: Installing Playwright...${NC}"
npm install
echo -e "${GREEN}✓ Playwright installed${NC}"
echo ""

# Install browsers
echo -e "${YELLOW}Step 2/2: Downloading browsers (~500MB)...${NC}"
echo -e "${BLUE}  This may take a few minutes...${NC}"
npx playwright install
echo -e "${GREEN}✓ Browsers installed${NC}"
echo ""

echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "You can now run benchmarks with:"
echo "  zig build benchmark-all"
echo ""
