import { CommonModule } from "@angular/common";
import { NgModule, NgZone } from "@angular/core";
import { FormsModule, ReactiveFormsModule } from "@angular/forms";

//custom pipes
import { DsfDateTime } from "./pipes/dsf-datetime.pipe";

import { LoadingComponent } from "./loading.component";
import { CapitalFirstLetter } from "./pipes/capital-first-letter.pipe";
import { Currency } from "./pipes/currency.pipe";
import { HasValuePipe } from "./pipes/hasvalue.pipe"; //pipe to check if the field has value
import { NepaliDatePipe } from "./pipes/nepali-date.pipe";
import { NumberInWordsPipe } from "./pipes/number-inwords.pipe";
import { ParseAmount } from "./pipes/parse-amount.pipe";
//import { Ng2TabModule } from 'ng2-tab';

import { AgGridModule } from "ag-grid-angular";
import { DsfGridComponent } from "./dsf-grid/dsf-grid.component";

import { ResetPatientcontextGuard } from "../shared/reset-patientcontext-guard";
import { NepaliCalendarModule } from "./calendar/np/nepali-calendar.module";
import { AmChartsService } from "@amcharts/amcharts3-angular";


import { DsfChartsService } from "../dashboards/shared/dsf-charts.service";

import { QRCodeModule } from "./dsf-qrcode/qr-code.module";
import { PrintStickerComponent } from "../appointments/opd-sticker/opd-sticker-print.component";
import { NotificationComponent } from "../core/notifications/notification.component";
import { CustomerHeaderComponent } from "../shared/customer-header/customer-header.component";
//lab and imaging view report
import { AngularMultiSelectModule } from "angular2-multiselect-dropdown";
import { LabTestsAddResultComponent } from "../labs/lab-tests/lab-add-result/lab-tests-add-result.component";
import { LabTestsViewReportComponent } from "../labs/lab-tests/lab-final-reports/lab-tests-view-report.component";
import { LabTestsResults } from "../labs/lab-tests/lab-tests-results.component";
import { ViewReportComponent } from "../radiology/shared/report/view-report.component";
import { DsfMultiSelectComponent } from "../shared/dsf-multiselect/dsf-multiselect.component";

import { RouterModule } from "@angular/router";
import { BillingBLService } from "../billing/shared/billing.bl.service";
import { BillingDLService } from "../billing/shared/billing.dl.service";
import { ClinicalDLService } from "../clinical/shared/clinical.dl.service";
import { LabService, LabTestResultService } from "../labs/shared/lab.service";
import { LabsBLService } from "../labs/shared/labs.bl.service";
import { LabsDLService } from "../labs/shared/labs.dl.service";
import { ImagingBLService } from "../radiology/shared/imaging.bl.service";
import { ImagingDLService } from "../radiology/shared/imaging.dl.service";
import { CustomDateComponent } from "./custom-date/custom-date.component";

import { CKEditorModule } from "ng2-ckeditor";
import { DsfCkEditorComponent } from "../shared/dsf-ckeditor/dsf-ckeditor.component";

import { LightboxModule } from "ngx-lightbox";
import { DoctorsBLService } from "../doctors/shared/doctors.bl.service";
import { DoctorsDLService } from "../doctors/shared/doctors.dl.service";
import { RadiologyService } from "../radiology/shared/radiology-service";
import { DatePickerComponent } from "./dsf-datepicker/dsf-datepicker.component";

import { PatientBillHistoryComponent } from "../billing/bill-history/patient-bill-history";

import { ResetOrdersGuard } from "../orders/reset-order-guard";
import { ResetDoctorcontextGuard } from "../shared/reset-doctorcontext-guard";
//import { Ng2AutoCompleteModule } from 'ng2-auto-complete';
// import { VitalsAddComponent } from '../clinical/vitals/vitals-add.component';
import { QrReaderComponent } from "./qr-code/qr-reader.component";
import { QrService } from "./qr-code/qr-service";

//added: sud-4july-for photo-cropping.
import { ImageCropperComponent } from "ngx-image-cropper";
import { WebcamModule } from "ngx-webcam";
import { SignatoriesComponent } from "../labs/shared/signatories/signatories.component";
import { PhotoCropperComponent } from "./photo-cropper/photo-cropper.component";

