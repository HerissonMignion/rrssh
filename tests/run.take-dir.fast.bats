#!/bin/bash


setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;
	. "$BATS_TEST_DIRNAME/lib_test.sh";

	temp_dir1=$(mktemp --directory);
	temp_dir2=$(mktemp --directory);
	temp_dir3=$(mktemp --directory);
}

teardown() {
	rm -rf "$temp_dir1";
	rm -rf "$temp_dir2";
	rm -rf "$temp_dir3";
}

compare_md5() {
	local file1=$1;
	local file2=$2;
	local file1md5=$(md5sum -- "$file1" | awk '{ print $1; }');
	local file2md5=$(md5sum -- "$file2" | awk '{ print $1; }');
	[ "$file1md5" == "$file2md5" ];
}

@test "the test suite's compare_md5 function works 2" {
	run compare_md5 /bin/bash /bin/bash;
	assert_success;

	run compare_md5 /bin/bash /bin/grep;
	assert_failure;
}

@test "new directory names are validated before execution starts" {
	run brrssh run --- --- echo asdf --- take-dir "$temp_dir1" . dropdir;
    assert_failure;
	refute_output --partial asdf;
	
	run brrssh run --- --- echo asdf --- take-dir "$temp_dir1" .. dropdir;
    assert_failure;
	refute_output --partial asdf;
	
	run brrssh run --- --- echo asdf --- take-dir "$temp_dir1" ../ dropdir;
    assert_failure;
	refute_output --partial asdf;
	
	run brrssh run --- --- echo asdf --- take-dir "$temp_dir1" ../. dropdir;
    assert_failure;
	refute_output --partial asdf;
	
	run brrssh run --- --- echo asdf --- take-dir "$temp_dir1" ../.. dropdir;
    assert_failure;
	refute_output --partial asdf;

	run brrssh run --- --- echo qwer --- take-dir "$temp_dir1" asdf/asdf dropdir;
    assert_failure;
	refute_output --partial qwer;
}

@test "pushing empty directory works" {
	mkdir "$temp_dir1/asdf";
	run brrssh run -f - <<SCRIPT;
take-dir $(printf %q "$temp_dir1/asdf") "" drop2
host localhost [
	drop-dir drop2 $(printf %q "$temp_dir2")
]
SCRIPT
	assert_success;

	run [ -d "$temp_dir2/asdf" ];
	assert_success;
}

@test "pulling empty directory works" {
	mkdir "$temp_dir1/asdf";
	run brrssh run -f - <<SCRIPT;
drop-dir drop2 $(printf %q "$temp_dir2")
host localhost [
	take-dir $(printf %q "$temp_dir1/asdf") "" drop2
]
SCRIPT
	assert_success;

	run [ -d "$temp_dir2/asdf" ];
	assert_success;
}

@test "useless take-dirs are successful" {
	run brrssh run --- take-dir "$temp_dir1" "" drop1;
	assert_success;

	run brrssh run --- take-dir "$temp_dir1" "" drop1 drop-dir drop2 "$temp_dir2";
	assert_success;
}

@test "directory pulling without renaming works" {
	cp /bin/cat "$temp_dir1/.";
	run brrssh run -f - <<SCRIPT;
cd $(printf %q "$temp_dir2")
drop-dir maindrop .
host localhost [
	host localhost [
		take-dir $(printf %q "$temp_dir1") "" maindrop
		--- echo asdf ---
	]
]
SCRIPT
	assert_success;
	assert_output --partial asdf;

	run [ -f "$temp_dir2/$(basename "$temp_dir1")/cat" ];
	assert_success;

	run compare_md5 "$temp_dir1/cat" "$temp_dir2/$(basename "$temp_dir1")/cat";
	assert_success;
}

@test "directory pushing without renaming works" {
	cp /bin/cat "$temp_dir1/.";
	run brrssh run -f - <<SCRIPT;
take-dir $(printf %q "$temp_dir1") "" maindrop
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

	run [ -f "$temp_dir2/$(basename "$temp_dir1")/cat" ];
	assert_success;

	run compare_md5 "$temp_dir1/cat" "$temp_dir2/$(basename "$temp_dir1")/cat";
	assert_success;
}

