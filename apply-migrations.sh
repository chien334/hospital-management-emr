#!/bin/bash

# Script to apply EF Core migrations to the database
# Run this script after generating migrations

echo "Starting the migration application script..."

# Define the main project where migrations will be applied
MAIN_PROJECT="/workspaces/hospital-management-emr/Code/Websites/DanpheEMR/DanpheEMR.csproj"
STARTUP_PROJECT="$MAIN_PROJECT"

# Array of DbContext classes to migrate
CONTEXTS=(
    "AdmissionDbContext"
    "BillingDbContext"
    "InventoryDbContext"
    "PharmacyDbContext"
    "AccountingDbContext"
    "CoreDbContext"
)

# Iterate through each context and apply migrations
for CONTEXT in "${CONTEXTS[@]}"
do
    echo "Applying migration for $CONTEXT..."
    
    # Apply the migration
    dotnet ef database update \
        --startup-project "$STARTUP_PROJECT" \
        --context "DanpheEMR.DalLayer.$CONTEXT" \
        --configuration "appsettings.migration.json"
    
    if [ $? -eq 0 ]; then
        echo "Successfully applied migration for $CONTEXT"
    else
        echo "Failed to apply migration for $CONTEXT, continuing with next context..."
    fi
    
    echo "------------------------------"
done

echo "Migration application script completed!"
