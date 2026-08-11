#!/bin/bash



setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

	temp_file1=$(mktemp);
}

teardown() {
	rm -f "$temp_file1";
}



@test "'command' command syntax" {
	run rrssh run --- --- echo asdf ---;
	assert_success;
	assert_output asdf;
	
	run rrssh run --- command [ echo asdf ];
	assert_success;
	assert_output asdf;
	
	run rrssh run --- command "echo asdf";
	assert_success;
	assert_output asdf;

	run rrssh run --- --- echo asdf;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- command "[" echo asdff;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- command;
	assert_failure;

	run rrssh run --- command [ echo asdf ] command;
	assert_failure;

	# we try to run a command called "]", which doesn't exist
	# currently commented because bats warns that 127 is for commands not found...
	# run -127 rrssh run --- command "]";
	# assert_failure;

	# run -127 rrssh run --- [ command "]" ];
	# assert_failure;
	
}

@test "operator 'try' 'not' syntax" {
	run rrssh run --- not;
	assert_failure;
	run rrssh run --- not not;
	assert_failure;

	run rrssh run --- try;
	assert_failure;
	run rrssh run --- try try;
	assert_failure;

	run rrssh run --- not try;
	assert_failure;

	run rrssh run --- try not;
	assert_failure;

	run rrssh run --- not try command [ echo asdf ];
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- try not command [ echo asdf ];
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- try command [ true ] try try;
	assert_failure;

	run rrssh run --- not not command [ true ];
	assert_failure;
	run rrssh run --- not not command [ false ];
	assert_failure;
}

@test "whole script syntax is validated before execution starts" {
	run rrssh run --- --- echo asdf --- "[";
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- command;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- host localhost "[";
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- host localhost "[" and --- echo ffgf --- "]";
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial ffgf;

	run rrssh --fake-su run --- --- echo asdf --- su charles "[";
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- "[" "[" --- echo asdf --- "]" --- echo qwer ---;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo asdf --- --- echo qwer --- "]";
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo asdf --- --- echo qwer --- "]" "]";
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;
}

@test "operator 'and' syntax" {
	run rrssh run --- and;
	assert_failure;

	run rrssh run --- and --- echo asdf ---;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- and;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- and --- echo qwer --- and;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo asdf --- and and --- echo qwer ---;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo qwer --- and [ [ [ [ ] ] and ] --- echo asdf --- ];
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo qwer --- and [ [ [ [ ] ] ] --- echo asdf --- ];
	assert_success;
	assert_output --partial asdf;
	assert_output --partial qwer;
}

@test "operator 'or' syntax" {
	run rrssh run --- or;
	assert_failure;

	run rrssh run --- or --- echo asdf ---;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- or;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- or --- echo qwer --- or;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo asdf --- or or --- echo qwer ---;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo qwer --- or [ [ [ [ ] ] or ] --- echo asdf --- ];
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo qwer --- or [ [ [ [ ] ] ] --- echo asdf --- ];
	assert_success;
	refute_output --partial asdf;
	assert_output --partial qwer;
}

@test "advanced operator syntax" {
	run rrssh run --- --- echo asdf --- not and --- false ---;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- not and --- false --- or echo --- qwer ---;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo asdf --- and try --- echo qwer ---;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- --- echo asdf --- [ --- echo qwer --- try ];
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;
}
















