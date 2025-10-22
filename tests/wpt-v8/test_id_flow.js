// Test to trace the ID flow

print("1. Create element");
const div = document.createElement("div");

print("2. Set ID via setAttribute");
div.setAttribute("id", "my-test-id");

print("3. Read ID back via .id property");
print("   div.id =", div.id);

print("4. Read ID back via getAttribute");
print("   div.getAttribute('id') =", div.getAttribute("id"));

print("5. Append to document");
document.appendChild(div);

print("6. Verify element is in tree via getElementsByTagName");
const divs = document.getElementsByTagName("div");
print("   getElementsByTagName('div').length =", divs.length);
if (divs.length > 0) {
    print("   divs[0].id =", divs[0].id);
    print("   divs[0] === div:", divs[0] === div);
}

print("7. Try getElementById");
const found = document.getElementById("my-test-id");
print("   getElementById result:", found);

print("Done");
