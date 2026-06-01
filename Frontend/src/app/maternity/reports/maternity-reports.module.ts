import { NgModule } from '@angular/core';
import { Routes, RouterModule, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { DanpheAutoCompleteModule } from '../../shared/danphe-autocomplete';
import { SharedModule } from '../../shared/shared.module';
import { ReportingService } from '../../reporting/shared/reporting-service';
import { MaternityReportsMatAllowanceComponent } from './maternity-allowance-report/mat-allowance-report.component';
import { MaternityReportsComponent } from './maternity-reports.component';
import { MaternityReportsRoutingModule } from './maternity-reports-routing.module';
import { MaternitySharedModule } from '../shared/maternity-shared-module';



@NgModule({ declarations: [
        MaternityReportsComponent,
        MaternityReportsMatAllowanceComponent
    ],
    bootstrap: [MaternityReportsComponent], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        DanpheAutoCompleteModule,
        SharedModule,
        MaternityReportsRoutingModule,
        MaternitySharedModule], providers: [
        ReportingService,
        provideHttpClient(withInterceptorsFromDi())
    ] })
export class MaternityReportsModule {


} 
