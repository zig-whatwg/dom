// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/eventPathRemoved.html

test(() => {
    const name = "path";
    assert_false(name in Event.prototype)
    assert_equals(Event.prototype[name], undefined)
    assert_false(name in new Event("test"))
    assert_equals((new Event("test"))[name], undefined)
  }, "Event.prototype should not have property named 'path'")

