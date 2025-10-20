// META: title=Test for Element.closest

const std = @import("std");
const dom = @import("dom");
const Document = dom.Document;
const Element = dom.Element;

test "Element.closest with type selector 'select'" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    // Build structure: container1 > container2 > container3 > form2, form1 > input1, fieldset1 > select1 > option1, option2, option3, option4, input2
    const container1 = try doc.createElement("container1");
    _ = try doc.prototype.appendChild(&container1.prototype);

    const container2 = try doc.createElement("container2");
    _ = try container1.prototype.appendChild(&container2.prototype);

    const container3 = try doc.createElement("container3");
    _ = try container2.prototype.appendChild(&container3.prototype);

    const form2 = try doc.createElement("form");
    try form2.setAttribute("id", "form2");
    try form2.setAttribute("class", "form-cls2");
    _ = try container3.prototype.appendChild(&form2.prototype);

    const form1 = try doc.createElement("form");
    try form1.setAttribute("id", "form1");
    try form1.setAttribute("class", "form-cls1");
    try form1.setAttribute("name", "form-a");
    _ = try container3.prototype.appendChild(&form1.prototype);

    const input1 = try doc.createElement("input");
    try input1.setAttribute("id", "input1");
    try input1.setAttribute("class", "input-cls1");
    try input1.setAttribute("required", "");
    _ = try form1.prototype.appendChild(&input1.prototype);

    const fieldset1 = try doc.createElement("fieldset");
    try fieldset1.setAttribute("id", "fieldset1");
    try fieldset1.setAttribute("class", "fieldset-cls2");
    _ = try form1.prototype.appendChild(&fieldset1.prototype);

    const select1 = try doc.createElement("select");
    try select1.setAttribute("id", "select1");
    try select1.setAttribute("class", "select-cls1");
    try select1.setAttribute("required", "");
    _ = try fieldset1.prototype.appendChild(&select1.prototype);

    const option1 = try doc.createElement("option");
    try option1.setAttribute("id", "option1");
    try option1.setAttribute("default", "");
    try option1.setAttribute("value", "");
    _ = try select1.prototype.appendChild(&option1.prototype);

    const option2 = try doc.createElement("option");
    try option2.setAttribute("id", "option2");
    try option2.setAttribute("selected", "");
    _ = try select1.prototype.appendChild(&option2.prototype);

    const option3 = try doc.createElement("option");
    try option3.setAttribute("id", "option3");
    _ = try select1.prototype.appendChild(&option3.prototype);

    const option4 = try doc.createElement("option");
    try option4.setAttribute("id", "option4");
    _ = try select1.prototype.appendChild(&option4.prototype);

    const input2 = try doc.createElement("input");
    try input2.setAttribute("id", "input2");
    try input2.setAttribute("type", "text");
    try input2.setAttribute("required", "");
    _ = try fieldset1.prototype.appendChild(&input2.prototype);

    // Test: select from option3
    const result = try option3.closest(allocator, "select");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("select1", result.?.getAttribute("id").?);
}

test "Element.closest with type selector 'fieldset'" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const form1 = try doc.createElement("form");
    _ = try container.prototype.appendChild(&form1.prototype);

    const fieldset1 = try doc.createElement("fieldset");
    try fieldset1.setAttribute("id", "fieldset1");
    _ = try form1.prototype.appendChild(&fieldset1.prototype);

    const select1 = try doc.createElement("select");
    _ = try fieldset1.prototype.appendChild(&select1.prototype);

    const option1 = try doc.createElement("option");
    try option1.setAttribute("id", "option1");
    _ = try select1.prototype.appendChild(&option1.prototype);

    const result = try option1.closest(allocator, "fieldset");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("fieldset1", result.?.getAttribute("id").?);
}

test "Element.closest with type selector 'container1'" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container1 = try doc.createElement("container1");
    try container1.setAttribute("id", "outer");
    _ = try doc.prototype.appendChild(&container1.prototype);

    const container2 = try doc.createElement("container2");
    _ = try container1.prototype.appendChild(&container2.prototype);

    const container3 = try doc.createElement("container3");
    _ = try container2.prototype.appendChild(&container3.prototype);

    const item = try doc.createElement("item");
    try item.setAttribute("id", "item1");
    _ = try container3.prototype.appendChild(&item.prototype);

    const result = try item.closest(allocator, "container1");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("outer", result.?.getAttribute("id").?);
}

test "Element.closest with attribute selector [default]" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const option1 = try doc.createElement("option");
    try option1.setAttribute("id", "option1");
    try option1.setAttribute("default", "");
    _ = try container.prototype.appendChild(&option1.prototype);

    const result = try option1.closest(allocator, "[default]");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("option1", result.?.getAttribute("id").?);
}

