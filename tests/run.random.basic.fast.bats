#!/bin/bash


setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

	temp_file1=$(mktemp);
}

teardown() {
	rm -f "$temp_file1";
}

@test "-o option works on host commands" {
	run rrssh run --- host;
	assert_failure;

	run rrssh run --- host or print asdf;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- host -o;
	assert_failure;

	run rrssh run --- host -o Port=22;
	assert_failure;

	run rrssh run --- host localhost -o Port=22;
	assert_failure;

	run rrssh run --- host localhost -o Port=22 :;
	assert_success;

	run rrssh run --- host localhost -o Port=22 : print;
	assert_failure;

	run rrssh run --- host localhost -o Port=22 : print asdf;
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- host -o Port=22 localhost : print asdf;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- host localhost -o Port=22 [ print ];
	assert_failure;

	run rrssh run --- host localhost -o Port=22 [ print asdf ];
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- host -o Port=22 localhost [ print asdf ];
	assert_failure;
	refute_output --partial asdf;




	
	run rrssh run --- host localhost : host;
	assert_failure;

	run rrssh run --- host localhost : host or print asdf;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- host localhost : host -o;
	assert_failure;

	run rrssh run --- host localhost : host -o Port=22;
	assert_failure;

	run rrssh run --- host localhost : host localhost -o Port=22;
	assert_failure;

	run rrssh run --- host localhost : host localhost -o Port=22 :;
	assert_success;

	run rrssh run --- host localhost : host localhost -o Port=22 : print;
	assert_failure;

	run rrssh run --- host localhost : host localhost -o Port=22 : print asdf;
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- host localhost : host -o Port=22 localhost : print asdf;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- host localhost : host localhost -o Port=22 [ print ];
	assert_failure;

	run rrssh run --- host localhost : host localhost -o Port=22 [ print asdf ];
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- host localhost : host -o Port=22 localhost [ print asdf ];
	assert_failure;
	refute_output --partial asdf;

	run rrssh --fake-su run --- su charles -o Port=22 [ print asdf ];
	assert_failure;
	refute_output --partial asdf;
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


@test "execution is stopped at the first non-0 exit code" {
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

@test "operator 'not' control flow" {
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

@test "print command works" {
	run rrssh run --- print asdf;
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- host localhost [ false and print asdf print qwer ] or print ffgf;
	assert_success;
	refute_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;
}

@test "spaces are preserved in commands" {
	run rrssh run --- --- echo asdf qwer ---;
	assert_success;
	assert_output "asdf qwer";

	run rrssh run --- --- echo "asdf     qwer" ---;
	assert_success;
	assert_output "asdf     qwer";

	run rrssh run --- host localhost : --- echo "asdf     qwer" ---;
	assert_success;
	assert_output "asdf     qwer";

	run rrssh run --- --- echo -n "asdf     qwer" --- --- echo "ffgf    rrtr" ---;
	assert_success;
	assert_output "asdf     qwerffgf    rrtr";
}

@test "no obligatory linefeeds appended after commands" {
	run rrssh run --- [ --- echo -n asdf --- --- echo -n qwer --- --- echo -n ffgf --- ];
	assert_success;
	assert_output --partial asdfqwerffgf;
}

@test "panic command works" {
	run rrssh run --- panic asdf;
	assert_failure;
	assert_output --partial asdf;

	run rrssh run --- try false and panic msg;
	assert_success;
	refute_output --partial msg;

	run rrssh run --- try host localhost [ try panic asdf or print ffgf ] or print qwer;
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;

	run rrssh run --- print asdf try false and panic;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- try false and panic asdf;
	assert_success;
	refute_output --partial asdf;
}
















