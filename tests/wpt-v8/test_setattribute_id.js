// Test using setAttribute("id", ...) instead of direct property assignment

print("Creating element...");
const div = document.createElement("div");

print("Setting ID via setAttribute...");
div.setAttribute("id", "test-via-setattr");

print("Appending to document...");
document.appendChild(div);

print("Trying getElementById...");
const found = document.getElementById("test-via-setattr");
print("getElementById result:", found);
print("found === div:", found === div);

print("Done");