@test "a name must be provided if source directory is called . or .. 1" {
	mkdir "$temp_dir1/asdf";
	cp /bin/grep "$temp_dir1/asdf/.";
	run brrssh run -f - <<SCRIPT;
--- echo echo ---
drop-dir drop2 $(printf %q "$temp_dir2")
host localhost [
	cd $(printf %q "$temp_dir1/asdf")
	take-dir . "" drop2
]
SCRIPT
	assert_failure;
	refute_output --partial echo;
}

@test "a name must be provided if source directory is called . or .. 2" {
	mkdir "$temp_dir1/asdf";
	cp /bin/grep "$temp_dir1/asdf/.";
	run brrssh run -f - <<SCRIPT;
--- echo echo ---
drop-dir drop2 $(printf %q "$temp_dir2")
host localhost [
	cd $(printf %q "$temp_dir1/asdf")
	take-dir . qwer drop2
]
SCRIPT
	assert_success;
	assert_output --partial echo;

	run [ -f "$temp_dir2/qwer/grep" ];
	assert_success;

	run compare_md5 /bin/grep "$temp_dir2/qwer/grep";
	assert_success;
}

@test "a name must be provided if source directory is called . or .. 3" {
	mkdir "$temp_dir1/asdf";
	cp /bin/grep "$temp_dir1/asdf/.";
	run brrssh run -f - <<SCRIPT;
--- echo echo ---
drop-dir drop2 $(printf %q "$temp_dir2")
host localhost [
	cd $(printf %q "$temp_dir1/asdf")
	take-dir .. "" drop2
]
SCRIPT
	assert_failure;
	refute_output --partial echo;
}

@test "a name must be provided if source directory is called . or .. 4" {
	mkdir "$temp_dir1/asdf";
	cp /bin/grep "$temp_dir1/asdf/.";
	run brrssh run -f - <<SCRIPT;
--- echo echo ---
drop-dir drop2 $(printf %q "$temp_dir2")
host localhost [
	cd $(printf %q "$temp_dir1/asdf")
	take-dir .. qwer drop2
]
SCRIPT
	assert_success;
	assert_output --partial echo;

	run [ -f "$temp_dir2/qwer/asdf/grep" ];
	assert_success;

	run compare_md5 /bin/grep "$temp_dir2/qwer/asdf/grep";
	assert_success;
}

@test "directory transfers on the same host 1" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
host localhost [
	drop-dir drop2 $(printf %q "$temp_dir2")
	take-dir $(printf %q "$temp_dir1/mydir") "" drop2
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;
	
	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;
}

