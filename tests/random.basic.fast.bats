#!/bin/bash


setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

	temp_file1=$(mktemp);
}

teardown() {
	rm -f "$temp_file1";
}



@test "can run an empty script" {
	run rrssh run ---;
	assert_success;

	
	cat <<"SCRIPT" > "$temp_file1";

SCRIPT
	run rrssh run -f "$temp_file1";
	assert_success;

	
	run rrssh run -f - <<"SCRIPT";

SCRIPT
	assert_success;
}




@test "can run a small script" {
	run rrssh run --- command [ echo asdf ] command [ echo qwer ] command [ echo ffgf ];
	assert_output --partial asdf;
	assert_output --partial qwer;
	assert_output --partial ffgf;
	assert_success;

	cat <<"SCRIPT" > "$temp_file1";
		command [ echo asdf ]
		command [ echo qwer ]
		command [ echo ffgf ]
SCRIPT
	run rrssh run -f "$temp_file1";
	assert_output --partial asdf;
	assert_output --partial qwer;
	assert_output --partial ffgf;
	assert_success;

	run rrssh run -f - <<"SCRIPT";
		command [ echo asdf ]
		command [ echo qwer ]
		command [ echo ffgf ]
SCRIPT
	assert_output --partial asdf;
	assert_output --partial qwer;
	assert_output --partial ffgf;
	assert_success;
}
























