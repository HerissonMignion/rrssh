#!/bin/bash

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;
	. "$BATS_TEST_DIRNAME/lib_test.sh";

	temp_file1=$(mktemp);
}

teardown() {
	rm -f "$temp_file1";
}


@test "the check command works with empty scripts" {
	run brrssh check ---;
	assert_success;

	
	cat <<"SCRIPT" > "$temp_file1";

SCRIPT
	run brrssh check -f "$temp_file1";
	assert_success;

	
	run brrssh check -f - <<"SCRIPT";

SCRIPT
	assert_success;
}

@test "the check command validates without executing scripts" {
	run brrssh check --- --- echo asdf ---;
	assert_success;
	refute_output --partial asdf;

	run brrssh check --- [ [ [ --- echo asdf --- ] ] ];
	assert_success;
	refute_output --partial asdf;
}

@test "the check command reports errors" {
	run brrssh check --- --- echo asdf;
	assert_failure;
	refute_output --partial asdf;
}









