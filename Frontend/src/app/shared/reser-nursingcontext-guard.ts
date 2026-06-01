import { Injectable } from "@angular/core";

import { VisitService } from "../appointments/shared/visit.service";
import { PatientService } from "../patients/shared/patient.service";
import { SecurityService } from "../security/shared/security.service";
import { MessageboxService } from "./messagebox/messagebox.service";
import { NavigationService } from "./navigation-service";
import { ENUM_MessageBox_Status } from "./shared-enums";

@Injectable()
export class ResetNursingContextGuard<T>
   {
  constructor(
    public visitService: VisitService,
    public patientService: PatientService,
    public navService: NavigationService,
    public securityService: SecurityService,
    public msgBoxServ: MessageboxService,

  ) { }
  canDeactivate() {
    this.patientService.CreateNewGlobal();
    this.visitService.CreateNewGlobal();
    this.navService.showSideNav = true;
    this.navService.showTopNav = true;
    this.securityService.currentModule = null;
    return true;
  }

  canActivate() {
    if (
      this.visitService.getGlobal().PatientId &&
      this.visitService.getGlobal().PatientVisitId
    ) {
      this.securityService.currentModule = "nursing";
      this.navService.showSideNav = false;
      this.navService.showTopNav = false;
      return true;
    } else {
      this.msgBoxServ.showMessage(ENUM_MessageBox_Status.Notice, ["Error ! Please select a patient-visit first.",]);
      // alert("Error ! Please select a patient-visit first.");
      return false;
    }
  }
}
