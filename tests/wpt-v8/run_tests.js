// WPT V8 Test Runner
//
// Runs converted WPT tests in V8 with DOM bindings.
//
// Usage:
//   d8 --expose-gc run_tests.js                    # Run all tests
//   d8 --expose-gc run_tests.js -- nodes/test.js   # Run single test
//   d8 --expose-gc run_tests.js -- nodes/          # Run directory

(function() {
    'use strict';

    // Load bootstrap (sets up DOM environment)
    load('tests/wpt-v8/runner_bootstrap.js');

    // Test results
    var stats = {
        total: 0,
        passed: 0,
        failed: 0,
        errors: []
    };

    // Load testharness.js (WPT test framework)
    load('tests/wpt-v8/resources/testharness.js');

    // Override test framework reporting to collect results
    var originalAddResult = add_result_callback;
    add_result_callback(function(test) {
        stats.total++;
        if (test.status === 0) { // PASS
            stats.passed++;
            print('✓ PASS:', test.name);
        } else {
            stats.failed++;
            print('✗ FAIL:', test.name);
            if (test.message) {
                print('  ', test.message);
            }
            stats.errors.push({
                name: test.name,
                message: test.message || 'Unknown error'
            });
        }
    });

    // Parse command line arguments
    var args = typeof scriptArgs !== 'undefined' ? scriptArgs : [];
    var testPaths = args.length > 0 ? args : [];

    if (testPaths.length === 0) {
        print('WPT V8 Test Runner');
        print('==================\n');
        print('Usage:');
        print('  d8 run_tests.js -- test.js          # Run single test');
        print('  d8 run_tests.js -- directory/       # Run directory');
        print('  d8 run_tests.js                     # Run all tests\n');
        
        // TODO: Implement directory scanning for "run all" mode
        print('ERROR: No test files specified');
        print('Directory scanning not yet implemented.');
        quit(1);
    }

    // Run tests
    print('Running tests...\n');
    
    testPaths.forEach(function(testPath) {
        try {
            // Make path relative to wpt-v8 directory if needed
            var fullPath = testPath.startsWith('tests/wpt-v8/') 
                ? testPath 
                : 'tests/wpt-v8/' + testPath;
            
            print('Loading:', fullPath);
            load(fullPath);
        } catch (e) {
            stats.total++;
            stats.failed++;
            stats.errors.push({
                name: testPath,
                message: e.toString()
            });
            print('✗ ERROR loading:', testPath);
            print('  ', e.toString());
        }
    });

    // Print summary
    print('\n==================');
    print('Test Summary');
    print('==================');
    print('Total:  ', stats.total);
    print('Passed: ', stats.passed);
    print('Failed: ', stats.failed);
    
    if (stats.failed > 0) {
        print('\nFailed tests:');
        stats.errors.forEach(function(error) {
            print('  -', error.name);
            print('    ', error.message);
        });
    }

    // Exit with error code if tests failed
    if (stats.failed > 0) {
        quit(1);
    }

})();
