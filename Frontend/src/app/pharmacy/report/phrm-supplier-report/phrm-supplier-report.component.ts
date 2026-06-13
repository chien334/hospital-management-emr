import { Component, OnInit } from '@angular/core';
import { DsfRoute } from '../../../security/shared/dsf-route.model';
import { SecurityService } from '../../../security/shared/security.service';

@Component({
  selector: 'app-phrm-supplier-report',
  templateUrl: './phrm-supplier-report.component.html',
  styles: []
})
export class PHRMSupplierReportComponent implements OnInit {

  validRoutes: DsfRoute[];

  constructor(public securityService: SecurityService) {
    this.validRoutes = this.securityService.GetChildRoutes("Pharmacy/Report/Supplier");
  }
  ngOnInit() {
  }

}
