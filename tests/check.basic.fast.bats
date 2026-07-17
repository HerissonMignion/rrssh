#!/bin/bash

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

	temp_file1=$(mktemp);
}

teardown() {
	rm -f "$temp_file1";
}


@test "the check command works with empty scripts" {
	run rrssh check ---;
	assert_success;

	
	cat <<"SCRIPT" > "$temp_file1";

SCRIPT
	run rrssh check -f "$temp_file1";
	assert_success;

	
	run rrssh check -f - <<"SCRIPT";

SCRIPT
	assert_success;
}

@test "the check command validates without executing scripts" {
	run rrssh check --- --- echo asdf ---;
	assert_success;
	refute_output --partial asdf;

	run rrssh check --- [ [ [ --- echo asdf --- ] ] ];
	assert_success;
	refute_output --partial asdf;
}

@test "the check command reports errors" {
	run rrssh check --- --- echo asdf;
	assert_failure;
	refute_output --partial asdf;
}









