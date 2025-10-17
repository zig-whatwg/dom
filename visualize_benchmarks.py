#!/usr/bin/env python3
"""
Visualize benchmark results from JSON files.

Usage:
    python visualize_benchmarks.py                    # Plot all results
    python visualize_benchmarks.py --compare file1.json file2.json  # Compare two runs
    python visualize_benchmarks.py --history          # Show trend over time
"""

import json
import argparse
import sys
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from collections import defaultdict

def load_benchmark_file(filepath: Path) -> Dict[str, Any]:
    """Load a benchmark JSON file."""
    with open(filepath, 'r') as f:
        return json.load(f)

def plot_single_run(data: Dict[str, Any], output_file: str | None = None):
    """Plot results from a single benchmark run."""
    results = data['results']
    
    # Group by category
    categories = defaultdict(list)
    for result in results:
        name = result['name']
        category = name.split(':')[0]
        categories[category].append(result)
    
    # Create subplots for each category
    fig, axes = plt.subplots(len(categories), 1, figsize=(12, 4 * len(categories)))
    if len(categories) == 1:
        axes = [axes]
    
    fig.suptitle(f"Benchmark Results - {data['optimize_mode']} mode", fontsize=16)
    
    for idx, (category, items) in enumerate(sorted(categories.items())):
        ax = axes[idx]
        
        names = [item['name'].split(': ', 1)[1] for item in items]
        ns_per_op = [item['ns_per_op'] for item in items]
        
        bars = ax.barh(names, ns_per_op)
        
        # Color bars based on performance
        for bar, value in zip(bars, ns_per_op):
            if value < 1000:  # < 1µs
                bar.set_color('#2ecc71')  # Green
            elif value < 10000:  # < 10µs
                bar.set_color('#f39c12')  # Orange
            elif value < 100000:  # < 100µs
                bar.set_color('#e74c3c')  # Red
            else:
                bar.set_color('#8e44ad')  # Purple
        
        ax.set_xlabel('Nanoseconds per operation')
        ax.set_title(f'{category} Benchmarks')
        ax.grid(axis='x', alpha=0.3)
        
        # Add value labels
        for bar in bars:
            width = bar.get_width()
            if width < 1000:
                label = f'{width:.0f}ns'
            elif width < 1000000:
                label = f'{width/1000:.1f}µs'
            else:
                label = f'{width/1000000:.1f}ms'
            
            ax.text(width, bar.get_y() + bar.get_height()/2,
                   f' {label}', va='center', fontsize=8)
    
    plt.tight_layout()
    
    if output_file:
        plt.savefig(output_file, dpi=150, bbox_inches='tight')
        print(f"Chart saved to: {output_file}")
    else:
        plt.show()

def compare_runs(file1: Path, file2: Path, output_file: str | None = None):
    """Compare two benchmark runs."""
    data1 = load_benchmark_file(file1)
    data2 = load_benchmark_file(file2)
    
    # Build lookup for results
    results1 = {r['name']: r for r in data1['results']}
    results2 = {r['name']: r for r in data2['results']}
    
    # Find common benchmarks
    common_names = sorted(set(results1.keys()) & set(results2.keys()))
    
    if not common_names:
        print("No common benchmarks found!")
        return
    
    # Calculate improvements
    improvements = []
    for name in common_names:
        r1 = results1[name]
        r2 = results2[name]
        
        old_time = r1['ns_per_op']
        new_time = r2['ns_per_op']
        
        if old_time > 0:
            improvement = ((old_time - new_time) / old_time) * 100
        else:
            improvement = 0
        
        improvements.append({
            'name': name,
            'old': old_time,
            'new': new_time,
            'improvement': improvement
        })
    
    # Sort by improvement
    improvements.sort(key=lambda x: abs(x['improvement']), reverse=True)
    
    # Create comparison plot
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, len(improvements) * 0.4))
    
    names = [item['name'].split(': ', 1)[1] for item in improvements]
    old_times = [item['old'] for item in improvements]
    new_times = [item['new'] for item in improvements]
    
    # Side-by-side bar chart
    y_pos = range(len(names))
    width = 0.35
    
    ax1.barh([i - width/2 for i in y_pos], old_times, width, label='Before', alpha=0.8)
    ax1.barh([i + width/2 for i in y_pos], new_times, width, label='After', alpha=0.8)
    ax1.set_yticks(y_pos)
    ax1.set_yticklabels(names, fontsize=8)
    ax1.set_xlabel('Nanoseconds per operation')
    ax1.set_title('Performance Comparison')
    ax1.legend()
    ax1.grid(axis='x', alpha=0.3)
    
    # Improvement percentage chart
    improvements_pct = [item['improvement'] for item in improvements]
    colors = ['green' if x > 0 else 'red' for x in improvements_pct]
    
    ax2.barh(y_pos, improvements_pct, color=colors, alpha=0.8)
    ax2.set_yticks(y_pos)
    ax2.set_yticklabels(names, fontsize=8)
    ax2.set_xlabel('Improvement (%)')
    ax2.set_title('Performance Change')
    ax2.axvline(x=0, color='black', linestyle='-', linewidth=0.5)
    ax2.grid(axis='x', alpha=0.3)
    
    # Add percentage labels
    for i, pct in enumerate(improvements_pct):
        if pct > 0:
            ax2.text(pct, i, f' +{pct:.1f}%', va='center', fontsize=7, color='green')
        else:
            ax2.text(pct, i, f' {pct:.1f}%', va='center', fontsize=7, color='red')
    
    plt.suptitle(f'Benchmark Comparison\n{file1.name} vs {file2.name}', fontsize=14)
    plt.tight_layout()
    
    if output_file:
        plt.savefig(output_file, dpi=150, bbox_inches='tight')
        print(f"Comparison chart saved to: {output_file}")
    else:
        plt.show()
    
    # Print summary
    print("\nPerformance Summary:")
    print("=" * 80)
    total_improvement = sum(improvements_pct) / len(improvements_pct)
    print(f"Average improvement: {total_improvement:+.1f}%")
    print(f"\nTop 5 improvements:")
    for item in improvements[:5]:
        print(f"  {item['name']}: {item['improvement']:+.1f}% "
              f"({item['old']/1000:.1f}µs → {item['new']/1000:.1f}µs)")
    
    if any(i['improvement'] < 0 for i in improvements):
        print(f"\nRegressions:")
        for item in improvements:
            if item['improvement'] < 0:
                print(f"  {item['name']}: {item['improvement']:+.1f}% "
                      f"({item['old']/1000:.1f}µs → {item['new']/1000:.1f}µs)")

