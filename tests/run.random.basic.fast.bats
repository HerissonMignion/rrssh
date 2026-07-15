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


@test "basic execution is stopped at the first non-0 exit code" {
	run rrssh run --- command [ exit 1 ];
	assert_failure;

	run rrssh run --- command [ echo asdf ] command [ false ];
	assert_output --partial asdf;
	assert_failure;

	run rrssh run --- command [ echo asdf ] command [ false ] command [ echo qwer ];
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_failure;

	run rrssh run --- command [ echo asdf ] command "false" command [ echo qwer ];
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_failure;

	run rrssh run --- command [ echo asdf ] command "true; false" command [ echo qwer ];
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_failure;

	run rrssh run --- command [ echo asdf ] --- false --- command [ echo qwer ];
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_failure;
	
}

@test "basic 'command' command syntax" {
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
	
}

@test "basic operator 'not' control flow" {
	run rrssh run --- not command [ true ];
	assert_failure;

	run rrssh run --- not command [ true ] command [ echo qwer ];
	assert_failure;
	refute_output --partial qwer;

	run rrssh run --- not command [ true ] not command [ echo asdf ];
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- not command [ false ];
	assert_success;

	run rrssh run --- not command [ false ] command [ true ] command [ echo asdf ];
	assert_success;
	assert_output --partial asdf;
}

@test "basic operator 'try' 'not' syntax" {
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





















