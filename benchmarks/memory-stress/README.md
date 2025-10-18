# DOM Memory Stress Test

Comprehensive memory stress test that performs extensive CRUD operations on a DOM document over a configurable time period, tracking memory consumption throughout.

## Overview

This stress test:
- Creates an initial DOM with ~1000 elements
- Performs weighted random operations (CREATE 30%, UPDATE 40%, READ 20%, DELETE 10%)
- Samples memory usage every 10 seconds
- Tracks operation statistics
- Generates interactive HTML reports with Chart.js visualizations

## Usage

### Quick Test (5 seconds)
```bash
zig build memory-stress -Doptimize=ReleaseFast -- --duration 5
```

### Development Test (30 seconds)
```bash
zig build memory-stress -Doptimize=ReleaseFast -- --duration 30
```

### Production Test (20 minutes)
```bash
zig build memory-stress -Doptimize=ReleaseFast -- --duration 1200
```

### Reproducible Test (with seed)
```bash
zig build memory-stress -Doptimize=ReleaseFast -- --duration 30 --seed 12345
```

### Custom Output Directory
```bash
zig build memory-stress -Doptimize=ReleaseFast -- --duration 30 --output-dir my_results
```

### Help
```bash
zig build memory-stress -Doptimize=ReleaseFast -- --help
```

## Command-Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--duration <seconds>` | Test duration in seconds | 1200 (20 minutes) |
| `--seed <number>` | Random seed for reproducibility | Current timestamp |
| `--output-dir <path>` | Output directory for results | `benchmark_results/memory_stress` |
| `--help` | Show help message | - |

## Output Files

The test generates two types of output files in the output directory:

### JSON Results
- `memory_samples_<timestamp>.json` - Raw test results with timestamp
- `memory_samples_latest.json` - Copy of the most recent results

Example JSON structure:
```json
{
  "config": {
    "duration_seconds": 30,
    "sample_interval_ms": 10000,
    "initial_dom_size": 1000,
    "seed": 1234567890
  },
  "samples": [
    {
      "timestamp_ms": 0,
      "bytes_used": 709622,
      "peak_bytes": 709622,
      "operations_completed": 0
    },
    ...
  ],
  "final_state": {
    "final_dom_size": 500000,
    "total_operations": 450000,
    "operation_breakdown": {
      "creates": 400000,
      "reads": 30000,
      "updates": 15000,
      "deletes": 5000
    }
  }
}
```

### HTML Visualizations
- `memory_samples_<timestamp>.html` - Interactive report with timestamp
- `memory_report_latest.html` - Copy of the most recent report

The HTML report includes:
- **Summary Cards**: Key metrics at a glance
- **Memory Usage Chart**: Line chart showing memory growth over time
- **Operations/Second Chart**: Performance metrics over time
- **Operation Breakdown**: Pie chart of operation distribution
- **Statistics Table**: Detailed operation statistics

## Operation Types

### CREATE (30% of operations)
Creates DOM fragments of varying sizes:
- **Small**: 1-10 elements
- **Medium**: 50-100 elements  
- **Large**: 500-1000 elements

Each fragment includes nested structure (divs, spans, paragraphs) with text nodes.

### UPDATE (40% of operations)
Modifies existing DOM nodes:
- **Text Updates**: Appends text to existing text nodes
- **Reparenting**: Moves elements to different parents

### READ (20% of operations)
Query operations:
- `getElementById()` - Direct ID lookup
- `getElementsByTagName()` - Tag name traversal
- `querySelector()` - CSS selector matching

### DELETE (10% of operations)
Removes nodes from the tree:
- **Single**: Remove individual element
- **Small**: Remove subtree with 5-20 elements
- **Medium**: Remove subtree with 50-100 elements
- **Large**: Remove subtree with 500-1000 elements

## Memory Tracking

Memory is tracked using Zig's `GeneralPurposeAllocator` with accurate byte-level tracking:

- **Initial Memory**: Recorded after DOM creation
- **Sample Interval**: Every 10 seconds during test
- **Peak Memory**: Highest memory usage observed
- **Final Memory**: Memory usage at test completion

The GPA provides accurate per-operation memory accounting, unlike browser APIs which report total heap usage.

## Architecture

