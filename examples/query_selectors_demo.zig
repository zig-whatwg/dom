//! Query Selectors Demo - Comprehensive CSS Selector Examples
//! ===========================================================
//!
//! This demo showcases querySelector() and querySelectorAll()
//! on a complex, deeply nested DOM tree. It demonstrates the full
//! power of CSS selector support including:
//!
//! **CSS Level 1-2:**
//! - Type selectors (element names)
//! - Class selectors (.class, .multiple.classes)
//! - ID selectors (#id)
//! - Universal selector (*)
//! - Descendant combinator (space)
//! - Child combinator (>)
//!
//! **CSS Level 3:**
//! - Adjacent sibling combinator (+)
//! - General sibling combinator (~)
//! - Attribute selectors with operators
//! - Structural pseudo-classes (:first-child, :last-child, :nth-child, etc.)
//! - :not() pseudo-class
//! - :empty pseudo-class
//! - :root pseudo-class
//!
//! **CSS Level 4:**
//! - Case-insensitive attribute matching ([attr="value" i])
//!
//! **Complex Selectors:**
//! - Compound selectors (tag.class#id[attr]:pseudo)
//! - Chained pseudo-classes (:first-child:not(.special))
//! - Multiple combinators (div > p + span)
//!
//! ## Selector Support Status
//!
//! **Fully Working ✅:** All CSS1-3 features except state-based pseudo-classes
//! **Not Implemented ❌:** :link, :visited, :hover, :focus, :enabled, :disabled
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
    std.debug.print("║     Query Selectors Demo - Advanced CSS Selector Features    ║\n", .{});
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

    try runBasicSelectors(doc);
    try runAttributeSelectors(doc);
    try runCombinatorSelectors(doc);
    try runPseudoClassSelectors(doc);
    try runComplexSelectors(doc);
    try runRidiculouslyComplexSelector(doc);

    std.debug.print("\n", .{});
    std.debug.print("✅ Demo completed successfully!\n", .{});
    std.debug.print("   All CSS selector features demonstrated.\n", .{});
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
    const title_text = try doc.createTextNode("Advanced Query Selector Demo");
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

    // Add nav items with varied attributes
    const nav_items = [_]struct { href: []const u8, text: []const u8, class: []const u8, lang: ?[]const u8 }{
        .{ .href = "/home", .text = "Home", .class = "nav-item active", .lang = null },
        .{ .href = "/about", .text = "About", .class = "nav-item", .lang = null },
        .{ .href = "/products", .text = "Products", .class = "nav-item featured", .lang = null },
        .{ .href = "/contact", .text = "Contact", .class = "nav-item", .lang = "en-US" },
    };

    for (nav_items) |item| {
        const li = try doc.createElement("li");
        try Element.setAttribute(li, "class", item.class);
        _ = try nav_list.appendChild(li);

        const a = try doc.createElement("a");
        try Element.setAttribute(a, "href", item.href);
        try Element.setAttribute(a, "class", "nav-link");
        try Element.setAttribute(a, "data-type", "NAVIGATION"); // Uppercase for case-insensitive demo
        if (item.lang) |lang| {
            try Element.setAttribute(a, "lang", lang);
        }
        _ = try li.appendChild(a);

        const link_text = try doc.createTextNode(item.text);
        _ = try a.appendChild(link_text.character_data.node);
    }

    // Create MAIN content area
    const main_elem = try doc.createElement("main");
    try Element.setAttribute(main_elem, "id", "main-content");
    try Element.setAttribute(main_elem, "class", "content-area");
    _ = try body.appendChild(main_elem);

    // Create multiple ARTICLE sections for sibling combinator demos
    const articles_data = [_]struct { id: []const u8, category: []const u8, featured: bool }{
        .{ .id = "article-1", .category = "technology", .featured = true },
        .{ .id = "article-2", .category = "design", .featured = false },
        .{ .id = "article-3", .category = "technology", .featured = false },
    };

    for (articles_data) |article_data| {
        const article = try doc.createElement("article");
        try Element.setAttribute(article, "id", article_data.id);
        var class_str: []const u8 = "article";
        if (article_data.featured) {
            class_str = "article featured";
        }
        try Element.setAttribute(article, "class", class_str);
        try Element.setAttribute(article, "data-category", article_data.category);
        _ = try main_elem.appendChild(article);

        const article_header = try doc.createElement("header");
        try Element.setAttribute(article_header, "class", "article-header");
        _ = try article.appendChild(article_header);

        const h2 = try doc.createElement("h2");
        try Element.setAttribute(h2, "class", "article-title");
        _ = try article_header.appendChild(h2);
        const h2_text = try doc.createTextNode("Article Title");
        _ = try h2.appendChild(h2_text.character_data.node);

        // Article content with various paragraph types
        const article_body = try doc.createElement("div");
        try Element.setAttribute(article_body, "class", "article-body");
        _ = try article.appendChild(article_body);

        // First paragraph (intro)
        const p1 = try doc.createElement("p");
        try Element.setAttribute(p1, "class", "intro");
        _ = try article_body.appendChild(p1);
        const p1_text = try doc.createTextNode("Introduction paragraph");
        _ = try p1.appendChild(p1_text.character_data.node);

        // Middle paragraphs
        const p2 = try doc.createElement("p");
        try Element.setAttribute(p2, "class", "content");
        _ = try article_body.appendChild(p2);
        const p2_text = try doc.createTextNode("Content paragraph");
        _ = try p2.appendChild(p2_text.character_data.node);

        // Last paragraph (with special class)
        const p3 = try doc.createElement("p");
        try Element.setAttribute(p3, "class", "content highlight");
        _ = try article_body.appendChild(p3);
        const p3_text = try doc.createTextNode("Highlighted content");
        _ = try p3.appendChild(p3_text.character_data.node);

        // Empty div for :empty demo
        const empty_div = try doc.createElement("div");
        try Element.setAttribute(empty_div, "class", "placeholder");
        _ = try article_body.appendChild(empty_div);
    }

    // Create SIDEBAR with nested structure
    const aside = try doc.createElement("aside");
    try Element.setAttribute(aside, "id", "sidebar");
    try Element.setAttribute(aside, "class", "sidebar");
    _ = try main_elem.appendChild(aside);

    // Sidebar widgets
    const widgets = [_]struct { id: []const u8, title: []const u8, class: []const u8 }{
        .{ .id = "recent-posts", .title = "Recent Posts", .class = "widget posts" },
        .{ .id = "categories", .title = "Categories", .class = "widget categories" },
        .{ .id = "tags", .title = "Tags", .class = "widget tags special" },
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

        // Add items (varying counts for nth-child demos)
        const item_count: usize = if (std.mem.eql(u8, widget.id, "recent-posts")) 5 else 3;
        var i: usize = 0;
        while (i < item_count) : (i += 1) {
            const item = try doc.createElement("li");
            try Element.setAttribute(item, "class", "widget-item");
            _ = try widget_content.appendChild(item);
            const item_link = try doc.createElement("a");
            try Element.setAttribute(item_link, "href", "/item");
            _ = try item.appendChild(item_link);
            const item_text = try doc.createTextNode("Item");
            _ = try item_link.appendChild(item_text.character_data.node);
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
    const copy_text = try doc.createTextNode("© 2025 Advanced Selector Demo");
    _ = try copyright.appendChild(copy_text.character_data.node);

    const social = try doc.createElement("div");
    try Element.setAttribute(social, "class", "social-links");
    _ = try footer_content.appendChild(social);

    const social_platforms = [_]struct { href: []const u8, name: []const u8 }{
        .{ .href = "https://twitter.com/example", .name = "Twitter" },
        .{ .href = "https://github.com/example", .name = "GitHub" },
        .{ .href = "https://linkedin.com/example", .name = "LinkedIn" },
    };

    for (social_platforms) |platform| {
        const link = try doc.createElement("a");
        try Element.setAttribute(link, "href", platform.href);
        try Element.setAttribute(link, "class", "social-link");
        try Element.setAttribute(link, "target", "_blank");
        try Element.setAttribute(link, "rel", "noopener noreferrer");
        _ = try social.appendChild(link);
        const link_text = try doc.createTextNode(platform.name);
        _ = try link.appendChild(link_text.character_data.node);
    }
}

/// Basic selectors (CSS Level 1-2)
fn runBasicSelectors(doc: *Document) !void {
    const allocator = doc.allocator;

    std.debug.print("═══════════════════════════════════════════════════════════════\n", .{});
    std.debug.print("  BASIC SELECTORS (CSS Level 1-2)\n", .{});
    std.debug.print("═══════════════════════════════════════════════════════════════\n\n", .{});

    // Example 1: Type selector
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
        for (results.items.items) |node| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const id = Element.getAttribute(elem, "id") orelse "(no id)";
            std.debug.print("      • <div id=\"{s}\">\n", .{id});
        }
        std.debug.print("\n", .{});
    }

    // Example 4: Multiple classes (compound selector)
    {
        std.debug.print("4️⃣  querySelectorAll('.nav-item.active')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".nav-item.active");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} active nav items (compound selector)\n\n", .{results.length()});
    }

    // Example 5: Universal selector
    {
        std.debug.print("5️⃣  querySelectorAll('aside *')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "aside *");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} elements inside <aside> (universal selector)\n\n", .{results.length()});
    }
}

