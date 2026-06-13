import { CommonModule } from '@angular/common';

import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { ReportingService } from '../../../reporting/shared/reporting-service';
import { DsfAutoCompleteModule } from '../../../shared/dsf-autocomplete';
import { SharedModule } from '../../../shared/shared.module';
import { InsPatientClaimDetailsView } from '../shared/ins-pat-claim-details-view/ins-pat-claim-details-view.component';
import { GovInsuranceService } from '../shared/ins-service';
import { GovInsuranceBlService } from '../shared/insurance.bl.service';
import { GovInsuranceDlService } from '../shared/insurance.dl.service';
import { GOVINSIncomeSegregationComponent } from './gov-income-segregation/gov-ins-income-segregation.component';
import { GovInsuranceReportsComponent } from './gov-ins-reports-main.component';
import { GovInsuranceReportsRoutingModule } from './gov-ins-reports-routing.module';
import { GOVINSPatientWiseClaimsComponent } from './gov-patient-wise-claims/gov-ins-patient-wise-claims.component';
import { GOVINSTotalItemsBillComponent } from './gov-total-items-bill/gov-ins-total-items-bill.component';



@NgModule({ declarations: [
        GovInsuranceReportsComponent,
        GOVINSTotalItemsBillComponent,
        GOVINSIncomeSegregationComponent,
        GOVINSPatientWiseClaimsComponent,
        InsPatientClaimDetailsView
    ],
    bootstrap: [GovInsuranceReportsComponent], imports: [CommonModule,
        ReactiveFormsModule,
        GovInsuranceReportsRoutingModule,
        FormsModule,
        DsfAutoCompleteModule,
        SharedModule], providers: [
        GovInsuranceDlService,
        GovInsuranceBlService,
        GovInsuranceService,
        ReportingService
    ] })
export class InsuranceReportsModule {


} 
