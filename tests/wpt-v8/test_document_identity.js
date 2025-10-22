// Test if document object maintains identity

print("=== Document Identity Test ===\n");

// Access document multiple times
const doc1 = document;
const doc2 = document;
const doc3 = document;

print("1. Document identity:");
print("   doc1 === doc2:", doc1 === doc2);
print("   doc2 === doc3:", doc2 === doc3);
print("   doc1 === doc3:", doc1 === doc3);

// Create element and check owner document
const div = document.createElement("div");
print("\n2. Element's owner document:");
// Note: ownerDocument might not be exposed yet
print("   typeof div:", typeof div);

// Append and check
document.appendChild(div);
div.id = "test";

// Get from different document references
const found1 = doc1.getElementById("test");
const found2 = doc2.getElementById("test");
const found3 = document.getElementById("test");

print("\n3. getElementById from different references:");
print("   doc1.getElementById('test'):", found1);
print("   doc2.getElementById('test'):", found2);
print("   document.getElementById('test'):", found3);
print("   found1 === found2:", found1 === found2);
print("   found2 === found3:", found2 === found3);

print("\n=== Test Complete ===");
