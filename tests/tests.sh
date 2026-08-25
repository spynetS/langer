#!/usr/bin/sh


# This script will run the tests in this golder

find ./ -exec sh -c '../langer "$1" || true' _ {} \;
