import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

import { HashLocationStrategy, LocationStrategy } from "@angular/common";
import { SharedModule } from '../shared/shared.module';
import { SocialServiceUnitRoutingModule } from './ssu-routing.module';
import { SSU_PatientListComponent } from './patient-list/ssu-patient-list.component';
import { SocialServiceUnitMainComponent } from './social-service-unit-main.component';
import { SSU_DLService } from './shared/ssu.dl.service';
import { SSU_BLService } from './shared/ssu.bl.service';
import { SSU_PatientComponent } from './patient/ssu-patient.component';
import { SettingsSharedModule } from '../settings-new/settings-shared.module';
import { DanpheAutoCompleteModule } from '../shared/danphe-autocomplete';

@NgModule({ declarations: [
        SocialServiceUnitMainComponent,
        SSU_PatientListComponent,
        SSU_PatientComponent
    ], imports: [CommonModule,
        ReactiveFormsModule,
        SocialServiceUnitRoutingModule,
        FormsModule,
        SharedModule,
        DanpheAutoCompleteModule,
        SettingsSharedModule], providers: [
        SSU_DLService,
        SSU_BLService
    ] })
export class SocialServiceUnitModule { }