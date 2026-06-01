import {
    NgForm,
    UntypedFormGroup,
    FormControl,
    Validators,
    UntypedFormBuilder,
    ReactiveFormsModule
} from '@angular/forms'

import * as moment from 'moment/moment';
export class Reaction {
    public ReactionId: number = 0;
    public ReactionCode: string = null;
    public ReactionName: string = null;

    public CreatedBy: number = null;
    public CreatedOn: string = null;

    public IsActive: boolean = true;
    public ModifiedBy: number = null;
    public ModifiedOn: string = null;

    public ReactionValidator: UntypedFormGroup = null;

    constructor() {

        var _formBuilder = new UntypedFormBuilder();
        this.ReactionValidator = _formBuilder.group({
            'ReactionName': ['', Validators.compose([Validators.required, Validators.maxLength(30)])]
        });
    }

    public IsDirty(fieldName): boolean {
        if (fieldName == undefined)
            return this.ReactionValidator.dirty;
        else
            return this.ReactionValidator.controls[fieldName].dirty;
    }

    public IsValid():boolean{if(this.ReactionValidator.valid){return true;}else{return false;}} 
    public IsValidCheck(fieldName, validator): boolean {
        if (fieldName == undefined) {
            return this.ReactionValidator.valid;
        }

        else
            return !(this.ReactionValidator.hasError(validator, fieldName));
    }


}