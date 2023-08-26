#!/bin/bash
# by https://github.com/spiritLHLS/ecs
# by spiritlhls
# 2023.04.12

# determine architecture of host
ARCH=$(uname -m)
if [[ $ARCH = *x86_64* ]]; then
	# host is running a 64-bit kernel
	ARCH="x64"
elif [[ $ARCH = *i?86* ]]; then
	# host is running a 32-bit kernel
	ARCH="x86"
elif [[ $ARCH = *aarch* || $ARCH = *arm* ]]; then
	KERNEL_BIT=$(getconf LONG_BIT)
	if [[ $KERNEL_BIT = *64* ]]; then
		# host is running an ARM 64-bit kernel
		ARCH="aarch64"
	else
		# host is running an ARM 32-bit kernel
		ARCH="arm"
	fi
	echo -e "\nARM compatibility is considered *experimental*"
else
	# host is running a non-supported kernel
	echo -e "Architecture not supported."
	exit 1
fi

[[ $ARCH = *aarch64* || $ARCH = *arm* ]] && MY_GEEKBENCH_DOWNLOAD_URL="https://cdn.geekbench.com/Geekbench-6.0.2-LinuxARMPreview.tar.gz" || MY_GEEKBENCH_DOWNLOAD_URL="https://cdn.geekbench.com/Geekbench-6.0.2-Linux.tar.gz"
MY_DIR="$HOME/gb6"
MY_GITHUB_API_TOKEN=""
MY_GITHUB_API_JSON="$MY_DIR/github-gist.json"
MY_GITHUB_API_LOG="$MY_DIR/github-gist.log"
MY_OUTPUT="$MY_DIR/output.html"
MY_GEEKBENCH_EMAIL=""
MY_GEEKBENCH_KEY=""
rm -rf "$MY_OUTPUT" Geekbench* gb5* geekbench.tar.gz*
#####################################################################
#### END Configuration Section
#####################################################################

ME=$(basename "$0")
MY_DATE_TIME=$(date -u "+%Y-%m-%d %H:%M:%S")
MY_DATE_TIME+=" UTC"
MY_TIMESTAMP_START=$(date "+%s")
MY_GEEKBENCH_NO_UPLOAD=""

if [[ ! -d "$MY_DIR" ]]; then
	mkdir "$MY_DIR" || exit_with_failure "Could not create folder '$MY_DIR'"
fi

#####################################################################
# Terminal output helpers
#####################################################################

function usage {
	returnCode="$1"
	echo
	echo -e "Usage: 
	$ME [-e <EMAIL>] [-k <KEY>] [-n] [-h]"
	echo -e "Options:
	[-e <EMAIL>]\\t unlock Geekbench using EMAIL and KEY (default: $MY_GEEKBENCH_EMAIL)
	[-k <KEY>]\\t unlock Geekbench using EMAIL and KEY (default: $MY_GEEKBENCH_KEY)
	[-n]\\t\\t do not upload results to the Geekbench Browser (only if unlocked)
	[-g <TOKEN>]\\t GitHub API personal access token, create new gist with results (default: $MY_GEEKBENCH_KEY)
	[-h]\\t\\t displays help (this message)"
	echo
	exit "$returnCode"
}

#####################################################################
# MAIN
#####################################################################

# echo_equals() outputs a line with =
function echo_equals() {
	COUNTER=0
	while [ $COUNTER -lt "$1" ]; do
		printf '='
		((COUNTER = COUNTER + 1))
	done
}

# echo_line() outputs a line with 70 =
function echo_line() {
	echo_equals "90"
	echo
}

# exit_with_failure() outputs a message before exiting the script.
function exit_with_failure() {
	echo
	echo "FAILURE: $1"
	echo
	exit 9
}

# echo_title() outputs a title to stdout and MY_OUTPUT
function echo_title() {
	echo "> $1"
	echo "<h1>$1</h1>" >>"$MY_OUTPUT"
}

