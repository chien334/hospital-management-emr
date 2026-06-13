using Audit.SqlServer.Providers;
using DsfEMR.CommonTypes;
using DsfEMR.Controllers.Settings.DTO;
using DsfEMR.Core.Caching;
using DsfEMR.Core.Configuration;
using DsfEMR.DalLayer;
using DsfEMR.DependencyInjection;
using DsfEMR.Security;
using DsfEMR.ServerModel;
using DsfEMR.Services;
using DsfEMR.Services.Billing;
using DsfEMR.Services.ClaimManagement;
using DsfEMR.Services.Dispensary;
using DsfEMR.Services.DispensaryTransfer;
using DsfEMR.Services.IMU;
using DsfEMR.Services.Inventory.InventoryDonation;
using DsfEMR.Services.LIS;
using DsfEMR.Services.Maternity;
using DsfEMR.Services.Medicare;
using DsfEMR.Services.Pharmacy.Mapper.PurchaseOrder;
using DsfEMR.Services.Pharmacy.PharmacyPO;
using DsfEMR.Services.Pharmacy.Rack;
using DsfEMR.Services.Pharmacy.SupplierLedger;
using DsfEMR.Services.ProcessConfirmation;
using DsfEMR.Services.QueueManagement;
using DsfEMR.Services.SSF;
using DsfEMR.Services.Utilities;
using DsfEMR.Services.Vaccination;
using DsfEMR.Utilities;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Razor;
using Microsoft.CodeAnalysis;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Newtonsoft.Json.Serialization;
using Swashbuckle.AspNetCore.Swagger;
using System;
using System.Collections.Generic;
using Microsoft.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;

namespace DsfEMR
{
    public class Startup
    {

        public IConfigurationRoot Configuration { get; }
        public IWebHostEnvironment CurrentEnvironment { get; set; }

        public Startup(IWebHostEnvironment env)
        {
            var builder = new ConfigurationBuilder()
                .SetBasePath(env.ContentRootPath)
                .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true)
                .AddJsonFile($"appsettings.{env.EnvironmentName}.json", optional: true)
                .AddEnvironmentVariables();
            Configuration = builder.Build();

            CurrentEnvironment = env;
            //check audit is enable or disable             
            if ((!string.IsNullOrEmpty(Configuration["IsAuditEnable"])) && Convert.ToBoolean(Configuration["IsAuditEnable"]) == true)
            {
                string adminConstr = Configuration["ConnectionStringAdmin"];
                bool isPg = adminConstr.Contains("Host=", StringComparison.OrdinalIgnoreCase) || adminConstr.Contains("Port=", StringComparison.OrdinalIgnoreCase);

                if (isPg)
                {
                    var conBuilderObj = new Npgsql.NpgsqlConnectionStringBuilder(adminConstr);
                    string encPwd = conBuilderObj.Password;
                    if (!string.IsNullOrEmpty(encPwd))
                    {
                        string decPwd = DecryptPassword(encPwd);
                        conBuilderObj.Password = decPwd;
                    }
                    Audit.Core.Configuration.DataProvider = new Audit.PostgreSql.Providers.PostgreSqlDataProvider()
                    {
                        ConnectionString = conBuilderObj.ConnectionString,
                        Schema = "public",
                        TableName = "DsfAudit",
                        IdColumnName = "AuditId",
                        DataColumnName = "Data",
                        LastUpdatedDateColumnName = "LastUpdatedDate"
                    };
                }
                else
                {
                    SqlConnectionStringBuilder conBuilderObj = new SqlConnectionStringBuilder(adminConstr);
                    string encPwd = conBuilderObj.Password;
                    if (!string.IsNullOrEmpty(encPwd))
                    {
                        string decPwd = DecryptPassword(encPwd);
                        conBuilderObj.Password = decPwd;
                    }
                    Audit.Core.Configuration.DataProvider = new SqlDataProvider()
                    {
                        ConnectionString = conBuilderObj.ConnectionString,
                        Schema = "dbo",
                        TableName = "DsfAudit",
                        IdColumnName = "AuditId",
                        JsonColumnName = "Data",
                        LastUpdatedDateColumnName = "LastUpdatedDate"
                    };
                }
            }


        }


        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            //start--for rbac-testing--sudarshanr--2march-2017
            //services.AddSession();

