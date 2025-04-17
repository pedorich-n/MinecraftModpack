#!/usr/bin/env bash
set +e -x

validate_hash() {
    hash_candidate="$1"

    if [[ "$hash_candidate" =~ ^sha256-[A-Za-z0-9\\/+]{43}= ]]; then
        return 0
    fi
    return 1
}

run() {

    output="$(nix flake check --quiet 2>&1)"
    nix_flake_check_exit_code="$?"
    if [ $nix_flake_check_exit_code -ne 0 ]; then
        new_hash=$(echo "$output" | grep "got:    sha256-" | tail -c 52)
        old_hash=$(echo "$output" | grep "specified: sha256-" | tail -c 52)
        if validate_hash "$old_hash" && validate_hash "$new_hash"; then
            # Replace / with \/ in old_hash
            existing_hash_match="${old_hash//\//\\/}" 
            if [ "$2" == "--dry-run" ]; then
                echo "dry-run: sed -i \"s;-hash = \"$existing_hash_match\";-hash = \"$new_hash\";g\" flake.nix"
            else
                sed -i "s;-hash = \"$existing_hash_match\";-hash = \"$new_hash\";g" flake.nix
            fi
            echo ./flake.nix: "$old_hash -> $new_hash"
            exit 0
        fi
    else 
        echo "$output"
    fi
    exit "$nix_flake_check_exit_code"
}

case "$1" in
    run) run "$@";;
    list) run --dry-run ;;
esac
echo "please provide action: run/list" && exit 1