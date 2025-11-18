#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Get the current branch name
branch_name=$(git rev-parse --abbrev-ref HEAD)

# Sanitize the branch name to create a valid version build identifier
# Replace invalid characters (e.g., '/') with hyphens or underscores
#sanitized_branch_name=$(echo "$branch_name" | sed 's/[^a-zA-Z0-9]/-/g')



# Update the version in pubspec.yaml using yq
yq e -i ".version = \"$branch_name\"" pubspec.yaml

echo "pubspec.yaml updated to version: $branch_name"
# Construct the deployment message
deploy_message="$branch_name"

# Run Firebase deploy with the constructed message
firebase deploy --only hosting --message "$deploy_message"

# Print a success message
echo "Deployment complete: $deploy_message"