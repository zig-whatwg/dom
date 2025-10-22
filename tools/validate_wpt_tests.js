#!/usr/bin/env node

/**
 * WPT Test Validator
 * 
 * Validates that converted WPT tests are syntactically correct
 * and properly structured.
 * 
 * Usage:
 *   node tools/validate_wpt_tests.js
 */

const fs = require('fs');
const path = require('path');

const TEST_DIR = path.join(__dirname, '..', 'tests', 'wpt-v8');

let stats = {
    total: 0,
    valid: 0,
    invalid: 0,
    errors: []
};

function validateTest(filePath) {
    stats.total++;
    
    try {
        const content = fs.readFileSync(filePath, 'utf8');
        
        // Check for syntax errors by attempting to parse
        // (Node.js will throw SyntaxError if invalid)
        new Function(content);
        
        // Check for required WPT header comment
        if (!content.includes('// Converted from WPT HTML test')) {
            throw new Error('Missing WPT conversion header');
        }
        
        // Check for original file reference
        if (!content.includes('// Original:')) {
            throw new Error('Missing original file reference');
        }
        
        stats.valid++;
        return true;
        
    } catch (err) {
        stats.invalid++;
        stats.errors.push({
            file: path.relative(TEST_DIR, filePath),
            error: err.message
        });
        return false;
    }
}

function scanDirectory(dir) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        
        if (entry.isDirectory()) {
            // Skip resources and examples directories
            if (entry.name === 'resources' || entry.name === 'examples') {
                continue;
            }
            scanDirectory(fullPath);
        } else if (entry.isFile() && entry.name.endsWith('.test.js')) {
            validateTest(fullPath);
        }
    }
}

console.log('=== WPT Test Validator ===\n');
console.log(`Scanning: ${TEST_DIR}\n`);

try {
    scanDirectory(TEST_DIR);
    
    console.log('=== Results ===');
    console.log(`Total tests:   ${stats.total}`);
    console.log(`Valid:         ${stats.valid} ✓`);
    console.log(`Invalid:       ${stats.invalid} ✗`);
    console.log(`Success rate:  ${((stats.valid / stats.total) * 100).toFixed(1)}%`);
    
    if (stats.invalid > 0) {
        console.log('\n=== Errors ===');
        for (const error of stats.errors) {
            console.log(`\n${error.file}:`);
            console.log(`  ${error.error}`);
        }
        process.exit(1);
    } else {
        console.log('\n✓ All tests are valid!');
        process.exit(0);
    }
    
} catch (err) {
    console.error('Fatal error:', err.message);
    process.exit(1);
}
