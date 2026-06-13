import { Component, OnInit } from '@angular/core';
import { DsfRoute } from '../../../security/shared/dsf-route.model';
import { SecurityService } from '../../../security/shared/security.service';

@Component({
  selector: 'app-phrm-stock-report',
  templateUrl: './phrm-stock-report.component.html',
  styles: []
})
export class PHRMStockReportComponent {
  validRoutes: DsfRoute[];

  constructor(public securityService: SecurityService) {
    this.validRoutes = this.securityService.GetChildRoutes("Pharmacy/Report/Stock");
  }
}
