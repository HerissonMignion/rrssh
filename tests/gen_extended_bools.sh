#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd);



exec 3> "$SCRIPT_DIR/zzz.auto_generated.control_flow.extended.slow.bats";

echo3() {
	1>&3 echo "$@";
}

cat3() {
	1>&3 cat "$@";
}

echo3 "#!/bin/bash";

echo3;
cat3 <<"STUFF";

setup() {
	bats_load_library bats-support;
	bats_load_library bats-assert;
}

teardown() {
	true;
}

STUFF


translate() {
	local op=$1;
	case "$op" in
		(and)
			echo '&&';
			;;
		(or)
			echo '||';
			;;
		(not)
			echo '!';
			;;
		("")
			echo;
			;;
	esac;
}


translate2() {
	local part=$1;
	echo "$part";
	return 0;
	case "$part" in
		("true")
			echo true;
			;;
		("false")
			echo false;
			;;
		("not true")
			echo '! true';
			;;
		("not false")
			echo '! false';
			;;
	esac;
}


test_combo() {
	local op1=$1;
	local op2=$2;
	local op3=$3;

	echo3 '@test "'"auto_generated extended boolean control flow test $op1 $op2 $op3"'" {';

	local part1;
	local part2;
	local part3;
	local part4;
	local part_values=(true false "not true" "not false");
	local cmd;
	local rrssh_cmd;
	local rc;
	for part1 in "${part_values[@]}"; do
		for part2 in "${part_values[@]}"; do
			for part3 in "${part_values[@]}"; do
				for part4 in "${part_values[@]}"; do

					cmd="$(translate2 "$part1") $(translate "$op1") $(translate2 "$part2") $(translate "$op2") $(translate2 "$part3") $(translate "$op3") $(translate2 "$part4")";
					cmd=${cmd//'not'/'!'};

					# echo "$cmd";
					(eval "$cmd");
					rc=$?;
					# echo $?;

					echo3 $'\t'"run rrssh run --- $part1 $op1 $part2 $op2 $part3 $op3 $part4;";
					if ((rc == 0)); then
						echo3 $'\t'"assert_success;";
					else
						echo3 $'\t'"assert_failure;";
					fi;

				done;
			done;
		done;
	done;
	

	echo3 '}';
	echo3;
	
}





for op1 in and or; do
	for op2 in and or; do
		for op3 in and or; do
			test_combo "$op1" "$op2" "$op3";
		done;
	done;
done;





