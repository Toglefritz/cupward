#!/bin/bash
# Starts and stops the Firebase Emulator Suite, preserving emulator state between runs.
#
# State is exported to the `emulator_data` directory when the emulators are stopped with Ctrl+X, and imported from it
# when they start. Place this script in the directory containing firebase.json.
#
# Usage:
#   ./firebase_emulator_suite.command          Start the emulators (also what double-clicking does).
#   ./firebase_emulator_suite.command start    Start the emulators.
#   ./firebase_emulator_suite.command stop     Export state from running emulators.
#
# While running:
#   Ctrl+X  Stop the emulators and export their state.
#   Ctrl+C  Stop the emulators without exporting state.

# Run from the directory containing this script.
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR" || exit 1

EXPORT_DIR="./emulator_data"

start_emulator() {
    echo "Starting Firebase Emulator Suite..."

    # Only import when previously exported state exists, otherwise the CLI errors out on the first run.
    if [ -d "$EXPORT_DIR" ]; then
        firebase emulators:start --import="$EXPORT_DIR" &
    else
        firebase emulators:start &
    fi
    EMULATOR_PID=$!

    echo "Emulators running. Press Ctrl+X to stop and export state, or Ctrl+C to stop without saving."

    # Listen for Ctrl+X ($'\x18').
    while true; do
        read -r -n 1 -s key
        if [[ $key == $'\x18' ]]; then
            echo "Ctrl+X pressed."
            stop_emulator
            kill "$EMULATOR_PID"
            exit 0
        fi
    done
}

stop_emulator() {
    mkdir -p "$EXPORT_DIR"
    echo "Exporting emulator state to $EXPORT_DIR..."
    firebase emulators:export "$EXPORT_DIR" --force
}

# Ctrl+C stops the emulators without saving state.
trap ctrl_c INT
ctrl_c() {
    echo "Caught Ctrl+C. Exiting without saving state."
    kill "$EMULATOR_PID"
    exit 0
}

if [ "$1" == "start" ] || [ -z "$1" ]; then
    start_emulator
elif [ "$1" == "stop" ]; then
    stop_emulator
else
    echo "Usage: $0 {start|stop}"
fi
