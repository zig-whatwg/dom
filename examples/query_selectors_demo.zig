//! Query Selectors Demo - Comprehensive CSS Selector Examples
//! ===========================================================
//!
//! This demo showcases querySelector() and querySelectorAll()
//! on a complex, deeply nested DOM tree. It demonstrates:
//!
//! - Type selectors (element names)
//! - Class selectors
//! - ID selectors
//! - Descendant combinators
//! - Child combinators (>)
//! - Attribute selectors
//! - Multiple selectors (,)
//! - Complex nested queries
//!
//! ## CSS Selector Support Status
//!
//! **Working ✅:** Simple selectors (element, #id, .class, [attr])
//! **Not Working ❌:** Combinators (>, space), pseudo-classes, comma lists
//!
//! This demo shows both working and non-working selectors to illustrate
//! the current implementation limits. See test output for results.
//!
//! Build and run:
//!   zig build run-query-demo

const std = @import("std");
const dom = @import("dom");

const Document = dom.Document;
const Element = dom.Element;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n", .{});
    std.debug.print("╔════════════════════════════════════════════════════════════════╗\n", .{});
    std.debug.print("║     Query Selectors Demo - Complex DOM Tree                   ║\n", .{});
    std.debug.print("╚════════════════════════════════════════════════════════════════╝\n", .{});
    std.debug.print("\n", .{});

    // Create the document
    const doc = try Document.init(allocator);
    defer doc.release();

    // Build a complex nested DOM structure
    try buildComplexDOM(doc);

    // Print the DOM structure
    std.debug.print("📊 DOM Structure Built:\n", .{});
    std.debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});
    try printDOMTree(doc.node, 0);
    std.debug.print("\n", .{});

    // Run comprehensive query selector examples
    std.debug.print("🔍 Query Selector Examples:\n", .{});
    std.debug.print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n", .{});
    std.debug.print("\n", .{});

    try runQueryExamples(doc);

    std.debug.print("\n", .{});
    std.debug.print("✅ Demo completed successfully!\n", .{});
    std.debug.print("\n", .{});
}

