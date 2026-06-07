#!/bin/bash
# Script to run the DanpheEMR backend locally.

# Exit immediately if a command exits with a non-zero status
set -e

# Change directory to the workspace root directory where the script is located
cd "$(dirname "$0")"

echo "======================================================="
echo "   Starting DanpheEMR Backend                         "
echo "   Target URL: http://localhost:5000                  "
echo "======================================================="

# Verify dotnet is installed
if ! command -v dotnet &> /dev/null; then
    echo "ERROR: dotnet CLI is not installed."
    echo "Please install .NET SDK (v8.0 or newer) from: https://dotnet.microsoft.com/download"
    exit 1
fi

export ASPNETCORE_ENVIRONMENT=Development

# Run the .NET Web App
dotnet run --project Code/Websites/DanpheEMR/DanpheEMR.csproj --urls "http://localhost:5000"
