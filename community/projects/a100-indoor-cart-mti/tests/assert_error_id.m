function assert_error_id(callback, expected_id)
%ASSERT_ERROR_ID Assert that a function handle throws a specific identifier.

did_throw = false;
try
    callback();
catch err
    did_throw = true;
    assert(strcmp(err.identifier, expected_id), ...
        'Expected error %s, got %s (%s).', expected_id, err.identifier, err.message);
end
assert(did_throw, 'Expected error %s, but no error was thrown.', expected_id);
end

