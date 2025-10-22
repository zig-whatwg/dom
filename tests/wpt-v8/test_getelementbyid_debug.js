// Debug getElementById more carefully

print("=== getElementById Debug ===\n");

// Test 1: Check if id is actually being set
const div = document.createElement("div");
print("1. Created div");
print("   div.id before:", div.id);

div.id = "test-id";
print("2. Set div.id = 'test-id'");
print("   div.id after:", div.id);

// Test 2: Check document state before appendChild
print("\n3. Before appendChild:");
const foundBefore = document.getElementById("test-id");
print("   getElementById('test-id'):", foundBefore);

// Test 3: Append to document
document.appendChild(div);
print("\n4. After appendChild:");

// Test 4: Try getElementById again
const foundAfter = document.getElementById("test-id");
print("   getElementById('test-id'):", foundAfter);
print("   foundAfter === null:", foundAfter === null);
print("   foundAfter === div:", foundAfter === div);

// Test 5: Try getElementsByTagName to see if element is in tree
print("\n5. Check getElementsByTagName:");
const divs = document.getElementsByTagName("div");
print("   divs.length:", divs.length);
if (divs.length > 0) {
    const firstDiv = divs[0];
    print("   divs[0]:", firstDiv);
    print("   divs[0] === div:", firstDiv === div);
    print("   divs[0].id:", firstDiv.id);
}

print("\n=== Debug Complete ===");
