# Testing

Put a unit test in the same file, in a `#[cfg(test)] mod tests` block. Put an
integration test in the `tests/` folder of its crate.

A test must not use the network. Use a recorded response.

Put a recorded response in the `tests/fixtures/` folder of its crate.
