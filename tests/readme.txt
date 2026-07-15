

I run all these tests by cd-ing in this directory and running:
../with-path.sh bats *.bats


On my distro (ubuntu), i need the packages "bats" and "bats-assert". i
also installed "bats-support" in case it's somewhat usefull, i dont
know.

To run the tests, the openssh server must be installed on the machine
and push your ssh key to yourself on your machine with the command
ssh-copy-id localhost.

To run the tests, rrssh must be in your PATH.



These are ran once before and after each test case in the file.  We
can assign temp dir paths to variables and they will be accessible
inside the test cases.

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;

	# create temp directory, for ex.
}

teardown() {
	true;
	# remove temp directory
}




assert_success
assert_failure
assert_failure 7
assert_output --partial something
refure_output --partial something







