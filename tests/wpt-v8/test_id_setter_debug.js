// Minimal test to check if ID setter is called

print("Creating element...");
const div = document.createElement("div");

print("Setting ID via property assignment...");
div.id = "test123";

print("Reading ID back...");
const readId = div.id;
print("div.id =", readId);

print("Done");
