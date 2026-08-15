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


@test "set-env familly syntax is validated" {
	run brrssh run --- print asdf set-env;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- print asdf unset-env;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- print asdf global-set-env;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- print asdf global-unset-env;
	assert_failure;
	refute_output --partial asdf;
}

@test "set-env unset-env works" {
	run brrssh run --- --- bash -c 'echo "$rrssh_asdf"' ---;
	assert_success;
	refute_output --partial asdf;

	run brrssh run --- set-env rrssh_asdf=asdf --- bash -c 'echo "$rrssh_asdf"' ---;
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- set-env rrssh_asdf=asdf [ --- bash -c 'echo "$rrssh_asdf"' --- ];
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- set-env rrssh_asdf=asdf unset-env rrssh_asdf [ --- bash -c 'echo "$rrssh_asdf"' --- ];
	assert_success;
	refute_output --partial asdf;

	run brrssh run --- set-env rrssh_asdf=asdf [ unset-env rrssh_asdf --- bash -c 'echo "$rrssh_asdf"' --- ];
	assert_success;
	refute_output --partial asdf;

	run brrssh run -f - <<"SCRIPT";
set-env rrssh_var1=asdf
set-env rrssh_var2=qwer
set-env rrssh_var3=ffgf
[
	--- bash -c 'echo "$rrssh_var1"' ---
	unset-env rrssh_var3
	host localhost [
		--- bash -c 'echo "$rrssh_var2"' ---
	]
	--- bash -c 'echo "$rrssh_var3"' ---
]
SCRIPT
	assert_success;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;

}

@test "global-set-env global-unset-env works" {
	run brrssh run -f - <<"SCRIPT";
global-set-env rrssh_var1=asdf
global-set-env rrssh_var2=qwer
global-set-env rrssh_var3=ffgf
global-set-env rrssh_var4=rrtr
global-set-env rrssh_var5=ddfd
unset-env rrssh_var2
host localhost [
	--- bash -c 'echo "$rrssh_var1"' ---
	--- bash -c 'echo "$rrssh_var2"' ---
	global-unset-env rrssh_var3
	set-env rrssh_var4=eere
	set-env rrssh_var5=ssds
	host localhost [
		--- bash -c 'echo "$rrssh_var3"' ---
		--- bash -c 'echo "$rrssh_var4"' ---
	]
	--- bash -c 'echo "$rrssh_var5"' ---
]
SCRIPT
	assert_success;
	assert_output --partial asdf;
	assert_output --partial qwer;
	refute_output --partial ffgf;
	refute_output --partial eere;
	assert_output --partial rrtr;
	assert_output --partial ssds;
	refute_output --partial ddfd;
}


