#!/usr/bin/env bash
set -euo pipefail

# Hyku Submodule Setup Script
#
# Usage:
#   bin/submodule_update.sh               # Use latest main
#   bin/submodule_update.sh abcdef12      # Use a specific commit SHA
#   bin/submodule_update.sh v1.2.3        # Use a tag
#   bin/submodule_update.sh my-feature    # Use a branch

TARGET_REF="${1:-}"

# Ensure submodule is initialized
git submodule update --init hyrax-webapp

cd hyrax-webapp

if [[ -n "$TARGET_REF" ]]; then
  echo "Checking out specified ref: $TARGET_REF"
  git fetch origin
  git checkout "$TARGET_REF"
else
  echo "Checking out latest main"
  git checkout main
  git pull origin main
fi

# Get short SHA for tagging
BASE_TAG=$(git rev-parse --short=8 HEAD)
cd ..

# Write BASE_TAG to .env (which docker-compose auto-loads)
echo "Setting BASE_TAG=$BASE_TAG in .env"

touch .env
if grep -q '^BASE_TAG=' .env; then
  # Replace existing BASE_TAG line safely
  awk -v new_tag="BASE_TAG=$BASE_TAG" '
    BEGIN { updated=0 }
    /^BASE_TAG=/ { print new_tag; updated=1; next }
    { print }
    END { if (!updated) print new_tag }
  ' .env > .env.tmp && mv .env.tmp .env
else
  echo "BASE_TAG=$BASE_TAG" >> .env
fi


echo "BASE_TAG written to .env"
echo
echo "Setup complete. You can now run:"
echo "   docker compose build"