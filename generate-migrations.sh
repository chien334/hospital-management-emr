#!/bin/bash

# Script to generate initial EF Core migrations for DbContext classes
# Run this script after the package references have been updated

echo "Starting the migration generation script..."

# Create directory for migrations if it doesn't exist
mkdir -p /workspaces/hospital-management-emr/Migrations

# Define the main project where migrations will be applied
MAIN_PROJECT="/workspaces/hospital-management-emr/Code/Websites/DanpheEMR/DanpheEMR.csproj"
STARTUP_PROJECT="$MAIN_PROJECT"
DAL_PROJECT="/workspaces/hospital-management-emr/Code/Components/DanpheEMR.DalLayer/DanpheEMR.DalLayer.csproj"

# Array of DbContext classes to migrate
CONTEXTS=(
    "AdmissionDbContext"
    "BillingDbContext"
    "InventoryDbContext"
    "PharmacyDbContext"
    "AccountingDbContext"
    "CoreDbContext"
)

# Iterate through each context and create migrations
for CONTEXT in "${CONTEXTS[@]}"
do
    echo "Generating migration for $CONTEXT..."
    
    # Create the migration
    dotnet ef migrations add "Initial_${CONTEXT}" \
        --startup-project "$STARTUP_PROJECT" \
        --project "$DAL_PROJECT" \
        --context "DanpheEMR.DalLayer.$CONTEXT" \
        --output-dir "Migrations/${CONTEXT}Migrations" \
        --configuration "appsettings.migration.json"
    
    if [ $? -eq 0 ]; then
        echo "Successfully created migration for $CONTEXT"
    else
        echo "Failed to create migration for $CONTEXT, continuing with next context..."
    fi
    
    echo "------------------------------"
done

echo "Migration generation script completed!"
echo "You can now apply migrations using 'dotnet ef database update --context <ContextName>'"
