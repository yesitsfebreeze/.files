require: checks.bash_32.exit equals 0

Every tracked bash script runs on macOS /bin/bash 3.2: no mapfile/readarray, associative arrays, case-folding expansions or &>>.
