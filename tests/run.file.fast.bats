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


@test "useless dropdirs are successful" {
	run rrssh run --- drop-dir maindrop "$temp_dir1";
	assert_success;

	run rrssh run --- drop-dir drop1 "$temp_dir1" drop-dir drop1 "$temp_dir2";
	assert_success;
}

@test "useless takes are successful" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run --- take-file "$temp_dir1/bash" "" drop1;
	assert_success;
	
	run rrssh run --- take-file "$temp_dir1/bash" "" drop1 drop-dir drop2 "$temp_dir2";
	assert_success;
}


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


@test "file pushing without renaming works" {
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


@test "file transfers on the same host 1" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
host localhost [
	drop-dir drop2 $(printf %q "$temp_dir2")
	take-file $(printf %q "$temp_dir1/bash") "" drop2
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;
}

@test "file transfers on the same host 2" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
host localhost [
	drop-dir drop2 $(printf %q "$temp_dir2")
	[
		take-file $(printf %q "$temp_dir1/bash") "" drop2
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;
}

@test "file transfers on the same host 3" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
host localhost [
	drop-dir drop2 $(printf %q "$temp_dir2")
	[
		[
			take-file $(printf %q "$temp_dir1/bash") "" drop2
		]
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;
}

@test "file transfers on the same host 4" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
host localhost [
	take-file $(printf %q "$temp_dir1/bash") "" drop2
	[
		drop-dir drop2 $(printf %q "$temp_dir2")
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;
}

@test "file transfers on the same host 5" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
host localhost [
	take-file $(printf %q "$temp_dir1/bash") "" drop2
	[
		[
			drop-dir drop2 $(printf %q "$temp_dir2")
		]
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;
}

@test "file transfers on the same host 6" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
drop-dir drop2 $(printf %q "$temp_dir2")
take-file $(printf %q "$temp_dir1/bash") "" drop2
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;
}

@test "file transfers on the same host 7" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
take-file $(printf %q "$temp_dir1/bash") "" drop2
drop-dir drop2 $(printf %q "$temp_dir2")
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;
}

@test "various file forwarding scenario 1" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh --fake-su run -f - <<SCRIPT;
take-file $(printf %q "$temp_dir1/bash") "" drop2
[
	[
		host localhost [
			[
				host localhost [
					host localhost [
						su charles [
							su charles [
								drop-dir drop2 $(printf %q "$temp_dir2")
							]
						]
					]
				]
			]
		]
	]
]

SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;
	
}



















