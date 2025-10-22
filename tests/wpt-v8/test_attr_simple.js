// Simple test without testharness to check Attr

print("Testing Attr...");
print("typeof document.createAttribute:", typeof document.createAttribute);

try {
    const attr = document.createAttribute("test");
    print("✓ createAttribute succeeded");
    print("  attr:", attr);
    print("  typeof attr:", typeof attr);
    print("  attr instanceof Node:", attr instanceof Node);
} catch (e) {
    print("✗ createAttribute failed:", e.message);
    print("  stack:", e.stack);
}
