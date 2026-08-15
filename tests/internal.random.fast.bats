#!/bin/bash

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;
	. "$BATS_TEST_DIRNAME/lib_test.sh";
}

teardown() {
	true;
}



@test "rrssh's kernel-inner-function mode works" {
	run brrssh kernel-inner-function -- exit 6;
	assert_failure 6;
	
	run brrssh kernel-inner-function -- exit 0;
	assert_success;

	run brrssh kernel-inner-function -- echo asdf;
	assert_success;
	assert_output asdf;
}

@test "sanitize_path works" {
	run brrssh kernel-inner-function -- sanitize_path "";
	assert_failure;
	refute_output --partial /;
	
	run brrssh kernel-inner-function -- sanitize_path /;
	assert_success;
	assert_output /;

	run brrssh kernel-inner-function -- sanitize_path ///////////////;
	assert_success;
	assert_output /;

	run brrssh kernel-inner-function -- sanitize_path ///////////////asdf;
	assert_success;
	assert_output /asdf;

	run brrssh kernel-inner-function -- sanitize_path asdf;
	assert_success;
	assert_output asdf;
    
}

@test "bash_realpath works" {
	run brrssh kernel-inner-function -- bash_realpath /usr/share/man;
	assert_success;
	assert_output /usr/share/man;

	run brrssh kernel-inner-function -- bash_realpath /usr/share/man/..;
	assert_success;
	assert_output /usr/share;

	run brrssh kernel-inner-function -- bash_realpath /usr/share/man/..///;
	assert_success;
	assert_output /usr/share;

	run brrssh kernel-inner-function -- bash_realpath /usr////share/man/..///;
	assert_success;
	assert_output /usr/share;

	# TODO: make this testable with the intended bash executable for
	# the root command.
	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath .";
	assert_success;
	assert_output /usr/share;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath ../././.";
	assert_success;
	assert_output /usr;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /man";
	assert_success;
	assert_output /man;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath man";
	assert_success;
	assert_output /usr/share/man;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath ./man";
	assert_success;
	assert_output /usr/share/man;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath ./man/.";
	assert_success;
	assert_output /usr/share/man;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath ./man/..";
	assert_success;
	assert_output /usr/share;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath ../man";
	assert_success;
	assert_output /usr/man;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /";
	assert_success;
	assert_output /;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /.";
	assert_success;
	assert_output /;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /..";
	assert_success;
	assert_output /;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /../";
	assert_success;
	assert_output /;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /../.";
	assert_success;
	assert_output /;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /../..";
	assert_success;
	assert_output /;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /./";
	assert_success;
	assert_output /;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /./.";
	assert_success;
	assert_output /;

	run bash -c "cd /usr/share; rrssh kernel-inner-function -- bash_realpath /./..";
	assert_success;
	assert_output /;
}









