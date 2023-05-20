#!/bin/bash

# Increment a version string using Semantic Versioning terminology.

# Parse command line options.

while getopts ":Mmp" Option
do
  case $Option in
    M ) major=true;;
    m ) minor=true;;
    p ) patch=true;;
  esac
done

# If a flag is missing, show usage message.
if [ $OPTIND -eq 1 ]; then
  echo "No options were passed";
  echo "usage: $(basename $0) [-Mmp] major.minor.patch"
  exit 1
fi

shift $(($OPTIND - 1))

version=$1

if [ -z $version ]; then
  version="0.0.0"
fi

# Build array from version string.
a=( ${version//./ } )

# Increment version numbers as requested.
if [ ! -z $major ]; then
  ((a[0]++))
  a[1]=0
  a[2]=0
fi

if [ ! -z $minor ]; then
  ((a[1]++))
  a[2]=0
fi

if [ ! -z $patch ]; then
  ((a[2]++))
fi

echo "${a[0]}.${a[1]}.${a[2]}"
