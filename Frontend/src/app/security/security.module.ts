import { NgModule } from '@angular/core';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';

import { SecurityBLService } from './shared/security.bl.service';
import { SecurityDLService } from './shared/security.dl.service';
import { SecurityService } from './shared/security.service';
import { AuthGuardService } from './shared/auth-guard.service';
import { authInterceptorProviders } from '../shared/token-interceptor/token-interceptor.service';

@NgModule({ declarations: [],
    bootstrap: [], imports: [ReactiveFormsModule,
        FormsModule,
        CommonModule], providers: [SecurityService, SecurityBLService, SecurityDLService, AuthGuardService, authInterceptorProviders, provideHttpClient(withInterceptorsFromDi())] })
export class SecurityModule { }