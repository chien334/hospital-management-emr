# Migration from Entity Framework 6 to Entity Framework Core

This document outlines the steps needed to migrate the hospital management EMR application from Entity Framework 6 to Entity Framework Core.

## Project State Analysis

The project currently consists of multiple components:
- Most projects already target .NET Core 3.1 but are using Entity Framework 6.4.4
- Several DbContext implementations have been migrated to Entity Framework Core:
  - AdmissionDbContextCore.cs
  - CoreDbContextCore.cs
  - AccountingDbContextCore.cs
  - InventoryDbContextCore.cs
  - PharmacyDbContextCore.cs
- The main application is a .NET Core 3.1 web application

## Key Migration Steps

### 1. Update NuGet Packages

Replace Entity Framework 6.4.4 references with EF Core packages in each project:

```xml
<!-- Remove -->
<PackageReference Include="EntityFramework" Version="6.4.4" />

<!-- Add -->
<PackageReference Include="Microsoft.EntityFrameworkCore" Version="3.1.32" />
<PackageReference Include="Microsoft.EntityFrameworkCore.SqlServer" Version="3.1.32" />
<PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="3.1.32">
  <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
  <PrivateAssets>all</PrivateAssets>
</PackageReference>
```

A script (`update-ef-core-packages.sh`) has been created to automate this process.

### 2. Migrate DbContext Classes

For each DbContext class, create a new EF Core version:

1. Change the base class from `System.Data.Entity.DbContext` to `Microsoft.EntityFrameworkCore.DbContext`
2. Update the constructor to use connection string
3. Implement `OnConfiguring` method with `optionsBuilder.UseSqlServer()`
4. Update `OnModelCreating` method to use `ModelBuilder` instead of `DbModelBuilder`
5. Replace relationship configuration syntax:
   - EF6: `.WillCascadeOnDelete(false)` 
   - EF Core: `.OnDelete(DeleteBehavior.NoAction)`
6. Update stored procedure calls to use ADO.NET or EF Core methods

The following DbContext classes have been migrated:
- AdmissionDbContextCore.cs
- CoreDbContextCore.cs
- AccountingDbContextCore.cs
- InventoryDbContextCore.cs
- PharmacyDbContextCore.cs
- BillingDbContextCore.cs

Remaining DbContext classes to migrate:
- LabDbContextCore.cs
- AppointmentDbContextCore.cs
- ClinicalDbContextCore.cs
- MasterDbContextCore.cs
- MedicalRecordsDbContextCore.cs
- NotiFicationDbContextCore.cs
- OrdersDbContextCore.cs
- PayrollDbContextCore.cs
- ReportingDbContextCore.cs
- RadiologyDbContextCore.cs

### 3. Modify Entity Classes

1. Update data annotations
2. Ensure navigation properties are properly configured for EF Core

### 4. Create Database Migrations

For each DbContext, create and apply migrations:

```bash
dotnet ef migrations add InitialCreate --context YourDbContext
dotnet ef database update --context YourDbContext
```

### 5. Update Services and Repositories

Update service layer code that interacts with DbContext:
- Replace EF6 specific methods with EF Core equivalents
- Update LINQ queries to EF Core syntax
- Handle any breaking changes

### 6. Testing

Test the application thoroughly, focusing on:
- Data access operations
- CRUD functionality
- Complex queries
- Performance benchmarks

## Namespace Changes

When migrating from Entity Framework 6 to Entity Framework Core, update the namespaces:

```csharp
// EF6 namespaces to remove
using System.Data.Entity;
using System.Data.Entity.ModelConfiguration.Conventions;
using System.Data.Entity.SqlServer;

// EF Core namespaces to add
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
```

## Breaking Changes to Watch For

1. **Lazy Loading**: Not enabled by default in EF Core
2. **Query Execution**: Immediate execution vs. deferred execution
3. **DbSet<T>.Add()**: Returns different types in EF6 vs. EF Core
4. **Include()**: Different behavior with nested includes
5. **Default Conventions**: Different between EF6 and EF Core
6. **Stored Procedures**: Different approach for executing stored procedures

## Migration Strategy

1. Migrate one DbContext at a time
2. Create parallel implementations (like AdmissionDbContextCore)
3. Switch the application to use the new context
4. Run tests to ensure functionality
5. Move to the next DbContext

This approach allows for incremental migration with minimal disruption to the application.
