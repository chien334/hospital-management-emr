# Phase 5: Verification, Dockerization & CI/CD Deployment

This final phase focuses on end-to-end verification, containerizing both separated projects, and establishing standard CI/CD deployment pipelines.

---

## 1. Testing and Verification

Once the components are decoupled and upgraded, we must run verification tests.

### A. Backend Web API Unit/Integration Tests:
Create a testing project `DanpheEMR.Tests` to assert connection, database context operations, and authentication logic.
```csharp
[Fact]
public async Task GetPatients_WithoutToken_ReturnsUnauthorized()
{
    var client = _factory.CreateClient();
    var response = await client.GetAsync("/api/patient");
    Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
}
```

### B. CORS and Pre-flight Verification:
Ensure the API responds to CORS request preflights correctly. Run:
```bash
curl -I -X OPTIONS -H "Origin: http://localhost:4200" -H "Access-Control-Request-Method: GET" http://localhost:5000/api/patient
```
Verify the output includes `Access-Control-Allow-Origin: http://localhost:4200` headers.

---

## 2. Dockerization Strategy

We will containerize the backend and frontend separately to run on any cross-platform cloud infrastructure (Linux/Docker).

### A. Backend Web API `Dockerfile` (`/Dockerfile.backend`):
```dockerfile
# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["Code/Websites/DanpheEMR/DanpheEMR.csproj", "Code/Websites/DanpheEMR/"]
COPY ["Code/Components/DanpheEMR.DalLayer/DanpheEMR.DalLayer.csproj", "Code/Components/DanpheEMR.DalLayer/"]
# Copy other projects...
RUN dotnet restore "Code/Websites/DanpheEMR/DanpheEMR.csproj"
COPY . .
WORKDIR "/src/Code/Websites/DanpheEMR"
RUN dotnet build "DanpheEMR.csproj" -c Release -o /app/build

# Publish Stage
FROM build AS publish
RUN dotnet publish "DanpheEMR.csproj" -c Release -o /app/publish

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "DanpheEMR.dll"]
```

### B. Frontend Angular `Dockerfile` (`/Dockerfile.frontend`):
```dockerfile
# Build Stage
FROM node:20 AS build
WORKDIR /app
COPY Frontend/package*.json ./
RUN npm install
COPY Frontend/ .
RUN npm run build --configuration=production

# Nginx Stage to Serve Static Assets
FROM nginx:alpine
COPY --from=build /app/dist/danphe-app /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## 3. Continuous Integration & Deployment (CI/CD)

We will configure GitHub Actions workflows to automate code verification and delivery.

### Workflow Example (`.github/workflows/deploy.yml`):
```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]

jobs:
  backend-ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup .NET
        uses: actions/setup-dotnet@v3
        with:
          dotnet-version: '8.0.x'
      - name: Restore dependencies
        run: dotnet restore Code/Solutions/DanpheEMR.sln
      - name: Build
        run: dotnet build Code/Solutions/DanpheEMR.sln --no-restore
      - name: Run Tests
        run: dotnet test Code/Solutions/DanpheEMR.sln

  frontend-ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: 20
      - name: Install dependencies
        run: |
          cd Frontend
          npm ci
      - name: Build Angular App
        run: |
          cd Frontend
          npm run build --prod
```
---

## 4. Final Verification Checklist

- [ ] Backend runs fully on `.NET 8.0` locally and in Docker container.
- [ ] Database migrations are created and successfully initialized on PostgreSQL.
- [ ] Angular 18/19 SPA builds and executes independently, communicating with the Web API via dynamic configs.
- [ ] Users can log in, receive a secure JWT, and navigate the application seamlessly.
- [ ] Language switching triggers dynamic rendering of translation assets (Vietnamese & English).
