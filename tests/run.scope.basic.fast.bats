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



@test "an empty scope is successful" {
	run brrssh run --- [ ];
	assert_success;

	run brrssh run --- host localhost [ ];
	assert_success;

	run brrssh run --fake-su --- su charles [ ];
	assert_success;
}



@test "rrssh returns the failing command's exit code 1" {
	run brrssh run --- --- exit 0 ---;
	assert_success;

	run brrssh run --- --- exit 4 ---;
	assert_failure 4;

	run brrssh run --- --- exit 3 --- --- exit 5 ---;
	assert_failure 3;

	run brrssh run --- not --- exit 3 --- --- exit 5 ---;
	assert_failure 5;

	run brrssh run --- --- exit 7 --- and --- exit 3 ---;
	assert_failure 7;

	run brrssh run --- [ --- exit 7 --- ] and --- exit 3 ---;
	assert_failure 7;

	run brrssh run --- [ --- exit 7 --- ] or --- exit 3 ---;
	assert_failure 3;
}

@test "rrssh returns the failing command's exit code 2" {
	run brrssh run --- [ [ [ [ --- exit 4 --- ] ] ] ];
	assert_failure 4;

	run brrssh run --- [ [ --- exit 3 --- ] ] and host localhost [ [ [ --- exit 7 --- ] ] ];
	assert_failure 3;
}

@test "an empty argument does not end the root scope" {
	run brrssh run --- --- echo asdf --- "" --- echo qwer ---;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run brrssh run --- [ --- echo asdf --- "" --- echo qwer --- ];
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run brrssh run --- host localhost [ --- echo asdf --- "" --- echo qwer --- ];
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;
}

@test "host/su command : form, syntax" {
	run brrssh run --- :;
	assert_failure;

	run brrssh run --- host localhost :;
	assert_success;

	run brrssh run --- host localhost : :;
	assert_failure;

	run brrssh run --- --- echo asdf --- host localhost : "[";
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- --- echo asdf --- "[" host localhost : "[";
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- --- echo asdf --- [ host localhost : "[" ];
	assert_failure;
	refute_output --partial asdf;

	run brrssh run --- --- echo asdf --- [ host localhost : [ ] --- echo qwer --- ];
	assert_success;
	assert_output --partial asdf;

	run brrssh run --- [ host localhost : ];
	assert_success;

	run brrssh run --- [ host localhost : ] [ host localhost : ] [ host localhost : ];
	assert_success;

	run brrssh run --- [ host localhost : ] [ host localhost : ] "[" host localhost : [ host localhost : ];
	assert_failure;

	run brrssh run --- [ host localhost : host localhost : host localhost [ host localhost : ] ];
	assert_success;



	
	run brrssh --fake-su run --- :;
	assert_failure;

	run brrssh --fake-su run --- su charles :;
	assert_success;

	run brrssh --fake-su run --- su charles : :;
	assert_failure;

	run brrssh --fake-su run --- --- echo asdf --- su charles : "[";
	assert_failure;
	refute_output --partial asdf;

	run brrssh --fake-su run --- --- echo asdf --- "[" su charles : "[";
	assert_failure;
	refute_output --partial asdf;

	run brrssh --fake-su run --- --- echo asdf --- [ su charles : "[" ];
	assert_failure;
	refute_output --partial asdf;

	run brrssh --fake-su run --- --- echo asdf --- [ su charles : [ ] --- echo qwer --- ];
	assert_success;
	assert_output --partial asdf;

	run brrssh --fake-su run --- [ su charles : ];
	assert_success;

	run brrssh --fake-su run --- [ su charles : ] [ su charles : ] [ su charles : ];
	assert_success;

	run brrssh --fake-su run --- [ su charles : ] [ su charles : ] "[" su charles : [ su charles : ];
	assert_failure;

	run brrssh --fake-su run --- [ su charles : su charles : su charles [ su charles : ] ];
	assert_success;
}

@test "host/su : command form, scope boundaries are correct" {
	run brrssh run --- cd /tmp host localhost : pwd;
	assert_success;
	refute_output --partial tmp;

	run brrssh run --- cd /tmp host localhost [ pwd ];
	assert_success;
	refute_output --partial tmp;

	run brrssh run --- cd /tmp host localhost [ cd / true ] pwd;
	assert_success;
	assert_output --partial tmp;

	run brrssh run --- cd /tmp host localhost : [ cd / true ] pwd;
	assert_success;
	refute_output --partial tmp;

	run brrssh run --- cd / host localhost : cd /tmp [ cd / true ] pwd;
	assert_success;
	assert_output --partial tmp;

	run brrssh run --- cd / host localhost : cd /tmp host localhost [ cd / true ] pwd;
	assert_success;
	assert_output --partial tmp;

	run brrssh run --- cd / host localhost : cd /tmp host localhost : [ cd / true ] pwd;
	assert_success;
	refute_output --partial tmp;
}

