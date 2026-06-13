import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';

import { RouterModule, ActivatedRoute } from '@angular/router'
import { DicomLoadStudyComponent } from './dicom-load-study/dicom-load-study.component';
import { DicomViewerModule } from './dicom-viewer/dicom-viewer.module';
import { DicomService } from './shared/dicom.service';
import { authInterceptorProviders } from '../token-interceptor/token-interceptor.service';

@NgModule({ declarations: [
        DicomLoadStudyComponent
    ],
    exports: [DicomLoadStudyComponent],
    bootstrap: [DicomLoadStudyComponent], imports: [FormsModule,
        CommonModule,
        MatProgressSpinnerModule,
        DicomViewerModule], providers: [DicomService,
        {
            provide: ActivatedRoute,
            useValue: undefined
        }, authInterceptorProviders] })
export class DicomMainModule { }
