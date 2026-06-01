import {
    NgForm,
    UntypedFormGroup,
    FormControl,
    Validators,
    UntypedFormBuilder
} from '@angular/forms'

import * as moment from 'moment/moment';

export class PatientVaccineDetailModel {
    PatientVaccineId: number;
    VaccineId: number = 0;
    PatientId: number;
    DoseNumber: number = 0;
    VaccineDate: string = "";
    Remarks: string;

    public PatVaccineDetailValidator: UntypedFormGroup = null;


    constructor() {
        var _formBuilder = new UntypedFormBuilder();
        this.PatVaccineDetailValidator = _formBuilder.group({
            'VaccineId': ['', Validators.compose([Validators.required, Validators.min(1)])],
            'DoseNumber': ['', Validators.compose([Validators.required, Validators.min(1)])]
        });
    }

    public IsDirty(fieldname): boolean {
        if (fieldname == undefined) {
            return this.PatVaccineDetailValidator.dirty;
        }
        else {
            return this.PatVaccineDetailValidator.controls[fieldname].dirty;
        }

    }

    public IsValid(): boolean { if (this.PatVaccineDetailValidator.valid) { return true; } else { return false; } }
    public IsValidCheck(fieldname, validator): boolean {
        if (this.PatVaccineDetailValidator.valid) {
            return true;
        }

        if (fieldname == undefined) {
            return this.PatVaccineDetailValidator.valid;
        }
        else {

            return !(this.PatVaccineDetailValidator.hasError(validator, fieldname));
        }
    }
}