import { CommonModule, HashLocationStrategy, LocationStrategy } from "@angular/common";
import { provideHttpClient, withInterceptorsFromDi } from "@angular/common/http";
import { NgModule } from "@angular/core";
import { FormsModule, ReactiveFormsModule } from "@angular/forms";
import { RouterModule } from "@angular/router";
import { SharedModule } from "../../shared/shared.module";
import { PaymentModeMainComponent } from "./payment-mode.main.component";

export const paymentModeRoutes =
  [
    {
      path: '', component: PaymentModeMainComponent
    }
  ] 


@NgModule({ declarations: [
        PaymentModeMainComponent
    ],
    bootstrap: [], imports: [CommonModule,
        ReactiveFormsModule,
        FormsModule,
        SharedModule,
        RouterModule.forChild(paymentModeRoutes)], providers: [
        { provide: LocationStrategy, useClass: HashLocationStrategy },
        provideHttpClient(withInterceptorsFromDi())
    ] })

export class PaymentModeSettingsModule {

}