import { CommonModule } from '@angular/common';
import { provideHttpClient, withInterceptorsFromDi } from '@angular/common/http';
import { NgModule } from '@angular/core'
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { SettingsSharedModule } from '../settings-new/settings-shared.module';
import { SharedModule } from '../shared/shared.module';
import { EchsStickerComponent } from './echs-sticker/echs-sticker.component';
import { PatientStickerComponent } from './patient-sticker/patient-sticker.component';

@NgModule({ declarations: [PatientStickerComponent, EchsStickerComponent],
    exports: [PatientStickerComponent, EchsStickerComponent], imports: [CommonModule,
        FormsModule,
        ReactiveFormsModule,
        SharedModule,
        SettingsSharedModule], providers: [provideHttpClient(withInterceptorsFromDi())] })
export class StickerSharedModule{

}