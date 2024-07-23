#!/usr/bin/env bash

# For now, we expect BUILD_ENUM to be provided in ENV
BUILD_ENUM=${BUILD_ENUM:-modrinth}

# Define the list of files to update
FILES_WITH_HASH_TO_UPDATE=("flake.nix");


run_command() {
    case "$BUILD_ENUM" in
        modrinth)
            nix build ./#modrinth-pack
            ;;
        packwiz)
            nix build ./#packwiz-server
            ;;
        *)
        echo "Invalid build type: $BUILD_ENUM, expected: 'modrinth' or 'packwiz'"
        exit 1
        ;;
    esac
}

# Disable immediate exit on error
set +e

# Run the build command and capture the output
OUTPUT=$(run_command 2>&1)
COMMAND_EXIT_CODE=$?

if [ $COMMAND_EXIT_CODE != 0 ]; then
    echo "$OUTPUT"
    exit $COMMAND_EXIT_CODE
fi

# Extract the old and new hash from the output
OLD_HASH=$(echo "$OUTPUT" | grep "specified:" | awk '{print $2}')
NEW_HASH=$(echo "$OUTPUT" | grep "got:" | awk '{print $2}')

if [[ $OLD_HASH == "sha256-"* && $NEW_HASH == "sha256"* ]]; then
    # Replace the old hash with the new hash in each file
    for FILE in "${FILES_WITH_HASH_TO_UPDATE[@]}"; do
        sed -i "s;$OLD_HASH;$NEW_HASH;" "$FILE"
    done

    # Run the command again and capture the output
    OUTPUT=$(run_command 2>&1)
    COMMAND_EXIT_CODE=$?
        
    # Check if the command was successful
    if [ $COMMAND_EXIT_CODE -ne 0 ]; then
        if echo "$OUTPUT" | grep -q "error: hash mismatch in fixed-output derivation"; then
            echo "Error: Hash mismatch still exists after update. Aborting."
            exit 1
        else
            echo "$OUTPUT"
            echo "Error: Command failed after hash update."
            exit 1
        fi
    else
        # Check if the command was successful
        if echo "$OUTPUT" | grep -q "error: hash mismatch in fixed-output derivation"; then
            echo "$OUTPUT"
            echo "Error: Hash mismatch still exists after update. Aborting."
            exit 1
        else
            echo "$OUTPUT"
            echo "Command executed successfully after hash update."
            exit 0
        fi
    fi
fi

# Output the command result to the console
echo "$OUTPUT"
echo "Build Succeeded with already correct hashes (presumably.)"