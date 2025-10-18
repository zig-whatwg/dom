# Web Platform Tests for DOM Implementation

This directory contains Web Platform Tests (WPT) converted from the official WPT repository located at `/Users/bcardarella/projects/wpt`.

## Structure

Tests are organized to match the WPT directory structure:
- File names are preserved exactly (with `.zig` extension instead of `.html`/`.js`)
- Test assertions and setup remain unchanged
- Only the test runner and syntax are adapted for Zig

## Running Tests

```bash
zig build test-wpt
```

## Status

Tests are converted but may have failing assertions. The goal is to preserve the exact test behavior from WPT to validate spec compliance.
