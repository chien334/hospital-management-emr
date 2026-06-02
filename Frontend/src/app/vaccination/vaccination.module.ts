import { NgModule } from '@angular/core';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { Routes, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';

import { SharedModule } from "../shared/shared.module";
import { AngularMultiSelectModule } from "angular2-multiselect-dropdown";
import { DanpheAutoCompleteModule } from '../shared/danphe-autocomplete';
import { MaternityRoutingModule } from './vaccination-routing.module';
import { VaccinationMainComponent } from './vaccination-main.component';
import { VaccinationPatientListComponent } from './patient-list/vaccination-patient-list.component';
import { VaccinationService } from './shared/vaccination.service';
import { VaccinationBLService } from './shared/vaccination.bl.service';
import { VaccinationDLService } from './shared/vaccination.dl.service';
import { VaccinationPatientRegistrationComponent } from './vaccination-patient-registration/vaccination-patient-registration.component';
import { PatientVaccinationDetailComponent } from './patient-vaccination-detail/patient-vaccination-detail';
import { VaccinationReportComponent } from './reports/vaccination-report.main.component';
import { PatientVaccinationDetailReportComponent } from './reports/vaccination-detail-report/patient-vaccine-report.component';
import { VaccineSelectComponent } from './shared/vaccine-select/vacc-select.component';
import { VaccinationStickerComponent } from './vacc-sticker/vaccination-sticker.component';
import { SettingsSharedModule } from '../settings-new/settings-shared.module';
import { VaccinationFollowupAddComponent } from './follow-up/vaccination-followup-add.component';
import { PatientVaccinationAppointmentDetailsReportComponent } from './reports/vaccination-appointment-details-report/vaccination-appointment-details-report.component';

@NgModule({ declarations: [
        VaccinationMainComponent,
        VaccinationPatientListComponent,
        VaccinationPatientRegistrationComponent,
        PatientVaccinationDetailComponent,
        PatientVaccinationAppointmentDetailsReportComponent,
        VaccinationReportComponent,
        PatientVaccinationDetailReportComponent,
        VaccineSelectComponent,
        VaccinationStickerComponent,
        VaccinationFollowupAddComponent
    ],
    bootstrap: [], imports: [MaternityRoutingModule,
        ReactiveFormsModule,
        FormsModule,
        CommonModule,
        AngularMultiSelectModule,
        SharedModule,
        DanpheAutoCompleteModule,
        SettingsSharedModule], providers: [VaccinationService, VaccinationBLService, VaccinationDLService] })
export class VaccinationModule { }
