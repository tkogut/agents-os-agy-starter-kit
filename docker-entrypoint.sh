#!/bin/bash
# docker-entrypoint.sh
# Sets up the container environment so that:
#   - $HOME resolves to the host user's home dir (e.g. /home/tkogut or /root)
#   - $HOME/projects is a symlink pointing to /projects (the volume mount)
# This ensures os-init creates projects that mirror correctly on the host filesystem.

set -e

# Ensure $HOME directory exists (required when HOME=/home/tkogut but container runs as root)
mkdir -p "$HOME"

# Create or update the symlink: $HOME/projects -> /projects
# /projects is the volume mount point set in docker-compose.yml
if [ -L "$HOME/projects" ]; then
    # Already a symlink — ensure it points correctly
    ln -sfn /projects "$HOME/projects"
elif [ ! -e "$HOME/projects" ]; then
    # Doesn't exist yet — create symlink
    ln -sfn /projects "$HOME/projects"
fi
# If it's a real directory, leave it alone to avoid data loss

# Execute the CMD passed to the container (default: /bin/bash)
exec "$@"
