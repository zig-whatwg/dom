/**
 * Benchmark Visualization Generator
 * 
 * Generates an interactive HTML report comparing Zig and browser performance
 * using Chart.js for beautiful visualizations.
 */

const fs = require('fs').promises;
const path = require('path');

const RESULTS_DIR = path.join(__dirname, '..', 'benchmark_results');
const OUTPUT_FILE = path.join(RESULTS_DIR, 'benchmark_report.html');

/**
 * Load Zig benchmark results
 */
async function loadZigResults() {
    const zigFile = path.join(RESULTS_DIR, 'zig_benchmarks_latest.txt');
    
    try {
        const content = await fs.readFile(zigFile, 'utf-8');
        const results = [];
        
        // Parse Zig benchmark output
        const lines = content.split('\n');
        for (const line of lines) {
            // Match lines like: "Pure query: getElementById (100 elem): 5ns/op (200000000 ops/sec) | 128MB total"
            // New format with total memory tracking
            const matchWithMemory = line.match(/^(.+?):\s+(\d+(?:\.\d+)?)(ns|µs|ms)\/op\s+\((\d+)\s+ops\/sec\)\s+\|\s+(\d+)(B|KB|MB|GB)\s+total/);
            if (matchWithMemory) {
                const name = matchWithMemory[1].trim();
                let timeValue = parseFloat(matchWithMemory[2]);
                const timeUnit = matchWithMemory[3];
                const opsPerSec = parseInt(matchWithMemory[4]);
                let memValue = parseFloat(matchWithMemory[5]);
                const memUnit = matchWithMemory[6];
                
                // Convert time to nanoseconds
                if (timeUnit === 'µs') timeValue *= 1000;
                if (timeUnit === 'ms') timeValue *= 1000000;
                
                // Convert memory to bytes
                if (memUnit === 'KB') memValue *= 1024;
                if (memUnit === 'MB') memValue *= 1024 * 1024;
                if (memUnit === 'GB') memValue *= 1024 * 1024 * 1024;
                
                results.push({
                    name,
                    nsPerOp: timeValue,
                    opsPerSec,
                    bytesPerOp: memValue,
                    bytesAllocated: memValue, // For compatibility
                    peakMemory: 0  // Not tracked per-operation
                });
                continue;
            }
            
            // Fallback: Match old format without memory: "Pure query: getElementById (100 elem): 5ns/op (200000000 ops/sec)"
            const matchOld = line.match(/^(.+?):\s+(\d+(?:\.\d+)?)(ns|µs|ms)\/op\s+\((\d+)\s+ops\/sec\)/);
            if (matchOld) {
                const name = matchOld[1].trim();
                let value = parseFloat(matchOld[2]);
                const unit = matchOld[3];
                const opsPerSec = parseInt(matchOld[4]);
                
                // Convert everything to nanoseconds
                if (unit === 'µs') value *= 1000;
                if (unit === 'ms') value *= 1000000;
                
                results.push({
                    name,
                    nsPerOp: value,
                    opsPerSec,
                    bytesPerOp: 0,
                    bytesAllocated: 0,
                    peakMemory: 0
                });
            }
        }
        
        return results;
    } catch (error) {
        console.warn('Could not load Zig results:', error.message);
        return [];
    }
}

/**
 * Load browser benchmark results
 */
async function loadBrowserResults() {
    const browserFile = path.join(RESULTS_DIR, 'browser_benchmarks_latest.json');
    
    try {
        const content = await fs.readFile(browserFile, 'utf-8');
        return JSON.parse(content);
    } catch (error) {
        console.warn('Could not load browser results:', error.message);
        return [];
    }
}

/**
 * Group results by benchmark name
 */
function groupResults(zigResults, browserResults) {
    const grouped = new Map();
    
    // Add Zig results
    for (const result of zigResults) {
        if (!grouped.has(result.name)) {
            grouped.set(result.name, {
                name: result.name,
                implementations: {}
            });
        }
        grouped.get(result.name).implementations['Zig'] = {
            nsPerOp: result.nsPerOp,
            opsPerSec: result.opsPerSec,
            bytesPerOp: result.bytesPerOp || 0,
            bytesAllocated: result.bytesAllocated || 0,
            peakMemory: result.peakMemory || 0
        };
    }
    
    // Add browser results
    for (const browserResult of browserResults) {
        if (browserResult.error) continue;
        
        for (const result of browserResult.results) {
            if (!grouped.has(result.name)) {
                grouped.set(result.name, {
                    name: result.name,
                    implementations: {}
                });
            }
            grouped.get(result.name).implementations[browserResult.browser] = {
                nsPerOp: result.nsPerOp,
                opsPerSec: result.opsPerSec,
                bytesPerOp: result.bytesPerOp || 0,
                bytesAllocated: result.bytesAllocated || 0,
                peakMemory: result.peakMemory || 0
            };
        }
    }
    
    return Array.from(grouped.values());
}

