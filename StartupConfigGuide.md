# Startup.cs Configuration Guide for EF Core Migration

Below is a sample implementation of the `ConfigureServices` method in `Startup.cs` to use Entity Framework Core DbContext classes. You'll need to modify your existing Startup.cs file to include these changes.

```csharp
public void ConfigureServices(IServiceCollection services)
{
    // Get connection string from configuration
    string connStr = Configuration.GetConnectionString("DefaultConnection");

    // Add DbContext classes as services
    services.AddScoped<DanpheEMR.DalLayer.AdmissionDbContext>(serviceProvider => {
        return new DanpheEMR.DalLayer.AdmissionDbContext(connStr);
    });
    
    services.AddScoped<DanpheEMR.Core.CoreDbContext>(serviceProvider => {
        return new DanpheEMR.Core.CoreDbContext(connStr);
    });
    
    services.AddScoped<DanpheEMR.DalLayer.InventoryDbContext>(serviceProvider => {
        return new DanpheEMR.DalLayer.InventoryDbContext(connStr);
    });
    
    services.AddScoped<DanpheEMR.DalLayer.PharmacyDbContext>(serviceProvider => {
        return new DanpheEMR.DalLayer.PharmacyDbContext(connStr);
    });
    
    services.AddScoped<DanpheEMR.DalLayer.BillingDbContext>(serviceProvider => {
        return new DanpheEMR.DalLayer.BillingDbContext(connStr);
    });
    
    services.AddScoped<DanpheEMR.DalLayer.AccountingDbContext>(serviceProvider => {
        return new DanpheEMR.DalLayer.AccountingDbContext(connStr);
    });
    
    // Configure EF Core with other settings if needed
    services.AddDbContext<ApplicationDbContext>(options =>
        options.UseSqlServer(connStr));
    
    // Configure lazy loading if needed
    services.AddDbContext<ApplicationDbContext>(options =>
        options.UseLazyLoadingProxies()
               .UseSqlServer(connStr));
    
    // Add other services and configurations
    services.AddControllers()
            .AddNewtonsoftJson(options => {
                options.SerializerSettings.ReferenceLoopHandling = Newtonsoft.Json.ReferenceLoopHandling.Ignore;
            });
    
    // Add MVC services
    services.AddMvc();
    
    // Add other required services
    // ...
}
```

## How to Apply the Changes

1. Locate your `Startup.cs` file in the main web application project
2. Replace the existing DbContext registrations with the ones above
3. Make sure to keep any other service registrations specific to your application
4. Update your controllers to use the injected DbContext classes

## Important Configuration Notes

### Lazy Loading

If your application relies on lazy loading:

```csharp
// 1. Add this package reference
// <PackageReference Include="Microsoft.EntityFrameworkCore.Proxies" Version="3.1.32" />

// 2. Enable lazy loading in OnConfiguring
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    if (!optionsBuilder.IsConfigured)
    {
        optionsBuilder.UseLazyLoadingProxies()
                     .UseSqlServer(_connectionString);
    }
}
```

### Command Timeout

For long-running queries:

```csharp
protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
{
    if (!optionsBuilder.IsConfigured)
    {
        optionsBuilder.UseSqlServer(_connectionString, 
            options => options.CommandTimeout(180)); // 3 minutes
    }
}
```

### Database Creation and Migrations

Optionally, you can apply migrations at startup:

```csharp
public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
{
    // Other configuration...
    
    // Apply migrations
    using (var serviceScope = app.ApplicationServices.GetRequiredService<IServiceScopeFactory>().CreateScope())
    {
        var context = serviceScope.ServiceProvider.GetService<ApplicationDbContext>();
        context.Database.Migrate();
    }
    
    // Other middleware...
}
```