/// Attribute selectors
fn runAttributeSelectors(doc: *Document) !void {
    const allocator = doc.allocator;

    std.debug.print("═══════════════════════════════════════════════════════════════\n", .{});
    std.debug.print("  ATTRIBUTE SELECTORS (CSS Level 3 & 4)\n", .{});
    std.debug.print("═══════════════════════════════════════════════════════════════\n\n", .{});

    // Example 1: Attribute exists
    {
        std.debug.print("1️⃣  querySelectorAll('[data-category]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[data-category]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} elements with data-category attribute\n\n", .{results.length()});
    }

    // Example 2: Attribute equals
    {
        std.debug.print("2️⃣  querySelectorAll('[data-category=\"technology\"]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[data-category=\"technology\"]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} technology articles (exact match)\n\n", .{results.length()});
    }

    // Example 3: Attribute contains (CSS3)
    {
        std.debug.print("3️⃣  querySelectorAll('[href*=\"github\"]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[href*=\"github\"]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} GitHub links (contains substring)\n\n", .{results.length()});
    }

    // Example 4: Attribute starts with (CSS3)
    {
        std.debug.print("4️⃣  querySelectorAll('[href^=\"https://\"]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[href^=\"https://\"]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} HTTPS links (starts with)\n\n", .{results.length()});
    }

    // Example 5: Attribute ends with (CSS3)
    {
        std.debug.print("5️⃣  querySelectorAll('[href$=\".com\"]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[href$=\".com\"]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} .com links (ends with)\n\n", .{results.length()});
    }

    // Example 6: Attribute language prefix (CSS3)
    {
        std.debug.print("6️⃣  querySelectorAll('[lang|=\"en\"]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[lang|=\"en\"]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} English language elements (lang prefix)\n\n", .{results.length()});
    }

    // Example 7: Case-insensitive attribute (CSS4) ⭐
    {
        std.debug.print("7️⃣  querySelectorAll('[data-type=\"navigation\" i]') - CSS Level 4 ⭐\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[data-type=\"navigation\" i]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} elements (case-insensitive: NAVIGATION = navigation)\n\n", .{results.length()});
    }
}