def plot_history(benchmark_dir: Path, output_file: str | None = None):
    """Plot benchmark history over time."""
    # Load all benchmark files
    json_files = sorted(benchmark_dir.glob("*.json"))
    if Path("benchmark_results/latest.json") in json_files:
        json_files.remove(Path("benchmark_results/latest.json"))
    
    if not json_files:
        print("No benchmark files found!")
        return
    
    # Load all data
    history = []
    for filepath in json_files:
        try:
            data = load_benchmark_file(filepath)
            history.append(data)
        except Exception as e:
            print(f"Error loading {filepath}: {e}")
    
    if not history:
        print("No valid benchmark data found!")
        return
    
    # Extract timestamps and results
    timestamps = [datetime.fromtimestamp(h['timestamp']) for h in history]
    
    # Group by benchmark name
    benchmark_data = defaultdict(list)
    for data in history:
        for result in data['results']:
            benchmark_data[result['name']].append(result['ns_per_op'])
    
    # Plot trends for key benchmarks
    key_benchmarks = [
        'querySelector: Small DOM (100 elems, #target)',
        'querySelector: Medium DOM (1000 elems, #target)',
        'querySelector: Large DOM (10000 elems, #target)',
        'querySelector: Class (.target, 1000 elems)',
        'SPA: Repeated querySelector (.component, 1000 queries)',
    ]
    
    fig, axes = plt.subplots(len(key_benchmarks), 1, figsize=(12, 3 * len(key_benchmarks)))
    if len(key_benchmarks) == 1:
        axes = [axes]
    
    for idx, benchmark_name in enumerate(key_benchmarks):
        if benchmark_name in benchmark_data:
            ax = axes[idx]
            values = benchmark_data[benchmark_name]
            
            ax.plot(timestamps[:len(values)], values, marker='o', linewidth=2, markersize=8)
            ax.set_xlabel('Date')
            ax.set_ylabel('ns/op')
            ax.set_title(benchmark_name)
            ax.grid(True, alpha=0.3)
            ax.xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
            plt.setp(ax.xaxis.get_majorticklabels(), rotation=45, ha='right')
            
            # Add value labels
            for x, y in zip(timestamps[:len(values)], values):
                if y < 1000:
                    label = f'{y:.0f}ns'
                elif y < 1000000:
                    label = f'{y/1000:.1f}µs'
                else:
                    label = f'{y/1000000:.1f}ms'
                ax.annotate(label, (x, y), textcoords="offset points",
                           xytext=(0,5), ha='center', fontsize=7)
    
    plt.suptitle('Benchmark History', fontsize=16)
    plt.tight_layout()
    
    if output_file:
        plt.savefig(output_file, dpi=150, bbox_inches='tight')
        print(f"History chart saved to: {output_file}")
    else:
        plt.show()

def main():
    parser = argparse.ArgumentParser(description='Visualize DOM benchmark results')
    parser.add_argument('--compare', nargs=2, metavar=('FILE1', 'FILE2'),
                       help='Compare two benchmark runs')
    parser.add_argument('--history', action='store_true',
                       help='Show benchmark history over time')
    parser.add_argument('--output', '-o', help='Output file for chart')
    parser.add_argument('file', nargs='?', help='Benchmark JSON file to visualize')
    
    args = parser.parse_args()
    
    try:
        if args.compare:
            file1 = Path(args.compare[0])
            file2 = Path(args.compare[1])
            if not file1.exists() or not file2.exists():
                print("Error: One or both comparison files not found")
                return 1
            compare_runs(file1, file2, args.output)
        
        elif args.history:
            benchmark_dir = Path('benchmark_results')
            if not benchmark_dir.exists():
                print("Error: benchmark_results directory not found")
                return 1
            plot_history(benchmark_dir, args.output)
        
        else:
            if args.file:
                filepath = Path(args.file)
            else:
                # Use latest.json by default
                filepath = Path('benchmark_results/latest.json')
            
            if not filepath.exists():
                print(f"Error: File not found: {filepath}")
                print("Run benchmarks first with: zig build bench")
                return 1
            
            data = load_benchmark_file(filepath)
            plot_single_run(data, args.output)
        
        return 0
    
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