@test "directory transfers on the same host 2" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
host localhost [
	drop-dir drop2 $(printf %q "$temp_dir2")
	[
		take-dir $(printf %q "$temp_dir1/mydir") "" drop2
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;
	
	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;
}

@test "directory transfers on the same host 3" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
host localhost [
	drop-dir drop2 $(printf %q "$temp_dir2")
	[
		[
			take-dir $(printf %q "$temp_dir1/mydir") "" drop2
		]
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;
}

@test "directory transfers on the same host 4" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
host localhost [
	take-dir $(printf %q "$temp_dir1/mydir") "" drop2
	[
		drop-dir drop2 $(printf %q "$temp_dir2")
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;
}

@test "directory transfers on the same host 5" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
host localhost [
	take-dir $(printf %q "$temp_dir1/mydir") "" drop2
	[
		[
			drop-dir drop2 $(printf %q "$temp_dir2")
		]
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;
}

@test "directory transfers on the same host 6" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
drop-dir drop2 $(printf %q "$temp_dir2")
take-dir $(printf %q "$temp_dir1/mydir") "" drop2
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;
}

@test "directory transfers on the same host 7" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
take-dir $(printf %q "$temp_dir1/mydir") "" drop2
drop-dir drop2 $(printf %q "$temp_dir2")
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;
}


@test "various directory forwarding scenario 1" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh --fake-su run -f - <<SCRIPT;
take-dir $(printf %q "$temp_dir1/mydir") "" drop2
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

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;
}

@test "various directory forwarding scenario 2" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
take-dir $(printf %q "$temp_dir1/mydir") '' anydrop
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir2")
	drop-dir anydrop $(printf %q "$temp_dir3")
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;

	run [ -f "$temp_dir3/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir3/mydir/grep";
	assert_success;
}

@test "various directory forwarding scenario 3" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
take-dir $(printf %q "$temp_dir1/mydir") '' anydrop
host localhost [
	host localhost [
		drop-dir anydrop $(printf %q "$temp_dir2")
	]
	host localhost [
		drop-dir anydrop $(printf %q "$temp_dir3")
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;

	run [ -f "$temp_dir3/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir3/mydir/grep";
	assert_success;
}


@test "various directory forwarding scenario 4" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
take-dir $(printf %q "$temp_dir1/mydir") '' anydrop
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir2")
	host localhost [
		drop-dir anydrop $(printf %q "$temp_dir3")
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;

	run [ -f "$temp_dir3/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir3/mydir/grep";
	assert_success;
}

@test "various directory pulling scenario 1" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh --fake-su run -f - <<SCRIPT;
drop-dir drop2 $(printf %q "$temp_dir2")
[
	[
		host localhost [
			[
				host localhost [
					host localhost [
						su charles [
							su charles [
								take-dir $(printf %q "$temp_dir1/mydir") "" drop2
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

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;
}

@test "various directory pulling scenario 2" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
drop-dir anydrop $(printf %q "$temp_dir2")
drop-dir anydrop $(printf %q "$temp_dir3")
host localhost [
	take-dir $(printf %q "$temp_dir1/mydir") '' anydrop
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;

	run [ -f "$temp_dir3/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir3/mydir/grep";
	assert_success;
}

@test "various directory pulling scenario 3" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir2")
	drop-dir anydrop $(printf %q "$temp_dir3")
	host localhost [
		take-dir $(printf %q "$temp_dir1/mydir") '' anydrop
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;

	run [ -f "$temp_dir3/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir3/mydir/grep";
	assert_success;
}

@test "various directory pulling scenario 4" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
drop-dir anydrop $(printf %q "$temp_dir2")
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir3")
	host localhost [
		take-dir $(printf %q "$temp_dir1/mydir") '' anydrop
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;

	run [ -f "$temp_dir3/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir3/mydir/grep";
	assert_success;
}

@test "bidirectionnal directory transfer" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
drop-dir anydrop $(printf %q "$temp_dir2")
host localhost [
	take-dir $(printf %q "$temp_dir1/mydir") '' anydrop
	host localhost [
		drop-dir anydrop $(printf %q "$temp_dir3")
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir2/mydir/grep";
	assert_success;

	run [ -f "$temp_dir3/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir3/mydir/grep";
	assert_success;
}

@test "conditionnal take-dir and drops 1" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
host localhost [
	try false and drop-dir anydrop $(printf %q "$temp_dir2")
	drop-dir anydrop $(printf %q "$temp_dir3")
	host localhost [
		take-dir $(printf %q "$temp_dir1/mydir") '' anydrop
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_failure;

	run [ -f "$temp_dir3/mydir/grep" ];
	assert_success;

	run compare_md5 "$temp_dir1/mydir/grep" "$temp_dir3/mydir/grep";
	assert_success;
}

@test "conditionnal take-dir and drops 2" {
	mkdir "$temp_dir1/mydir";
	cp /bin/grep "$temp_dir1/mydir/.";
	run brrssh run -f - <<SCRIPT;
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir2")
	drop-dir anydrop $(printf %q "$temp_dir3")
	host localhost [
		false and take-dir $(printf %q "$temp_dir1/mydir") '' anydrop or --- echo QWER ---
	]
]
SCRIPT
	assert_success;
	assert_output --partial QWER;

	run [ -f "$temp_dir2/mydir/grep" ];
	assert_failure;

	run [ -f "$temp_dir3/mydir/grep" ];
	assert_failure;
}


