# echo_step() outputs a step to stdout and MY_OUTPUT
function echo_step() {
	echo "    > $1"
	echo "<h2>$1</h2>" >>"$MY_OUTPUT"
}

# echo_sub_step() outputs a step to stdout and MY_OUTPUT
function echo_sub_step() {
	echo "      > $1"
	echo "<h3>$1</h3>" >>"$MY_OUTPUT"
}

echo_line

while getopts "ne:k:g:h" opt; do
	case $opt in
	n)
		MY_GEEKBENCH_NO_UPLOAD="1"
		;;
	e)
		MY_GEEKBENCH_EMAIL="$OPTARG"
		;;
	k)
		MY_GEEKBENCH_KEY="$OPTARG"
		;;
	*)
		usage 1
		;;
	esac
done

# Download Geekbench 6
echo "    > Download Geekbench 6"
if curl -L -k "$MY_GEEKBENCH_DOWNLOAD_URL" -o geekbench.tar.gz 2>/dev/null && chmod +x geekbench.tar.gz; then
	if tar xvfz geekbench.tar.gz -C "$MY_DIR" --strip-components=1 >/dev/null 2>&1; then
		if [[ -x "$MY_DIR/geekbench6" ]]; then
			echo "        > Geekbench successfully downloaded"
		else
			exit_with_failure "Could not find '$MY_DIR/geekbench6'"
		fi
	else
		exit_with_failure "Could not unpack geekbench.tar.gz"
	fi
else
	exit_with_failure "Could not download Geekbench '$MY_GEEKBENCH_DOWNLOAD_URL'"
fi

# Unlock Geekbench 6
if [[ $MY_GEEKBENCH_EMAIL && $MY_GEEKBENCH_KEY ]]; then
	if "$MY_DIR/geekbench6" --unlock "$MY_GEEKBENCH_EMAIL" "$MY_GEEKBENCH_KEY" >/dev/null 2>&1; then
		echo "        > Geekbench successfully unlocked"
	else
		exit_with_failure "Could not unlock Geekbench"
	fi
else
	echo "        > Geekbench is in tryout mode"
fi

#####################################################################
# Run Geekbench 6
#####################################################################
clear
echo_line
echo "Now let's run Geekbench 6. This takes a little longer."
echo_line

echo_title "Geekbench 6"
if [[ $MY_GEEKBENCH_NO_UPLOAD ]]; then
	"$MY_DIR/geekbench6" --no-upload >>"$MY_OUTPUT" 2>&1
else
	"$MY_DIR/geekbench6" --upload >>"$MY_OUTPUT" 2>&1
fi
# cat "$MY_OUTPUT"
GEEKBENCH_URL=$(cat "$MY_OUTPUT" | grep -o 'https://browser.geekbench.com/v6/cpu/[0-9]\+' | head -n1)
[[ ! -z $LOCAL_CURL ]] && DL_CMD="curl -s" || DL_CMD="wget -qO-"
GEEKBENCH_SCORES=$($DL_CMD $GEEKBENCH_URL | grep "div class='score'") ||
	GEEKBENCH_SCORES=$($DL_CMD $GEEKBENCH_URL | grep "span class='score'")
GEEKBENCH_SCORES_SINGLE=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $3 }')
GEEKBENCH_SCORES_MULTI=$(echo $GEEKBENCH_SCORES | awk -v FS="(>|<)" '{ print $7 }')
echo -en "\r\033[0K"
echo -e "Geekbench $VERSION Benchmark Test:"
printf "%-15s | %-30s\n" "Test" "Value"
printf "%-15s | %-30s\n"
printf "%-15s | %-30s\n" "Single Core" "$GEEKBENCH_SCORES_SINGLE"
printf "%-15s | %-30s\n" "Multi Core" "$GEEKBENCH_SCORES_MULTI"
printf "%-15s | %-30s\n" "Full Test" "$GEEKBENCH_URL"
rm -rf "$MY_OUTPUT" Geekbench* gb5* geekbench.tar.gz*
echo_line
