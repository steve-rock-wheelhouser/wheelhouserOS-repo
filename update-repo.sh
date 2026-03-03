#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define directories
REPO_DIR="/home/user/wheelhouser-repo"
# Handling the ~/home/user case you specified vs standard ~/rpmbuild
RPM_SOURCE="$HOME/rpmbuild/RPMS/x86_64"

# Fallback just in case you actually have a /home/user/home/user/rpmbuild structure
if [ ! -d "$RPM_SOURCE" ] && [ -d "/home/user/home/user/rpmbuild/RPMS/x86_64" ]; then
    RPM_SOURCE="/home/user/home/user/rpmbuild/RPMS/x86_64"
fi

echo "Moving to repository directory: $REPO_DIR"
cd "$REPO_DIR"

echo "Copying over newest RPM binaries from $RPM_SOURCE..."
# Copy only files that exist, avoid failing if no rpm files
cp "$RPM_SOURCE"/*.rpm "$REPO_DIR/x86_64/" 2>/dev/null || echo "No new RPM files found to copy."

echo "Updating repodata..."
# Handle Flatpak environment by escaping to host, otherwise use direct command
if command -v flatpak-spawn &> /dev/null && flatpak-spawn --host command -v createrepo_c &> /dev/null; then
    flatpak-spawn --host createrepo_c .
elif command -v createrepo_c &> /dev/null; then
    createrepo_c .
elif command -v createrepo &> /dev/null; then
    createrepo .
else
    echo "Warning: createrepo/createrepo_c command missing! Cannot update repodata."
    exit 1
fi

echo "Staging changes for Git..."
git add .

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo "No changes detected. Nothing to commit or push."
    exit 0
fi

echo "Committing updates..."
# Commit with a timestamp
git commit -m "Update binaries and repodata: $(date +'%Y-%m-%d %H:%M:%S')"

echo "Pushing changes to GitHub..."
git push origin main

echo "Repository update complete!"