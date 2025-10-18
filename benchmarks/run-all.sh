#!/bin/bash
#
# Run all benchmarks and generate visualization
#
# This script:
# 1. Runs Zig benchmarks (ReleaseFast)
# 2. Runs browser benchmarks (Playwright)
# 3. Generates HTML visualization report
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  DOM Benchmark Suite - Complete Pipeline${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Step 1: Run Zig benchmarks
echo -e "${YELLOW}Step 1/3: Running Zig benchmarks...${NC}"
echo ""
cd "$(dirname "$0")/.."
zig build bench -Doptimize=ReleaseFast > benchmark_results/zig_benchmarks_latest.txt 2>&1
echo -e "${GREEN}✓ Zig benchmarks complete${NC}"
echo ""

# Step 2: Check if Playwright is set up
if [ ! -d "benchmarks/js/node_modules" ]; then
    echo -e "${RED}❌ Playwright not installed${NC}"
    echo ""
    echo "Please run the following commands first:"
    echo ""
    echo "  cd benchmarks/js"
    echo "  npm install"
    echo "  npx playwright install"
    echo "  cd ../.."
    echo ""
    echo "Then run this command again."
    exit 1
fi

# Step 3: Run browser benchmarks
echo -e "${YELLOW}Step 2/3: Running browser benchmarks...${NC}"
echo -e "${BLUE}  This will run benchmarks in Chromium, Firefox, and WebKit${NC}"
echo -e "${BLUE}  Please wait, this may take several minutes...${NC}"
echo ""
cd benchmarks/js
node playwright-runner.js
cd ../..
echo -e "${GREEN}✓ Browser benchmarks complete${NC}"
echo ""

# Step 4: Generate visualization
echo -e "${YELLOW}Step 3/3: Generating visualization...${NC}"
echo ""
cd benchmarks
node visualize.js
cd ..
echo -e "${GREEN}✓ Visualization generated${NC}"
echo ""

# Summary
echo -e "${BLUE}================================================${NC}"
echo -e "${GREEN}  All benchmarks complete!${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo "Results:"
echo "  - Zig results:     benchmark_results/zig_benchmarks_latest.txt"
echo "  - Browser results: benchmark_results/browser_benchmarks_latest.json"
echo "  - HTML report:     benchmark_results/benchmark_report.html"
echo ""
echo -e "${BLUE}Open the HTML report:${NC}"
echo "  file://$(pwd)/benchmark_results/benchmark_report.html"
echo ""