```
benchmarks/memory-stress/
├── stress_test.zig       - Core test logic (operations, tracking)
├── stress_runner.zig     - CLI executable (argument parsing, JSON output)
├── visualize_memory.js   - HTML report generator (Chart.js)
└── README.md            - This file

Output:
benchmark_results/memory_stress/
├── memory_samples_*.json  - Raw test data
├── memory_samples_*.html  - Interactive reports
└── memory_report_latest.html - Latest report (quick access)
```

## Design Decisions

### Why Track Memory with GPA?
- **Accurate**: Tracks every allocation/deallocation
- **Precise**: Byte-level granularity
- **Portable**: Works across all platforms
- **Reliable**: No API quirks like browser memory reporting

### Why Weighted Operations?
The 30/40/20/10 distribution (CREATE/UPDATE/READ/DELETE) reflects realistic web application behavior:
- Heavy creation (adding content)
- Frequent updates (user interactions)
- Regular reads (queries)
- Occasional deletions (cleanup)

### Why 10-Second Sample Interval?
- Captures trends without overwhelming output
- Reasonable for tests from 30s to 1 hour+
- Generates manageable JSON file sizes

### Why No Attribute Updates?
Attributes require string interning through Document's string pool. For simplicity in the stress test, we focus on structural operations (create, reparent, delete) and text updates which more directly stress memory management.

## Interpreting Results

### Healthy Memory Profile
- Linear or sub-linear growth
- Consistent operation rates
- No sudden memory spikes
- Memory released on deletes

### Potential Issues
- **Exponential Growth**: Possible memory leak
- **Declining Ops/Sec**: Performance degradation
- **Memory Spikes**: GC pressure or fragmentation
- **No Memory Release**: Deletion not freeing memory

### Typical Results (30-second test)
- Initial Memory: ~700 KB
- Final Memory: ~300-600 MB
- Total Operations: ~750,000
- Operations/Second: ~25,000
- Final DOM Size: ~750,000 elements

## Development Notes

### Adding New Operations
1. Add operation logic to `stress_test.zig`
2. Update operation stats tracking
3. Adjust weights in main loop
4. Update this README

### Modifying Sample Interval
Edit `StressTestConfig` default in `stress_test.zig`:
```zig
pub const StressTestConfig = struct {
    sample_interval_ms: u64 = 10000, // Change this
    ...
};
```

### Customizing Visualization
Edit `visualize_memory.js`:
- Chart colors: Modify `borderColor` and `backgroundColor`
- Chart types: Change `type:` field
- Layout: Adjust CSS grid and styles

## Troubleshooting

### "Compilation Error"
Ensure you're using Zig 0.15.1 or later:
```bash
zig version
```

### "Segmentation Fault"
Run in debug mode for detailed error:
```bash
zig build memory-stress -Doptimize=Debug -- --duration 5
```

### "Out of Memory"
Reduce test duration or increase system resources:
```bash
zig build memory-stress -Doptimize=ReleaseFast -- --duration 10
```

### "Chart Not Displaying"
Ensure you have internet connection (Chart.js loads from CDN). Or open the HTML file in a browser with JavaScript enabled.

### "No JSON File Found"
The stress test must complete successfully before visualization runs. Check for errors in the test output.

## Examples

### Quick Smoke Test
```bash
# 5-second test to verify everything works
zig build memory-stress -Doptimize=ReleaseFast -- --duration 5
open benchmark_results/memory_stress/memory_report_latest.html
```

### Compare Two Runs
```bash
# Run 1: With optimization
zig build memory-stress -Doptimize=ReleaseFast -- --duration 30 --seed 42 --output-dir results_fast

# Run 2: Debug mode (slower)
zig build memory-stress -Doptimize=Debug -- --duration 30 --seed 42 --output-dir results_debug

# Compare results
open results_fast/memory_report_latest.html
open results_debug/memory_report_latest.html
```

### Long-Running Stability Test
```bash
# 1-hour test
zig build memory-stress -Doptimize=ReleaseFast -- --duration 3600
```

## Contributing

When modifying the stress test:

1. Ensure tests still pass
2. Update this README with any new options or behaviors
3. Verify JSON output structure remains compatible
4. Check visualization renders correctly with new data
5. Document any new operation types or metrics

## License

Same as parent project.
