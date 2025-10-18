#!/usr/bin/env node

/**
 * Memory Stress Test Visualization
 * 
 * Generates interactive HTML report showing:
 * - Memory leak detection (linear growth = leak)
 * - Per-cycle leak rate
 * - Pass/Fail status
 */

const fs = require('fs');
const path = require('path');

const RESULTS_DIR = 'benchmark_results/memory_stress';
const LATEST_FILE = path.join(RESULTS_DIR, 'memory_samples_latest.json');
const CHART_JS_CDN = 'https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js';

function formatBytes(bytes) {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i];
}

function formatNumber(num) {
  if (num === undefined || num === null) return '0';
  return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function loadResults() {
  if (!fs.existsSync(LATEST_FILE)) {
    console.error(`Error: Results file not found: ${LATEST_FILE}`);
    process.exit(1);
  }
  const data = fs.readFileSync(LATEST_FILE, 'utf8');
  return JSON.parse(data);
}

function generateHTML(results) {
  const { config, samples, final_state } = results;
  
  const initialMem = samples[0].bytes_used;
  const finalMem = samples[samples.length - 1].bytes_used;
  const memoryLeaked = finalMem - initialMem;
  const leakPerCycle = final_state.cycles_completed > 0 ? 
    memoryLeaked / final_state.cycles_completed : 0;
  
  const timestamps = samples.map(s => (s.timestamp_ms / 1000).toFixed(1));
  const memoryMB = samples.map(s => s.bytes_used / (1024 * 1024));
  
  const isLeak = memoryLeaked > 1024; // More than 1KB leaked
  const statusClass = isLeak ? 'fail' : 'pass';
  const statusText = isLeak ? '❌ FAIL' : '✅ PASS';
  const statusMessage = isLeak ? 
    'Memory leak detected! Memory should return to baseline.' :
    'No memory leak detected. Memory remains stable.';

  const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Memory Stress Test - Leak Detection</title>
  <script src="${CHART_JS_CDN}"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: #333;
      padding: 20px;
      min-height: 100vh;
    }
    .container { max-width: 1400px; margin: 0 auto; }
    .header {
      background: white;
      border-radius: 12px;
      padding: 30px;
      margin-bottom: 20px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    .header h1 { color: #667eea; margin-bottom: 10px; font-size: 2.5em; }
    .header .subtitle { color: #666; font-size: 1.1em; }
    .status-banner {
      padding: 20px 30px;
      border-radius: 12px;
      margin-bottom: 20px;
      font-size: 1.2em;
      font-weight: bold;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    .status-banner.pass { background: #48bb78; color: white; }
    .status-banner.fail { background: #f56565; color: white; }
    .status-banner .message {
      font-size: 0.9em;
      font-weight: normal;
      margin-top: 5px;
      opacity: 0.95;
    }
    .summary {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 20px;
      margin-bottom: 20px;
    }
    .stat-card {
      background: white;
      border-radius: 12px;
      padding: 25px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      transition: transform 0.2s;
    }
    .stat-card:hover { transform: translateY(-5px); }
    .stat-card .label {
      color: #888;
      font-size: 0.9em;
      text-transform: uppercase;
      letter-spacing: 1px;
      margin-bottom: 10px;
    }
    .stat-card .value { color: #667eea; font-size: 2em; font-weight: bold; }
    .stat-card .subvalue { color: #999; font-size: 0.9em; margin-top: 5px; }
    .stat-card.leak { border: 3px solid #f56565; }
    .stat-card.leak .value { color: #f56565; }
    .chart-container {
      background: white;
      border-radius: 12px;
      padding: 25px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      margin-bottom: 20px;
    }
    .chart-container h2 { color: #667eea; margin-bottom: 20px; font-size: 1.5em; }
    .chart-wrapper { position: relative; height: 400px; }
    .info-box {
      background: white;
      border-radius: 12px;
      padding: 25px;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
      margin-bottom: 20px;
    }
    .info-box h2 { color: #667eea; margin-bottom: 15px; font-size: 1.5em; }
    .info-box p { color: #666; line-height: 1.6; margin-bottom: 10px; }
    .info-box .highlight {
      background: #fef3c7;
      padding: 15px;
      border-left: 4px solid #f59e0b;
      border-radius: 4px;
      margin: 15px 0;
    }
    .info-box code {
      background: #f7fafc;
      padding: 2px 6px;
      border-radius: 3px;
      font-family: Monaco, monospace;
      color: #e53e3e;
    }
    table { width: 100%; border-collapse: collapse; margin-top: 15px; }
    th, td { text-align: left; padding: 12px; border-bottom: 1px solid #eee; }
    th {
      background: #f8f9fa;
      color: #667eea;
      font-weight: 600;
      text-transform: uppercase;
      font-size: 0.85em;
      letter-spacing: 1px;
    }
    tr:hover { background: #f8f9fa; }
    .footer {
      text-align: center;
      color: white;
      margin-top: 30px;
      padding: 20px;
      font-size: 0.9em;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔬 Memory Stress Test Results</h1>
      <p class="subtitle">Document Lifecycle Leak Detection</p>
    </div>
    
    <div class="status-banner ${statusClass}">
      <div>${statusText}: ${statusMessage}</div>
      <div class="message">
        ${isLeak ? 
          `Memory leaked: ${formatBytes(memoryLeaked)} across ${formatNumber(final_state.cycles_completed)} cycles` :
          'All memory properly freed between Document lifecycles'}
      </div>
    </div>
    
    <div class="summary">
      <div class="stat-card">
        <div class="label">Test Duration</div>
        <div class="value">${config.duration_seconds}s</div>
        <div class="subvalue">Sample interval: ${config.sample_interval_ms / 1000}s</div>
      </div>
      
      <div class="stat-card">
        <div class="label">Cycles Completed</div>
        <div class="value">${formatNumber(final_state.cycles_completed)}</div>
        <div class="subvalue">${config.nodes_per_cycle} nodes × ${config.operations_per_node} ops</div>
      </div>
      
      <div class="stat-card ${isLeak ? 'leak' : ''}">
        <div class="label">Memory Leaked</div>
        <div class="value">${formatBytes(memoryLeaked)}</div>
        <div class="subvalue">${formatBytes(leakPerCycle)} per cycle</div>
      </div>
      
      <div class="stat-card">
        <div class="label">Total Operations</div>
        <div class="value">${formatNumber(
          final_state.operation_breakdown.nodes_created + 
          final_state.operation_breakdown.nodes_deleted +
          final_state.operation_breakdown.reads +
          final_state.operation_breakdown.updates +
          (final_state.operation_breakdown.attribute_ops || 0) +
          (final_state.operation_breakdown.complex_queries || 0)
        )}</div>
        <div class="subvalue">${formatNumber(final_state.operation_breakdown.reads)} reads / ${formatNumber(final_state.operation_breakdown.updates)} updates</div>
      </div>
      
      <div class="stat-card">
        <div class="label">Advanced Operations</div>
        <div class="value">${formatNumber(
          (final_state.operation_breakdown.attribute_ops || 0) +
          (final_state.operation_breakdown.complex_queries || 0)
        )}</div>
        <div class="subvalue">${formatNumber(final_state.operation_breakdown.attribute_ops || 0)} attributes / ${formatNumber(final_state.operation_breakdown.complex_queries || 0)} queries</div>
      </div>
    </div>
    
    <div class="chart-container">
      <h2>📊 Memory Growth Over Time</h2>
      <div class="chart-wrapper">
        <canvas id="memoryChart"></canvas>
      </div>
    </div>
    
    <div class="info-box">
      <h2>🔍 Test Methodology</h2>
      <p>This stress test uses a <strong>Persistent Document</strong> approach to detect memory leaks in long-running applications:</p>
      <ol style="margin-left: 20px; color: #666; line-height: 1.8;">
        <li>Create a single Document that persists for the entire test duration</li>
        <li>Continuously add/remove nodes to maintain steady-state DOM (500-1000 nodes)</li>
        <li>Perform read operations (getElementsByTagName, getElementsByClassName)</li>
        <li>Perform complex queries (querySelector/querySelectorAll with various selectors)</li>
        <li>Perform attribute operations (get/set/has/remove attributes)</li>
        <li>Update text content with bounded growth</li>
        <li>Measure memory every ${config.sample_interval_ms / 1000}s</li>
      </ol>
      <div class="highlight">
        <strong>Key Insight:</strong> Memory should stabilize after initial HashMap capacity growth. 
        Continuous growth indicates a leak. Stable memory (±${formatBytes(5000)}/cycle) indicates proper cleanup.
      </div>
    </div>
    
    <div class="footer">
      Generated ${new Date().toLocaleString()} | Seed: ${config.seed}
    </div>
  </div>
  
  <script>
    const ctx = document.getElementById('memoryChart').getContext('2d');
    new Chart(ctx, {
      type: 'line',
      data: {
        labels: ${JSON.stringify(timestamps.map(t => `${t}s`))},
        datasets: [{
          label: 'Memory (MB)',
          data: ${JSON.stringify(memoryMB)},
          borderColor: ${isLeak ? "'rgb(245, 101, 101)'" : "'rgb(72, 187, 120)'"},
          backgroundColor: ${isLeak ? "'rgba(245, 101, 101, 0.1)'" : "'rgba(72, 187, 120, 0.1)'"},
          tension: 0.4,
          fill: true,
          pointRadius: 6,
          borderWidth: 3,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            title: { display: true, text: 'Memory (MB)' }
          },
          x: {
            title: { display: true, text: 'Time (seconds)' }
          }
        }
      }
    });
  </script>
</body>
</html>`;
  return html;
}

function main() {
  console.log('\n==============================================');
  console.log('  Memory Stress Test Visualization');
  console.log('==============================================\n');
  
  const results = loadResults();
  console.log(`✓ Loaded ${results.samples.length} samples`);
  console.log(`✓ Cycles: ${formatNumber(results.final_state.cycles_completed)}`);
  
  const html = generateHTML(results);
  const outputFile = path.join(RESULTS_DIR, 'memory_report_latest.html');
  fs.writeFileSync(outputFile, html, 'utf8');
  
  console.log(`✓ HTML report: ${outputFile}\n`);
}

main();
