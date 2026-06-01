import {
    NgForm,
    UntypedFormGroup,
    FormControl,
    Validators,
    UntypedFormBuilder,
    ReactiveFormsModule
} from '@angular/forms';
export class EmployeeType {
    public EmployeeTypeId: number = 0;
    public EmployeeTypeName: string = null;
    public Description: string = null;
    public CreatedBy: number = null;
    public ModifiedBy: number = null;

    public CreatedOn: string = null;
    public ModifiedOn: string = null;
    public IsActive: boolean = true;
    public EmployeeTypeValidator: UntypedFormGroup = null;


    constructor() {

        var _formBuilder = new UntypedFormBuilder();
        this.EmployeeTypeValidator = _formBuilder.group({
            'EmployeeTypeName': ['', Validators.compose([Validators.required])],
        });
    }

    public IsDirty(fieldName): boolean {
        if (fieldName == undefined)
            return this.EmployeeTypeValidator.dirty;
        else
            return this.EmployeeTypeValidator.controls[fieldName].dirty;
    }

    public IsValid():boolean{if(this.EmployeeTypeValidator.valid){return true;}else{return false;}} public IsValidCheck(fieldName, validator): boolean {
        if (fieldName == undefined) {
            return this.EmployeeTypeValidator.valid;
        }

        else
            return !(this.EmployeeTypeValidator.hasError(validator, fieldName));
    }

}





