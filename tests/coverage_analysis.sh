#!/bin/bash

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd);
cd "$SCRIPT_DIR";



main() {
	local coverage_file=$(mktemp);
	export RRSSH_COVERAGE_FILE="$coverage_file";

	../with-path.sh bats *.fast.bats;

	grep -Po '\b(pipeline_)?coverage id_[a-zA-Z0-9_\-]+\b' ../rrssh | awk '{ print $2; }' |
		while IFS="" read -r line || [ -n "$line" ]; do
			grep -xFq "$line" "$coverage_file" || {
				echo "Not found: $line";
			};

		done;

	rm -f "$coverage_file";
}

main "$@";
