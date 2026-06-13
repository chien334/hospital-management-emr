import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

import { HashLocationStrategy, LocationStrategy } from "@angular/common";
import { SharedModule } from '../../shared/shared.module';
import { DsfAutoCompleteModule } from '../../shared/dsf-autocomplete';
import { ParameterListComponent } from './parameters/parameter-list.component';
import { ParameterEditComponent } from './parameters/parameter-edit.component';


export const coreSettingsRoutes =
  [
    {
      path: '', component: ParameterListComponent
    }
  ]

@NgModule({ declarations: [
        ParameterListComponent,
        ParameterEditComponent
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        DsfAutoCompleteModule,
        RouterModule.forChild(coreSettingsRoutes)], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy }
    ] })
export class CoreSettingsModule {

}
