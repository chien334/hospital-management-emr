import {
    NgForm,
    UntypedFormGroup,
    FormControl,
    Validators,
    UntypedFormBuilder,
    ReactiveFormsModule
} from '@angular/forms'

export class CostCenterItemModel {
    public CostCenterItemId: number = 0;
    public CostCenterItemName: string = "";
    public Description: string = null;
    public CreatedBy: number = 0;
    public CreatedOn: string = "";
    public IsActive: boolean = true;
    
    public CostCenterItemValidator:UntypedFormGroup= null;

    constructor() {

        var _formBuilder = new UntypedFormBuilder();
        this.CostCenterItemValidator = _formBuilder.group({
            'CostCenterItemName': ['', Validators.compose([Validators.required])],
        });
    }

    public IsDirty(fieldName): boolean {
        if (fieldName == undefined)
            return this.CostCenterItemValidator.dirty;
        else
            return this.CostCenterItemValidator.controls[fieldName].dirty;
    }

    public IsValid():boolean{if(this.CostCenterItemValidator.valid){return true;}else{return false;}} public IsValidCheck(fieldName, validator): boolean {
        if (fieldName == undefined) {
            return this.CostCenterItemValidator.valid;

        }
        else
            return !(this.CostCenterItemValidator.hasError(validator, fieldName));
    }
}



