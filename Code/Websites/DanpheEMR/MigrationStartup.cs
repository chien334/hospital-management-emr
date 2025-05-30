using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using DanpheEMR.DalLayer;
using DanpheEMR.Core;

namespace DanpheEMR
{
    public class MigrationStartup
    {
        public MigrationStartup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            // Get connection string from appsettings.json
            string connStr = Configuration["Connectionstring"];
            
            if (string.IsNullOrEmpty(connStr))
            {
                throw new InvalidOperationException("Connection string 'Connectionstring' not found in configuration.");
            }

            // For migration purposes, we only need basic services
            // The existing DbContext classes use Entity Framework 6, not Entity Framework Core
            // This startup class is specifically for database migrations and doesn't need full DbContext registration
            
            // Add basic services that might be needed for migrations
            services.AddLogging();
            services.AddOptions();
            
            // Note: The actual DbContext classes in this system use Entity Framework 6 (EF6)
            // and inherit from System.Data.Entity.DbContext, not Microsoft.EntityFrameworkCore.DbContext
            // For migrations, we should use the Entity Framework 6 migration tools instead of EF Core
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            // Minimal configuration for migration scenarios
            if (env.EnvironmentName == "Development")
            {
                app.UseDeveloperExceptionPage();
            }
        }
    }
}
