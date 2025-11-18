#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the current branch name
app_version=$(git rev-parse --abbrev-ref HEAD)
# Extract the version from pubspec.yaml
# app_version=$(grep '^version: ' pubspec.yaml | awk '{print $2}')

# Create a version.json file with the extracted version
cat <<EOF > version.json
{
  "version": "$app_version",
  "release_date": "$(date +"%Y-%m-%d")"
}
EOF
# Check if index.html exists in the web directory
if [[ ! -f "web2/index.html" ]]; then
  echo "Error: index.html file not found!"
  exit 1
fi

# Replace the line after the VERSION comment with the new version
# shellcheck disable=SC2154
sed -i.bak '/<!-- VERSION: __VERSION__ -->/{n;s/.*/     <div>ver: '"$app_version"'<\/div>/;}' web/index.html


# Print a success message
echo "index.html updated successfully with version: $app_version"
# Print a success message
echo "version.json file created successfully with version: $app_version"
# Build the Flutter web app with the version as a dart define
flutter build web --no-tree-shake-icons --dart-define=APP_VERSION=$app_version
