#!/usr/bin/env bash

# Obtain the base directory this script resides in.
BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo "BASE_DIR is ${BASE_DIR}"
cd $BASE_DIR
# Useful constants
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_OFF="\033[0m"

# Parse args
JOBS=8
PREFIX=""
USAGE="./build.sh [-j num_jobs] "
while [ "$1" != "" ]; do
  case $1 in
    -j | --jobs ) shift
                  JOBS=$1
                  ;;
    * )           echo $USAGE
                  exit 1
esac
shift
done

#创建编译目录
BUILD_DIR=_im_build
mkdir -p $BUILD_DIR

set -e nounset

#退出就回到基础目录
trap 'cd $BASE_DIR' EXIT
cd $BUILD_DIR || exit

cmake  $BASE_DIR/src/

make -j "$JOBS"
echo -e "${COLOR_GREEN}im_http build is complete. good job${COLOR_OFF}"