@test "host command's landing error paths are working" {
	run brrssh run -f - <<"SCRIPT";
host localhost [
	host localhost [
		--- echo asdf ---
		make-command-fail id_nuirhienvfh
		host localhost [
			--- echo qwer ---
		]
		--- echo ffgf ---
	]
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;
	
	run brrssh run -f - <<"SCRIPT";
host localhost [
	host localhost [
		--- echo asdf ---
		make-command-fail id_fdhv9qh5gf
		host localhost [
			--- echo qwer ---
		]
		--- echo ffgf ---
	]
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;
	
	run brrssh run -f - <<"SCRIPT";
host localhost [
	host localhost [
		--- echo asdf ---
		make-command-fail id_asudhfisuh
		host localhost [
			--- echo qwer ---
		]
		--- echo ffgf ---
	]
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;

}


@test "su command's landing error paths are working" {
	run brrssh --fake-su run -f - <<"SCRIPT";
host localhost [
	host localhost [
		--- echo asdf ---
		make-command-fail id_nuirhienvfh
		su charles [
			--- echo qwer ---
		]
		--- echo ffgf ---
	]
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;
	
	run brrssh --fake-su run -f - <<"SCRIPT";
host localhost [
	host localhost [
		--- echo asdf ---
		make-command-fail id_fdhv9qh5gf
		su charles [
			--- echo qwer ---
		]
		--- echo ffgf ---
	]
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;
	
	run brrssh --fake-su run -f - <<"SCRIPT";
host localhost [
	host localhost [
		--- echo asdf ---
		make-command-fail id_asudhfisuh
		su charles [
			--- echo qwer ---
		]
		--- echo ffgf ---
	]
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;
}

@test "-p makes rrssh panic on any failing command chain" {
	run brrssh run -f - <<"SCRIPT";
[
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_success;
	assert_output --partial asdf;

	run brrssh -p run -f - <<"SCRIPT";
[
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_failure 7;
	refute_output --partial asdf;

	
	run brrssh run -f - <<"SCRIPT";
host localhost [
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_success;
	assert_output --partial asdf;

	run brrssh -p run -f - <<"SCRIPT";
host localhost [
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_failure 7;
	refute_output --partial asdf;

	
	run brrssh --fake-su run -f - <<"SCRIPT";
su charles [
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_success;
	assert_output --partial asdf;

	run brrssh --fake-su -p run -f - <<"SCRIPT";
su charles [
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_failure 7;
	refute_output --partial asdf;

}

@test "host command's landing error paths triggers a panic" {
	run brrssh run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_nuirhienvfh
	host localhost [
		--- echo qwer ---
	] or --- echo ffgf ---
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;

	run brrssh run -f - <<"SCRIPT";
try host localhost [
	--- echo asdf ---
	make-command-fail id_fdhv9qh5gf
	try host localhost [
		--- echo qwer ---
	] or --- echo ffgf ---
] or true
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;

	run brrssh run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_asudhfisuh
	host localhost [
		--- echo qwer ---
	] or --- echo ffgf ---
] or --- echo rrtr ---
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;
	refute_output --partial rrtr;
}



@test "su command's landing error paths triggers a panic" {
	run brrssh --fake-su run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_nuirhienvfh
	su charles [
		--- echo qwer ---
	] or --- echo ffgf ---
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;

	run brrssh --fake-su run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_fdhv9qh5gf
	su charles [
		--- echo qwer ---
	] or --- echo ffgf ---
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;

	run brrssh --fake-su run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_asudhfisuh
	su charles [
		--- echo qwer ---
	] or --- echo ffgf ---
]
SCRIPT
	assert_failure;
	assert_output --partial asdf;
	refute_output --partial qwer;
	refute_output --partial ffgf;
}

@test "-i makes host command not panic on landing failure" {
	run brrssh -i run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_nuirhienvfh
	host localhost [
		--- echo qwer ---
	] or --- echo ffgf ---
]
SCRIPT
	assert_success;
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;

	run brrssh -i run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_fdhv9qh5gf
	host localhost [
		--- echo qwer ---
	] or --- echo ffgf ---
]
SCRIPT
	assert_success;
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;

	run brrssh -i run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_asudhfisuh
	host localhost [
		--- echo qwer ---
	] or --- echo ffgf ---
]
SCRIPT
	assert_success;
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;
}

@test "-i makes su command not panic on landing failure" {
	run brrssh --fake-su -i run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_nuirhienvfh
	su charles [
		--- echo qwer ---
	] or --- echo ffgf ---
]
SCRIPT
	assert_success;
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;

	run brrssh --fake-su -i run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_fdhv9qh5gf
	su charles [
		--- echo qwer ---
	] or --- echo ffgf ---
] or --- echo rrtr ---
SCRIPT
	assert_success;
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;
	refute_output --partial rrtr;

	run brrssh --fake-su -i run -f - <<"SCRIPT";
host localhost [
	--- echo asdf ---
	make-command-fail id_asudhfisuh
	su charles [
		--- echo qwer ---
	] or --- echo ffgf ---
]
SCRIPT
	assert_success;
	assert_output --partial asdf;
	refute_output --partial qwer;
	assert_output --partial ffgf;
}