test "Element.closest with attribute selector [selected] - no match" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const option1 = try doc.createElement("option");
    try option1.setAttribute("id", "option1");
    try option1.setAttribute("default", "");
    _ = try container.prototype.appendChild(&option1.prototype);

    const result = try option1.closest(allocator, "[selected]");
    try std.testing.expect(result == null);
}

test "Element.closest with attribute selector [selected] - match" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const option1 = try doc.createElement("option");
    try option1.setAttribute("id", "option1");
    try option1.setAttribute("selected", "");
    _ = try container.prototype.appendChild(&option1.prototype);

    const result = try option1.closest(allocator, "[selected]");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("option1", result.?.getAttribute("id").?);
}

test "Element.closest with attribute selector [name=\"form-a\"]" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const form1 = try doc.createElement("form");
    try form1.setAttribute("id", "form1");
    try form1.setAttribute("name", "form-a");
    _ = try doc.prototype.appendChild(&form1.prototype);

    const item = try doc.createElement("item");
    try item.setAttribute("id", "item1");
    _ = try form1.prototype.appendChild(&item.prototype);

    const result = try item.closest(allocator, "[name=\"form-a\"]");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("form1", result.?.getAttribute("id").?);
}

test "Element.closest with compound selector form[name=\"form-a\"]" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const form1 = try doc.createElement("form");
    try form1.setAttribute("id", "form1");
    try form1.setAttribute("name", "form-a");
    _ = try doc.prototype.appendChild(&form1.prototype);

    const item = try doc.createElement("item");
    try item.setAttribute("id", "item1");
    _ = try form1.prototype.appendChild(&item.prototype);

    const result = try item.closest(allocator, "form[name=\"form-a\"]");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("form1", result.?.getAttribute("id").?);
}

test "Element.closest with compound selector input[required]" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const form1 = try doc.createElement("form");
    _ = try doc.prototype.appendChild(&form1.prototype);

    const input1 = try doc.createElement("input");
    try input1.setAttribute("id", "input1");
    try input1.setAttribute("required", "");
    _ = try form1.prototype.appendChild(&input1.prototype);

    const result = try input1.closest(allocator, "input[required]");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("input1", result.?.getAttribute("id").?);
}

test "Element.closest with compound selector select[required] - no match" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const form1 = try doc.createElement("form");
    _ = try doc.prototype.appendChild(&form1.prototype);

    const input1 = try doc.createElement("input");
    try input1.setAttribute("id", "input1");
    try input1.setAttribute("required", "");
    _ = try form1.prototype.appendChild(&input1.prototype);

    const result = try input1.closest(allocator, "select[required]");
    try std.testing.expect(result == null);
}

test "Element.closest with :not() pseudo-class" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container1 = try doc.createElement("container");
    try container1.setAttribute("class", "cls3");
    _ = try doc.prototype.appendChild(&container1.prototype);

    const container2 = try doc.createElement("container");
    try container2.setAttribute("id", "container2");
    try container2.setAttribute("class", "cls2");
    _ = try container1.prototype.appendChild(&container2.prototype);

    const container3 = try doc.createElement("container");
    try container3.setAttribute("class", "cls1");
    _ = try container2.prototype.appendChild(&container3.prototype);

    const item = try doc.createElement("item");
    _ = try container3.prototype.appendChild(&item.prototype);

    const result = try item.closest(allocator, "container:not(.cls1)");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("container2", result.?.getAttribute("id").?);
}

test "Element.closest with class selector .cls3" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container1 = try doc.createElement("container");
    try container1.setAttribute("id", "container1");
    try container1.setAttribute("class", "cls3");
    _ = try doc.prototype.appendChild(&container1.prototype);

    const container2 = try doc.createElement("container");
    try container2.setAttribute("class", "cls2");
    _ = try container1.prototype.appendChild(&container2.prototype);

    const container3 = try doc.createElement("container");
    try container3.setAttribute("class", "cls1");
    _ = try container2.prototype.appendChild(&container3.prototype);

    const result = try container3.closest(allocator, "container.cls3");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("container1", result.?.getAttribute("id").?);
}

test "Element.closest with ID selector container#container2" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container1 = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container1.prototype);

    const container2 = try doc.createElement("container");
    try container2.setAttribute("id", "container2");
    _ = try container1.prototype.appendChild(&container2.prototype);

    const container3 = try doc.createElement("container");
    _ = try container2.prototype.appendChild(&container3.prototype);

    const input1 = try doc.createElement("input");
    _ = try container3.prototype.appendChild(&input1.prototype);

    const result = try input1.closest(allocator, "container#container2");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("container2", result.?.getAttribute("id").?);
}

