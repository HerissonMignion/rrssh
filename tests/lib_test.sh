



brrssh() {
	if [ -n "$RRSSH_BASH_EXE" ]; then
		"$RRSSH_BASH_EXE" "$(which rrssh)" "$@";
	else
		rrssh "$@";
	fi;
}