/// Build a complex nested DOM structure resembling a real web page
fn buildComplexDOM(doc: *Document) !void {
    // Create HTML root
    const html = try doc.createElement("html");
    doc.document_element = html;
    _ = try doc.node.appendChild(html);

    // Create HEAD
    const head = try doc.createElement("head");
    _ = try html.appendChild(head);

    const title = try doc.createElement("title");
    _ = try head.appendChild(title);
    const title_text = try doc.createTextNode("Query Selector Demo");
    _ = try title.appendChild(title_text.character_data.node);

    // Create BODY
    const body = try doc.createElement("body");
    try Element.setAttribute(body, "class", "main-content");
    _ = try html.appendChild(body);

    // Create HEADER
    const header = try doc.createElement("header");
    try Element.setAttribute(header, "id", "site-header");
    try Element.setAttribute(header, "class", "header primary");
    _ = try body.appendChild(header);

    const nav = try doc.createElement("nav");
    try Element.setAttribute(nav, "class", "navigation");
    _ = try header.appendChild(nav);

    const nav_list = try doc.createElement("ul");
    try Element.setAttribute(nav_list, "class", "nav-list");
    _ = try nav.appendChild(nav_list);

    // Add nav items
    const nav_items = [_]struct { href: []const u8, text: []const u8, class: []const u8 }{
        .{ .href = "/home", .text = "Home", .class = "nav-item active" },
        .{ .href = "/about", .text = "About", .class = "nav-item" },
        .{ .href = "/products", .text = "Products", .class = "nav-item" },
        .{ .href = "/contact", .text = "Contact", .class = "nav-item" },
    };

    for (nav_items) |item| {
        const li = try doc.createElement("li");
        try Element.setAttribute(li, "class", item.class);
        _ = try nav_list.appendChild(li);

        const a = try doc.createElement("a");
        try Element.setAttribute(a, "href", item.href);
        try Element.setAttribute(a, "class", "nav-link");
        _ = try li.appendChild(a);

        const link_text = try doc.createTextNode(item.text);
        _ = try a.appendChild(link_text.character_data.node);
    }

    // Create MAIN content area
    const main_elem = try doc.createElement("main");
    try Element.setAttribute(main_elem, "id", "main-content");
    try Element.setAttribute(main_elem, "class", "content-area");
    _ = try body.appendChild(main_elem);

    // Create ARTICLE section
    const article = try doc.createElement("article");
    try Element.setAttribute(article, "id", "featured-article");
    try Element.setAttribute(article, "class", "article featured");
    try Element.setAttribute(article, "data-category", "technology");
    _ = try main_elem.appendChild(article);

    const article_header = try doc.createElement("header");
    try Element.setAttribute(article_header, "class", "article-header");
    _ = try article.appendChild(article_header);

    const h1 = try doc.createElement("h1");
    try Element.setAttribute(h1, "class", "article-title");
    _ = try article_header.appendChild(h1);
    const h1_text = try doc.createTextNode("Understanding Query Selectors");
    _ = try h1.appendChild(h1_text.character_data.node);

    const article_meta = try doc.createElement("div");
    try Element.setAttribute(article_meta, "class", "article-meta");
    _ = try article_header.appendChild(article_meta);

    const author = try doc.createElement("span");
    try Element.setAttribute(author, "class", "author");
    try Element.setAttribute(author, "data-author-id", "42");
    _ = try article_meta.appendChild(author);
    const author_text = try doc.createTextNode("Jane Doe");
    _ = try author.appendChild(author_text.character_data.node);

    const date = try doc.createElement("time");
    try Element.setAttribute(date, "class", "publish-date");
    try Element.setAttribute(date, "datetime", "2025-10-10");
    _ = try article_meta.appendChild(date);
    const date_text = try doc.createTextNode("October 10, 2025");
    _ = try date.appendChild(date_text.character_data.node);

    // Article content
    const article_body = try doc.createElement("div");
    try Element.setAttribute(article_body, "class", "article-body");
    _ = try article.appendChild(article_body);

    // Add paragraphs
    const paragraphs = [_]struct { class: []const u8, text: []const u8 }{
        .{ .class = "intro", .text = "This is an introduction to CSS query selectors." },
        .{ .class = "content", .text = "Query selectors allow you to find elements in the DOM." },
        .{ .class = "content highlight", .text = "They use CSS selector syntax for powerful matching." },
    };

    for (paragraphs) |para| {
        const p = try doc.createElement("p");
        try Element.setAttribute(p, "class", para.class);
        _ = try article_body.appendChild(p);
        const p_text = try doc.createTextNode(para.text);
        _ = try p.appendChild(p_text.character_data.node);
    }

    // Add code example
    const code_block = try doc.createElement("div");
    try Element.setAttribute(code_block, "class", "code-block");
    _ = try article_body.appendChild(code_block);

    const pre = try doc.createElement("pre");
    _ = try code_block.appendChild(pre);

    const code = try doc.createElement("code");
    try Element.setAttribute(code, "class", "language-css");
    try Element.setAttribute(code, "data-language", "css");
    _ = try pre.appendChild(code);
    const code_text = try doc.createTextNode(".class > element");
    _ = try code.appendChild(code_text.character_data.node);

    // Create SIDEBAR
    const aside = try doc.createElement("aside");
    try Element.setAttribute(aside, "id", "sidebar");
    try Element.setAttribute(aside, "class", "sidebar");
    _ = try main_elem.appendChild(aside);

    // Sidebar widgets
    const widgets = [_]struct { id: []const u8, title: []const u8, class: []const u8 }{
        .{ .id = "recent-posts", .title = "Recent Posts", .class = "widget posts" },
        .{ .id = "categories", .title = "Categories", .class = "widget categories" },
        .{ .id = "tags", .title = "Tags", .class = "widget tags" },
    };

    for (widgets) |widget| {
        const widget_div = try doc.createElement("div");
        try Element.setAttribute(widget_div, "id", widget.id);
        try Element.setAttribute(widget_div, "class", widget.class);
        _ = try aside.appendChild(widget_div);

        const widget_title = try doc.createElement("h3");
        try Element.setAttribute(widget_title, "class", "widget-title");
        _ = try widget_div.appendChild(widget_title);
        const widget_title_text = try doc.createTextNode(widget.title);
        _ = try widget_title.appendChild(widget_title_text.character_data.node);

        const widget_content = try doc.createElement("ul");
        try Element.setAttribute(widget_content, "class", "widget-content");
        _ = try widget_div.appendChild(widget_content);

        // Add some items
        var i: usize = 0;
        while (i < 3) : (i += 1) {
            const item = try doc.createElement("li");
            try Element.setAttribute(item, "class", "widget-item");
            _ = try widget_content.appendChild(item);
            const item_text = try doc.createTextNode("Item");
            _ = try item.appendChild(item_text.character_data.node);
        }
    }

    // Create FOOTER
    const footer = try doc.createElement("footer");
    try Element.setAttribute(footer, "id", "site-footer");
    try Element.setAttribute(footer, "class", "footer");
    _ = try body.appendChild(footer);

    const footer_content = try doc.createElement("div");
    try Element.setAttribute(footer_content, "class", "footer-content");
    _ = try footer.appendChild(footer_content);

    const copyright = try doc.createElement("p");
    try Element.setAttribute(copyright, "class", "copyright");
    _ = try footer_content.appendChild(copyright);
    const copy_text = try doc.createTextNode("© 2025 Query Selector Demo");
    _ = try copyright.appendChild(copy_text.character_data.node);

    const social = try doc.createElement("div");
    try Element.setAttribute(social, "class", "social-links");
    _ = try footer_content.appendChild(social);

    const social_platforms = [_]struct { href: []const u8, name: []const u8 }{
        .{ .href = "https://twitter.com", .name = "Twitter" },
        .{ .href = "https://github.com", .name = "GitHub" },
        .{ .href = "https://linkedin.com", .name = "LinkedIn" },
    };

    for (social_platforms) |platform| {
        const link = try doc.createElement("a");
        try Element.setAttribute(link, "href", platform.href);
        try Element.setAttribute(link, "class", "social-link");
        try Element.setAttribute(link, "target", "_blank");
        _ = try social.appendChild(link);
        const link_text = try doc.createTextNode(platform.name);
        _ = try link.appendChild(link_text.character_data.node);
    }
}

