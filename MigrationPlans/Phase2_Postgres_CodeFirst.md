# Phase 2: Database Transition (SQL Server Database-First to PostgreSQL Code-First)

This phase covers transitioning the ORM model from MS SQL Database-First to PostgreSQL Code-First with EF Core Migrations.

---

## 1. Reverse-Engineering MS SQL to Generate C# POCO Entities

Since the database structure was managed outside of the code, we first generate clean C# model classes.

### Steps:
1. Ensure the MS SQL database is active.
2. Run the Entity Framework Core CLI scaffold command:
   ```bash
   dotnet ef dbcontext scaffold "Server=YOUR_SQL_SERVER;Database=DsfEMR;Trusted_Connection=True;" Microsoft.EntityFrameworkCore.SqlServer -o Models -d --context-dir Contexts --no-onconfiguring
   ```
3. Extract mapping configurations into clean separate classes (`IEntityTypeConfiguration<T>`) to keep Entity classes as clean POCO (Plain Old CLR Object) files:
   ```csharp
   public class PatientConfiguration : IEntityTypeConfiguration<PatientModel>
   {
       public void Configure(EntityTypeBuilder<PatientModel> builder)
       {
           builder.ToTable("MST_Patient");
           builder.HasKey(p => p.PatientId);
           builder.Property(p => p.FirstName).HasMaxLength(100).IsRequired();
       }
   }
   ```

---

## 2. Porting Database Schema and Casing to PostgreSQL

PostgreSQL treats unquoted identifiers as lowercase, which causes queries to fail if mappings are PascalCase. We will configure snake_case mapping globally.

### Configuration in DbContext:
In each DbContext file (`DsfEMR.DalLayer`), configure the dynamic converter in `OnModelCreating`:
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);
    
    // Apply configurations
    modelBuilder.ApplyConfigurationsFromAssembly(typeof(BillingDbContext).Assembly);
    
    // Convert to PostgreSQL snake_case naming conventions
    foreach (var entity in modelBuilder.Model.GetEntityTypes())
    {
        // Convert Table Names
        entity.SetTableName(entity.GetTableName()?.ToSnakeCase());
        
        // Convert Column Names
        foreach (var property in entity.GetProperties())
        {
            property.SetColumnName(property.GetColumnName()?.ToSnakeCase());
        }
    }
}
```

---

## 3. Initializing PostgreSQL EF Core Migrations

Once the entities are ported, we bootstrap the new PostgreSQL database using EF migrations.

### Steps:
1. Configure Npgsql in the backend Web API:
   ```csharp
   builder.Services.AddDbContext<BillingDbContext>(options =>
       options.UseNpgsql(builder.Configuration.GetConnectionString("PostgreSqlConnection")));
   ```
2. Generate the initial migrations:
   ```bash
   dotnet ef migrations add InitialPostgresSchema --project Code/Components/DsfEMR.DalLayer --startup-project Code/Websites/DsfEMR
   ```
3. Apply the schema directly to PostgreSQL:
   ```bash
   dotnet ef database update --project Code/Components/DsfEMR.DalLayer --startup-project Code/Websites/DsfEMR
   ```

---

## 4. Historical Data Migration Strategy

To copy the existing medical records and transactional data from SQL Server to PostgreSQL:
- **Approach A (Recommended for small/medium DBs)**: Write a lightweight custom C# console utility inside the solution that reads data via SQL Server DbContext and writes it in batches to the PostgreSQL DbContext. This automatically handles C# mapping and timezone formatting.
- **Approach B (Recommended for large DBs)**: Use the open-source **`pgloader`** tool. Define a pgloader config script to convert MSSQL structures and migrate data dynamically into PostgreSQL.
