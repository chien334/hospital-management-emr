import {
  NgForm,
  UntypedFormGroup,
  FormControl,
  Validators,
  UntypedFormBuilder,
  ReactiveFormsModule
} from '@angular/forms'


export class Role {
  public RoleId: number = 0;
  public RoleName: string = null;
  public RoleDescription: string = null;
  public RoleType: string = 'custom';//Available values = 'custom', 'system' //pratik: 6 july 2020
  public ApplicationId: number = null;
  public IsSysAdmin: boolean = false;
  public IsActive: boolean = true;
  public RolePriority: number = null;
  public DefaultRouteId: number = null;
  public CreatedBy: number = null;
  public ModifiedBy: number = null;

  public CreatedOn: string = null;
  public ModifiedOn: string = null;

  public IsSelected: boolean = false;

  public RoleValidator: UntypedFormGroup = null;

  constructor() {

    var _formBuilder = new UntypedFormBuilder();
    this.RoleValidator = _formBuilder.group({
      'RoleName': ['', Validators.compose([Validators.required])]
    });
  }
  public IsDirty(fieldName): boolean {
    if (fieldName == undefined)
      return this.RoleValidator.dirty;
    else
      return this.RoleValidator.controls[fieldName].dirty;
  }


  public IsValid(): boolean { if (this.RoleValidator.valid) { return true; } else { return false; } }
  public IsValidCheck(fieldName, validator): boolean {
    if (fieldName == undefined) {
      return this.RoleValidator.valid;
    }
    else
      return !(this.RoleValidator.hasError(validator, fieldName));
  }
}
