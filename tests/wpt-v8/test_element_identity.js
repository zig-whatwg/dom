// Check if the same element is being accessed

print("Creating element...");
const div = document.createElement("div");

print("Setting attribute via setAttribute...");
div.setAttribute("id", "test123");
div.setAttribute("data-test", "value123");

print("Reading via getAttribute:");
print("  id =", div.getAttribute("id"));
print("  data-test =", div.getAttribute("data-test"));

print("Reading via property:");
print("  div.id =", div.id);

print("Appending to document...");
document.appendChild(div);

print("After append, reading via getElementsByTagName:");
const divs = document.getElementsByTagName("div");
print("  divs.length =", divs.length);
if (divs.length > 0) {
    print("  divs[0] === div:", divs[0] === div);
    print("  divs[0].getAttribute('id') =", divs[0].getAttribute("id"));
    print("  divs[0].getAttribute('data-test') =", divs[0].getAttribute("data-test"));
    print("  divs[0].id =", divs[0].id);
}

print("Done");
