// WPT Test Reporter for V8
//
// This hooks into testharness.js to report test results to console

(function(global) {
    'use strict';

    // Track test results
    var results = {
        passed: 0,
        failed: 0,
        total: 0,
        errors: []
    };

    // Add result callback to report individual tests
    add_result_callback(function(test) {
        results.total++;
        
        if (test.status === 0) {  // PASS
            results.passed++;
            print('  ✓ PASS: ' + test.name);
        } else if (test.status === 1) {  // FAIL
            results.failed++;
            print('  ✗ FAIL: ' + test.name);
            if (test.message) {
                print('           ' + test.message);
            }
            results.errors.push({
                name: test.name,
                message: test.message || 'Unknown error',
                stack: test.stack || ''
            });
        } else if (test.status === 2) {  // TIMEOUT
            results.failed++;
            print('  ⏱ TIMEOUT: ' + test.name);
            results.errors.push({
                name: test.name,
                message: 'Test timed out',
                stack: ''
            });
        } else if (test.status === 3) {  // NOTRUN
            print('  ⊘ NOTRUN: ' + test.name);
        }
    });

    // Add completion callback to print summary
    add_completion_callback(function(tests, harness_status) {
        print('\n' + '='.repeat(50));
        print('Test Results');
        print('='.repeat(50));
        print('Total:  ' + results.total);
        print('Passed: ' + results.passed);
        print('Failed: ' + results.failed);
        print('='.repeat(50));
        
        if (results.failed > 0) {
            print('\nFailed Tests:');
            results.errors.forEach(function(error) {
                print('  • ' + error.name);
                print('    ' + error.message);
                if (error.stack) {
                    print('    ' + error.stack);
                }
            });
        }
        
        // Exit with non-zero code if tests failed
        if (results.failed > 0) {
            if (typeof quit !== 'undefined') {
                quit(1);
            }
        }
    });

    print('[Reporter] Test result reporting configured');

})(this);