            // Adds a default in-memory implementation of IDistributedCache.
            //services.AddDistributedMemoryCache();//removed after using sqlserver-distributed cache-18apr'17-sudarshan

            services.AddSession(options =>
            {
                //IMPORTANT-- remove the hardcoded value 20 from below
                //keep short timeout like max 2-3 hours, 
                //we've to redirect to login once the session expires.
                options.IdleTimeout = TimeSpan.FromHours(2);
                options.Cookie.HttpOnly = true;

            });
            //end--for rbac-testing--sudarshanr

            //Krishna, 19thMay'23, Moved all the interfaces and services that were registered here into an extension method, Do not registered them in Startup file itself,
            //instead add them in that extension method(used just below this comment)
            services.AddDsfServices(Configuration);

            var mapperConfig = new AutoMapper.MapperConfiguration(mc =>
            {
                mc.AddProfile(new MappingProfile());
                mc.AddProfile(new PurchaseOrderMappingProfile());
            });
            AutoMapper.IMapper mapper = mapperConfig.CreateMapper();
            services.AddSingleton(mapper);

            // Add framework services.
            services.AddOptions();

            services.Configure<MyConfiguration>(Configuration);

            //Krishna, 19thMay'23, Moved the registration of Swagger and JWT to an extension method inside ConfigureServices class.
            services.AddSwaggerAndJwtServices(Configuration);

            //start: sud-9Jan'19 for pwd encryption testing

            string connStr = Configuration["Connectionstring"];
            bool isPgConn = connStr.Contains("Host=", StringComparison.OrdinalIgnoreCase) || connStr.Contains("Port=", StringComparison.OrdinalIgnoreCase);

            if (isPgConn)
            {
                var connStringBuilder = new Npgsql.NpgsqlConnectionStringBuilder(connStr);
                string encPassword = connStringBuilder.Password;
                if (!string.IsNullOrEmpty(encPassword))
                {
                    string decrypted = DecryptPassword(encPassword);
                    connStringBuilder.Password = decrypted;
                    Configuration["Connectionstring"] = connStringBuilder.ToString();
                }
            }
            else
            {
                SqlConnectionStringBuilder connStringBuilder = new SqlConnectionStringBuilder(connStr);
                string encPassword = connStringBuilder.Password;
                if (!string.IsNullOrEmpty(encPassword))
                {
                    string decrypted = DecryptPassword(encPassword);
                    connStringBuilder.Password = decrypted;
                    Configuration["Connectionstring"] = connStringBuilder.ToString();
                }
            }

            //For DsfAdmin Database connectionstring.
            string connStrAdmin = Configuration["ConnectionStringAdmin"];
            bool isPgConnAdmin = connStrAdmin.Contains("Host=", StringComparison.OrdinalIgnoreCase) || connStrAdmin.Contains("Port=", StringComparison.OrdinalIgnoreCase);

            if (isPgConnAdmin)
            {
                var connStringBuilder2 = new Npgsql.NpgsqlConnectionStringBuilder(connStrAdmin);
                string encPwd_Admin = connStringBuilder2.Password;
                if (!string.IsNullOrEmpty(encPwd_Admin))
                {
                    string decPwd_Admin = DecryptPassword(encPwd_Admin);
                    connStringBuilder2.Password = decPwd_Admin;
                    Configuration["ConnectionStringAdmin"] = connStringBuilder2.ToString();
                }
            }
            else
            {
                SqlConnectionStringBuilder connStringBuilder2 = new SqlConnectionStringBuilder(connStrAdmin);
                string encPwd_Admin = connStringBuilder2.Password;
                if (!string.IsNullOrEmpty(encPwd_Admin))
                {
                    string decPwd_Admin = DecryptPassword(encPwd_Admin);
                    connStringBuilder2.Password = decPwd_Admin;
                    Configuration["ConnectionStringAdmin"] = connStringBuilder2.ToString();
                }
            }

