#!/usr/bin/env bash

set -e

if [[ -z "$1" ]];
then
  echo "Target directory argument is missing."
  exit 1
fi

if [[ -z "$2" ]];
then
  echo "Version argument is missing."
  exit 1
fi

CHANNEL="stable"
if [[ "$2" == *beta ]]
then
  CHANNEL="beta"
elif [[ "$2" == *dev ]]
then
  CHANNEL="dev"
fi

mkdir -p "$1"
cd "$1"
curl -sS "https://storage.googleapis.com/dart-archive/channels/$CHANNEL/raw/$2/sdk/dartsdk-linux-x64-release.zip" >dartsdk.zip
unzip -q dartsdk.zip
rm -f dartsdk.zip
