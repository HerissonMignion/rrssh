#!/bin/bash

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;
}

teardown() {
	true;
}



@test "rrssh's kernel-inner-function mode works" {
	run rrssh kernel-inner-function -- exit 6;
	assert_failure 6;
	
	run rrssh kernel-inner-function -- exit 0;
	assert_success;

	run rrssh kernel-inner-function -- echo asdf;
	assert_success;
	assert_output asdf;
}

@test "sanitize_path works" {
	run rrssh kernel-inner-function -- sanitize_path "";
	assert_failure;
	refute_output --partial /;
	
	run rrssh kernel-inner-function -- sanitize_path /;
	assert_success;
	assert_output /;

	run rrssh kernel-inner-function -- sanitize_path ///////////////;
	assert_success;
	assert_output /;

	run rrssh kernel-inner-function -- sanitize_path ///////////////asdf;
	assert_success;
	assert_output /asdf;

	run rrssh kernel-inner-function -- sanitize_path asdf;
	assert_success;
	assert_output asdf;
	
	
	
}










