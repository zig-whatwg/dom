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
    const zigFile = path.join(RESULTS_DIR, 'phase4_release_fast.txt');
    
    try {
        const content = await fs.readFile(zigFile, 'utf-8');
        const results = [];
        
        // Parse Zig benchmark output
        const lines = content.split('\n');
        for (const line of lines) {
            // Match lines like: "Pure query: getElementById (100 elem): 5ns/op (200000000 ops/sec)"
            const match = line.match(/^(.+?):\s+(\d+(?:\.\d+)?)(ns|µs|ms)\/op\s+\((\d+)\s+ops\/sec\)/);
            if (match) {
                const name = match[1].trim();
                let value = parseFloat(match[2]);
                const unit = match[3];
                const opsPerSec = parseInt(match[4]);
                
                // Convert everything to nanoseconds
                if (unit === 'µs') value *= 1000;
                if (unit === 'ms') value *= 1000000;
                
                results.push({
                    name,
                    nsPerOp: value,
                    opsPerSec
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
            opsPerSec: result.opsPerSec
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
                opsPerSec: result.opsPerSec
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
    
    // Group benchmarks by category
    const categories = {
        'ID Queries': groupedResults.filter(r => r.name.includes('getElementById') || r.name.includes('#id')),
        'Tag Queries': groupedResults.filter(r => r.name.includes('TagName') || r.name.includes('tag (') && !r.name.includes('#')),
        'Class Queries': groupedResults.filter(r => r.name.includes('ClassName') || r.name.includes('.class')),
        'Complex Queries': groupedResults.filter(r => 
            !r.name.includes('getElementById') &&
            !r.name.includes('#id') &&
            !r.name.includes('TagName') &&
            !r.name.includes('tag (') &&
            !r.name.includes('ClassName') &&
            !r.name.includes('.class')
        )
    };
    
    // Generate chart data for each category
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
