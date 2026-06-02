import { NgModule } from '@angular/core';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { Routes, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

import { SharedModule } from "../shared/shared.module";
import { AngularMultiSelectModule } from "angular2-multiselect-dropdown";
import { DanpheAutoCompleteModule } from '../shared/danphe-autocomplete';
import { SettingsSharedModule } from '../settings-new/settings-shared.module';
import { QueueManagementRoutingModule } from './queue-management-routing.module';
import { QueueManagementMainComponent } from './queue-management-main-component';
import { QueueManagementOpdComponent } from './opd/opd.component';
import { QueueManagementService } from './shared/Qmgnt.service';
import { QueueManagementDLService } from './shared/Qmgnt.dl.service';
import { QueueManagementBLService } from './shared/Qmgnt.bl.service';
@NgModule({ declarations: [
        QueueManagementMainComponent,
        QueueManagementOpdComponent
    ],
    bootstrap: [], imports: [QueueManagementRoutingModule,
        ReactiveFormsModule,
        FormsModule,
        CommonModule,
        AngularMultiSelectModule,
        SharedModule,
        DanpheAutoCompleteModule,
        SettingsSharedModule], providers: [QueueManagementService, QueueManagementDLService, QueueManagementBLService] })
export class QueueManagementModule { }
