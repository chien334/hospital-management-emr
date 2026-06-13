import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

import { HashLocationStrategy, LocationStrategy } from "@angular/common";
import { SecuritySettingsMainComponent } from './security-setting.main.component';
import { SharedModule } from '../../shared/shared.module';
import { DsfAutoCompleteModule } from '../../shared/dsf-autocomplete';
import { UserAddComponent } from './users/user-add.component';
import { UserListComponent } from './users/user-list.component';
import { UserRoleMapComponent } from './user-role-map/user-role-map.component';
import { RoleAddComponent } from './roles/role-add.component';
import { RoleListComponent } from './roles/role-list.component';
import { RolePermissionManageComponent } from './role-perm-map/role-permission-manage.component';
import { ResetPasswordComponent } from './reset-password/reset-password.component';
import { SortByPipe } from './role-perm-map/sort-pipe';
import { AuthGuardService } from '../../security/shared/auth-guard.service';

export const securitySettingsRoutes: Routes =
  [
    {
      path: '', component: SecuritySettingsMainComponent,
      children: [
        { path: '', redirectTo: 'ManageUser', pathMatch: 'full' },
        { path: 'ManageUser', component: UserListComponent, canActivate: [AuthGuardService] },
        { path: 'ManageRole', component: RoleListComponent, canActivate: [AuthGuardService] }
      ]
    }
  ]


@NgModule({ declarations: [
        SecuritySettingsMainComponent,
        UserAddComponent,
        UserListComponent,
        UserRoleMapComponent,
        RoleAddComponent,
        RoleListComponent,
        RolePermissionManageComponent,
        ResetPasswordComponent,
        SortByPipe
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        DsfAutoCompleteModule,
        RouterModule.forChild(securitySettingsRoutes)], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy }
    ] })
export class SecuritySettingsModule {

}   
