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



@test "rrssh returns the failing command's exit code 1" {
	run rrssh run --- --- exit 0 ---;
	assert_success;

	run rrssh run --- --- exit 4 ---;
	assert_failure 4;

	run rrssh run --- --- exit 3 --- --- exit 5 ---;
	assert_failure 3;

	run rrssh run --- not --- exit 3 --- --- exit 5 ---;
	assert_failure 5;

	run rrssh run --- --- exit 7 --- and --- exit 3 ---;
	assert_failure 7;

	run rrssh run --- [ --- exit 7 --- ] and --- exit 3 ---;
	assert_failure 7;

	run rrssh run --- [ --- exit 7 --- ] or --- exit 3 ---;
	assert_failure 3;
}

@test "rrssh returns the failing command's exit code 2" {
	run rrssh run --- [ [ [ [ --- exit 4 --- ] ] ] ];
	assert_failure 4;

	run rrssh run [ [ --- exit 3 --- ] ] and host localhost [ [ [ --- exit 7 --- ] ] ];
	assert_failure 3;
}


