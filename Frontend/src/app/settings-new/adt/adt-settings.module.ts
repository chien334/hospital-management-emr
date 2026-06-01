import { CommonModule, HashLocationStrategy, LocationStrategy } from '@angular/common';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { NgModule } from '@angular/core';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { RouterModule, Routes } from '@angular/router';
import { DanpheAutoCompleteModule } from '../../shared/danphe-autocomplete';
import { SharedModule } from '../../shared/shared.module';

import { AuthGuardService } from '../../security/shared/auth-guard.service';
import { ADTSettingsMainComponent } from './adt-settings-main.component';
import { AddAutoBillingItemsComponent } from './auto-billing-items/add-auto-billing-items.component';
import { AutoBillingItemListComponent } from './auto-billing-items/auto-billing-item-list.component';
import { BedFeatureSchemePriceCategoryListComponent } from './bed-feature-scheme-pricecategory/bed-feature-scheme-pricecategory-list.component';
import { BedFeatureSchemePriceCategoryAddComponent } from './bed-feature-scheme-pricecategory/bed-feature-scheme-pricectaegory-add.component';
import { BedFeatureAddComponent } from './bed-features/bed-feature-add.component';
import { BedFeatureListComponent } from './bed-features/bed-feature-list.component';
import { BedAddComponent } from './beds/bed-add.component';
import { BedListComponent } from './beds/bed-list.component';
import { DepositSettingsAddComponent } from './deposit-settings/deposit-settings-add.component';
import { DepossitSettingsListComponent } from './deposit-settings/deposit-settings-list.component';
import { WardAddComponent } from './wards/ward-add.component';
import { WardListComponent } from './wards/ward-list.component';

export const adtSettingsRoutes: Routes =
  [
    {
      path: '', component: ADTSettingsMainComponent,
      children: [
        { path: '', redirectTo: 'ManageWard', pathMatch: 'full' },
        { path: 'ManageWard', component: WardListComponent, canActivate: [AuthGuardService] },
        { path: 'ManageBedFeature', component: BedFeatureListComponent, canActivate: [AuthGuardService] },
        { path: 'ManageBed', component: BedListComponent, canActivate: [AuthGuardService] },
        { path: 'ManageAutoAddBillItems', component: AutoBillingItemListComponent, canActivate: [AuthGuardService] },
        { path: 'ManageBedFeatureSchemePriceCategory', component: BedFeatureSchemePriceCategoryListComponent, canActivate: [AuthGuardService] },
        { path: 'DepositSettings', component: DepossitSettingsListComponent, canActivate: [AuthGuardService] }
      ]
    }
  ]

@NgModule({ declarations: [
        ADTSettingsMainComponent,
        AutoBillingItemListComponent,
        BedFeatureAddComponent,
        BedFeatureListComponent,
        BedAddComponent,
        BedListComponent,
        WardAddComponent,
        WardListComponent,
        AddAutoBillingItemsComponent,
        WardListComponent,
        BedFeatureSchemePriceCategoryListComponent,
        BedFeatureSchemePriceCategoryAddComponent,
        DepossitSettingsListComponent,
        DepositSettingsAddComponent
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        DanpheAutoCompleteModule,
        RouterModule.forChild(adtSettingsRoutes)], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy },
        provideHttpClient(withInterceptorsFromDi())
    ] })
export class ADTSettingsModule {

}
