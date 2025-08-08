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

if [ -z "$REMOTE_NPM_REGISTRY_URL" ]; then
  echo 'Must specify a remote npm registry URL!'
  exit 10
fi
# endregion

JS_SCRIPTS_PATH="$WORKSPACE_PATH/build-scripts/scripts/npm/library/js"

# 读取当前npm项目根模块的版本信息，检查版本号是否符合要求
node $JS_SCRIPTS_PATH/check-versions.js "$PROJECT_PATH"
check_version_of_projects_out="$(node $JS_SCRIPTS_PATH/check-versions.js "$PROJECT_PATH")"

#
# 检查版本号
#
# 当grep命令未找到匹配的字符串时，将返回非0的返回值（返回值为Exit Code，不是程序的输出内容，
# 可通过“$?”得到上一行命令的返回值）。
# 文件设置了set -e，任何一行命令返回值不为0时，均会中止脚本的执行，在命令后加上“|| true”可
# 忽略单行命令的异常。
# true是一个shell命令，它的返回值始终为0，false命令的返回值始终为1。
#
projects_passed=$(echo "$check_version_of_projects_out" | grep -i 'results.projectsPassed=true') || true
dependencies_passed=$(echo "$check_version_of_projects_out" | grep -i 'results.dependenciesPassed=true') || true
# -z表示字符串为空，-n表示字符串不为空
if [ -n "$projects_passed" ] && [ -z "$dependencies_passed" ]; then
  echo 'Some projects with release version contain dependencies with development version!'
  exit 10
fi

registry_name=development
is_development_version=true

if [ -z "$projects_passed" ]; then
  echo -e '\n\nUsing development repository to publish artifacts.\n'
else
  registry_name=release
  is_development_version=false
fi

echo "IS_DEVELOPMENT_VERSION=$is_development_version" >> "$GITHUB_OUTPUT"

local_registry_path="$(readlink -fm ~/.local/share/verdaccio/storage)"

# 将存储npm仓库文件的Git仓库clone到workspace下
cd $WORKSPACE_PATH
git clone "$REMOTE_NPM_REGISTRY_URL" maven-repo
mkdir -p ~/.config/verdaccio
mkdir -p $local_registry_path
mkdir -p maven-repo/repository/npm/$registry_name

# 还原verdaccio的环境
npm install -g verdaccio@6.1.6

cp -f maven-repo/files/verdaccio/htpasswd ~/.config/verdaccio/
cp -rf maven-repo/files/verdaccio/storage/$registry_name/. $local_registry_path/
cp -rf maven-repo/repository/npm/$registry_name/. $local_registry_path/

# 移除仓库中已存在的与当前项目中的模块版本相同的包
for project in "$@"; do
  node $JS_SCRIPTS_PATH/remove-existing-package.js "$PROJECT_PATH/$project" "$local_registry_path"
done

cd $PROJECT_PATH

nohup verdaccio > /dev/null 2>&1 &
sleep 3s

# 构建并发布到本地npm仓库
local-publish() {
  if [ -z "$1" ]; then
    echo 'Must specify a project name!'
    exit 10
  fi

  cd $PROJECT_PATH/$1
  cp -f $WORKSPACE_PATH/maven-repo/files/verdaccio/.npmrc.honoka ./

  npm publish --userconfig .npmrc.honoka --registry=http://localhost:4873
}

for project in "$@"; do
  echo -e "\n\nPublishing $project...\n"
  local-publish $project
done
