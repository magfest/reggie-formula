#! /bin/bash

if [ "$1" != "" ]; then
    EVENT_NAME=$1
fi

if [ "$2" != "" ]; then
    EVENT_YEAR=$2
fi

if [ -z "$EVENT_NAME" ] || [ -z "$EVENT_YEAR" ]; then
    echo "Usage: $0 EVENT_NAME EVENT_YEAR"
    echo ""
    echo "     EVENT_NAME can be one of the following: super, labs, stock, west"
    echo "     EVENT_YEAR can be any valid year: 2018, 2019, 2020, ..."
    echo ""
    echo "EVENT_NAME and EVENT_YEAR may also be specified as environment variables."
    exit 1
fi

export EVENT_NAME=$EVENT_NAME
export EVENT_YEAR=$EVENT_YEAR
vagrant up