            //end: sud-9Jan'19 for pwd encryption testing


            services.AddMvc(options => options.EnableEndpointRouting = false)
                        .AddJsonOptions(options => options.JsonSerializerOptions.PropertyNamingPolicy = null); // added for disabling serialising json with camel case

            //services.AddMvc().AddApplicationPart(typeof(LoginViewModel).Assembly);
            //start: using service configuration for caching class.--sudarshan 1march'17
            //once we've added appsetting.json into the Configuration, it's accessible easily using the key.
            string connString = Configuration["Connectionstring"];
            int cacheExpMins = Convert.ToInt32(Configuration["CacheExpirationMinutes"]);
            //add cache as singleton since there should be one global object of it.. 
            services.AddSingleton<DsfCache>(new DsfCache(connString, cacheExpMins));
            //end: using service configuration for caching class.

            //used in LabReportExport to differntiate abnormal values based on this parameter
            bool highlightAbnormalLabResult = Convert.ToBoolean(Configuration["highlightAbnormalLabResult"]);

            //AuditTrail Enable and Disable 
            string auditValueStr = Configuration["IsAuditEnable"];
            if (!string.IsNullOrEmpty(auditValueStr))
            {
                bool IsAuditEnable = Convert.ToBoolean(auditValueStr);
                if (IsAuditEnable == false)
                {
                    Audit.Core.Configuration.AuditDisabled = true;
                }
            }
            else
            {
                Audit.Core.Configuration.AuditDisabled = true;
            }

            ////for distributed sqlserver caching --added: 18Apr2017-sudarshan
            //services.AddDistributedSqlServerCache(options =>
            //{
            //    options.ConnectionString = connString;
            //    options.SchemaName = "dbo";
            //    options.TableName = "CORE_DistributedCache"; // this has to be same what we gave while running the command.
            //});

            //add RBAC also as a singleton service.          
            services.AddSingleton<RBAC>(new RBAC(connString, cacheExpMins));
            ///add nepali date as a singleton for one time initialization.
            services.AddSingleton<NepaliDate>(new NepaliDate(connString));

            //add FileUploader as a singleton as well
            string storagePath = CurrentEnvironment.WebRootPath + "\\" + Configuration["FileStorageRelativeLocation"];
            services.AddSingleton<FileUploader>(new FileUploader(storagePath));

            services.Configure<Microsoft.AspNetCore.Server.Kestrel.Core.KestrelServerOptions>(options =>
            {
                options.AllowSynchronousIO = true;
            });
            services.Configure<Microsoft.AspNetCore.Builder.IISServerOptions>(options =>
            {
                options.AllowSynchronousIO = true;
            });

            // Razor dynamic compilation is obsolete in .NET 8 Web API
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            app.UseDeveloperExceptionPage();
            app.UseMiddleware<RewindMiddleWare>();
            //start--for rbac-testing--sudarshanr--2march-2017
            app.UseSession();

            //end--for rbac-testing--sudarshanr


            app.UseMvc(
                routes =>
                {
                    routes.MapRoute("DefaultRoute", "{controller}/{action}");
                    routes.MapRoute(name: "Default", template: "{controller=Home}/{action=Index}/{id?}");
                }
                );

            string isDevEnv = Configuration["environment:isdevelopment"];

            if (bool.Parse(isDevEnv))//env.IsDevelopment build it only if it's development.
            {
                //Use Swagger
                app.UseSwagger();
                app.UseSwaggerUI(c =>
                {
                    c.SwaggerEndpoint("/swagger/v1/swagger.json", "DsfEMR-APIs-v1");
                });
            }
        }


        //start: sud-9Jan'19-- for ConnectionString encryption/decryption

        //use existing decrypt method from RBAC.
        private string DecryptPassword(string encryptedPwd)
        {
            try
            {
                string retVal = DsfEMR.Security.RBAC.DecryptPassword(encryptedPwd);
                return retVal;
            }
            catch (Exception)
            {
                return encryptedPwd;
            }
        }

        //end: sud-9Jan'19-- for ConnectionString encryption/decryption

    }
}
