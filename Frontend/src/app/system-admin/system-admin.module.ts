import { CommonModule, HashLocationStrategy, LocationStrategy } from '@angular/common';

import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { DatabaseAuditComponent } from "./database-audit/database-audit.component";
import { DatabaseBackupComponent } from "./database-backup/database-backup.component";
import { InvoiceDetailsComponent } from "./invoice-details/invoice-details.component";
import { SalesBookReportComponent } from './sales-book/sales-book-report.component';
import { SystemAdminBLService } from "./shared/system-admin.bl.service";
import { SystemAdminDLService } from './shared/system-admin.dl.service';
import { SystemAdminMainComponent } from "./system-admin-main.component";
import { SystemAdminRoutingModule } from "./system-admin-routing.module";
//import { Ng2AutoCompleteModule } from 'ng2-auto-complete';
import { DsfAutoCompleteModule } from '../shared/dsf-autocomplete/dsf-auto-complete.module';
import { SharedModule } from "../shared/shared.module";
import { AuditTrailComponent } from './audit-trail/audit-trail.component';
import { AuditTrailOlderComponent } from './audit-trail/main-older-audit-trail';
import { NewSalesBookComponent } from './new-sales-book/new-sales-book.component';
import { PHRMSalesBookComponent } from './sales-book/phrm-sales-book-report.component';
@NgModule({ declarations: [
        SystemAdminMainComponent,
        DatabaseBackupComponent,
        DatabaseAuditComponent,
        InvoiceDetailsComponent,
        SalesBookReportComponent,
        PHRMSalesBookComponent,
        AuditTrailComponent,
        AuditTrailOlderComponent,
        NewSalesBookComponent
    ],
    bootstrap: [], imports: [SystemAdminRoutingModule,
        CommonModule,
        ReactiveFormsModule,
        FormsModule,
        // Ng2AutoCompleteModule,
        DsfAutoCompleteModule,
        SharedModule], providers: [
        SystemAdminBLService,
        SystemAdminDLService,
        { provide: LocationStrategy, useClass: HashLocationStrategy }
    ] })
export class SystemAdminModule { }

