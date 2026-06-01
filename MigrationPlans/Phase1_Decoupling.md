# Phase 1: Decoupling, Project Conversion & Isolation

This phase focuses on extracting the embedded Angular application and converting the .NET projects to the modern cross-platform SDK-style targeting **.NET 8.0**.

---

## 1. Extracting the Frontend SPA

Currently, the Angular 7 application sits in `Code/Websites/DanpheEMR/wwwroot/DanpheApp`. We will move it to the root of the workspace.

### Steps:
1. Create a root directory named `/Frontend`.
2. Move all contents of `/Code/Websites/DanpheEMR/wwwroot/DanpheApp/*` to `/Frontend`.
3. In `/Frontend/angular.json`, update the `outputPath` configuration:
   ```json
   "outputPath": "dist/danphe-app"
   ```
4. Verify the frontend builds independently:
   ```bash
   cd /Frontend
   npm install
   npm run build
   ```

---

## 2. Converting Backend Projects to SDK-Style (.NET 8.0)

All library projects (`Code/Components/*`) and the main Web project (`Code/Websites/DanpheEMR`) currently use old MSBuild formats and target `.NET Framework 4.6.1`. We will convert them to SDK-Style targeting `net8.0`.

### Migration Steps per Project:
1. **Backup**: Ensure a clean git branch is checked out before modifying `.csproj` files.
2. **Convert Project Files**: Replace the contents of each `.csproj` with the modern, simplified SDK-style XML.

#### Example Component Project (`DanpheEMR.DalLayer.csproj`):
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <AssemblyName>DanpheEMR.DalLayer</AssemblyName>
    <RootNamespace>DanpheEMR.DalLayer</RootNamespace>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.EntityFrameworkCore" Version="8.0.0" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\DanpheEMR.Core\DanpheEMR.Core.csproj" />
    <ProjectReference Include="..\DanpheEMR.Security\DanpheEMR.Security.csproj" />
    <ProjectReference Include="..\DanpheEMR.ServerModel\DanpheEMR.ServerModel.csproj" />
  </ItemGroup>
</Project>
```

3. **Delete Obsolete Files**:
   - Delete `packages.config` files inside the projects (NuGet packages are now declared directly inside the `.csproj` file).
   - Delete `Properties/AssemblyInfo.cs` files (metadata like AssemblyVersion is now configured inside the `.csproj` file or auto-generated).

---

## 3. Detaching static file serving from Web API

The main project `DanpheEMR` will be stripped of MVC View and static asset hosting configurations.

### Program.cs Actions:
- Remove static file middleware calls like `app.UseStaticFiles()` and `app.UseDefaultFiles()`.
- Delete the `/Views` directory in the backend project.
- Enable CORS (Cross-Origin Resource Sharing) to allow requests from the standalone frontend.