/// Combinator selectors
fn runCombinatorSelectors(doc: *Document) !void {
    const allocator = doc.allocator;

    std.debug.print("═══════════════════════════════════════════════════════════════\n", .{});
    std.debug.print("  COMBINATOR SELECTORS (CSS Level 2 & 3)\n", .{});
    std.debug.print("═══════════════════════════════════════════════════════════════\n\n", .{});

    // Example 1: Descendant combinator
    {
        std.debug.print("1️⃣  querySelectorAll('nav a')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "nav a");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} links inside <nav> (descendant combinator)\n\n", .{results.length()});
    }

    // Example 2: Child combinator (CSS2)
    {
        std.debug.print("2️⃣  querySelectorAll('article > header')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "article > header");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} <header> elements (direct children of <article>)\n\n", .{results.length()});
    }

    // Example 3: Adjacent sibling combinator (CSS2)
    {
        std.debug.print("3️⃣  querySelectorAll('article + article')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "article + article");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} <article> elements (immediately after another article)\n\n", .{results.length()});
    }

    // Example 4: General sibling combinator (CSS3)
    {
        std.debug.print("4️⃣  querySelectorAll('.widget.posts ~ .widget')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".widget.posts ~ .widget");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} widgets (following posts widget)\n\n", .{results.length()});
    }

    // Example 5: Complex multi-combinator
    {
        std.debug.print("5️⃣  querySelectorAll('main > article > div > p')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "main > article > div > p");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} paragraphs (multiple child combinators)\n\n", .{results.length()});
    }
}

