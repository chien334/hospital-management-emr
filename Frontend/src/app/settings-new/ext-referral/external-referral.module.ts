import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { HashLocationStrategy, LocationStrategy } from "@angular/common";

import { SharedModule } from '../../shared/shared.module';

//import { ExternalReferralMainComponent } from './external-referral-main.component';
//import { AddExternalReferralComponent } from './add-new/add-ext-referral.component';
import { ListExternalReferralComponent } from './list/list-ext-referral.component';
import { SettingsSharedModule } from '../settings-shared.module';


export const extRefSettingsRoutes =
  [
    {
      path: '', component: ListExternalReferralComponent
    }
  ] 


@NgModule({ declarations: [
        //AddExternalReferralComponent,
        ListExternalReferralComponent
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        RouterModule.forChild(extRefSettingsRoutes),
        SettingsSharedModule], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy },
        provideHttpClient(withInterceptorsFromDi())
    ] })

export class ExternalReferralModule {

}
