import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormsModule } from '@angular/forms';

import { HashLocationStrategy, LocationStrategy } from "@angular/common";
import { SharedModule } from '../../shared/shared.module';
import { DanpheAutoCompleteModule } from '../../shared/danphe-autocomplete';
import { GeolocationSettingsMainComponent } from './geolocation-settings-main.component';
import { CountryAddComponent } from './countries/country-add.component';
import { CountryListComponent } from './countries/country-list.component';
import { CountrySubdivisionAddComponent } from './subdivisions/country-subdivision-add.component';
import { CountrySubdivisionListComponent } from './subdivisions/country-subdivision-list.component';
import { AuthGuardService } from '../../security/shared/auth-guard.service';
import { MunicipalityListComponent } from './municipalities/municipality-list.component';
import { MunicipalityAddComponent } from './municipalities/municipality-add.component';
export const geoLocSettingsRoutes: Routes =
  [
    {
      path: '', component: GeolocationSettingsMainComponent,
      children: [
        { path: '', redirectTo: 'ManageCountry', pathMatch: 'full' },
        { path: 'ManageCountry', component: CountryListComponent, canActivate: [AuthGuardService] },
        { path: 'ManageSubdivision', component: CountrySubdivisionListComponent, canActivate: [AuthGuardService] },
        { path: 'ManageMunicipality', component: MunicipalityListComponent, canActivate: [AuthGuardService] }
      ]
    }
  ]

@NgModule({ declarations: [
        GeolocationSettingsMainComponent,
        CountryAddComponent,
        CountryListComponent,
        CountrySubdivisionAddComponent,
        CountrySubdivisionListComponent,
        MunicipalityListComponent,
        MunicipalityAddComponent
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        DanpheAutoCompleteModule,
        RouterModule.forChild(geoLocSettingsRoutes)], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy }
    ] })
export class GeolocationSettingsModule {

}
