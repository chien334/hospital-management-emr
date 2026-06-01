import {
    UntypedFormBuilder,
    UntypedFormGroup,
    Validators
} from '@angular/forms';
export class CreditOrganization {
    public OrganizationId: number = 0;
    public OrganizationName: string = '';
    public IsActive: boolean = true;
    public CreatedOn: string = '';
    public CreatedBy: number = 0;
    public ModifiedOn: string = null;
    public ModifiedBy: number = null;
    public IsDefault: boolean = false;

    public CreditOrganizationValidator: UntypedFormGroup = null;


    constructor() {

        var _formBuilder = new UntypedFormBuilder();
        this.CreditOrganizationValidator = _formBuilder.group({
            'OrganizationName': ['', Validators.compose([Validators.required])],
        });
    }

    public IsDirty(fieldName): boolean {
        if (fieldName == undefined)
            return this.CreditOrganizationValidator.dirty;
        else
            return this.CreditOrganizationValidator.controls[fieldName].dirty;
    }

    public IsValid(): boolean { if (this.CreditOrganizationValidator.valid) { return true; } else { return false; } } public IsValidCheck(fieldName, validator): boolean {
        if (fieldName == undefined) {
            return this.CreditOrganizationValidator.valid;
        }

        else
            return !(this.CreditOrganizationValidator.hasError(validator, fieldName));
    }

}





