# Detailed Migration Guide for Hospital Management EMR

This guide outlines the step-by-step process to migrate the hospital management EMR system from Entity Framework 6 to Entity Framework Core.

## Migration Progress

### Completed Tasks
- Created EF Core versions of the following DbContext classes:
  - AdmissionDbContextCore.cs
  - CoreDbContextCore.cs
  - AccountingDbContextCore.cs
  - InventoryDbContextCore.cs
  - PharmacyDbContextCore.cs

### Pending Tasks
- Create EF Core versions of remaining DbContext classes:
  - BillingDbContextCore.cs
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

## Implementation Strategy

For a successful migration, follow these detailed steps:

### Step 1: Update NuGet Packages

Update each project file to replace EntityFramework 6.4.4 with EF Core packages:

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

### Step 2: Migrate DbContext Classes

For each DbContext class, implement these changes:

1. Change base class:
   ```csharp
   // From
   public class YourDbContext : DbContext
   
   // To
   public class YourDbContext : DbContext
   ```

2. Update constructor and connection handling:
   ```csharp
   private readonly string _connectionString;

   public YourDbContext(string connectionString)
   {
       _connectionString = connectionString;
   }

   protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
   {
       if (!optionsBuilder.IsConfigured)
       {
           optionsBuilder.UseSqlServer(_connectionString);
       }
   }
   ```

3. Update OnModelCreating method:
   ```csharp
   // From
   protected override void OnModelCreating(DbModelBuilder modelBuilder)
   
   // To
   protected override void OnModelCreating(ModelBuilder modelBuilder)
   ```

4. Update relationship configuration:
   ```csharp
   // From
   modelBuilder.Entity<YourEntity>()
       .HasRequired(e => e.RelatedEntity)
       .WithMany()
       .HasForeignKey(e => e.RelatedEntityId)
       .WillCascadeOnDelete(false);
   
   // To
   modelBuilder.Entity<YourEntity>()
       .HasOne(e => e.RelatedEntity)
       .WithMany()
       .HasForeignKey(e => e.RelatedEntityId)
       .OnDelete(DeleteBehavior.NoAction);
   ```

5. Update stored procedure calls:
   ```csharp
   // Using ADO.NET for stored procedures with DataTable
   public DataTable ExecuteStoredProcedure(parameters)
   {
       DataTable result = new DataTable();
       
       using (var connection = new SqlConnection(_connectionString))
       {
           connection.Open();
           
           using (var command = new SqlCommand("SP_ProcedureName", connection))
           {
               command.CommandType = CommandType.StoredProcedure;
               
               // Add parameters
               command.Parameters.Add(new SqlParameter("@Param1", SqlDbType.Int) { Value = param1 ?? (object)DBNull.Value });
               
               // Execute and fill DataTable
               using (var adapter = new SqlDataAdapter(command))
               {
                   adapter.Fill(result);
               }
           }
       }
       
       return result;
   }
   ```

### Step 3: Update Service Layer

Modify services that interact with DbContext:

1. Update dependency injection to use the Core versions:
   ```csharp
   // Registration in Startup.cs
   services.AddScoped<IYourService, YourService>(serviceProvider => {
       string connStr = Configuration.GetConnectionString("DefaultConnection");
       return new YourService(new YourDbContextCore(connStr));
   });
   ```

2. Update LINQ queries that might have different behavior:
   - Use `.ToList()` before further operations to ensure immediate execution
   - Check for changes in `Include()` behavior
   - Update any database-generated values handling

### Step 4: Database Migrations

For each DbContext:

1. Install the EF Core tools:
   ```bash
   dotnet tool install --global dotnet-ef
   ```

2. Add an initial migration:
   ```bash
   dotnet ef migrations add InitialCreateForYourContext --context YourDbContextCore
   ```

3. Apply the migration:
   ```bash
   dotnet ef database update --context YourDbContextCore
   ```

### Step 5: Testing Strategy

Test the application in phases:

1. **Unit Testing**:
   - Test each migrated DbContext in isolation
   - Verify CRUD operations
   - Test complex queries

2. **Integration Testing**:
   - Test service layer with new DbContext implementations
   - Test transactions spanning multiple contexts

3. **End-to-End Testing**:
   - Test complete user workflows
   - Verify data integrity across operations

4. **Performance Testing**:
   - Compare query performance before and after migration
   - Identify and optimize slow queries

## Common Issues and Solutions

### 1. Lazy Loading

EF Core requires explicit opt-in for lazy loading:

```csharp
// In OnConfiguring
optionsBuilder.UseLazyLoadingProxies();

// And add package
// Microsoft.EntityFrameworkCore.Proxies
```

### 2. Change Tracking

EF Core has different change tracking behavior:

```csharp
// Check tracking status
context.ChangeTracker.Entries().Where(e => e.State == EntityState.Modified);

// Disable tracking for read-only queries
context.YourEntities.AsNoTracking().ToList();
```

### 3. Transactions

Update transaction handling:

```csharp
using (var transaction = context.Database.BeginTransaction())
{
    try
    {
        // Perform operations
        context.SaveChanges();
        transaction.Commit();
    }
    catch
    {
        transaction.Rollback();
        throw;
    }
}
```

### 4. Identity Column Handling

EF Core handles identity columns differently:

```csharp
// Configure identity column
modelBuilder.Entity<YourEntity>()
    .Property(e => e.Id)
    .UseIdentityColumn();
```

## Testing Checklist

Ensure to test these critical areas after migration:

- [ ] Database schema integrity
- [ ] CRUD operations for all entities
- [ ] Complex LINQ queries and Include statements
- [ ] Stored procedure calls
- [ ] Transaction management
- [ ] Performance of high-volume queries
- [ ] Authentication and authorization flows
- [ ] Report generation
- [ ] Billing and accounting operations
- [ ] Patient record management

## Rollback Plan

In case of issues:

1. Keep both EF6 and EF Core DbContext versions
2. Implement feature flags to switch between implementations
3. Have database backup points before each migration phase
4. Document database state at each migration step
