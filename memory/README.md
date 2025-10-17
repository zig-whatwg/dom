# Memory Directory

This directory stores persistent knowledge managed by Claude's memory tool.

## Purpose

The memory tool enables Claude to store and retrieve information across conversations, maintaining project context and accumulated knowledge.

## Files

### `completed_features.json`
Tracks which WHATWG DOM features have been implemented, when, and their current status.

### `design_decisions.md`
Documents architectural decisions, rationale, and trade-offs made during implementation.

### `performance_baselines.json`
Stores benchmark results to track performance over time and catch regressions.

### `spec_interpretations.md`
Notes about complex or ambiguous spec sections and how they were interpreted in this implementation.

## Usage

Claude uses the memory tool automatically to:
- Track completed work across sessions
- Remember design decisions
- Maintain performance baselines
- Store spec interpretation notes
- Build up project knowledge over time

## Note

This directory is managed by Claude's memory tool. Manual edits may be overwritten.