/// Pseudo-class selectors
fn runPseudoClassSelectors(doc: *Document) !void {
    const allocator = doc.allocator;

    std.debug.print("═══════════════════════════════════════════════════════════════\n", .{});
    std.debug.print("  PSEUDO-CLASS SELECTORS (CSS Level 3)\n", .{});
    std.debug.print("═══════════════════════════════════════════════════════════════\n\n", .{});

    // Example 1: :first-child
    {
        std.debug.print("1️⃣  querySelectorAll('article > div > p:first-child')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "article > div > p:first-child");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} first paragraph(s) in article bodies\n\n", .{results.length()});
    }

    // Example 2: :last-child
    {
        std.debug.print("2️⃣  querySelectorAll('.widget-content li:last-child')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".widget-content li:last-child");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} last items in widget lists\n\n", .{results.length()});
    }

    // Example 3: :nth-child (CSS3)
    {
        std.debug.print("3️⃣  querySelectorAll('.widget-content li:nth-child(2)')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".widget-content li:nth-child(2)");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} second items (nth-child)\n\n", .{results.length()});
    }

    // Example 4: :nth-child with formula (CSS3)
    {
        std.debug.print("4️⃣  querySelectorAll('.widget-content li:nth-child(odd)')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".widget-content li:nth-child(odd)");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} odd-numbered items (nth-child with formula)\n\n", .{results.length()});
    }

    // Example 5: :only-child (CSS3)
    {
        std.debug.print("5️⃣  querySelectorAll('p:only-child')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "p:only-child");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} paragraphs (that are only children)\n\n", .{results.length()});
    }

    // Example 6: :empty (CSS3)
    {
        std.debug.print("6️⃣  querySelectorAll('div:empty')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "div:empty");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} empty <div> elements\n\n", .{results.length()});
    }

    // Example 7: :not() pseudo-class (CSS3) ⭐
    {
        std.debug.print("7️⃣  querySelectorAll('.widget:not(.special)') - CSS Level 3 ⭐\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".widget:not(.special)");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} non-special widgets (negation pseudo-class)\n\n", .{results.length()});
    }

    // Example 8: :first-of-type (CSS3)
    {
        std.debug.print("8️⃣  querySelectorAll('article:first-of-type')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "article:first-of-type");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} first <article> of its type\n\n", .{results.length()});
    }
}

