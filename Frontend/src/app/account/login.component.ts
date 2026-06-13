import { HttpClient } from '@angular/common/http';
import { Component, OnDestroy, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { TranslateService } from '@ngx-translate/core';
import { NavigationService } from '../shared/navigation-service';

@Component({
  selector: 'dsf-login',
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.css']
})
export class LoginComponent implements OnInit, OnDestroy {
  public username = '';
  public password = '';
  public rememberMe = false;
  public showPassword = false;
  public loading = false;
  public errorMessage = '';

  constructor(
    private http: HttpClient,
    private router: Router,
    private navService: NavigationService,
    public translate: TranslateService
  ) {}

  ngOnInit(): void {
    // Hide navigation elements for the isolated login page
    this.navService.showSideNav = false;
    this.navService.showTopNav = false;

    // Check if user is already authenticated
    const token = localStorage.getItem('jwt_token');
    if (token) {
      // If already logged in, redirect to root dashboard
      this.router.navigate(['/']);
    }
  }

  ngOnDestroy(): void {
    // Restore navigation layout when moving away from login
    this.navService.showSideNav = true;
    this.navService.showTopNav = true;
  }

  get currentLanguageName(): string {
    return this.translate.currentLang === 'en' ? 'English' : 'Tiếng Việt';
  }

  switchLanguage(lang: string): void {
    this.translate.use(lang);
    localStorage.setItem('selected_language', lang);
  }

  togglePasswordVisibility(): void {
    this.showPassword = !this.showPassword;
  }

  onSubmit(): void {
    if (!this.username.trim() || !this.password.trim()) {
      this.errorMessage = this.translate.instant('LOGIN.ERROR_REQUIRED');
      return;
    }

    this.loading = true;
    this.errorMessage = '';

    const payload = {
      UserName: this.username,
      Password: this.password,
      RememberMe: this.rememberMe
    };

    this.http.post<any>('/api/Account/GetLoginJwtToken', payload).subscribe(
      res => {
        this.loading = false;
        if (res && res.loginJwtToken) {
          // Store token in both key names for absolute compatibility
          localStorage.setItem('jwt_token', res.loginJwtToken);
          localStorage.setItem('loginJwtToken', res.loginJwtToken);
          
          // Clear any logout flags
          localStorage.removeItem('logout-event');

          // Clean bootstrap reload to ensure all application state/routes load correctly
          window.location.href = '/';
        } else {
          this.errorMessage = this.translate.instant('LOGIN.ERROR_INVALID');
        }
      },
      err => {
        this.loading = false;
        if (err.status === 401 || err.status === 403) {
          this.errorMessage = this.translate.instant('LOGIN.ERROR_INVALID');
        } else {
          this.errorMessage = this.translate.instant('LOGIN.ERROR_GENERIC');
        }
        console.error('Login error details:', err);
      }
    );
  }
}
