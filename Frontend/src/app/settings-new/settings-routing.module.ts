import { NgModule } from '@angular/core';
import { RouterModule } from "@angular/router";
import { PageNotFound } from '../404-error/404-not-found.component';
import { AuthGuardService } from '../security/shared/auth-guard.service';
import { SettingsMainComponent } from './settings-main.component';
import { TaxManageComponent } from "./tax/tax-manage.component";


@NgModule({
  imports: [
    RouterModule.forChild([
      {
        path: '',
        component: SettingsMainComponent, canActivate: [AuthGuardService],

        children: [
          // { path: '', redirectTo: 'DepartmentsManage', pathMatch: 'full' },
          { path: 'DepartmentsManage', loadChildren: () => import('./departments/dept-settings.module').then(m => m.DepartmentSettingsModule), canActivate: [AuthGuardService] },
          { path: 'RadiologyManage', loadChildren: () => import('./radiology/radiology-settings.module').then(m => m.RadiologySettingsModule), canActivate: [AuthGuardService] },
          { path: 'ADTManage', loadChildren: () => import('./adt/adt-settings.module').then(m => m.ADTSettingsModule), canActivate: [AuthGuardService] },
          { path: 'EmployeeManage', loadChildren: () => import('./employee/emp-settings.module').then(m => m.EmpSettingsModule), canActivate: [AuthGuardService] },
          { path: 'SecurityManage', loadChildren: () => import('./security/security-settings.module').then(m => m.SecuritySettingsModule), canActivate: [AuthGuardService] },
          { path: 'BillingManage', loadChildren: () => import('./billing/billing-settings.module').then(m => m.BillingSettingsModule), canActivate: [AuthGuardService] },
          { path: 'GeolocationManage', loadChildren: () => import('./geolocation/geolocation-settings.module').then(m => m.GeolocationSettingsModule), canActivate: [AuthGuardService] },
          { path: 'ClinicalManage', loadChildren: () => import('./clinical/clinical-settings.module').then(m => m.ClinicalSettingsModule), canActivate: [AuthGuardService] },
          { path: 'TaxManage', component: TaxManageComponent, canActivate: [AuthGuardService] },
          // { path: 'DynamicTemplates', component: DynamicTemplateEditComponent }, replaced with new module 
          { path: 'DynamicTemplates', loadChildren: () => import('./dynamic-templates/dynamic-template.module').then(m => m.DynamicTemplateModule), canActivate: [AuthGuardService] },
          { path: 'EditCoreCFG', loadChildren: () => import('./core/core-settings.module').then(m => m.CoreSettingsModule) },
          { path: 'ExtReferral', loadChildren: () => import('./ext-referral/external-referral.module').then(m => m.ExternalReferralModule), canActivate: [AuthGuardService] },
          { path: 'Banks', loadChildren: () => import('./banks/banks.module').then(m => m.BanksModule), canActivate: [AuthGuardService] },
          { path: 'Printers', loadChildren: () => import('./printers/printer-settings.module').then(m => m.PrinterSettingModule), canActivate: [AuthGuardService] },
          { path: 'PrintExportConfiguration', loadChildren: () => import('./print-export-configuration/print-export-configuration.module').then(m => m.PrintExportConfigurationModule), canActivate: [AuthGuardService] },
          { path: 'PaymentModeSettings', loadChildren: () => import('./payment-mode-settings/payment-mode.module').then(m => m.PaymentModeSettingsModule), canActivate: [AuthGuardService] },
          { path: 'PriceCategory', loadChildren: () => import('./price-cateogory/pricecategory.module').then(m => m.PriceCategoryModule), canActivate: [AuthGuardService] },
        ]
      },
      { path: "**", component: PageNotFound }

    ])
  ],
  exports: [
    RouterModule
  ]
})
export class SettingsRoutingModule { }