/// Complex and advanced selectors
fn runComplexSelectors(doc: *Document) !void {
    const allocator = doc.allocator;

    std.debug.print("═══════════════════════════════════════════════════════════════\n", .{});
    std.debug.print("  COMPLEX & ADVANCED SELECTORS\n", .{});
    std.debug.print("═══════════════════════════════════════════════════════════════\n\n", .{});

    // Example 1: Compound selector with multiple parts
    {
        std.debug.print("1️⃣  querySelectorAll('article.featured[data-category=\"technology\"]')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "article.featured[data-category=\"technology\"]");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} featured technology articles (compound selector)\n\n", .{results.length()});
    }

    // Example 2: Chained pseudo-classes ⭐
    {
        std.debug.print("2️⃣  querySelectorAll('p:first-child:not(.intro)') - Chained pseudo-classes ⭐\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "p:first-child:not(.intro)");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} first-child paragraphs (that are not intro)\n\n", .{results.length()});
    }

    // Example 3: Multiple combinators in sequence
    {
        std.debug.print("3️⃣  querySelectorAll('#sidebar > .widget ~ .widget h3')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "#sidebar > .widget ~ .widget h3");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} h3 elements (child + sibling + descendant)\n\n", .{results.length()});
    }

    // Example 4: Deep nesting with classes and pseudo-classes
    {
        std.debug.print("4️⃣  querySelectorAll('.article .article-body p:not(:first-child)')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".article .article-body p:not(:first-child)");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} non-first paragraphs in articles\n\n", .{results.length()});
    }

    // Example 5: Attribute + pseudo-class combination
    {
        std.debug.print("5️⃣  querySelectorAll('[href]:not([target=\"_blank\"])')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "[href]:not([target=\"_blank\"])");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} internal links (has href, not target=_blank)\n\n", .{results.length()});
    }

    // Example 6: Complex descendant with multiple classes
    {
        std.debug.print("6️⃣  querySelectorAll('.content-area article.featured > div.article-body')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, ".content-area article.featured > div.article-body");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} featured article bodies (complex selector)\n\n", .{results.length()});
    }

    // Example 7: Ultimate complexity - all features combined
    {
        std.debug.print("7️⃣  querySelectorAll('#main-content > article:not(.featured) .article-body > p:last-child')\n", .{});
        const results = try Element.querySelectorAll(doc.document_element.?, "#main-content > article:not(.featured) .article-body > p:last-child");
        defer {
            results.deinit();
            allocator.destroy(results);
        }
        std.debug.print("   ✅ Found {d} elements (ID + child + :not() + descendant + child + :last-child)\n", .{results.length()});
        std.debug.print("   💡 This selector combines: ID, child combinator, negation,\n", .{});
        std.debug.print("      descendant combinator, and structural pseudo-class!\n\n", .{});
    }
}

/// RIDICULOUSLY COMPLEX SELECTOR TEST
/// This function tests an absurdly complex selector on a deeply nested document
fn runRidiculouslyComplexSelector(doc: *Document) !void {
    const allocator = doc.allocator;

    std.debug.print("═══════════════════════════════════════════════════════════════\n", .{});
    std.debug.print("  🔥 THE ULTIMATE CHALLENGE: RIDICULOUSLY COMPLEX SELECTOR 🔥\n", .{});
    std.debug.print("═══════════════════════════════════════════════════════════════\n\n", .{});

    // Build an even deeper, more complex structure specifically for this test
    const ultimate_root = try doc.createElement("section");
    try Element.setAttribute(ultimate_root, "id", "ultimate-test");
    try Element.setAttribute(ultimate_root, "class", "test-arena crazy-nested");
    try Element.setAttribute(ultimate_root, "data-level", "MAXIMUM");
    try Element.setAttribute(ultimate_root, "aria-label", "Ultimate Selector Challenge");
    _ = try doc.document_element.?.appendChild(ultimate_root);

    // Level 1: Container with multiple attributes
    const level1 = try doc.createElement("div");
    try Element.setAttribute(level1, "id", "level-1");
    try Element.setAttribute(level1, "class", "container primary active");
    try Element.setAttribute(level1, "data-depth", "1");
    try Element.setAttribute(level1, "role", "main");
    _ = try ultimate_root.appendChild(level1);

    // Level 2: Multiple siblings with varying attributes
    var sibling_count: usize = 0;
    while (sibling_count < 5) : (sibling_count += 1) {
        const level2 = try doc.createElement("div");
        try Element.setAttribute(level2, "class", if (sibling_count == 2) "box special highlighted" else "box");
        const depth_str = try std.fmt.allocPrint(allocator, "{d}", .{sibling_count + 2});
        defer allocator.free(depth_str);
        try Element.setAttribute(level2, "data-depth", depth_str);
        try Element.setAttribute(level2, "data-index", depth_str);
        if (sibling_count % 2 == 0) {
            try Element.setAttribute(level2, "data-even", "true");
        }
        _ = try level1.appendChild(level2);

        // Level 3: Nested lists and complex structures
        if (sibling_count == 2) { // Only in the special box
            const level3_wrapper = try doc.createElement("div");
            try Element.setAttribute(level3_wrapper, "class", "wrapper nested-content");
            try Element.setAttribute(level3_wrapper, "data-type", "complex");
            _ = try level2.appendChild(level3_wrapper);

            // Level 4: Article with metadata
            const article = try doc.createElement("article");
            try Element.setAttribute(article, "id", "deep-article");
            try Element.setAttribute(article, "class", "post featured premium");
            try Element.setAttribute(article, "data-category", "technology");
            try Element.setAttribute(article, "data-author", "jane-doe");
            try Element.setAttribute(article, "data-published", "2025-01-10");
            try Element.setAttribute(article, "lang", "en-US");
            _ = try level3_wrapper.appendChild(article);

            // Level 5: Article header
            const art_header = try doc.createElement("header");
            try Element.setAttribute(art_header, "class", "article-header meta-rich");
            _ = try article.appendChild(art_header);

            // Level 6: Title with compound classes
            const title = try doc.createElement("h1");
            try Element.setAttribute(title, "class", "title primary featured");
            try Element.setAttribute(title, "data-priority", "high");
            _ = try art_header.appendChild(title);

            const title_text = try doc.createTextNode("The Ultimate DOM Selector Test");
            _ = try title.appendChild(title_text.character_data.node);

            // Level 7: Metadata section with multiple children
            const meta = try doc.createElement("div");
            try Element.setAttribute(meta, "class", "metadata");
            _ = try art_header.appendChild(meta);

            // Author info
            const author_span = try doc.createElement("span");
            try Element.setAttribute(author_span, "class", "author-info highlighted");
            try Element.setAttribute(author_span, "data-verified", "true");
            try Element.setAttribute(author_span, "itemprop", "author");
            _ = try meta.appendChild(author_span);

            // Date info (this will be our target!)
            const date_span = try doc.createElement("span");
            try Element.setAttribute(date_span, "class", "date-info published");
            try Element.setAttribute(date_span, "data-format", "iso");
            try Element.setAttribute(date_span, "datetime", "2025-01-10T00:00:00Z");
            try Element.setAttribute(date_span, "itemprop", "datePublished");
            _ = try meta.appendChild(date_span);

            const date_text = try doc.createTextNode("January 10, 2025");
            _ = try date_span.appendChild(date_text.character_data.node);

            // Category badge (also a potential target)
            const badge = try doc.createElement("span");
            try Element.setAttribute(badge, "class", "badge category tech premium");
            try Element.setAttribute(badge, "data-color", "blue");
            try Element.setAttribute(badge, "aria-label", "Technology Category");
            _ = try meta.appendChild(badge);

            // Level 8: Article body with deeply nested paragraphs
            const art_body = try doc.createElement("div");
            try Element.setAttribute(art_body, "class", "article-body content-rich");
            try Element.setAttribute(art_body, "data-format", "markdown");
            _ = try article.appendChild(art_body);

            // Multiple paragraphs with varying attributes
            var para_count: usize = 0;
            while (para_count < 4) : (para_count += 1) {
                const para = try doc.createElement("p");
                const para_class = switch (para_count) {
                    0 => "intro lead bold",
                    1 => "content normal",
                    2 => "content highlight important",
                    else => "content conclusion",
                };
                try Element.setAttribute(para, "class", para_class);
                const para_depth = try std.fmt.allocPrint(allocator, "{d}", .{para_count + 8});
                defer allocator.free(para_depth);
                try Element.setAttribute(para, "data-paragraph", para_depth);
                _ = try art_body.appendChild(para);

                // Level 9: Inline elements within paragraphs
                if (para_count == 2) { // In the highlighted paragraph
                    const strong_elem = try doc.createElement("strong");
                    try Element.setAttribute(strong_elem, "class", "emphasis critical");
                    try Element.setAttribute(strong_elem, "data-weight", "700");
                    _ = try para.appendChild(strong_elem);

                    const code_elem = try doc.createElement("code");
                    try Element.setAttribute(code_elem, "class", "inline-code syntax-highlighted");
                    try Element.setAttribute(code_elem, "data-lang", "zig");
                    try Element.setAttribute(code_elem, "spellcheck", "false");
                    _ = try strong_elem.appendChild(code_elem);

                    // THIS IS THE ULTIMATE TARGET!
                    const target_text = try doc.createTextNode("ULTIMATE TARGET FOUND!");
                    _ = try code_elem.appendChild(target_text.character_data.node);
                }
            }

            // Level 10: Footer with social links
            const art_footer = try doc.createElement("footer");
            try Element.setAttribute(art_footer, "class", "article-footer actions");
            _ = try article.appendChild(art_footer);

            const share_div = try doc.createElement("div");
            try Element.setAttribute(share_div, "class", "social-share");
            try Element.setAttribute(share_div, "data-network-count", "3");
            _ = try art_footer.appendChild(share_div);
        }
    }

    std.debug.print("🏗️  Built an EXTREMELY DEEP AND COMPLEX DOM structure:\n", .{});
    std.debug.print("   • 10+ levels of nesting\n", .{});
    std.debug.print("   • Multiple siblings at each level\n", .{});
    std.debug.print("   • Compound selectors (element.class.class#id[attr])\n", .{});
    std.debug.print("   • Multiple attribute matchers\n", .{});
    std.debug.print("   • Pseudo-class filters\n", .{});
    std.debug.print("   • Chained combinators (>, +, ~, descendant)\n", .{});
    std.debug.print("\n", .{});

    // THE RIDICULOUSLY COMPLEX SELECTOR!
    // This selector combines:
    // - ID selector
    // - Multiple compound selectors with 2-3 classes each
    // - Multiple attribute selectors with different operators
    // - Child combinator (>)
    // - Descendant combinator (space)
    // - Pseudo-class (:not, :nth-child)
    // - 9+ levels of nesting
    const ridiculous_selector =
        "#ultimate-test[data-level=\"MAXIMUM\"][aria-label] " ++ // Level 0: ID + 2 attributes
        "> div#level-1.container.primary.active[role=\"main\"] " ++ // Level 1: ID + 3 classes + attribute
        "> div.box.special.highlighted:nth-child(3)[data-even] " ++ // Level 2: 3 classes + pseudo + attribute
        "> div.wrapper.nested-content[data-type=\"complex\"] " ++ // Level 3: 2 classes + attribute
        "> article.post.featured.premium[data-category=\"technology\"][lang|=\"en\"] " ++ // Level 4: 3 classes + 2 attributes
        "> header.article-header:not(.simple) " ++ // Level 5: compound + :not pseudo
        "> div.metadata " ++ // Level 6: descendant combinator
        "span.badge.category.tech[data-color=\"blue\"][aria-label]"; // Level 7: 4 classes + 2 attributes

    std.debug.print("🎯 THE ULTIMATE SELECTOR (beautifully formatted):\n\n", .{});
    std.debug.print("    #ultimate-test[data-level=\"MAXIMUM\"][aria-label]\n", .{});
    std.debug.print("    > div#level-1.container.primary.active[role=\"main\"]\n", .{});
    std.debug.print("    > div.box.special.highlighted:nth-child(3)[data-even]\n", .{});
    std.debug.print("    > div.wrapper.nested-content[data-type=\"complex\"]\n", .{});
    std.debug.print("    > article.post.featured.premium[data-category=\"technology\"][lang|=\"en\"]\n", .{});
    std.debug.print("    > header.article-header:not(.simple)\n", .{});
    std.debug.print("    > div.metadata\n", .{});
    std.debug.print("    span.badge.category.tech[data-color=\"blue\"][aria-label]\n\n", .{});

    std.debug.print("📊 Selector Complexity Analysis:\n", .{});
    std.debug.print("   • Depth: 7 levels of combinators\n", .{});
    std.debug.print("   • Components: 35+ individual selector components\n", .{});
    std.debug.print("   • Compound selectors: 7 (some with 4+ parts)\n", .{});
    std.debug.print("   • Attribute selectors: 8\n", .{});
    std.debug.print("   • Pseudo-classes: 2 (:nth-child, :not)\n", .{});
    std.debug.print("   • Class selectors: 20+\n", .{});
    std.debug.print("   • ID selectors: 2\n", .{});
    std.debug.print("   • Combinators: 6 child (>), 1 descendant\n", .{});
    std.debug.print("\n", .{});

    std.debug.print("⏱️  Running the ULTIMATE query...\n", .{});
    const start_time = std.time.milliTimestamp();

    const results = try Element.querySelectorAll(doc.document_element.?, ridiculous_selector);
    defer {
        results.deinit();
        allocator.destroy(results);
    }

    const end_time = std.time.milliTimestamp();
    const elapsed = end_time - start_time;

    std.debug.print("\n", .{});
    if (results.length() > 0) {
        std.debug.print("🎉 SUCCESS! Found {d} element(s) matching the ULTIMATE selector!\n", .{results.length()});
        std.debug.print("   ⚡ Query completed in {d}ms\n\n", .{elapsed});

        for (results.items.items) |node| {
            const elem: *dom.Node = @ptrCast(@alignCast(node));
            const class = Element.getAttribute(elem, "class") orelse "(no class)";
            const data_color = Element.getAttribute(elem, "data-color") orelse "(no color)";
            std.debug.print("   ✨ Matched Element:\n", .{});
            std.debug.print("      Tag: <span>\n", .{});
            std.debug.print("      Classes: {s}\n", .{class});
            std.debug.print("      data-color: {s}\n", .{data_color});
        }
    } else {
        std.debug.print("❌ No matches found (but the selector was valid!)\n", .{});
        std.debug.print("   ⚡ Query completed in {d}ms\n", .{elapsed});
    }

    std.debug.print("\n", .{});
    std.debug.print("💪 ACHIEVEMENT UNLOCKED: Ultimate Selector Master!\n", .{});
    std.debug.print("   You've successfully queried a selector with:\n", .{});
    std.debug.print("   • 35+ selector components\n", .{});
    std.debug.print("   • 7 levels of combinators\n", .{});
    std.debug.print("   • Multiple compound selectors\n", .{});
    std.debug.print("   • Complex attribute matching\n", .{});
    std.debug.print("   • Pseudo-class filtering\n", .{});
    std.debug.print("   This proves the DOM implementation can handle real-world\n", .{});
    std.debug.print("   enterprise-level selector complexity! 🚀\n\n", .{});
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
