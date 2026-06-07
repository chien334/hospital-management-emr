#!/bin/bash
# Script to run the DanpheEMR frontend locally.

# Exit immediately if a command exits with a non-zero status
set -e

# Change directory to the workspace root directory where the script is located
cd "$(dirname "$0")"

echo "======================================================="
echo "   Starting DanpheEMR Frontend                        "
echo "   Proxy Config: proxy.conf.json                      "
echo "======================================================="

# Verify node and npm are installed
if ! command -v npm &> /dev/null; then
    echo "ERROR: npm/node is not installed."
    echo "Please install Node.js (v20 or newer) from: https://nodejs.org/"
    exit 1
fi

# Navigate to Frontend directory
cd Frontend

# If node_modules does not exist, run npm install
if [ ! -d "node_modules" ]; then
    echo "node_modules folder not found. Running npm install..."
    npm install --force
fi

# Start Angular dev server
npm start
