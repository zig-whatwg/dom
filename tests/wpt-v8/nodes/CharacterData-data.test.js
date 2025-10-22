// Converted from WPT HTML test
// Original: /Users/bcardarella/projects/wpt/dom/nodes/CharacterData-data.html

function testNode(create, type) {
  test(function() {
    var node = create()
    assert_equals(node.data, "test")
    assert_equals(node.length, 4)
  }, type + ".data initial value")

  test(function() {
    var node = create()
    assert_equals(node.data, "test")

    node.data = null;
    assert_equals(node.data, "")
    assert_equals(node.length, 0)
  }, type + ".data = null")

  test(function() {
    var node = create()
    assert_equals(node.data, "test")

    node.data = undefined;
    assert_equals(node.data, "undefined")
    assert_equals(node.length, 9)
  }, type + ".data = undefined")

  test(function() {
    var node = create()
    assert_equals(node.data, "test")

    node.data = 0;
    assert_equals(node.data, "0")
    assert_equals(node.length, 1)
  }, type + ".data = 0")

  test(function() {
    var node = create()
    assert_equals(node.data, "test")

    node.data = "";
    assert_equals(node.data, "")
    assert_equals(node.length, 0)
  }, type + ".data = ''")

  test(function() {
    var node = create()
    assert_equals(node.data, "test")

    node.data = "--";
    assert_equals(node.data, "--")
    assert_equals(node.length, 2)
  }, type + ".data = '--'")

  test(function() {
    var node = create()
    assert_equals(node.data, "test")

    node.data = "資料";
    assert_equals(node.data, "資料")
    assert_equals(node.length, 2)
  }, type + ".data = '資料'")

  test(function() {
    var node = create()
    assert_equals(node.data, "test")

    node.data = "🌠 test 🌠 TEST";
    assert_equals(node.data, "🌠 test 🌠 TEST")
    assert_equals(node.length, 15)  // Counting UTF-16 code units
  }, type + ".data = '🌠 test 🌠 TEST'")
}

testNode(function() { return document.createTextNode("test") }, "Text")
testNode(function() { return document.createComment("test") }, "Comment")

