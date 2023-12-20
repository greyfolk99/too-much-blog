#!/bin/bash


project_path=$(pwd)
project_name=$(basename "$project_path")
deploy_path=$(cd ../../apps/"$project_name" && mkdir -p temp && cd temp && pwd)
server_static_resources_path="$project_path/server/src/main/resources/static"

# exit if paths are empty
if [ -z "$deploy_path" ] || [ -z "$server_static_resources_path" ]; then
    echo "Invalid paths"
    exit 1
fi

# check paths and ask if they are correct
echo "Deploy path: $deploy_path"
echo "Server static resources path: $server_static_resources_path"
echo "Is this correct? this will clean and copy files to these paths. [Y/n]"
read -r answer
if [ "$answer" != "${answer#[Yy]}" ]; then
    echo "Continuing..."
else
    echo "Exiting..."
    exit 1
fi

# build
echo ""
echo "### Building Client..."
cd ./client || echo "client directory not found"
npm run build || npm install && npm run build

rm -rf "$server_static_resources_path"
mkdir "$server_static_resources_path"
cp -r dist/* "$server_static_resources_path"
cd ../

echo ""
echo "### Building Server..."
cd ./server || echo "server directory not found"
./gradlew clean bootJar
rm -rf "$deploy_path"
mkdir "$deploy_path"
cp build/libs/*.jar "$deploy_path" || exit 1
cp build/resources/main/application.yml "$deploy_path" || exit 1

# read project name and version
project=$(./gradlew rootProjectName -q)
echo "Project: $project"
version=$(./gradlew properties -q | grep "version:" | awk '{print $2}')
echo "Version: $version"

# create .env file in deploy path
cd "$deploy_path" && cd ..
rm -f .env >> /dev/null
touch .env && cat <<EOF > .env
APP_NAME=$project
APP_VERSION=$version
EOF