import { PatientUploadFilesComponent } from "../patients/patient-upload-files/patient-upload-files.component";
import { EmergencyStickerComponent } from "./emergency-sticker/emergency-sticker.component";
import { PrintHeaderComponent } from "./print-header/print-header";

//sud:30Sept'18--to replace ng-autocomplete with dsf-autocomplete
import { RbacPermissionDirective } from "../security/shared/rbac-permission.directive";
import { DsfAutoCompleteModule } from "../shared/dsf-autocomplete/dsf-auto-complete.module";

import { BillingHeaderComponent } from "../shared/billing-header/billing-header.component";
//import { DepositReceiptComponent } from "../billing/print-pages/deposit-slip/deposit-receipt.component";
import { DsfBarCodeComponent } from "./bar-code/dsf-bar-code.component";

import { VisitSticker_Generic_Single_Component } from "./visit-generic-stickers/visit-gen-sticker-single.component";
import { VisitSticker_Generic_PrintComponent } from "./visit-generic-stickers/visit-generic-stickers-print.component";

import { PostReportComponent } from "../radiology/shared/report/post-report.component";

import { HTTP_INTERCEPTORS } from "@angular/common/http";
import { MatTooltipModule } from "@angular/material/tooltip";
import { TranslateModule } from "@ngx-translate/core";
import { DrugsRequestComponent } from "../nursing/drugs-request/drugs-request.component";
import { DicomMainModule } from "./dsf-dicom-viewer/dicom-main.module";
import { DicomService } from "./dsf-dicom-viewer/shared/dicom.service";
import { LoaderComponent } from "./dsf-loader-intercepter/dsf-loader";
import { DsfLoadingInterceptor } from "./dsf-loader-intercepter/dsf-loading.services";
import { BooleanParameterPipe } from "./pipes/boolean-parameter.pipe";
import { SearchFilterPipe } from "./pipes/data-filter.pipe";
import { SearchService } from "./search.service";

import { BillStickerComponent } from "../billing/bill-sticker/bill-sticker.component";
import { TermsAddComponent } from '../inventory/settings/termsconditions/terms-add.component';
import { TermsListComponent } from '../inventory/settings/termsconditions/terms-list.component';
import { LabTestsViewReportFormat2Component } from "../labs/lab-tests/lab-final-reports/lab-report-format2/lab-tests-view-report-format2.component";
import { PHRMItemMasterManageComponent } from "../pharmacy/setting/item/phrm-item-manage.component";
import { SettingsSharedModule } from "../settings-new/settings-shared.module";

