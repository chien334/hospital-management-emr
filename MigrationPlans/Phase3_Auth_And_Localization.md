# Phase 3: JWT Authentication & Frontend Multi-Language

This phase implements secure, stateless authentication and adds dynamic Vietnamese and English localization.

---

## 1. Stateless JWT Authentication (Backend)

We will replace legacy coupled sessions with standard signed JSON Web Tokens.

### AuthController implementation:
Create `/Controllers/Security/AuthController.cs`:
```csharp
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IConfiguration _config;
    private readonly RbacDbContext _context;

    public AuthController(IConfiguration config, RbacDbContext context)
    {
        _config = config;
        _context = context;
    }

    [HttpPost("login")]
    public IActionResult Login([FromBody] LoginRequest request)
    {
        // 1. Verify User Credentials
        var user = _context.Users.FirstOrDefault(u => u.UserName == request.UserName && u.Password == request.Password);
        if (user == null) return Unauthorized(new { message = "Invalid credentials" });

        // 2. Generate JWT Claims
        var claims = new[] {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(ClaimTypes.Name, user.UserName),
            new Claim(ClaimTypes.Role, user.RoleId.ToString())
        };

        // 3. Create Key and Signature
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        // 4. Generate Token
        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.Now.AddHours(8),
            signingCredentials: creds
        );

        return Ok(new {
            token = new JwtSecurityTokenHandler().WriteToken(token),
            userName = user.UserName,
            userId = user.UserId
        });
    }
}
```

### Configure JWT Settings in `appsettings.json`:
```json
{
  "Jwt": {
    "Key": "SuperSecretKeyEnsure32CharactersOrMoreLongHere!!",
    "Issuer": "DanpheEmrAPI",
    "Audience": "DanpheEmrClient"
  }
}
```

---

## 2. JWT Authentication Interceptor (Frontend)

We will automatically capture and attach the token on the Angular client.

### Angular Interceptor (`TokenInterceptor.ts`):
Create `/Frontend/src/app/shared/interceptors/token.interceptor.ts`:
```typescript
import { Injectable } from '@angular/core';
import { HttpRequest, HttpHandler, HttpEvent, HttpInterceptor, HttpErrorResponse } from '@angular/common/http';
import { Observable, throwError } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { Router } from '@angular/router';

@Injectable()
export class TokenInterceptor implements HttpInterceptor {
    constructor(private router: Router) {}

    intercept(request: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
        const token = localStorage.getItem('jwt_token');
        if (token) {
            request = request.clone({
                setHeaders: {
                    Authorization: `Bearer ${token}`
                }
            });
        }
        return next.handle(request).pipe(
            catchError((error: HttpErrorResponse) => {
                if (error.status === 401 || error.status === 403) {
                    // Redirect to login on token expiration
                    localStorage.removeItem('jwt_token');
                    this.router.navigate(['/login']);
                }
                return throwError(error);
            })
        );
    }
}
```

---

## 3. Frontend Multi-Language (ngx-translate)

We will configure dynamic bilingual translation between Vietnamese (Việt) and English (Anh).

### Installation:
```bash
cd /Frontend
npm install @ngx-translate/core @ngx-translate/http-loader --save
```

### Configure Translation Files:
Create localization files under `/Frontend/src/assets/i18n/`:

#### `vi.json` (Vietnamese):
```json
{
  "LOGIN": {
    "TITLE": "Đăng Nhập Hệ Thống EMR",
    "USERNAME": "Tên đăng nhập",
    "PASSWORD": "Mật khẩu",
    "BUTTON": "Đăng Nhập"
  },
  "NAVBAR": {
    "PATIENTS": "Danh sách bệnh nhân",
    "APPOINTMENTS": "Lịch hẹn",
    "BILLING": "Thanh toán"
  }
}
```

#### `en.json` (English):
```json
{
  "LOGIN": {
    "TITLE": "EMR System Login",
    "USERNAME": "Username",
    "PASSWORD": "Password",
    "BUTTON": "Login"
  },
  "NAVBAR": {
    "PATIENTS": "Patients List",
    "APPOINTMENTS": "Appointments",
    "BILLING": "Billing"
  }
}
```

### Setup Switcher Dropdown in UI:
Inject the `TranslateService` in your navbar component and switch languages on selection:
```typescript
import { TranslateService } from '@ngx-translate/core';

constructor(private translate: TranslateService) {
    translate.setDefaultLang('vi'); // Set default
    const savedLang = localStorage.getItem('selected_language');
    translate.use(savedLang || 'vi');
}

switchLanguage(lang: string) {
    this.translate.use(lang);
    localStorage.setItem('selected_language', lang);
}
```
In the HTML template, bind using:
```html
<label>{{ 'LOGIN.USERNAME' | translate }}</label>
```