/**
 * Generate HTML report
 */
function generateHTML(groupedResults, browserResults) {
    const browsers = browserResults
        .filter(r => !r.error)
        .map(r => r.browser);
    
    const implementations = ['Zig', ...browsers];
    
    // Filter out Zig internal components - they're not comparable
    const comparableResults = groupedResults.filter(r => 
        !r.name.includes('Tokenizer') && 
        !r.name.includes('Parser') && 
        !r.name.includes('Matcher')
    );
    
    // Group benchmarks by category with proper organization
    const categories = {
        'Pure Query: ID Lookups': comparableResults.filter(r => 
            r.name.startsWith('Pure query: getElementById') || 
            r.name.startsWith('Pure query: querySelector #id')
        ),
        'Pure Query: Tag Lookups': comparableResults.filter(r => 
            r.name.startsWith('Pure query: getElementsByTagName') || 
            r.name.startsWith('Pure query: querySelector tag')
        ),
        'Pure Query: Class Lookups': comparableResults.filter(r => 
            r.name.startsWith('Pure query: getElementsByClassName') || 
            r.name.startsWith('Pure query: querySelector .class')
        ),
        'Complex Selectors': comparableResults.filter(r => 
            r.name.startsWith('Complex:')
        ),
        'DOM Construction': comparableResults.filter(r => 
            r.name.startsWith('DOM construction:')
        ),
        'Full Benchmarks (Construction + Query)': comparableResults.filter(r => 
            (r.name.startsWith('querySelector:') || 
             r.name.startsWith('getElementById:')) &&
            !r.name.startsWith('Pure query:')
        ),
        'SPA Patterns': comparableResults.filter(r => 
            r.name.startsWith('SPA:')
        ),
        'Internal Components': comparableResults.filter(r => 
            r.name.startsWith('Tokenizer:') || 
            r.name.startsWith('Parser:') || 
            r.name.startsWith('Matcher:')
        )
    };
    
    // Generate chart data for each category (timing)
    const chartDataSets = Object.entries(categories).map(([categoryName, benchmarks]) => {
        return {
            category: categoryName,
            benchmarks: benchmarks.map(bench => ({
                name: bench.name,
                data: implementations.map(impl => {
                    const result = bench.implementations[impl];
                    return result ? result.nsPerOp : null;
                })
            }))
        };
    });
    
    // Generate chart data for memory usage
    const memoryDataSets = Object.entries(categories).map(([categoryName, benchmarks]) => {
        return {
            category: categoryName,
            benchmarks: benchmarks.map(bench => ({
                name: bench.name,
                data: implementations.map(impl => {
                    const result = bench.implementations[impl];
                    return result && result.bytesPerOp ? result.bytesPerOp : null;
                })
            }))
        };
    });
    
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DOM Benchmark Results</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        
        header {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 30px;
        }
        
        h1 {
            color: #333;
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .subtitle {
            color: #666;
            font-size: 1.1em;
        }
        
        .implementations {
            display: flex;
            gap: 15px;
            margin-top: 20px;
            flex-wrap: wrap;
        }
        
        .impl-badge {
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .impl-zig { background: #f9a825; color: white; }
        .impl-chromium { background: #4285f4; color: white; }
        .impl-firefox { background: #ff6611; color: white; }
        .impl-webkit { background: #00aaff; color: white; }
        
        .category {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            margin-bottom: 30px;
        }
        
        .category h2 {
            color: #333;
            margin-bottom: 20px;
            font-size: 1.8em;
        }
        
        .chart-container {
            position: relative;
            height: 400px;
            margin-bottom: 30px;
        }
        
        .stats-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        .stats-table th,
        .stats-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        
        .stats-table th {
            background: #f5f5f5;
            font-weight: 600;
            color: #333;
        }
        
        .stats-table tr:hover {
            background: #f9f9f9;
        }
        
        .winner {
            font-weight: 600;
            color: #4caf50;
        }
        
        .speedup {
            font-size: 0.9em;
            color: #666;
        }
        
        footer {
            text-align: center;
            color: white;
            padding: 20px;
            opacity: 0.8;
        }
        
        .legend {
            display: flex;
            gap: 20px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .legend-color {
            width: 20px;
            height: 20px;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 DOM Benchmark Results</h1>
            <p class="subtitle">Performance comparison: Zig vs Browser Implementations</p>
            <div class="implementations">
                ${implementations.map(impl => `
                    <div class="impl-badge impl-${impl.toLowerCase()}">
                        <span>●</span> ${impl}
                    </div>
                `).join('')}
            </div>
        </header>
        
        ${Object.entries(categories).map(([categoryName, benchmarks], index) => {
            if (benchmarks.length === 0) return '';
            
            return `
            <div class="category">
                <h2>${categoryName}</h2>
                <div class="chart-container">
                    <canvas id="chart-${index}"></canvas>
                </div>
                
                <table class="stats-table">
                    <thead>
                        <tr>
                            <th>Benchmark</th>
                            ${implementations.map(impl => `<th>${impl}</th>`).join('')}
                            <th>Winner</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${benchmarks.map(bench => {
                            const values = implementations.map(impl => {
                                const result = bench.implementations[impl];
                                return result ? result.nsPerOp : Infinity;
                            });
                            const minValue = Math.min(...values.filter(v => v !== Infinity));
                            const winnerIndex = values.indexOf(minValue);
                            const winner = implementations[winnerIndex];
                            
                            return `
                            <tr>
                                <td><strong>${bench.name}</strong></td>
                                ${implementations.map((impl, i) => {
                                    const result = bench.implementations[impl];
                                    if (!result) return '<td>-</td>';
                                    
                                    const nsPerOp = result.nsPerOp;
                                    let display;
                                    if (nsPerOp === 0 || nsPerOp < 0.001) {
                                        display = `< 1ns`;
                                    } else if (nsPerOp < 1000) {
                                        display = `${Math.round(nsPerOp)}ns`;
                                    } else if (nsPerOp < 1000000) {
                                        display = `${Math.round(nsPerOp / 1000)}µs`;
                                    } else {
                                        display = `${Math.round(nsPerOp / 1000000)}ms`;
                                    }
                                    
                                    const speedup = nsPerOp / minValue;
                                    const speedupText = speedup > 1 ? ` (${speedup.toFixed(1)}x slower)` : '';
                                    
                                    return `<td>${display}<span class="speedup">${speedupText}</span></td>`;
                                }).join('')}
                                <td class="winner">${winner}</td>
                            </tr>
                            `;
                        }).join('')}
                    </tbody>
                </table>
            </div>
            `;
        }).join('')}
        
        <div class="category">
            <h1 style="margin-bottom: 30px;">💾 Memory Usage Rankings</h1>
            <p class="subtitle" style="margin-bottom: 30px;">Lower is better - peak memory consumption during benchmark execution</p>
            
            ${Object.entries(categories).map(([categoryName, benchmarks], index) => {
                if (benchmarks.length === 0) return '';
                
                // Filter out benchmarks with no memory data
                const benchmarksWithMemory = benchmarks.filter(bench => {
                    return Object.values(bench.implementations).some(impl => impl && impl.bytesPerOp > 0);
                });
                
                if (benchmarksWithMemory.length === 0) return '';
                
                return `
                <div style="margin-bottom: 40px;">
                    <h2>${categoryName}</h2>
                    <table class="stats-table">
                        <thead>
                            <tr>
                                <th>Benchmark</th>
                                ${implementations.map(impl => `<th>${impl}</th>`).join('')}
                                <th>Winner (Lowest Memory)</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${benchmarksWithMemory.map(bench => {
                                const values = implementations.map(impl => {
                                    const result = bench.implementations[impl];
                                    return result && result.bytesPerOp ? result.bytesPerOp : Infinity;
                                });
                                const minValue = Math.min(...values.filter(v => v !== Infinity && v > 0));
                                const winnerIndex = values.indexOf(minValue);
                                const winner = minValue !== Infinity ? implementations[winnerIndex] : 'N/A';
                                
                                return `
                                <tr>
                                    <td><strong>${bench.name}</strong></td>
                                    ${implementations.map((impl, i) => {
                                        const result = bench.implementations[impl];
                                        if (!result || !result.bytesPerOp || result.bytesPerOp === 0) return '<td>-</td>';
                                        
                                        const bytes = result.bytesPerOp;
                                        let display;
                                        if (bytes < 1024) {
                                            display = `${bytes}B`;
                                        } else if (bytes < 1024 * 1024) {
                                            display = `${Math.round(bytes / 1024)}KB`;
                                        } else {
                                            display = `${Math.round(bytes / (1024 * 1024))}MB`;
                                        }
                                        
                                        const ratio = bytes / minValue;
                                        const ratioText = ratio > 1 ? ` (${ratio.toFixed(1)}x more)` : '';
                                        
                                        return `<td>${display}<span class="speedup">${ratioText}</span></td>`;
                                    }).join('')}
                                    <td class="winner">${winner}</td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                </div>
                `;
            }).join('')}
        </div>
        
        <footer>
            <p>Generated: ${new Date().toLocaleString()}</p>
            <p>Zig DOM Implementation - Benchmark Report</p>
        </footer>
    </div>
    
    <script>
        const implementations = ${JSON.stringify(implementations)};
        const colors = {
            'Zig': '#f9a825',
            'Chromium': '#4285f4',
            'Firefox': '#ff6611',
            'WebKit': '#00aaff'
        };
        
        const chartData = ${JSON.stringify(chartDataSets)};
        
        // Create charts
        chartData.forEach((category, index) => {
            if (category.benchmarks.length === 0) return;
            
            const ctx = document.getElementById(\`chart-\${index}\`);
            
            const datasets = implementations.map((impl, i) => ({
                label: impl,
                data: category.benchmarks.map(b => b.data[i]),
                backgroundColor: colors[impl] || \`hsl(\${i * 60}, 70%, 60%)\`,
                borderColor: colors[impl] || \`hsl(\${i * 60}, 70%, 50%)\`,
                borderWidth: 2
            }));
            
            new Chart(ctx, {
                type: 'bar',
                data: {
                    labels: category.benchmarks.map(b => b.name.replace(/Pure query: /, '').replace(/ \\(\\d+ elem\\)/, '')),
                    datasets: datasets
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: false
                        },
                        legend: {
                            position: 'top',
                            labels: {
                                font: {
                                    size: 12,
                                    weight: 600
                                },
                                padding: 15
                            }
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    let value = context.parsed.y;
                                    if (value === null) return '';
                                    
                                    let display;
                                    if (value < 1000) {
                                        display = Math.round(value) + 'ns';
                                    } else if (value < 1000000) {
                                        display = Math.round(value / 1000) + 'µs';
                                    } else {
                                        display = Math.round(value / 1000000) + 'ms';
                                    }
                                    
                                    return context.dataset.label + ': ' + display;
                                }
                            }
                        }
                    },
                    scales: {
                        y: {
                            type: 'logarithmic',
                            title: {
                                display: true,
                                text: 'Time per Operation (ns, log scale)',
                                font: {
                                    size: 14,
                                    weight: 600
                                }
                            },
                            ticks: {
                                callback: function(value) {
                                    if (value < 1000) return value + 'ns';
                                    if (value < 1000000) return (value / 1000) + 'µs';
                                    return (value / 1000000) + 'ms';
                                }
                            }
                        },
                        x: {
                            ticks: {
                                font: {
                                    size: 11
                                }
                            }
                        }
                    }
                }
            });
        });
    </script>
</body>
</html>`;
    
    return html;
}

/**
 * Main entry point
 */
async function main() {
    console.log('Benchmark Visualization Generator');
    console.log('==================================\n');
    
    console.log('Loading results...');
    const zigResults = await loadZigResults();
    const browserResults = await loadBrowserResults();
    
    console.log(`  Zig benchmarks: ${zigResults.length}`);
    console.log(`  Browser results: ${browserResults.length} browsers\n`);
    
    if (zigResults.length === 0 && browserResults.length === 0) {
        console.error('❌ No results found. Run benchmarks first.');
        process.exit(1);
    }
    
    console.log('Grouping results...');
    const groupedResults = groupResults(zigResults, browserResults);
    console.log(`  ${groupedResults.length} unique benchmarks\n`);
    
    console.log('Generating HTML report...');
    const html = generateHTML(groupedResults, browserResults);
    
    await fs.mkdir(RESULTS_DIR, { recursive: true });
    await fs.writeFile(OUTPUT_FILE, html);
    
    console.log(`\n✅ Report generated: ${OUTPUT_FILE}`);
    console.log(`\nOpen in browser: file://${OUTPUT_FILE}`);
}

// Run if called directly
if (require.main === module) {
    main().catch(error => {
        console.error('Error:', error);
        process.exit(1);
    });
}

module.exports = { main };