test "Element.closest with child combinator .cls3 > .cls2" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container1 = try doc.createElement("container");
    try container1.setAttribute("class", "cls3");
    _ = try doc.prototype.appendChild(&container1.prototype);

    const container2 = try doc.createElement("container");
    try container2.setAttribute("id", "container2");
    try container2.setAttribute("class", "cls2");
    _ = try container1.prototype.appendChild(&container2.prototype);

    const container3 = try doc.createElement("container");
    try container3.setAttribute("class", "cls1");
    _ = try container2.prototype.appendChild(&container3.prototype);

    const item = try doc.createElement("item");
    _ = try container3.prototype.appendChild(&item.prototype);

    const result = try item.closest(allocator, ".cls3 > .cls2");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("container2", result.?.getAttribute("id").?);
}

test "Element.closest with child combinator .cls3 > .cls1 - no match" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container1 = try doc.createElement("container");
    try container1.setAttribute("class", "cls3");
    _ = try doc.prototype.appendChild(&container1.prototype);

    const container2 = try doc.createElement("container");
    try container2.setAttribute("class", "cls2");
    _ = try container1.prototype.appendChild(&container2.prototype);

    const container3 = try doc.createElement("container");
    try container3.setAttribute("class", "cls1");
    _ = try container2.prototype.appendChild(&container3.prototype);

    const item = try doc.createElement("item");
    _ = try container3.prototype.appendChild(&item.prototype);

    const result = try item.closest(allocator, ".cls3 > .cls1");
    try std.testing.expect(result == null);
}

test "Element.closest with child combinator form > input[required] - no match" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const form1 = try doc.createElement("form");
    _ = try doc.prototype.appendChild(&form1.prototype);

    const fieldset1 = try doc.createElement("fieldset");
    _ = try form1.prototype.appendChild(&fieldset1.prototype);

    const input1 = try doc.createElement("input");
    try input1.setAttribute("required", "");
    _ = try fieldset1.prototype.appendChild(&input1.prototype);

    const result = try input1.closest(allocator, "form > input[required]");
    try std.testing.expect(result == null);
}

test "Element.closest with child combinator fieldset > select[required]" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fieldset1 = try doc.createElement("fieldset");
    _ = try doc.prototype.appendChild(&fieldset1.prototype);

    const select1 = try doc.createElement("select");
    try select1.setAttribute("id", "select1");
    try select1.setAttribute("required", "");
    _ = try fieldset1.prototype.appendChild(&select1.prototype);

    const option1 = try doc.createElement("option");
    _ = try select1.prototype.appendChild(&option1.prototype);

    const result = try option1.closest(allocator, "fieldset > select[required]");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("select1", result.?.getAttribute("id").?);
}

test "Element.closest with adjacent sibling combinator input + fieldset - no match" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const input1 = try doc.createElement("input");
    _ = try container.prototype.appendChild(&input1.prototype);

    const fieldset1 = try doc.createElement("fieldset");
    _ = try container.prototype.appendChild(&fieldset1.prototype);

    const item = try doc.createElement("item");
    _ = try container.prototype.appendChild(&item.prototype);

    const result = try item.closest(allocator, "input + fieldset");
    try std.testing.expect(result == null);
}

test "Element.closest with adjacent sibling combinator form + form - from option" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const form1 = try doc.createElement("form");
    _ = try container.prototype.appendChild(&form1.prototype);

    const form2 = try doc.createElement("form");
    try form2.setAttribute("id", "form2");
    _ = try container.prototype.appendChild(&form2.prototype);

    const select1 = try doc.createElement("select");
    _ = try form2.prototype.appendChild(&select1.prototype);

    const option1 = try doc.createElement("option");
    _ = try select1.prototype.appendChild(&option1.prototype);

    const result = try option1.closest(allocator, "form + form");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("form2", result.?.getAttribute("id").?);
}

test "Element.closest with adjacent sibling combinator form + form - from form" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const form1 = try doc.createElement("form");
    _ = try container.prototype.appendChild(&form1.prototype);

    const form2 = try doc.createElement("form");
    try form2.setAttribute("id", "form2");
    _ = try container.prototype.appendChild(&form2.prototype);

    const result = try form2.closest(allocator, "form + form");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("form2", result.?.getAttribute("id").?);
}

test "Element.closest with :empty pseudo-class" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const container = try doc.createElement("container");
    _ = try doc.prototype.appendChild(&container.prototype);

    const form1 = try doc.createElement("form");
    try form1.setAttribute("id", "form1");
    _ = try container.prototype.appendChild(&form1.prototype);

    const result = try form1.closest(allocator, ":empty");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("form1", result.?.getAttribute("id").?);
}

