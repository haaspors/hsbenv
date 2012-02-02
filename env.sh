#!/bin/bash

alias_dict=(
  "android:arm-android"
  "ios:arm-darwin"
  "isim:armsim-darwin"
)

if [ "$1" = "clean" ]; then
  rm $(find toolchain -iname "tc.*.in" | sed -e "s/\.in$//g" -e "s#/tc\.#/#g")
  exit 0
fi

case $# in
  0)
    cpu="$(uname -m | tr '[:upper:]' '[:lower:]')"
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    export HSB_TARGET=$cpu-$os

    echo "Target not specified - HSB_TARGET=$HSB_TARGET"
    ;;
  1)
    # check against alias_dict
    t=$1
    for key_value in ${alias_dict[@]} ; do
      [ "${key_value%%:*}" = "$t" ] && t=${key_value##*:}
    done

    export HSB_TARGET=$t
    ;;
  *)
    echo "Format: $0 <TARGET>"
    exit 1
    ;;
esac

cd $(dirname $0)

bash --rcfile bashrc
