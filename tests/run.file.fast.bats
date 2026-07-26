#!/bin/bash


setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

	temp_dir1=$(mktemp --directory);
	temp_dir2=$(mktemp --directory);
	temp_dir3=$(mktemp --directory);
}

teardown() {
	rm -rf "$temp_dir1";
	rm -rf "$temp_dir2";
	rm -rf "$temp_dir3";
}


# TODO: check md5sum

# TODO: more tests

@test "file pulling without renaming works" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
cd $(printf %q "$temp_dir2")
drop-dir maindrop .
host localhost [
	host localhost [
		take-file $(printf %q "$temp_dir1/bash") '' maindrop
		--- echo asdf ---
	]
]
SCRIPT
	assert_success;
	assert_output --partial asdf;

	run [ -f "$temp_dir2/bash" ];
	assert_success;

}


@test "file pushing without renaming workd" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
take-file $(printf %q "$temp_dir1/bash") '' maindrop
host localhost [
	host localhost [
		cd $(printf %q "$temp_dir2")
		drop-dir maindrop .
		--- echo asdf ---
	]
]
SCRIPT
	assert_success;
	assert_output --partial asdf;

	run [ -f "$temp_dir2/bash" ];
	assert_success;

}