test "Element.closest with :last-child pseudo-class" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fieldset1 = try doc.createElement("fieldset");
    try fieldset1.setAttribute("id", "fieldset1");
    _ = try doc.prototype.appendChild(&fieldset1.prototype);

    const select1 = try doc.createElement("select");
    try select1.setAttribute("id", "select1");
    _ = try fieldset1.prototype.appendChild(&select1.prototype);

    const option1 = try doc.createElement("option");
    _ = try select1.prototype.appendChild(&option1.prototype);

    const option2 = try doc.createElement("option");
    try option2.setAttribute("id", "option2");
    _ = try select1.prototype.appendChild(&option2.prototype);

    // option2 itself is :last-child of select1, so should match itself
    const result = try option2.closest(allocator, ":last-child");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("option2", result.?.getAttribute("id").?);
}

test "Element.closest with :first-child pseudo-class" {
    const allocator = std.testing.allocator;
    const doc = try Document.init(allocator);
    defer doc.release();

    const fieldset1 = try doc.createElement("fieldset");
    _ = try doc.prototype.appendChild(&fieldset1.prototype);

    const select1 = try doc.createElement("select");
    try select1.setAttribute("id", "select1");
    _ = try fieldset1.prototype.appendChild(&select1.prototype);

    const option1 = try doc.createElement("option");
    try option1.setAttribute("id", "option1");
    _ = try select1.prototype.appendChild(&option1.prototype);

    const option2 = try doc.createElement("option");
    _ = try select1.prototype.appendChild(&option2.prototype);

    // option1 itself is :first-child of select1, so should match itself
    const result = try option1.closest(allocator, ":first-child");
    try std.testing.expect(result != null);
    try std.testing.expectEqualStrings("option1", result.?.getAttribute("id").?);
}

// TODO: Implement :scope pseudo-class support
// test "Element.closest with :scope pseudo-class" {
//     const allocator = std.testing.allocator;
//     const doc = try Document.init(allocator);
//     defer doc.release();
//
//     const container = try doc.createElement("container");
//     _ = try doc.prototype.appendChild(&container.prototype);
//
//     const option1 = try doc.createElement("option");
//     try option1.setAttribute("id", "option1");
//     _ = try container.prototype.appendChild(&option1.prototype);
//
//     const result = try option1.closest(allocator, ":scope");
//     try std.testing.expect(result != null);
//     try std.testing.expectEqualStrings("option1", result.?.getAttribute("id").?);
// }

// TODO: Implement :scope pseudo-class support
// test "Element.closest with select > :scope" {
//     const allocator = std.testing.allocator;
//     const doc = try Document.init(allocator);
//     defer doc.release();
//
//     const select1 = try doc.createElement("select");
//     _ = try doc.prototype.appendChild(&select1.prototype);
//
//     const option1 = try doc.createElement("option");
//     try option1.setAttribute("id", "option1");
//     _ = try select1.prototype.appendChild(&option1.prototype);
//
//     const result = try option1.closest(allocator, "select > :scope");
//     try std.testing.expect(result != null);
//     try std.testing.expectEqualStrings("option1", result.?.getAttribute("id").?);
// }

// TODO: Implement :scope pseudo-class support
// test "Element.closest with container > :scope - no match" {
//     const allocator = std.testing.allocator;
//     const doc = try Document.init(allocator);
//     defer doc.release();
//
//     const select1 = try doc.createElement("select");
//     _ = try doc.prototype.appendChild(&select1.prototype);
//
//     const option1 = try doc.createElement("option");
//     try option1.setAttribute("id", "option1");
//     _ = try select1.prototype.appendChild(&option1.prototype);
//
//     const result = try option1.closest(allocator, "container > :scope");
//     try std.testing.expect(result == null);
// }

// TODO: Implement :has() pseudo-class support
// test "Element.closest with :has(> :scope)" {
//     const allocator = std.testing.allocator;
//     const doc = try Document.init(allocator);
//     defer doc.release();
//
//     const select1 = try doc.createElement("select");
//     try select1.setAttribute("id", "select1");
//     _ = try doc.prototype.appendChild(&select1.prototype);
//
//     const option1 = try doc.createElement("option");
//     _ = try select1.prototype.appendChild(&option1.prototype);
//
//     const result = try option1.closest(allocator, ":has(> :scope)");
//     try std.testing.expect(result != null);
//     try std.testing.expectEqualStrings("select1", result.?.getAttribute("id").?);
// }
