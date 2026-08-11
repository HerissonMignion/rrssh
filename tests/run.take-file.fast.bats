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

compare_md5() {
	local file1=$1;
	local file2=$2;
	local file1md5=$(md5sum -- "$file1" | awk '{ print $1; }');
	local file2md5=$(md5sum -- "$file2" | awk '{ print $1; }');
	[ "$file1md5" == "$file2md5" ];
}

@test "relative dropdirs are stored as absolute path" {
	cp /bin/grep "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
--- mkdir -p $(printf %q "$temp_dir2/dir/dir") ---
host localhost [
	cd $(printf %q "$temp_dir2")
	drop-dir drop2 ./dir
	cd dir
	take-file $(printf %q "$temp_dir1/grep") "" drop2
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/dir/grep" ];
	assert_success;

	run [ -f "$temp_dir2/dir/dir/grep" ];
	assert_failure;
}

@test "the test suite's compare_md5 function works" {
	run compare_md5 /bin/bash /bin/bash;
	assert_success;

	run compare_md5 /bin/bash /bin/grep;
	assert_failure;
}

@test "new file names are validated before execution starts" {
	run rrssh run --- --- echo asdf --- take-file /bin/bash . dropdir;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- take-file /bin/bash .. dropdir;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- take-file /bin/bash ../ dropdir;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- take-file /bin/bash ../. dropdir;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- take-file /bin/bash ../.. dropdir;
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo qwer --- take-file /bin/bash asdf/asdf dropdir;
	assert_failure;
	refute_output --partial qwer;
}

@test "pushing empty files works" {
	touch "$temp_dir1/asdf.txt";
	run rrssh run -f - <<SCRIPT;
take-file $(printf %q "$temp_dir1/asdf.txt") "" drop2
host localhost [
	drop-dir drop2 $(printf %q "$temp_dir2")
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/asdf.txt" ];
	assert_success;

	run compare_md5 "$temp_dir1/asdf.txt" "$temp_dir2/asdf.txt";
	assert_success;
}

@test "pulling empty files works" {
	touch "$temp_dir1/asdf.txt";
	run rrssh run -f - <<SCRIPT;
drop-dir drop2 $(printf %q "$temp_dir2")
host localhost [
	take-file $(printf %q "$temp_dir1/asdf.txt") "" drop2
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/asdf.txt" ];
	assert_success;

	run compare_md5 "$temp_dir1/asdf.txt" "$temp_dir2/asdf.txt";
	assert_success;
}

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

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
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

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
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
	
	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
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
	
	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
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

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
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

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
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

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
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

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
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

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
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

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
	assert_success;
}

@test "various file forwarding scenario 2" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
take-file $(printf %q "$temp_dir1/bash") '' anydrop
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir2")
	drop-dir anydrop $(printf %q "$temp_dir3")
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
	assert_success;

	run [ -f "$temp_dir3/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir3/bash";
	assert_success;
}

@test "various file forwarding scenario 3" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
take-file $(printf %q "$temp_dir1/bash") '' anydrop
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

	run [ -f "$temp_dir2/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
	assert_success;

	run [ -f "$temp_dir3/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir3/bash";
	assert_success;
}

@test "various file forwarding scenario 4" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
take-file $(printf %q "$temp_dir1/bash") '' anydrop
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir2")
	host localhost [
		drop-dir anydrop $(printf %q "$temp_dir3")
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
	assert_success;

	run [ -f "$temp_dir3/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir3/bash";
	assert_success;
}




@test "various file pulling scenario 1" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh --fake-su run -f - <<SCRIPT;
drop-dir drop2 $(printf %q "$temp_dir2")
[
	[
		host localhost [
			[
				host localhost [
					host localhost [
						su charles [
							su charles [
								take-file $(printf %q "$temp_dir1/bash") "" drop2
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

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
	assert_success;
}

@test "various file pulling scenario 2" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
drop-dir anydrop $(printf %q "$temp_dir2")
drop-dir anydrop $(printf %q "$temp_dir3")
host localhost [
	take-file $(printf %q "$temp_dir1/bash") '' anydrop
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
	assert_success;

	run [ -f "$temp_dir3/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir3/bash";
	assert_success;
}

@test "various file pulling scenario 3" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir2")
	drop-dir anydrop $(printf %q "$temp_dir3")
	host localhost [
		take-file $(printf %q "$temp_dir1/bash") '' anydrop
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
	assert_success;

	run [ -f "$temp_dir3/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir3/bash";
	assert_success;
}

@test "various file pulling scenario 4" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
drop-dir anydrop $(printf %q "$temp_dir2")
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir3")
	host localhost [
		take-file $(printf %q "$temp_dir1/bash") '' anydrop
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
	assert_success;

	run [ -f "$temp_dir3/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir3/bash";
	assert_success;
}

@test "bidirectionnal file transfer" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
drop-dir anydrop $(printf %q "$temp_dir2")
host localhost [
	take-file $(printf %q "$temp_dir1/bash") '' anydrop
	host localhost [
		drop-dir anydrop $(printf %q "$temp_dir3")
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir2/bash";
	assert_success;

	run [ -f "$temp_dir3/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir3/bash";
	assert_success;
}


@test "conditionnal take-file and drops 1" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
host localhost [
	try false and drop-dir anydrop $(printf %q "$temp_dir2")
	drop-dir anydrop $(printf %q "$temp_dir3")
	host localhost [
		take-file $(printf %q "$temp_dir1/bash") '' anydrop
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/bash" ];
	assert_failure;

	run [ -f "$temp_dir3/bash" ];
	assert_success;

	run compare_md5 "$temp_dir1/bash" "$temp_dir3/bash";
	assert_success;
}

@test "conditionnal take-file and drops 2" {
	cp /bin/bash "$temp_dir1/.";
	run rrssh run -f - <<SCRIPT;
host localhost [
	drop-dir anydrop $(printf %q "$temp_dir2")
	drop-dir anydrop $(printf %q "$temp_dir3")
	host localhost [
		false and take-file $(printf %q "$temp_dir1/bash") '' anydrop or --- echo QWER ---
	]
]
SCRIPT
	assert_success;
	assert_output --partial QWER;

	run [ -f "$temp_dir2/bash" ];
	assert_failure;

	run [ -f "$temp_dir3/bash" ];
	assert_failure;
}

@test "multiple file transfers are routed properly" {
	run rrssh run -f - <<SCRIPT;
take-file /bin/cat miaw drop2
drop-dir drop3 $(printf %q "$temp_dir3")
host localhost [
	take-file /bin/bash fav drop3
	take-file /bin/grep 'second      fav' drop2
	host localhost [
		drop-dir drop2 $(printf %q "$temp_dir2")
		take-file /bin/ls '' drop3
	]
]
SCRIPT
	assert_success;

	run [ -f "$temp_dir2/miaw" ];
	assert_success;
	run compare_md5 "/bin/cat" "$temp_dir2/miaw";
	assert_success;
	run [ -f "$temp_dir3/miaw" ];
	assert_failure;

	run [ -f "$temp_dir3/fav" ];
	assert_success;
	run compare_md5 "/bin/bash" "$temp_dir3/fav";
	assert_success;
	run [ -f "$temp_dir2/fav" ];
	assert_failure;
	
	run [ -f "$temp_dir2/second      fav" ];
	assert_success;
	run compare_md5 "/bin/grep" "$temp_dir2/second      fav";
	assert_success;
	run [ -f "$temp_dir3/second      fav" ];
	assert_failure;

	run [ -f "$temp_dir3/ls" ];
	assert_success;
	run compare_md5 "/bin/ls" "$temp_dir3/ls";
	assert_success;
	run [ -f "$temp_dir2/ls" ];
	assert_failure;
}









