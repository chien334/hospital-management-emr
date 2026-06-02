
import { PageNotFound } from './404-error/404-not-found.component';
import { UnAuthorizedAccessComponent } from './account/unauthorizes-access.component';
import { LoginComponent } from './account/login.component';
import { DashboardHomeComponent } from './dashboards/home/dashboard-home.component';
import { DynamicReportComponent } from './dynamic-report/dynamic-report.component';
import { AuthGuardService } from './security/shared/auth-guard.service';
import { ActivateInventoryComponent } from './shared/activate-inventory/activate-inventory.component';
export const AppRoutingConstant = [
  { path: "", component: DashboardHomeComponent },
  { path: "Home/Index", component: DashboardHomeComponent },
  {
    path: "Doctors",
    loadChildren: () => import('./doctors/doctors.module').then(m => m.DoctorsModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Patient",
    loadChildren: () => import('./patients/patients.module').then(m => m.PatientsModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Appointment",
    loadChildren: () => import('./appointments/appointments.module').then(m => m.AppointmentsModule),
    canActivate: [AuthGuardService],
    data: { currentRoute: "Appointment" }
  },
  {
    path: "Billing",
    loadChildren: () => import('./billing/billing.module').then(m => m.BillingModule),
    canActivate: [AuthGuardService],
    data: { currentRoute: "Billing" }
  },
  { path: "Lab", loadChildren: () => import('./labs/labs.module').then(m => m.LabsModule) },
  {
    path: "Radiology",
    loadChildren: () => import('./radiology/radiology.module').then(m => m.RadiologyModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Employee",
    loadChildren: () => import('./employee/employee.module').then(m => m.EmployeeModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "ADTMain",
    loadChildren: () => import('./adt/adt.module').then(m => m.ADTModule),
    data: { currentRoute: "ADTMain" }
  },
  {
    path: "Settings",
    loadChildren: () => import('./settings-new/settings.module').then(m => m.SettingsModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Reports",
    loadChildren: () => import('./reporting/reporting.module').then(m => m.ReportingModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Helpdesk",
    loadChildren: () => import('./helpdesk/helpdesk.module').then(m => m.HelpdeskModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Inventory",
    loadChildren: () => import('./inventory/inventory.module').then(m => m.InventoryModule),
    canActivate: [AuthGuardService],
    data: { currentRoute: "Inventory" },
  },
  {
    path: "Accounting",
    loadChildren: () => import('./accounting/accounting.module').then(m => m.AccountingModule),
  },
  {
    path: "SystemAdmin",
    loadChildren: () => import('./system-admin/system-admin.module').then(m => m.SystemAdminModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Pharmacy",
    loadChildren: () => import('./pharmacy/pharmacy.module').then(m => m.PharmacyModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Nursing",
    loadChildren: () => import('./nursing/nursing.module').then(m => m.NursingModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Scheduling",
    loadChildren: () => import('./scheduling/scheduling.module').then(m => m.SchedulingModule),
    canActivate: [AuthGuardService],
  },
  //{
  //  path: "Fraction",
  //  loadChildren: "./fraction/fraction.module#FractionModule",
  //},
  {
    path: "WardSupply",
    loadChildren: () => import('./wardsupply/wardsupply.module').then(m => m.WardSupplyModule),
  },
  {
    path: "Emergency",
    loadChildren: () => import('./emergency/emergency.module').then(m => m.EmergencyModule),
  },
  {
    path: "Incentive",
    loadChildren: () => import('./incentive/incentive.module').then(m => m.IncentiveModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Medical-records",
    loadChildren:
      () => import('./medical-records/medical-records.module').then(m => m.MedicalRecordsModule),
  },
  {
    path: "PayrollMain",
    loadChildren: () => import('./payroll-module/payroll-main.module').then(m => m.PayrollMainModule),
  },
  {
    path: "Verification",
    loadChildren: () => import('./verification/verification.module').then(m => m.VerificationModule),
  },
  {
    path: "OperationTheatre",
    loadChildren: () => import('./ot-module/ot.module').then(m => m.OperationTheatreModule),
  },
  {
    path: "Dispensary",
    loadChildren: () => import('./dispensary/dispensary.module').then(m => m.DispensaryModule),
  },
  {
    path: "SSU",
    loadChildren: () => import('./ssu/social-service-unit.module').then(m => m.SocialServiceUnitModule),
  },
  {
    path: 'GovInsurance',
    loadChildren: () => import('./insurance/nep-gov/gov-insurance.module').then(m => m.GovInsuranceModule),
    canActivate: [AuthGuardService]
  },
  {
    path: "FixedAssets",
    loadChildren: () => import('./fixed-asset/fixed-assets.module').then(m => m.FixedAssetsModule),
    data: { currentRoute: "FixedAssets" },
  },
  {
    path: "ProcurementMain",
    loadChildren: () => import('./procurement/procurement.module').then(m => m.ProcurementModule),
    canActivate: [AuthGuardService],
    data: { currentRoute: "ProcurementMain" },
  },
  {
    path: "CSSD",
    loadChildren: () => import('./cssd/cssd.module').then(m => m.CssdModule),
    canActivate: [AuthGuardService],
  },
  { path: "ActivateInventory", component: ActivateInventoryComponent },
  {
    path: "Maternity",
    loadChildren: () => import('./maternity/maternity.module').then(m => m.MaternityModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "Vaccination",
    loadChildren: () => import('./vaccination/vaccination.module').then(m => m.VaccinationModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "QueueManagement",
    loadChildren:
      () => import('./queue-management/queue-management.module').then(m => m.QueueManagementModule),
    canActivate: [AuthGuardService],
  },
  {
    path: "ClaimManagement",
    loadChildren:
      () => import('./claim-management/claim-management.module').then(m => m.ClaimManagementModule)
    , canActivate: [AuthGuardService]
  },
  { path: "DynamicReport", component: DynamicReportComponent },
  { path: "UnAuthorized", component: UnAuthorizedAccessComponent },
  { path: "Utilities", loadChildren: () => import('./utilities/utilities.module').then(m => m.UtilitiesModule), canActivate: [AuthGuardService], data: { currentRoute: 'Utilities' } },
  { path: "MktReferral", loadChildren: () => import('./mktreferral/mktreferral.module').then(m => m.MktreferralModule) },
  { path: "login", component: LoginComponent },

  { path: "**", component: PageNotFound },
];
