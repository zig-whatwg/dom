// Debug test to see if testharness works

print("Before test definition");

test(() => {
    print("Inside test function");
    assert_true(true, "This should pass");
}, "Simple passing test");

print("After test definition");
