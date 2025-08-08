#!/bin/bash

set -e

# region 参数校验
if [ -z "$PROJECT_PATH" ]; then
  if [ -z "$GITHUB_WORKSPACE" ]; then
    echo 'Must specify a project root path!'
    exit 10
  else
    PROJECT_PATH="$GITHUB_WORKSPACE/repo"
  fi
fi

cd "$PROJECT_PATH"
PROJECT_PATH="$(pwd)"
WORKSPACE_PATH="$(readlink -fm ..)"
echo "Working with project path: $PROJECT_PATH"

if [ -z "$GIT_USERNAME" ] || [ -z "$GIT_EMAIL" ]; then
  echo 'Must specify the Git username and email!'
  exit 10
fi
# endregion

PROJECT_NAME="$(basename "$WORKSPACE_PATH")"

cd $WORKSPACE_PATH

# 创建提交信息
registry_name=release
commit_message="Update $PROJECT_NAME"
if [ "$IS_DEVELOPMENT_VERSION" != 'false' ]; then
  registry_name=development
  commit_message="$commit_message (dev)"
fi

local_registry_path="$(readlink -fm ~/.local/share/verdaccio/storage)"

# 将本地npm仓库复制到Git仓库中
mv -f $local_registry_path/.verdaccio-db.json maven-repo/files/verdaccio/storage/$registry_name/
cp -rf $local_registry_path/. maven-repo/repository/npm/$registry_name/

# 进入存储Maven仓库文件的Git仓库，设置提交者信息，然后提交并推送
cd maven-repo
date > repository/npm/update_time.txt

git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"
git add repository/npm/$registry_name
git add files/verdaccio/storage/$registry_name
git add repository/npm/update_time.txt
git commit -m "$commit_message"
git push
