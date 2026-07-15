#!/bin/bash

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

	temp_file1=$(mktemp);
}

teardown() {
	rm -f "$temp_file1";
}

@test "advanced control flow 1" {
	run rrssh run --- --- false --- --- echo asdf ---;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo qwer --- --- false --- --- echo asdf ---;
	assert_failure;
	refute_output --partial asdf;
	assert_output --partial qwer;

	run rrssh run --- --- false --- or --- echo asdf ---;
	assert_success;
	assert_output --partial asdf;

	
	run rrssh run --- try --- echo asdf --- --- false --- --- echo qwer ---;
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo asdf --- try --- false --- --- echo qwer ---;
	assert_success;
	assert_output --partial asdf;
	assert_output --partial qwer;

	run rrssh run --- --- echo asdf --- --- false --- try --- echo qwer ---;
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;


	run rrssh run --- --- echo asdf --- or --- false ---;
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- --- echo asdf --- or --- false --- or --- false ---;
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- --- echo asdf --- or --- false --- and --- false ---;
	assert_failure;
	assert_output --partial asdf;

	run rrssh run --- --- echo asdf --- or --- false --- and not --- false ---;
	assert_success;
	assert_output --partial asdf;
	
	
}

@test "advanced control flow 2" {
	run rrssh run --- host localhost [ --- false --- ] --- echo asdf ---;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- [ host localhost [ [ [ --- false --- ] ] ] ] --- echo asdf ---;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- [ host localhost [ [ [ --- true --- ] ] ] ] --- echo asdf ---;
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- --- false --- and [ [ ] host localhost [ --- echo asdf --- ] ] and --- echo qwer ---;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- false --- and [ [ ] host localhost [ --- echo asdf --- ] ] or --- echo qwer ---;
	assert_success;
	assert_output --partial qwer;
	refute_output --partial asdf;

}


@test "advanced control flow 3" {
	run rrssh run --- [ [ ] ] --- echo asdf ---;
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- [ [ ] ] and --- echo asdf ---;
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- [ [ false ] ] and --- echo asdf ---;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- [ [ false ] ] or --- echo asdf ---;
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- [ [ false ] or --- echo qwer --- ] or --- echo asdf ---;
	assert_success;
	assert_output --partial qwer;
	refute_output --partial asdf;

	run rrssh run --- [ [ false or --- echo ffgf --- ] or --- echo qwer --- ] or --- echo asdf ---;
	assert_success;
	assert_output --partial ffgf;
	refute_output --partial qwer;
	refute_output --partial asdf;

	run rrssh run --- [ [ false --- echo asdf --- ] --- echo qwer --- false ] --- echo ffgf ---;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;

	run rrssh run --- [ try [ false --- echo asdf --- ] --- echo qwer --- false ] --- echo ffgf ---;
	assert_failure;
	refute_output --partial asdf;
	assert_output --partial qwer;
	refute_output --partial ffgf;

	run rrssh run --- try [ try [ false --- echo asdf --- ] --- echo qwer --- false ] --- echo ffgf ---;
	assert_success;
	refute_output --partial asdf;
	assert_output --partial qwer;
	assert_output --partial ffgf;
	
	run rrssh run --- try [ [ false --- echo asdf --- ] --- echo qwer --- false ] --- echo ffgf ---;
	assert_success;
	refute_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;
	
	run rrssh run --- try [ [ --- echo asdf --- false ] --- echo qwer --- false ] --- echo ffgf ---;
	assert_success;
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;
	
}