import { PageNotFound } from "../404-error/404-not-found.component";
import { ResetAccountingServiceGuard } from "../accounting/shared/reset-accounting-service-guard";
import { ADT_BLService } from "../adt/shared/adt.bl.service";
import { OldDischargeSummaryAddComponent } from "../discharge-summary/add-view-summary/old-discharge-summary-add.component";
import { OldDischargeSummaryViewComponent } from "../discharge-summary/add-view-summary/old-discharge-summary-view.component";
import { DischargeSummaryBLService } from "../discharge-summary/shared/discharge-summary.bl.service";
import { DischargeSummaryDLService } from "../discharge-summary/shared/discharge-summary.dl.service";
import { PatientOverviewMainComponent } from "../doctors/patient/patient-overview-main.component";
import { TrackInventoryRequisitionComponent } from "../inventory/internal/track-requisition/track-requisition.component";
import { PHRMCategoryManageComponent } from "../pharmacy/setting/category/phrm-category-manage.component";
import { PHRMCompanyManageComponent } from "../pharmacy/setting/company/phrm-company-manage.component";
import { PHRMGenericManageComponent } from "../pharmacy/setting/generic/phrm-generic-manage.component";
import { PHRMItemTypeManageComponent } from "../pharmacy/setting/item-type/phrm-item-type-manage.component";
import { PHRMPackingTypeAddComponent } from "../pharmacy/setting/packing-type/phrm-packing-type-add.component";
import { PHRMPackingTypeListComponent } from "../pharmacy/setting/packing-type/phrm-packing-type-list.component";
import { PHRMUnitOfMeasurementManageComponent } from "../pharmacy/setting/uom/phrm-uom-manage.component";
import { EnglishCalendarComponent } from "./calendar/en-calendar/en-calendar.component";
import { DsfDateChangeComponent } from "./dsf-date-change.component";
import { DsfDateRangeSelectComponent } from "./dsf-date-range-select/dsf-date-range-select.component";
import { InlineEditComponent } from "./dsf-inline-edit/inline-edit.component";
import { DateLabelComponent } from "./date-controls/date-label/date-label.component";
import { FiscalYearCalendarComponent } from "./date-controls/fiscal-year-calendar/fiscal-year-calendar.component";
import { FromToDateSelectComponent } from "./date-controls/from-to-date/from-to-date-select.component";
import { AddInvoiceHeaderComponent } from "./invoice-header/add-invoice-header.component";
import { InvoiceHeaderListComponent } from "./invoice-header/invoice-header-list.component";
import { SelectInvoiceHeaderComponent } from "./invoice-header/select-invoice-header.component";
import { ShowInvoiceHeaderComponent } from "./invoice-header/show-invoice-header.component";
import { DsfPrintComponent } from "./print-service/print.component";
import { ResetNursingContextGuard } from "./reser-nursingcontext-guard";
import { ResetEmergencyContextGuard } from "./reset-emergencycontext-guard";
//import { PdfViewerModule } from 'ng2-pdf-viewer'; //rusha:30May'21--commented until proper solution is found.
import { CMHDischargeSummaryTemplateComponent } from "../discharge-summary/add-view-summary/view-templates/CMH/cmh-discharge-summary-template.comonent";
import { FishTailDischargeSummaryViewTemplateComponent } from "../discharge-summary/add-view-summary/view-templates/FishTail/fishtail-discharge-summary-template.comonent";
import { SCHDischargeSummaryTemplateComponent } from "../discharge-summary/add-view-summary/view-templates/SCH/sch-discharge-summary-template.comonent";
import { DefaultDischargeSummaryTemplateComponent } from "../discharge-summary/add-view-summary/view-templates/default-discharge-summary-template.comonent";
import { DischargeSummaryAddComponent } from "../discharge-summary/add/discharge-summary-add.component";
import { DischargeSummaryViewComponent } from "../discharge-summary/view/discharge-summary-view.component";
import { PharmacyCreditNotePrintComponent } from "../pharmacy/receipt/pharmacy-credit-note-print/pharmacy-credit-note-print.component";
import { PharmacyInvoicePrintComponent } from "../pharmacy/receipt/pharmacy-invoice-print/pharmacy-invoice-print.component";
import { PharmacyProvisionalInvoicePrintComponent } from "../pharmacy/receipt/pharmacy-provisional-invoice-print/pharmacy-provisional-invoice-print.component";
import { PharmacyProvisionalReturnInvoicePrintComponent } from "../pharmacy/receipt/pharmacy-provisional-invoice-return/pharmacy-provisional-invoice-return-print.component";
import { PharmacyReceiptComponent } from "../pharmacy/receipt/pharmacy-receipt.component";
import { PhrmInvoiceViewComponent } from "../pharmacy/sale/invoice-view/phrm-invoice-view.component";
import { PHRMUpdateMRPComponent } from "../pharmacy/setting/mrp/phrm-update-mrp.component";
import { MunicipalitySelectComponent } from "./address-controls/municipality-select.component";
import { DsfConfirmationDialogComponent } from "./dsf-confirmation-dialog/dsf-confirmation-dialog.component";
import { DsfConfirmationDirective } from "./dsf-confirmation-dialog/dsf-confirmation.directive";
import { DndDirective } from "./dnd.directive";
import { InventoryFieldCustomizationService } from "./inventory-field-customization.service";
import { DispatchNpViewComponent } from './nepali-receipt-views/dispatch-np-view/dispatch-np-view.component';
import { RequisitionNpViewComponent } from "./nepali-receipt-views/requisition-np-view/requisition-np-view.component";
import { Pagination } from "./pagination/pagination.component";
import { GRChargesPipe } from "./pipes/gr-charges.pipe";
import { ItemListFilterPipe } from "./pipes/list-filter.pipe";
import { PaymentDetailsPipe } from "./pipes/payment-details.pipe";
import { DsfPrintNewComponent } from "./print-service/print-new.component";
import { ProgressBarComponent } from "./progress-bar/progress-bar.component";
import { StickerComponent } from "./stickers/registration-sticker.component";
import { authInterceptorProviders } from "./token-interceptor/token-interceptor.service";



