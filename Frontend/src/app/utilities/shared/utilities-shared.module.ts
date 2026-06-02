import { CommonModule } from "@angular/common";

import { NgModule } from "@angular/core";
import { FormsModule, ReactiveFormsModule } from "@angular/forms";
import { BillingSharedModule } from "../../billing/billing-shared.module";
import { SharedModule } from "../../shared/shared.module";
import { PrintOrganizationDepositComponent } from "../organization-deposit/print-pages/print-organization-deposit.component";
import { ProcessConfirmationComponent } from "./process-confirmation/process-confirmation.component";
import { UtilitiesBLService } from "./utilities.bl.service";
import { UtilitiesDLService } from "./utilities.dl.service";


@NgModule({ declarations: [
        PrintOrganizationDepositComponent,
        ProcessConfirmationComponent
    ],
    exports: [
        PrintOrganizationDepositComponent,
        ProcessConfirmationComponent
    ],
    bootstrap: [], imports: [ReactiveFormsModule,
        FormsModule,
        CommonModule,
        SharedModule,
        BillingSharedModule], providers: [
        UtilitiesBLService,
        UtilitiesDLService] })
export class UtilitiesSharedModule { }
