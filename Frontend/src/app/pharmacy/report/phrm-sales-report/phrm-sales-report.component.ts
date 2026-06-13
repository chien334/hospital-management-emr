import { Component, OnInit } from '@angular/core';
import { DsfRoute } from '../../../security/shared/dsf-route.model';
import { SecurityService } from '../../../security/shared/security.service';

@Component({
  selector: 'app-phrm-sales-report',
  templateUrl: './phrm-sales-report.component.html',
  styles: []
})
export class PHRMSalesReportComponent implements OnInit {
  validRoutes: DsfRoute[];

  constructor(public securityService: SecurityService) {
    this.validRoutes = this.securityService.GetChildRoutes("Pharmacy/Report/Sales");
  }
  ngOnInit() {
  }

}
