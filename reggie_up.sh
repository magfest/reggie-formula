#! /bin/bash
# fail on any errors
set -e

# output all stderr and stdout to a logfile, and to the screen as well
logfile=install.log
exec &> >(tee -a "$logfile")


# fail on any errors
set -e

# output all stderr and stdout to a logfile, and to the screen as well
logfile=install.log
exec &> >(tee -a "$logfile")

if [ "$1" != "" ]; then
    EVENT_NAME=$1
fi
if [ "$1" = "help" ]; then
    echo "Usage: $0 EVENT_NAME EVENT_YEAR"
    echo ""
    echo "     EVENT_NAME can be one of the following: super, labs, stock, west"
    echo "     EVENT_YEAR can be any valid year: 2018, 2019, 2020, ..."
    echo ""
    echo "EVENT_NAME and EVENT_YEAR may also be specified as environment variables."
    exit 1
fi
if [ "$2" != "" ]; then
    EVENT_YEAR=$2
fi

if [ -z "$EVENT_NAME" ] || [ -z "$EVENT_YEAR" ]; then
echo "What event is this for: super, labs, stock, west,other. ?"
read EVENT_NAME
echo "What is the events year ie. 2018,2019,2020,...... ?"
read EVENT_YEAR
fi

export EVENT_NAME=$EVENT_NAME
export EVENT_YEAR=$EVENT_YEAR
vagrant up
