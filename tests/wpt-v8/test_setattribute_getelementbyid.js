// Test getElementById using setAttribute (not property assignment)

print("Creating element...");
const div = document.createElement("div");

print("Setting ID via setAttribute...");
div.setAttribute("id", "my-test-id");

print("Checking attribute was set:");
print("  getAttribute('id'):", div.getAttribute("id"));
print("  div.id property:", div.id);

print("Appending to document...");
document.appendChild(div);

print("Calling getElementById...");
const found = document.getElementById("my-test-id");

print("Result:", found);
print("found === div:", found === div);
print("found === null:", found === null);

if (found) {
    print("SUCCESS: getElementById found the element!");
} else {
    print("FAIL: getElementById returned null");
}
