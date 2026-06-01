import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';

import { CoreDLService } from './shared/core.dl.service';
import { CoreBLService } from './shared/core.bl.service';
import { CoreService } from './shared/core.service';
import { authInterceptorProviders } from '../shared/token-interceptor/token-interceptor.service';
//import { BackButtonDisable } from './shared/backbutton-disable.service'

@NgModule({ declarations: [],
    bootstrap: [] //do we need anything here ? <sudarshan:2jan2017>
    , imports: [CommonModule], providers: [CoreDLService, CoreBLService, CoreService, authInterceptorProviders, provideHttpClient(withInterceptorsFromDi())] })
export class CoreModule {

}