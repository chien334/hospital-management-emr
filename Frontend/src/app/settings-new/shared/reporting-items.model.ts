import {
    NgForm,
    UntypedFormGroup,
    FormControl,
    Validators,
    UntypedFormBuilder,
    ReactiveFormsModule
  } from '@angular/forms';
  
  export class ReportingItemsModel {
    public ReportingItemsId:number = 0;
    public ReportingItemName: string = "";
    public DynamicReportId:number = 0;
    public RptCountUnit:string;
    public IsActive: boolean = true;
    public CreatedBy: number = null;
    public ModifiedBy: number = null;
    public CreatedOn: string = null;
    public ModifiedOn: string = null;
    public ReportingItemsValidator: UntypedFormGroup = null;
    public ReportName: string = "";

    constructor() {

        var _formBuilder = new UntypedFormBuilder();
        this.ReportingItemsValidator = _formBuilder.group({
          'ReportingItemName': ['', Validators.required],
        });
      }

      public IsDirty(fieldName): boolean {
        if (fieldName == undefined)
          return this.ReportingItemsValidator.dirty;
        else
          return this.ReportingItemsValidator.controls[fieldName].dirty;
      }
    
      public IsValid(): boolean { if (this.ReportingItemsValidator.valid) { return true; } else { return false; } }
      public IsValidCheck(fieldName, validator): boolean {
        if (fieldName == undefined) {
          return this.ReportingItemsValidator.valid;
        }
    
        else
          return !(this.ReportingItemsValidator.hasError(validator, fieldName));
      }
  }
  
  
  
  
  
  