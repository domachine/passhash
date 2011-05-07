#!/bin/bash


strchr()
{
    echo "$1" | grep "$2" &>/dev/null
    return $?
}

isdigit()
{
    echo "$1" | egrep '^[0-9]+$' &>/dev/null
    return $?
}

tobool()
{
    if [[ $1 == 1 ]] || [[ $1 == "true" ]]; then
	echo "true"
    elif [[ $1 == 0 ]] || [[ $1 == "false" ]]; then
	echo "false"
    else
	echo -1
    fi
}

dohelp()
{
cat <<EOF

 -- Passhash wrapper 0.0.6 --

Usage: $APP [OPTIONS ...] <site-tag> [<master-key>]

OPTIONS:
  -j <java-path>                Specify the path to the java-executable.
  -r <rhino-classpath>          Specify the path to the rhino classpath.
                                (Usually the js.jar)
  -s|--size <size>              An integer specifying the desired size
                                of the generated password.
  -h|--help                     Show this help message and exit.
  --require-digit <bool>        Specifies if digits should be injected
                                in the generated password.
  --require-punctuation <bool>  Specifies if punctuation should be injected
                                in the generated password.
  --require-mixed-case <bool>   Specifies if the password should be mixed
                                case.
  --restrict-special <bool>     Specify if the password should consist of
                                special characters only.
  --restrict-digits <bool>      Specifies if the password should consist
                                of digits only.

ARGUMENTS:
  <bool>     Can be either true, false or 1, 0


Copyright (C) Dominik Burgdoerfer <dominik.burgdoerfer@googlemail.com>

EOF
}

LIB_DIR=

# Get directory where the script resides in.
if [[ -z $LIB_DIR ]] && strchr "$0" "/"; then
    LIB_DIR=$(dirname "$0")
elif [[ -z $LIB_DIR ]]; then
    if ! [[ -f $0 ]]; then
        # Script resides in PATH
	LIB_DIR=$(which "$0")
    else
	LIB_DIR=$(dirname "$0")
    fi
fi


APP=$(basename "$0")

[[ -z $JAVA ]] && JAVA=java
[[ -z $RHINO_CLASSPATH ]] && RHINO_CLASSPATH=/usr/share/java/js.jar

REQUIRE_DIGIT="true"
REQUIRE_PUNCTUATION="true"
REQUIRE_MIXED_CASE="true"
RESTRICT_SPECIAL="false"
RESTRICT_DIGITS="false"
SIZE=18

error()
{
    echo "$APP: error: $@" >&2
    exit 1
}

# Parse command line.
shortopts="j:r:h"
TEMP=$(getopt -o "j:r:hs:" \
    --long "require-digit:,require-punctuation:,require-mixed-case:,\
restrict-special:,restrict-digits:,size:,help" -n "$APP" -- "$@")

if (( $? != 0 )); then
    exit 1
fi

eval set -- "$TEMP"
while true; do
    case "$1" in
	-j)
	    JAVA=$2
	    shift
	    ;;
	-r)
	    RHINO_CLASSPATH=$2
	    shift
	    ;;
	--require-digit)
	    value=$(tobool "$2")
	    if [[ $value == -1 ]]; then
		error "require-digit argument must be a boolean value."
	    fi
	    REQUIRE_DIGIT=$value
	    ;;
	--require-punctuation)
	    value=$(tobool "$2")
	    if [[ $value == -1 ]]; then
		error "require-punctuation argument must be a boolean value."
	    fi

	    REQUIRE_PUNCTUATION=$value
	    ;;
	--require-mixed-case)
	    value=$(tobool "$2")
	    if [[ $value == -1 ]]; then
		error "require-mixed-case argument must be a boolean value."
	    fi

	    REQUIRE_MIXED_CASE=$value
	    ;;
	--restrict-special)
	    value=$(tobool "$2")
	    if [[ $value == -1 ]]; then
		error "restrict-special argument must be a boolean value."
	    fi

	    RESTRICT_SPECIAL=$value
	    ;;
	--restrict-digits)
	    value=$(tobool "$2")
	    if [[ $value == -1 ]]; then
		error "restrict-digits argument must be a boolean value."
	    fi

	    RESTRICT_DIGITS=$value
	    ;;
	-s|--size)
	    if isdigit "$2"; then
		SIZE=18
	    else
		error "size argument must be a number."
	    fi
	    ;;
	-h|--help)
	    dohelp
	    exit 0
	    ;;
	--)
	    shift
	    break;
	    ;;
    esac

    shift
done

# Check for classpath existence.
if [[ -z $RHINO_CLASSPATH ]] || ! [[ -f $RHINO_CLASSPATH ]]; then
    error "rhino jar-file not found: $RHINO_CLASSPATH"
fi

# Will hold the masterkey
MASTERKEY=
if [[ $# -eq 1 ]]; then
    # Not enough arguments -> ask the user for password
    read -s -p "Password: " MASTERKEY
    echo
elif [[ $# -eq 2 ]]; then
    MASTERKEY=$2
else
    error "invalid number of command-line arguments."
fi

exec "$JAVA" -classpath "$RHINO_CLASSPATH" \
    org.mozilla.javascript.tools.shell.Main \
    -e "SITE_TAG=\"$1\"" \
    -e "MASTERKEY=\"$MASTERKEY\"" \
    -e "SIZE=$SIZE" \
    -e "REQUIRE_DIGIT=$REQUIRE_DIGIT" \
    -e "REQUIRE_PUNCTUATION=$REQUIRE_PUNCTUATION" \
    -e "REQUIRE_MIXED_CASE=$REQUIRE_MIXED_CASE" \
    -e "RESTRICT_SPECIAL=$RESTRICT_SPECIAL" \
    -e "RESTRICT_DIGITS=$RESTRICT_DIGITS" \
    "$LIB_DIR/passhash.js"
