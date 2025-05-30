#!/bin/bash

# Script to update NuGet package references in .csproj files
# Replace Entity Framework 6.4.4 with Entity Framework Core 3.1.32

echo "Starting the migration script for .NET Core and Entity Framework Core..."

# Find all .csproj files in the solution
find /workspaces/hospital-management-emr -name "*.csproj" -type f | while read -r file; do
    echo "Processing: $file"

    # Check if the file contains a reference to EntityFramework 6.4.4
    if grep -q '<PackageReference Include="EntityFramework" Version="6.4.4" />' "$file"; then
        echo "  Found EntityFramework 6.4.4 reference in $file"
        
        # Create a backup of the file
        cp "$file" "${file}.bak"
        
        # Replace the EntityFramework reference with EF Core references
        sed -i 's|<PackageReference Include="EntityFramework" Version="6.4.4" />|<PackageReference Include="Microsoft.EntityFrameworkCore" Version="3.1.32" />\n    <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="3.1.32" />\n    <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="3.1.32">\n      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>\n      <PrivateAssets>all</PrivateAssets>\n    </PackageReference>|' "$file"
        
        echo "  Updated $file with EF Core references"
    else
        echo "  No EntityFramework 6.4.4 reference found in $file, checking for other versions..."
        
        # Check for any other EntityFramework reference
        if grep -q '<PackageReference Include="EntityFramework"' "$file"; then
            echo "  Found different EntityFramework version in $file"
            
            # Create a backup of the file
            cp "$file" "${file}.bak"
            
            # Replace any EntityFramework reference with EF Core references
            sed -i 's|<PackageReference Include="EntityFramework".*/>|<PackageReference Include="Microsoft.EntityFrameworkCore" Version="3.1.32" />\n    <PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="3.1.32" />\n    <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="3.1.32">\n      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>\n      <PrivateAssets>all</PrivateAssets>\n    </PackageReference>|' "$file"
            
            echo "  Updated $file with EF Core references"
        else
            echo "  No EntityFramework reference found in $file"
        fi
    fi
    
    # Add Lazy Loading Proxies if needed - check for EF lazy loading configuration
    if grep -q 'LazyLoadingEnabled = true' "$file" && ! grep -q 'Microsoft.EntityFrameworkCore.Proxies' "$file"; then
        echo "  Adding EF Core Proxies for lazy loading support"
        sed -i '/<PackageReference Include="Microsoft.EntityFrameworkCore.Tools"/a\    <PackageReference Include="Microsoft.EntityFrameworkCore.Proxies" Version="3.1.32" />' "$file"
    fi
    
    echo "  Done processing $file"
    echo "------------------------------"
done

echo "Migration script completed successfully!"
echo "Please review the changes and test your application."
echo "Backup files with .bak extension have been created for each modified file."
