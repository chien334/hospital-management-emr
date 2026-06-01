import {NgModule} from '@angular/core';
import { MaternitypatientPaymentModel } from '../payments/maternity-patient-payment/maternity-patient-payment.model';
import { MaternityPaymentReceiptComponent } from '../receipts/maternity-payment-receipt.component';
import { CommonModule } from '@angular/common';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { SharedModule } from '../../shared/shared.module';
import { MaternityBLService } from './maternity.bl.service';
import { MaternityDLService } from './maternity.dl.service';
import { SettingsSharedModule } from '../../settings-new/settings-shared.module';

@NgModule({ declarations: [MaternityPaymentReceiptComponent],
    exports: [MaternityPaymentReceiptComponent], imports: [CommonModule,
        FormsModule,
        ReactiveFormsModule,
        SharedModule,
        SettingsSharedModule], providers: [MaternityBLService, MaternityDLService, provideHttpClient(withInterceptorsFromDi())] })
export class MaternitySharedModule{

}