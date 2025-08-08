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

if [ -z "$REMOTE_MAVEN_REPO_URL" ]; then
  echo 'Must specify a remote Maven repository URL!'
  exit 10
fi

if [ -z "$GIT_USERNAME" ] || [ -z "$GIT_EMAIL" ]; then
  echo 'Must specify the Git username and email!'
  exit 10
fi
# endregion

PROJECT_NAME="$(basename "$WORKSPACE_PATH")"

# 将存储Maven仓库文件的Git仓库clone到workspace下
cd $WORKSPACE_PATH
git clone "$REMOTE_MAVEN_REPO_URL" maven-repo

# 解压maven-repo.tar.gz
cd maven-repo-changes
tar -zxf maven-repo.tar.gz
cd ..

#
# 将[workspace]/maven-repo-changes/maven-repo/repository下所有内容，复制到[workspace]/maven-repo
# /repository下，并替换已存在的内容。
#
cp -rf maven-repo-changes/maven-repo/repository/. maven-repo/repository/

# 进入存储Maven仓库文件的Git仓库，设置提交者信息，然后提交并推送
cd maven-repo/repository
date > update_time.txt

commit_message="Update $PROJECT_NAME"
if [ "$IS_DEVELOPMENT_VERSION" != 'false' ]; then
  commit_message="$commit_message (dev)"
fi

git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"
git add .
git commit -m "$commit_message"
git push
