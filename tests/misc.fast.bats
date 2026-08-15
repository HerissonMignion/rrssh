#!/bin/bash

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;
	. "$BATS_TEST_DIRNAME/lib_test.sh";
}

teardown() {
	true;
}

@test "verify rrssh's debug output" {
	# run bats with --verbose-run --show-output-of-passing-tests to
	# make sure that bash versions are as expected when running the
	# test suite.
	run brrssh run --- delim debug;
	assert_success;
	run brrssh run --- delim host localhost : debug;
	assert_success;
}
