import { CommonModule, HashLocationStrategy, LocationStrategy } from '@angular/common';

import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';
import { AuthGuardService } from '../../security/shared/auth-guard.service';
import { SharedModule } from '../../shared/shared.module';
import { DynamicTemplateMainComponent } from './dynamic-template-main.component';
import { FieldMappingComponent } from './field-mapping/field-mapping.component';
import { FieldsComponent } from './fields/fields.component';
import { TemplateTypeComponent } from './template-type/template-type.component';
import { TemplateComponent } from './template/template.component';



const routes: Routes = [
    {
        path: '',
        canActivate: [AuthGuardService],
        component: DynamicTemplateMainComponent,
        children: [
            { path: '', redirectTo: 'Templates', pathMatch: 'full' },
            { path: 'Templates', component: TemplateComponent },
            { path: 'TemplateTypes', component: TemplateTypeComponent },
            { path: 'FieldMaster', component: FieldsComponent },
            { path: 'FieldMappings', component: FieldMappingComponent }
        ]
    }
];

@NgModule({ declarations: [
        TemplateTypeComponent,
        TemplateComponent,
        FieldsComponent,
        FieldMappingComponent,
        DynamicTemplateMainComponent
    ],
    bootstrap: [], imports: [CommonModule,
        FormsModule,
        RouterModule.forChild(routes),
        SharedModule,
        ReactiveFormsModule], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy }
    ] })
export class DynamicTemplateModule { }
