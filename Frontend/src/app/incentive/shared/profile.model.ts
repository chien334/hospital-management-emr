import { UntypedFormGroup, UntypedFormBuilder, Validators, FormControl } from '@angular/forms';

export class ProfileModel {
  ProfileId: number = 0;
  ProfileName: string = null;
  PriceCategoryId: number = null;
  TDSPercentage: number = null;
  IsActive: boolean = true;
  Description: string = null;
  public CreatedBy: number = null;
  public CreatedOn: string = null;

  // display purpose
  PriceCategoryName: string = null;
  AttachedProfileId: number = null;

  ProfileValidator: UntypedFormGroup = null;

  constructor() {
    const _fb = new UntypedFormBuilder();
    this.ProfileValidator = _fb.group({
      'ProfileName': ['', Validators.required], 
      //'PriceCategoryId': [null, Validators.required],
      //'TDSPercentage': [null, Validators.required]
    });
  }

  public IsDirty(fieldName): boolean {
    if (fieldName == undefined) {
      return this.ProfileValidator.dirty;
    }
    else {
      return this.ProfileValidator.controls[fieldName].dirty;
    }
  }

  public IsValid(): boolean { if (this.ProfileValidator.valid) { return true; } else { return false; } }
  public IsValidCheck(fieldName, validator): boolean {
    if (fieldName == undefined) {
      return this.ProfileValidator.valid;
    }
    else {
      return !(this.ProfileValidator.hasError(validator, fieldName));
    }
  }

}