@NgModule({
    providers: [
        ResetPatientcontextGuard,
        ResetOrdersGuard,
        ResetDoctorcontextGuard,
        ResetNursingContextGuard,
        ResetEmergencyContextGuard,
        DsfChartsService,
        LabTestResultService,
        LabsBLService,
        LabsDLService,
        ImagingBLService,
        ImagingDLService,
        BillingBLService,
        BillingDLService,
        DoctorsBLService,
        DoctorsDLService,
        ClinicalDLService,
        RadiologyService,
        QrService,
        SearchService,
        ResetAccountingServiceGuard,
        ADT_BLService,
        DischargeSummaryBLService,
        DischargeSummaryDLService,
        DicomService,
        LoaderComponent,
        {
            provide: HTTP_INTERCEPTORS,
            useClass: DsfLoadingInterceptor,
            multi: true,
        },
        LabService,
        InventoryFieldCustomizationService,
        authInterceptorProviders,
        {
            provide: AmChartsService,
            useFactory: (zone: NgZone) => new AmChartsService(zone),
            deps: [NgZone]
        }
    ],
    imports: [
        ReactiveFormsModule,
        FormsModule,
        CommonModule,
        RouterModule,
        AgGridModule,
        NepaliCalendarModule,
        DsfAutoCompleteModule,
        LightboxModule,
        QRCodeModule,
        AngularMultiSelectModule,
        CKEditorModule,
        ImageCropperComponent,
        WebcamModule,
        DicomMainModule,
        MatTooltipModule,
        DicomMainModule,
        MatTooltipModule,
        SettingsSharedModule,
        TranslateModule,
        //PdfViewerModule,
    ],
    declarations: [
        DsfDateTime,
        HasValuePipe,
        LoadingComponent,
        NumberInWordsPipe,
        ParseAmount,
        Currency,
        CapitalFirstLetter,
        DsfGridComponent,
        CustomerHeaderComponent,
        PrintStickerComponent,
        NotificationComponent,
        CustomDateComponent,
        LabTestsViewReportComponent,
        LabTestsViewReportFormat2Component,
        PostReportComponent,
        ViewReportComponent,
        LabTestsAddResultComponent,
        DsfMultiSelectComponent,
        DatePickerComponent,
        DsfCkEditorComponent,
        PatientBillHistoryComponent,
        LabTestsResults,
        QrReaderComponent,
        PhotoCropperComponent,
        //NotesComponent,
        NepaliDatePipe,
        SignatoriesComponent,
        PatientUploadFilesComponent,
        EmergencyStickerComponent,
        PrintHeaderComponent,
        BillingHeaderComponent,
        //DepositReceiptComponent,
        RbacPermissionDirective,
        DsfBarCodeComponent,
        VisitSticker_Generic_Single_Component,
        VisitSticker_Generic_PrintComponent,
        DrugsRequestComponent,
        BooleanParameterPipe,
        SearchFilterPipe,
        BillStickerComponent,
        PHRMItemMasterManageComponent,
        PHRMPackingTypeAddComponent,
        PHRMPackingTypeListComponent,
        OldDischargeSummaryAddComponent,
        OldDischargeSummaryViewComponent,
        DischargeSummaryAddComponent,
        DischargeSummaryViewComponent,
        TrackInventoryRequisitionComponent,
        InlineEditComponent,
        DsfDateRangeSelectComponent,
        DsfPrintComponent,
        DsfDateChangeComponent,
        TermsListComponent,
        TermsAddComponent,
        PatientOverviewMainComponent,
        PageNotFound,
        FromToDateSelectComponent,
        DateLabelComponent,
        EnglishCalendarComponent,
        AddInvoiceHeaderComponent,
        InvoiceHeaderListComponent,
        FiscalYearCalendarComponent,
        SelectInvoiceHeaderComponent,
        ShowInvoiceHeaderComponent,
        FiscalYearCalendarComponent,
        PHRMGenericManageComponent,
        PHRMUnitOfMeasurementManageComponent,
        PHRMItemTypeManageComponent,
        PHRMCompanyManageComponent,
        PHRMCategoryManageComponent,
        PhrmInvoiceViewComponent,
        PharmacyReceiptComponent,
        PHRMUpdateMRPComponent,
        RequisitionNpViewComponent,
        DispatchNpViewComponent,
        MunicipalitySelectComponent,
        DefaultDischargeSummaryTemplateComponent,
        SCHDischargeSummaryTemplateComponent,
        DndDirective,
        ProgressBarComponent,
        GRChargesPipe,
        ProgressBarComponent,
        FishTailDischargeSummaryViewTemplateComponent,
        PaymentDetailsPipe,
        CMHDischargeSummaryTemplateComponent,
        Pagination,
        ItemListFilterPipe,
        StickerComponent,
        PharmacyInvoicePrintComponent,
        PharmacyCreditNotePrintComponent,
        DsfConfirmationDialogComponent,
        DsfConfirmationDirective,
        DsfPrintNewComponent,
        PharmacyProvisionalInvoicePrintComponent,
        PharmacyProvisionalReturnInvoicePrintComponent
    ],
    exports: [
        DsfDateTime,
        CommonModule,
        FormsModule,
        HasValuePipe,
        NepaliDatePipe,
        BooleanParameterPipe,
        TranslateModule,
        //LoadingComponent,
        NumberInWordsPipe,
        // Ng2TabModule,
        CapitalFirstLetter,
        ParseAmount,
        Currency,
        DsfGridComponent,
        NepaliCalendarModule,
        CustomerHeaderComponent,
        PrintStickerComponent,
        NotificationComponent,
        CustomDateComponent,
        LabTestsViewReportComponent,
        LabTestsViewReportFormat2Component,
        LabTestsAddResultComponent,
        PostReportComponent,
        ViewReportComponent,
        DsfMultiSelectComponent,
        DatePickerComponent,
        DsfCkEditorComponent,
        PatientBillHistoryComponent,
        QRCodeModule,
        LabTestsResults,
        QrReaderComponent,
        ImageCropperComponent,
        WebcamModule,
        PhotoCropperComponent,
        SignatoriesComponent,
        PatientUploadFilesComponent,
        EmergencyStickerComponent,
        PrintHeaderComponent,
        BillingHeaderComponent,
        //DepositReceiptComponent,
        RbacPermissionDirective,
        //NgxBarcodeModule,
        DsfBarCodeComponent,
        VisitSticker_Generic_Single_Component,
        VisitSticker_Generic_PrintComponent,
        DrugsRequestComponent,
        DicomMainModule,
        MatTooltipModule,
        SearchFilterPipe,
        BillStickerComponent,
        PHRMItemMasterManageComponent,
        DischargeSummaryAddComponent,
        DischargeSummaryViewComponent,
        OldDischargeSummaryAddComponent,
        OldDischargeSummaryViewComponent,
        TrackInventoryRequisitionComponent,
        InlineEditComponent,
        DsfDateRangeSelectComponent,
        DsfPrintComponent,
        DsfDateChangeComponent,
        TermsListComponent,
        TermsAddComponent,
        PatientOverviewMainComponent,
        PageNotFound,
        FromToDateSelectComponent,
        EnglishCalendarComponent,
        DateLabelComponent,
        AddInvoiceHeaderComponent,
        InvoiceHeaderListComponent,
        FiscalYearCalendarComponent,
        PHRMPackingTypeAddComponent,
        PHRMPackingTypeListComponent,
        SelectInvoiceHeaderComponent,
        ShowInvoiceHeaderComponent,
        PHRMGenericManageComponent,
        PHRMUnitOfMeasurementManageComponent,
        PHRMItemTypeManageComponent,
        PHRMCompanyManageComponent,
        PHRMCategoryManageComponent,
        //PdfViewerModule,
        PhrmInvoiceViewComponent,
        PharmacyReceiptComponent,
        PHRMUpdateMRPComponent,
        RequisitionNpViewComponent,
        DispatchNpViewComponent,
        MunicipalitySelectComponent,
        DefaultDischargeSummaryTemplateComponent,
        SCHDischargeSummaryTemplateComponent,
        DndDirective,
        ProgressBarComponent,
        GRChargesPipe,
        PaymentDetailsPipe,
        CMHDischargeSummaryTemplateComponent,
        Pagination,
        ItemListFilterPipe,
        StickerComponent,
        PharmacyInvoicePrintComponent,
        PharmacyCreditNotePrintComponent,
        DsfConfirmationDialogComponent,
        DsfConfirmationDirective,
        DsfPrintNewComponent,
        PharmacyProvisionalInvoicePrintComponent,
        PharmacyProvisionalReturnInvoicePrintComponent
    ]
})
export class SharedModule { }
