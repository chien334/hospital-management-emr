import { CommonModule, HashLocationStrategy, LocationStrategy } from '@angular/common';

import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { DepartmentSettingsModule } from '../../../settings-new/departments/dept-settings.module';
import { EmpSettingsModule } from '../../../settings-new/employee/emp-settings.module';
import { DanpheAutoCompleteModule } from '../../../shared/danphe-autocomplete';
import { SharedModule } from '../../../shared/shared.module';
import { MedicareBLService } from '../shared/medicare.bl.service';
import { MedicareDLService } from '../shared/medicare.dl.service';
import { MedicareService } from '../shared/service/medicare.service';
import { MedicareDependentComponent } from './dependent/medicare-dependent.component';
import { MedicareRegistrationMainComponent } from './medicare-registration-main.component';
import { MedicareRegistrationRoutingModule } from './medicare-registration.routing.module';
import { MedicareMemberComponent } from './member/medicare-member.component';


@NgModule({ declarations: [
        MedicareRegistrationMainComponent,
        MedicareMemberComponent,
        MedicareDependentComponent
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        DanpheAutoCompleteModule,
        EmpSettingsModule,
        DepartmentSettingsModule,
        MedicareRegistrationRoutingModule], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy },
        MedicareBLService,
        MedicareDLService,
        MedicareService
    ] })
export class MedicareRegistrationModule {

}
