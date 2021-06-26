#!/bin/sh

set -e

echo "Rebuilding $1.pp"

checkmodule -M -m -o $1.mod $1.te
semodule_package -o $1.pp -m $1.mod

echo "Installing $1.pp"

semodule -i /root/$1.pp

