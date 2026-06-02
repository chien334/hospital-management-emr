import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

import { HashLocationStrategy, LocationStrategy } from "@angular/common";
import { SharedModule } from '../../shared/shared.module';
import { SettingsSharedModule } from '../settings-shared.module';
import { ListPrinterSettingsComponent } from './list/list-printer-settings.component';


export const printerSettingsRoutes =
  [
    {
      path: '', component: ListPrinterSettingsComponent
    }
  ] 


@NgModule({ declarations: [
        ListPrinterSettingsComponent
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        RouterModule.forChild(printerSettingsRoutes),
        SettingsSharedModule], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy }
    ] })

export class PrinterSettingModule {

}
