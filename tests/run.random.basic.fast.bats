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

@test "-n option works on host commands" {
	run brrssh run --- host -n;
	assert_failure;

	run brrssh run --- host localhost -n;
	assert_failure;

	run brrssh run --- host localhost -n -o Port=22;
	assert_failure;

	run brrssh run --- host localhost -o Port=22 -n;
	assert_failure;

	run brrssh run --- host localhost -n [ print asdf ];
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- host localhost -o Port=22 -n [ print asdf ];
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- host localhost -n -o Port=22 [ print asdf ];
	assert_success;
	assert_output --partial asdf;
}

@test "-o option works on host commands" {
	run brrssh run --- host;
	assert_failure;

	run brrssh run --- host or print asdf;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- host -o;
	assert_failure;

	run brrssh run --- host -o Port=22;
	assert_failure;

	run brrssh run --- host localhost -o Port=22;
	assert_failure;

	run brrssh run --- host localhost -o Port=22 :;
	assert_success;

	run brrssh run --- host localhost -o Port=22 : print;
	assert_failure;

	run brrssh run --- host localhost -o Port=22 : print asdf;
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- host -o Port=22 localhost : print asdf;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- host localhost -o Port=22 [ print ];
	assert_failure;

	run brrssh run --- host localhost -o Port=22 [ print asdf ];
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- host -o Port=22 localhost [ print asdf ];
	assert_failure;
	refute_output --partial asdf;




	
	run brrssh run --- host localhost : host;
	assert_failure;

	run brrssh run --- host localhost : host or print asdf;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- host localhost : host -o;
	assert_failure;

	run brrssh run --- host localhost : host -o Port=22;
	assert_failure;

	run brrssh run --- host localhost : host localhost -o Port=22;
	assert_failure;

	run brrssh run --- host localhost : host localhost -o Port=22 :;
	assert_success;

	run brrssh run --- host localhost : host localhost -o Port=22 : print;
	assert_failure;

	run brrssh run --- host localhost : host localhost -o Port=22 : print asdf;
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- host localhost : host -o Port=22 localhost : print asdf;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- host localhost : host localhost -o Port=22 [ print ];
	assert_failure;

	run brrssh run --- host localhost : host localhost -o Port=22 [ print asdf ];
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- host localhost : host -o Port=22 localhost [ print asdf ];
	assert_failure;
	refute_output --partial asdf;

	run brrssh --fake-su run --- su charles -o Port=22 [ print asdf ];
	assert_failure;
	refute_output --partial asdf;
}

@test "can run an empty script" {
	run brrssh run ---;
	assert_success;

	
	cat <<"SCRIPT" > "$temp_file1";

SCRIPT
	run brrssh run -f "$temp_file1";
	assert_success;

	
	run brrssh run -f - <<"SCRIPT";

SCRIPT
	assert_success;
}




@test "can run a small script" {
	run brrssh run --- command [ echo asdf ] command [ echo qwer ] command [ echo ffgf ];
	assert_output --partial asdf;
	assert_output --partial qwer;
	assert_output --partial ffgf;
	assert_success;

	cat <<"SCRIPT" > "$temp_file1";
		command [ echo asdf ]
		command [ echo qwer ]
		command [ echo ffgf ]
SCRIPT
	run brrssh run -f "$temp_file1";
	assert_output --partial asdf;
	assert_output --partial qwer;
	assert_output --partial ffgf;
	assert_success;

	run brrssh run -f - <<"SCRIPT";
		command [ echo asdf ]
		command [ echo qwer ]
		command [ echo ffgf ]
SCRIPT
	assert_output --partial asdf;
	assert_output --partial qwer;
	assert_output --partial ffgf;
	assert_success;
}


@test "execution is stopped at the first non-0 exit code" {
	run brrssh run --- command [ exit 1 ];
	assert_failure;

	run brrssh run --- command [ echo asdf ] command [ false ];
	assert_output --partial asdf;
	assert_failure;

	run brrssh run --- command [ echo asdf ] command [ false ] command [ echo qwer ];
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_failure;

	run brrssh run --- command [ echo asdf ] command "false" command [ echo qwer ];
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_failure;

	run brrssh run --- command [ echo asdf ] command "true; false" command [ echo qwer ];
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_failure;

	run brrssh run --- command [ echo asdf ] --- false --- command [ echo qwer ];
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_failure;
	
}

@test "operator 'not' control flow" {
	run brrssh run --- not command [ true ];
	assert_failure;

	run brrssh run --- not command [ true ] command [ echo qwer ];
	assert_failure;
	refute_output --partial qwer;

	run brrssh run --- not command [ true ] not command [ echo asdf ];
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- not command [ false ];
	assert_success;

	run brrssh run --- not command [ false ] command [ true ] command [ echo asdf ];
	assert_success;
	assert_output --partial asdf;
}

@test "print command works" {
	run brrssh run --- print asdf;
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- host localhost [ false and print asdf print qwer ] or print ffgf;
	assert_success;
	refute_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;
}

@test "spaces are preserved in commands" {
	run brrssh run --- --- echo asdf qwer ---;
	assert_success;
	assert_output "asdf qwer";

	run brrssh run --- --- echo "asdf     qwer" ---;
	assert_success;
	assert_output "asdf     qwer";

	run brrssh run --- host localhost : --- echo "asdf     qwer" ---;
	assert_success;
	assert_output "asdf     qwer";

	run brrssh run --- --- echo -n "asdf     qwer" --- --- echo "ffgf    rrtr" ---;
	assert_success;
	assert_output "asdf     qwerffgf    rrtr";
}

@test "no obligatory linefeeds appended after commands" {
	run brrssh run --- [ --- echo -n asdf --- --- echo -n qwer --- --- echo -n ffgf --- ];
	assert_success;
	assert_output --partial asdfqwerffgf;
}

@test "panic command works" {
	run brrssh run --- panic asdf;
	assert_failure;
	assert_output --partial asdf;

	run brrssh run --- try false and panic msg;
	assert_success;
	refute_output --partial msg;

	run brrssh run --- try host localhost [ try panic asdf or print ffgf ] or print qwer;
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;

	run brrssh run --- print asdf try false and panic;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- try false and panic asdf;
	assert_success;
	refute_output --partial asdf;
}
















