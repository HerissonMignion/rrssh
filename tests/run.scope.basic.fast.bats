#!/bin/bash


setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

	temp_file1=$(mktemp);
}

teardown() {
	rm -f "$temp_file1";
}



@test "an empty scope is successful" {
	run rrssh run --- [ ];
	assert_success;

	run rrssh run --- host localhost [ ];
	assert_success;

	run rrssh run --fake-su --- su charles [ ];
	assert_success;
}

# TODO: exit code

