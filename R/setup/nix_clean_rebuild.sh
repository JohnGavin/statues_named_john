#!/bin/bash
# R/setup/nix_clean_rebuild.sh
# "Nuclear Option" for Nix environment recovery.
# WARNING: This removes ALL unused Nix store paths from your system.

echo "================================================================="
echo "⚠️  WARNING: NUCLEAR OPTION ⚠️"
echo "================================================================="
echo "This script will:"
echo "1. Delete .local-shell (GC root) if it exists."
echo "2. Run 'nix-collect-garbage -d' (Deleting ALL unused Nix store paths on your system!)."
echo "3. Re-build 'default.nix' from scratch."
echo
echo "Use this ONLY if you suspect deep corruption of the local Nix store"
echo "that prevents the environment from loading (e.g., persistent segfaults"
echo "that shouldn't happen)."
echo
echo "This may take a long time to re-download/re-build everything."
echo "================================================================="

read -p "Are you sure you want to proceed? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -L ".local-shell" ]; then
        echo "Removing .local-shell symlink..."
        rm .local-shell
    fi

    echo "Running garbage collection..."
    nix-collect-garbage -d

    echo "Rebuilding environment..."
    nix-build default.nix -A shell -o .local-shell

    echo "✅ Rebuild complete. Try entering the shell now: nix-shell"
else
    echo "Aborted."
fi
