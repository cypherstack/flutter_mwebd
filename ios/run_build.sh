#!/usr/bin/env bash

set -e

THIS_DIR=`pwd`
pushd ../
dart tool/build.dart -p ios -b "$THIS_DIR/build" -o  "$THIS_DIR/build"
popd