/// Run comprehensive query selector examples
fn runQueryExamples(doc: *Document) !void {
    const allocator = doc.allocator;

    // Example 1: Simple element selector
    {
        std.debug.print("1️⃣  querySelector('article')\n", .{});
        if (try Element.querySelector(doc.document_element.?, "article")) |result| {
            const id = Element.getAttribute(result, "id") orelse "(no id)";
            std.debug.print("   ✅ Found: <article id=\"{s}\">\n\n", .{id});
        }
    }

    // Example 2: ID selector
    {
        std.debug.print("2️⃣  querySelector('#site-header')\n", .{});
        if (try Element.querySelector(doc.document_element.?, "#site-header")) |result| {
            const class = Element.getAttribute(result, "class") orelse "(no class)";
            std.debug.print("   ✅ Found: <header class=\"{s}\">\n\n", .{class});
        }
    }

    // Example 3: Class selector
    {
        std.debug.print("3️⃣  querySelectorAll('.widget')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".widget");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} widgets:\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const id = Element.getAttribute(elem, "id") orelse "(no id)";
            std.debug.print("      {d}. <div id=\"{s}\">\n", .{ i + 1, id });
        }
        std.debug.print("\n", .{});
    }

    // Example 4: Descendant combinator
    {
        std.debug.print("4️⃣  querySelectorAll('nav a')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "nav a");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} navigation links:\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const href = Element.getAttribute(elem, "href") orelse "(no href)";
            std.debug.print("      {d}. <a href=\"{s}\">\n", .{ i + 1, href });
        }
        std.debug.print("\n", .{});
    }

    // Example 5: Child combinator
    {
        std.debug.print("5️⃣  querySelectorAll('article > header')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "article > header");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} article headers (direct children only)\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const class = Element.getAttribute(elem, "class") orelse "(no class)";
            std.debug.print("      {d}. <header class=\"{s}\">\n", .{ i + 1, class });
        }
        std.debug.print("\n", .{});
    }

    // Example 6: Multiple classes
    {
        std.debug.print("6️⃣  querySelectorAll('.nav-item.active')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".nav-item.active");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} active nav items\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const class = Element.getAttribute(elem, "class") orelse "(no class)";
            std.debug.print("      {d}. <li class=\"{s}\">\n", .{ i + 1, class });
        }
        std.debug.print("\n", .{});
    }

    // Example 7: Attribute selector
    {
        std.debug.print("7️⃣  querySelectorAll('[data-category]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[data-category]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} elements with data-category attribute:\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const category = Element.getAttribute(elem, "data-category") orelse "(none)";
            std.debug.print("      {d}. data-category=\"{s}\"\n", .{ i + 1, category });
        }
        std.debug.print("\n", .{});
    }

    // Example 8: Attribute value selector
    {
        std.debug.print("8️⃣  querySelectorAll('[data-category=\"technology\"]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[data-category=\"technology\"]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} technology articles\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const id = Element.getAttribute(elem, "id") orelse "(no id)";
            std.debug.print("      {d}. <article id=\"{s}\">\n", .{ i + 1, id });
        }
        std.debug.print("\n", .{});
    }

    // Example 9: Multiple selectors
    {
        std.debug.print("9️⃣  querySelectorAll('h1, h2, h3')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "h1, h2, h3");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} headings:\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            std.debug.print("      {d}. <{s}>\n", .{ i + 1, elem.node_name });
        }
        std.debug.print("\n", .{});
    }

    // Example 10: Complex nested selector
    {
        std.debug.print("🔟 querySelectorAll('.article .article-body p.highlight')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".article .article-body p.highlight");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} highlighted paragraphs in articles:\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const class = Element.getAttribute(elem, "class") orelse "(no class)";
            std.debug.print("      {d}. <p class=\"{s}\">\n", .{ i + 1, class });
        }
        std.debug.print("\n", .{});
    }

    // Example 11: Attribute contains
    {
        std.debug.print("1️⃣1️⃣  querySelectorAll('[href*=\"github\"]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[href*=\"github\"]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} GitHub links:\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const href = Element.getAttribute(elem, "href") orelse "(no href)";
            std.debug.print("      {d}. <a href=\"{s}\">\n", .{ i + 1, href });
        }
        std.debug.print("\n", .{});
    }

    // Example 12: Direct child with class
    {
        std.debug.print("1️⃣2️⃣  querySelectorAll('#sidebar > .widget')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "#sidebar > .widget");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} widgets (direct children of sidebar):\n", .{results.length()});
        for (results.items.items, 0..) |node, i| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const id = Element.getAttribute(elem, "id") orelse "(no id)";
            std.debug.print("      {d}. <div id=\"{s}\">\n", .{ i + 1, id });
        }
        std.debug.print("\n", .{});
    }
}

/// Print the DOM tree structure
fn printDOMTree(node: *dom.Node, depth: usize) !void {
    // Print indentation
    var i: usize = 0;
    while (i < depth) : (i += 1) {
        std.debug.print("  ", .{});
    }

    // Print node info
    if (node.node_type == .element_node) {
        const id = Element.getAttribute(node, "id");
        const class = Element.getAttribute(node, "class");

        std.debug.print("<{s}", .{node.node_name});
        if (id) |id_val| {
            std.debug.print(" id=\"{s}\"", .{id_val});
        }
        if (class) |class_val| {
            std.debug.print(" class=\"{s}\"", .{class_val});
        }
        std.debug.print(">\n", .{});
    } else if (node.node_type == .text_node) {
        // Don't print empty text nodes (whitespace)
        return;
    } else {
        std.debug.print("{s}\n", .{node.node_name});
    }

    // Recurse into children
    var child = dom.Node.firstChild(node);
    while (child) |c| {
        try printDOMTree(c, depth + 1);
        child = dom.Node.nextSibling(c);
    }
}
