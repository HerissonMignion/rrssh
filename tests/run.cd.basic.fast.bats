#!/bin/bash

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

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
	run rrssh run --- cd;
	assert_failure;

	run rrssh run --- --- echo asdf --- cd;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- [ --- echo asdf --- cd ];
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- cd "$temp_dir";
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- home;
	assert_success;

	run rrssh run --- pushd;
	assert_failure;

	run rrssh run --- --- echo asdf --- pushd;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- [ --- echo asdf --- pushd ];
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- pushd "$temp_dir";
	assert_success;
	assert_output --partial asdf;
	
}

@test "cd command works" {
	run rrssh run --- cd "$temp_dir";
	assert_success;

	run rrssh run --- cd "$temp_dir" cd asdfasdfasdf;
	assert_failure;

	run rrssh run --- cd "$temp_dir" or cd "$temp_dir2" pwd;
	assert_success;
	assert_output --partial "$temp_dir";
	refute_output --partial "$temp_dir2";

	run rrssh run --- cd "$temp_dir" or cd "$temp_dir2" [ [ pwd ] ];
	assert_success;
	assert_output --partial "$temp_dir";
	refute_output --partial "$temp_dir2";

	run rrssh run --- cd "$temp_dir" [ cd "$temp_dir2" ] pwd;
	assert_success;
	assert_output --partial "$temp_dir";
	refute_output --partial "$temp_dir2";

	run rrssh run --- [ cd "$temp_dir" ] cd "$temp_dir2" pwd;
	assert_success;
	refute_output --partial "$temp_dir";
	assert_output --partial "$temp_dir2";
}

@test "pushd popd commands work" {
	run rrssh run --- pushd "$temp_dir" pushd "$temp_dir2" pwd;
	assert_success;
	assert_output --partial "$temp_dir2";

	run rrssh run --- pushd "$temp_dir" pushd "$temp_dir2" popd pwd;
	assert_success;
	assert_output --partial "$temp_dir";

	run rrssh run --- [ [ pushd "$temp_dir" pushd "$temp_dir2" popd pwd ] ];
	assert_success;
	assert_output --partial "$temp_dir";

	# we currently dont support carrying the directory stack accros
	# local forks, even if we says that changes wont reflect outside
	# the inner scope. but one day we could change this, maybe.
	run rrssh run --- pushd "$temp_dir" pushd "$temp_dir2" [ popd pwd ];
	assert_failure;
	refute_output --partial "$temp_dir";
	
}



















