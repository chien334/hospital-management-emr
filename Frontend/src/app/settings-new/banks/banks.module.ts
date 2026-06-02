import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

import { HashLocationStrategy, LocationStrategy } from "@angular/common";
import { SharedModule } from '../../shared/shared.module';
import { SettingsSharedModule } from '../settings-shared.module';
import { BankListComponent } from './list/bank-list.component';
import { AddBanksComponent } from './add-new/add-banks.component';


export const bankSettingsRoutes =
  [
    {
      path: '', component: BankListComponent
    }
  ] 


@NgModule({ declarations: [
        BankListComponent,
        AddBanksComponent
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        RouterModule.forChild(bankSettingsRoutes),
        SettingsSharedModule], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy }
    ] })

export class BanksModule {

}
