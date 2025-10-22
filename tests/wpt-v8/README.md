# WPT V8 Test Suite

This directory contains Web Platform Tests (WPT) converted from HTML format to standalone JavaScript files that can be executed in V8 with the DOM library.

## Structure

```
wpt-v8/
├── resources/
│   ├── testharness.js       # WPT test framework
│   └── testharnessreport.js # WPT test reporting
├── nodes/                    # DOM Node tests (142 tests)
├── events/                   # Event dispatch, bubbling tests (83 tests)
├── ranges/                   # DOM Range API tests (38 tests)
├── traversal/                # TreeWalker, NodeIterator tests (16 tests)
├── collections/              # HTMLCollection, NamedNodeMap tests (9 tests)
├── lists/                    # DOMTokenList tests (5 tests)
├── abort/                    # AbortController, AbortSignal tests (3 tests)
├── *.test.js                 # Root-level tests (9 tests)
├── common.js                 # Shared test utilities
├── constants.js              # Shared constants
├── runner_bootstrap.js       # V8 + DOM setup
├── run_tests.js              # Test runner
└── README.md                 # This file
```

**Total: 362 tests**

## Running Tests

**Note**: The original plan was to use d8, but d8 cannot load the V8 bindings library directly. Instead, a custom test runner has been created.

### Current Status

✅ **Test runner built**: `../../v8-bindings/wpt_test_runner`  
✅ **V8 bindings working**: Basic DOM operations work  
❌ **WPT tests failing**: Missing DOM API wrappers (getElementById, querySelector, etc.)

### Run Tests (once wrappers are added)

```bash
# From project root
./v8-bindings/wpt_test_runner \
  tests/wpt-v8/runner_bootstrap.js \
  tests/wpt-v8/resources/testharness.js \
  tests/wpt-v8/attributes-are-nodes.test.js
```

### What Needs to be Fixed

See `../../v8-bindings/WPTV8_INTEGRATION_STATUS.md` for:
- Complete list of missing DOM API wrappers
- Step-by-step instructions to add them
- Code examples for each wrapper type

**Quick summary**: The Zig DOM has all the functionality, but the V8 JavaScript wrappers for query methods (getElementById, querySelector, etc.) haven't been written yet.

## Test Format

Tests are converted from WPT HTML files:
- HTML structure is converted to `document.body.innerHTML = ...`
- Inline `<script>` content is extracted
- External `<script src="...">` dependencies are copied
- Absolute paths (`/resources/`) are converted to relative paths

## Requirements

- **d8**: V8's command-line shell
- **DOM library**: Compiled Zig DOM implementation
- **v8-bindings**: V8 JavaScript bindings to DOM library

## Test Filtering

These tests exclude:
- Rendering/layout tests (offsetWidth, getBoundingClientRect, etc.)
- CSS/styling tests
- Experimental APIs (Observable, DOM Parts)
- Browser-specific features

## Output

Test results are printed to console:
- ✓ PASS - Test passed
- ✗ FAIL - Test failed (with error message)
- Summary with pass/fail counts

## Conversion

Tests are auto-converted from `/Users/bcardarella/projects/wpt/dom/` using:

```bash
zig build wpt-convert
```

This scans WPT HTML tests, applies filtering, extracts JavaScript, and writes to this directory.

## Test Framework

Uses WPT's testharness.js framework:
- `test(fn, name)` - Synchronous test
- `async_test(fn, name)` - Asynchronous test
- `assert_true(condition, message)` - Assert condition is true
- `assert_equals(actual, expected, message)` - Assert equality
- `assert_throws_dom(error, fn, message)` - Assert function throws DOM exception
- And many more assertions...

See https://web-platform-tests.org/writing-tests/testharness-api.html for full API.

## Notes

- Tests are generated - do NOT manually edit `.test.js` files
- To fix tests, modify source WPT HTML and re-run converter
- Tests run in V8 with DOM bindings, not in a browser
- Some tests may fail due to missing/unimplemented DOM features
