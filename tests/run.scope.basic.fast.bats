#!/bin/bash


setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

	temp_file1=$(mktemp);
}

teardown() {
	rm -f "$temp_file1";
}



@test "an empty scope is successful" {
	run rrssh run --- [ ];
	assert_success;

	run rrssh run --- host localhost [ ];
	assert_success;

	run rrssh run --fake-su --- su charles [ ];
	assert_success;
}



@test "rrssh returns the failing command's exit code 1" {
	run rrssh run --- --- exit 0 ---;
	assert_success;

	run rrssh run --- --- exit 4 ---;
	assert_failure 4;

	run rrssh run --- --- exit 3 --- --- exit 5 ---;
	assert_failure 3;

	run rrssh run --- not --- exit 3 --- --- exit 5 ---;
	assert_failure 5;

	run rrssh run --- --- exit 7 --- and --- exit 3 ---;
	assert_failure 7;

	run rrssh run --- [ --- exit 7 --- ] and --- exit 3 ---;
	assert_failure 7;

	run rrssh run --- [ --- exit 7 --- ] or --- exit 3 ---;
	assert_failure 3;
}

@test "rrssh returns the failing command's exit code 2" {
	run rrssh run --- [ [ [ [ --- exit 4 --- ] ] ] ];
	assert_failure 4;

	run rrssh run --- [ [ --- exit 3 --- ] ] and host localhost [ [ [ --- exit 7 --- ] ] ];
	assert_failure 3;
}

@test "an empty argument does not end the root scope" {
	run rrssh run --- --- echo asdf --- "" --- echo qwer ---;
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- [ --- echo asdf --- "" --- echo qwer --- ];
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;

	run rrssh run --- host localhost [ --- echo asdf --- "" --- echo qwer --- ];
	assert_failure;
	refute_output --partial asdf;
	refute_output --partial qwer;
}

@test "host/su command : form, syntax" {
	run rrssh run --- :;
	assert_failure;

	run rrssh run --- host localhost :;
	assert_success;

	run rrssh run --- host localhost : :;
	assert_failure;

	run rrssh run --- --- echo asdf --- host localhost : "[";
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- "[" host localhost : "[";
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- [ host localhost : "[" ];
	assert_failure;
	refute_output --partial asdf;

	run rrssh run --- --- echo asdf --- [ host localhost : [ ] --- echo qwer --- ];
	assert_success;
	assert_output --partial asdf;

	run rrssh run --- [ host localhost : ];
	assert_success;

	run rrssh run --- [ host localhost : ] [ host localhost : ] [ host localhost : ];
	assert_success;

	run rrssh run --- [ host localhost : ] [ host localhost : ] "[" host localhost : [ host localhost : ];
	assert_failure;

	run rrssh run --- [ host localhost : host localhost : host localhost [ host localhost : ] ];
	assert_success;



	
	run rrssh --fake-su run --- :;
	assert_failure;

	run rrssh --fake-su run --- su charles :;
	assert_success;

	run rrssh --fake-su run --- su charles : :;
	assert_failure;

	run rrssh --fake-su run --- --- echo asdf --- su charles : "[";
	assert_failure;
	refute_output --partial asdf;

	run rrssh --fake-su run --- --- echo asdf --- "[" su charles : "[";
	assert_failure;
	refute_output --partial asdf;

	run rrssh --fake-su run --- --- echo asdf --- [ su charles : "[" ];
	assert_failure;
	refute_output --partial asdf;

	run rrssh --fake-su run --- --- echo asdf --- [ su charles : [ ] --- echo qwer --- ];
	assert_success;
	assert_output --partial asdf;

	run rrssh --fake-su run --- [ su charles : ];
	assert_success;

	run rrssh --fake-su run --- [ su charles : ] [ su charles : ] [ su charles : ];
	assert_success;

	run rrssh --fake-su run --- [ su charles : ] [ su charles : ] "[" su charles : [ su charles : ];
	assert_failure;

	run rrssh --fake-su run --- [ su charles : su charles : su charles [ su charles : ] ];
	assert_success;
}

@test "host/su : command form, scope boundaries are correct" {
	run rrssh run --- cd /tmp host localhost : pwd;
	assert_success;
	refute_output --partial tmp;

	run rrssh run --- cd /tmp host localhost [ pwd ];
	assert_success;
	refute_output --partial tmp;

	run rrssh run --- cd /tmp host localhost [ cd / true ] pwd;
	assert_success;
	assert_output --partial tmp;

	run rrssh run --- cd /tmp host localhost : [ cd / true ] pwd;
	assert_success;
	refute_output --partial tmp;

	run rrssh run --- cd / host localhost : cd /tmp [ cd / true ] pwd;
	assert_success;
	assert_output --partial tmp;

	run rrssh run --- cd / host localhost : cd /tmp host localhost [ cd / true ] pwd;
	assert_success;
	assert_output --partial tmp;

	run rrssh run --- cd / host localhost : cd /tmp host localhost : [ cd / true ] pwd;
	assert_success;
	refute_output --partial tmp;
}

@test "host command's landing error paths are working" {
	run rrssh run -f - <<"SCRIPT";
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
	
	run rrssh run -f - <<"SCRIPT";
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
	
	run rrssh run -f - <<"SCRIPT";
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
	run rrssh --fake-su run -f - <<"SCRIPT";
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
	
	run rrssh --fake-su run -f - <<"SCRIPT";
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
	
	run rrssh --fake-su run -f - <<"SCRIPT";
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
	run rrssh run -f - <<"SCRIPT";
[
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_success;
	assert_output --partial asdf;

	run rrssh -p run -f - <<"SCRIPT";
[
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_failure 7;
	refute_output --partial asdf;

	
	run rrssh run -f - <<"SCRIPT";
host localhost [
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_success;
	assert_output --partial asdf;

	run rrssh -p run -f - <<"SCRIPT";
host localhost [
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_failure 7;
	refute_output --partial asdf;

	
	run rrssh --fake-su run -f - <<"SCRIPT";
su charles [
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_success;
	assert_output --partial asdf;

	run rrssh --fake-su -p run -f - <<"SCRIPT";
su charles [
	--- exit 7 ---
] or --- echo asdf ---
SCRIPT
	assert_failure 7;
	refute_output --partial asdf;

}

@test "host command's landing error paths triggers a panic" {
	run rrssh run -f - <<"SCRIPT";
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

	run rrssh run -f - <<"SCRIPT";
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

	run rrssh run -f - <<"SCRIPT";
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
	run rrssh --fake-su run -f - <<"SCRIPT";
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

	run rrssh --fake-su run -f - <<"SCRIPT";
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

	run rrssh --fake-su run -f - <<"SCRIPT";
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
	run rrssh -i run -f - <<"SCRIPT";
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

	run rrssh -i run -f - <<"SCRIPT";
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

	run rrssh -i run -f - <<"SCRIPT";
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
	run rrssh --fake-su -i run -f - <<"SCRIPT";
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

	run rrssh --fake-su -i run -f - <<"SCRIPT";
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

	run rrssh --fake-su -i run -f - <<"SCRIPT";
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
















