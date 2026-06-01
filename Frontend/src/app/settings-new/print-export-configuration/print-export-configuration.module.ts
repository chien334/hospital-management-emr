import { CommonModule, HashLocationStrategy, LocationStrategy } from "@angular/common";
import { provideHttpClient, withInterceptorsFromDi } from "@angular/common/http";
import { NgModule } from "@angular/core";
import { FormsModule, ReactiveFormsModule } from "@angular/forms";
import { RouterModule } from "@angular/router";
import { SharedModule } from "../../shared/shared.module";
import { SettingsSharedModule } from "../settings-shared.module";
import { AddPrintExportConfigurationComponent } from "./add-new-configuration/add-new-configuration.component";
import { PrintExportConfigurationMainComponent } from "./print-export-configuration.main.component";

export const printExportConfigurationRoutes =
  [
    {
      path: '', component: PrintExportConfigurationMainComponent
    }
  ] 


@NgModule({ declarations: [
        PrintExportConfigurationMainComponent,
        AddPrintExportConfigurationComponent
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        RouterModule.forChild(printExportConfigurationRoutes)], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy },
        provideHttpClient(withInterceptorsFromDi())
    ] })

export class PrintExportConfigurationModule {

}