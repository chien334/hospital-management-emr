import { Component, OnInit } from '@angular/core';
import { DsfRoute } from '../../../security/shared/dsf-route.model';
import { SecurityService } from '../../../security/shared/security.service';

@Component({
  selector: 'app-inv-supplier-report-main',
  templateUrl: './inv-supplier-report-main.component.html',
  styleUrls: ['./inv-supplier-report-main.component.css']
})
export class InvSupplierReportMainComponent implements OnInit {

  validRoutes: DsfRoute[];
  constructor(public securityService: SecurityService) {
    this.validRoutes = this.securityService.GetChildRoutes("Inventory/Reports/Supplier");
  }

  ngOnInit() {
  }

}
