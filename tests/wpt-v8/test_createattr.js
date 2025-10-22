// Simple test for createAttribute without testharness

print("=== createAttribute Test ===\n");

// Test 1: Create attribute
try {
    const attr = document.createAttribute("id");
    print("✓ Test 1: createAttribute succeeded");
    print("  Type:", typeof attr);
    print("  ToString:", attr);
} catch (e) {
    print("✗ Test 1 FAILED:", e.message);
}

// Test 2: Attribute name
try {
    const attr = document.createAttribute("class");
    // TODO: Add name property test when implemented
    print("✓ Test 2: createAttribute with different name succeeded");
} catch (e) {
    print("✗ Test 2 FAILED:", e.message);
}

// Test 3: appendChild should fail with HierarchyRequestError
try {
    const parent = document.createElement("div");
    const attr = document.createAttribute("test");
    
    try {
        parent.appendChild(attr);
        print("✗ Test 3 FAILED: appendChild should have thrown");
    } catch (e2) {
        print("✓ Test 3: appendChild correctly threw error");
        print("  Error:", e2.message);
    }
} catch (e) {
    print("✗ Test 3 FAILED:", e.message);
}

print("\n=== Tests Complete ===");
