#!/usr/bin/env bash

set -e

REPO_URL="https://github.com/jphulse/godot-shared-components.git"
ADDON_PATH="addons/jeremy_components"

if [ ! -d ".git" ]; then
    echo "Error: this does not look like the root of a Git repository."
    echo "Run this from your Godot project's root folder."
    exit 1
fi

if [ ! -f "project.godot" ]; then
    echo "Warning: project.godot was not found."
    echo "This may not be a Godot project root."
    read -p "Continue anyway? [y/N] " confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        exit 1
    fi
fi

if [ -e "$ADDON_PATH" ]; then
    echo "Error: $ADDON_PATH already exists."
    echo "Remove it first or choose a different addon path."
    exit 1
fi

mkdir -p addons

echo "Adding shared Godot components as a submodule..."
git submodule add "$REPO_URL" "$ADDON_PATH"

echo "Initializing and updating submodule..."
git submodule update --init --recursive

echo
echo "Done."
echo "Shared components added at: $ADDON_PATH"
echo
echo "Next steps:"
echo "  git add .gitmodules $ADDON_PATH"
echo "  git commit -m \"Add shared Godot components submodule\""