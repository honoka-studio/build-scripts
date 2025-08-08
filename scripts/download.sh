#!/bin/bash

set -e

if [ -z "$GITHUB_WORKSPACE" ]; then
  echo 'Must specify a project root path!'
  exit 10
fi

cd "$GITHUB_WORKSPACE"

repo_name='honoka-studio/build-scripts'

if echo "$BUILD_SCRIPTS_VERSION" | grep -q '\.'; then
  ref_name="tags"
else
  ref_name="heads"
fi

scripts_url="https://github.com/$repo_name/archive/refs/$ref_name/$BUILD_SCRIPTS_VERSION.tar.gz"

echo "Downloading scripts from $scripts_url"
curl -L --fail -o scripts.tar.gz $scripts_url

tar -zxf scripts.tar.gz
rm -f scripts.tar.gz
mv $(echo $repo_name | cut -d'/' -f2)-$BUILD_SCRIPTS_VERSION build-scripts

find ./build-scripts -type f -name '*.sh' | xargs chmod +x
