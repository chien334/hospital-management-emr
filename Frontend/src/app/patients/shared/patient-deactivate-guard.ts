import { Injectable } from '@angular/core';

import { PatientService } from './patient.service';

import { IRouteGuard } from '../../shared/route-guard.interface';

@Injectable()
export class PatientDeactivateGuard  {

    canDeactivate(target: IRouteGuard) {
        if (!target.CanRouteLeave()) {
            return window.confirm('This page contains unsaved changes. Do you want to continue ? Changes will be discarded.');
        }
        return true;
    }
}