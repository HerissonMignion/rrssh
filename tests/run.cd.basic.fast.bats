#!/bin/bash

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;
	. "$BATS_TEST_DIRNAME/lib_test.sh";

	# temp_file1=$(mktemp);
	temp_dir=$(mktemp --directory);
	temp_dir2=$(mktemp --directory);
}

teardown() {
	# rm -f "$temp_file1";
	rm -rf "$temp_dir";
	rm -rf "$temp_dir2";
}



@test "cd home pushd popd syntax works" {
	run brrssh run --- cd;
	assert_failure;

	run brrssh run --- --- echo asdf --- cd;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- [ --- echo asdf --- cd ];
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- --- echo asdf --- cd "$temp_dir";
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- home;
	assert_success;

	run brrssh run --- pushd;
	assert_failure;

	run brrssh run --- --- echo asdf --- pushd;
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- [ --- echo asdf --- pushd ];
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- --- echo asdf --- pushd "$temp_dir";
	assert_success;
	assert_output --partial asdf;
	
}

@test "cd command works" {
	run brrssh run --- cd "$temp_dir";
	assert_success;

	run brrssh run --- cd "$temp_dir" cd asdfasdfasdf;
	assert_failure;

	run brrssh run --- cd "$temp_dir" or cd "$temp_dir2" pwd;
	assert_success;
	assert_output --partial "$temp_dir";
	refute_output --partial "$temp_dir2";

	run brrssh run --- cd "$temp_dir" or cd "$temp_dir2" [ [ pwd ] ];
	assert_success;
	assert_output --partial "$temp_dir";
	refute_output --partial "$temp_dir2";

	run brrssh run --- cd "$temp_dir" [ cd "$temp_dir2" ] pwd;
	assert_success;
	assert_output --partial "$temp_dir";
	refute_output --partial "$temp_dir2";

	run brrssh run --- [ cd "$temp_dir" ] cd "$temp_dir2" pwd;
	assert_success;
	refute_output --partial "$temp_dir";
	assert_output --partial "$temp_dir2";
}

@test "pushd popd commands work" {
	run brrssh run --- pushd "$temp_dir" pushd "$temp_dir2" pwd;
	assert_success;
	assert_output --partial "$temp_dir2";

	run brrssh run --- pushd "$temp_dir" pushd "$temp_dir2" popd pwd;
	assert_success;
	assert_output --partial "$temp_dir";

	run brrssh run --- [ [ pushd "$temp_dir" pushd "$temp_dir2" popd pwd ] ];
	assert_success;
	assert_output --partial "$temp_dir";

	# we currently dont support carrying the directory stack accros
	# local forks, even if we says that changes wont reflect outside
	# the inner scope. but one day we could change this, maybe.
	run brrssh run --- pushd "$temp_dir" pushd "$temp_dir2" [ popd pwd ];
	assert_failure;
	refute_output --partial "$temp_dir";
	
}



















