import { Injectable } from "@angular/core";
import { Observable } from "rxjs";
import { CoreDLService } from "../../core/shared/core.dl.service";
import { DsfHTTPResponse } from "../../shared/common-models";
import { ReferralCommission_DTO } from "./DTOs/referral-commission.dto";
import { ReferringOrganization_DTO } from "./DTOs/referral-organization.dto";
import { ReferralParty_DTO } from "./DTOs/referral-party.dto";
import { MarketingReferralDLService } from "./marketingreferral.dl.service";


@Injectable()
export class MarketingReferralBLService {
    constructor(public coreDLService: CoreDLService, public mktreferralDLService: MarketingReferralDLService) {

    }
    public GetInvoiceList(fromDate, toDate): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.GetInvoiceList(fromDate, toDate)
            .map(res => {
                return res;
            });
    }
    public GetMarketingReferralDetailReport(fromDate, toDate, ReferringPartyId): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.GetMarketingReferralDetailReport(fromDate, toDate, ReferringPartyId)
            .map(res => {
                return res;
            });
    }
    public GetBillDetails(billTransactionId): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.GetBillDetails(billTransactionId)
            .map(res => {
                return res;
            });
    }
    public GetReferralScheme(): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.GetReferralScheme()
            .map(res => {
                return res;
            });
    }

    public GetReferringParty(): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.GetReferringParty()
            .map(res => {
                return res;
            });
    }
    public GetReferringPartyGroup(): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.GetReferringPartyGroup()
            .map(res => {
                return res;
            });
    }
    public GetReferringOrganization(): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.GetReferringOrganization()
            .map(res => {
                return res;
            });
    }
    public GetAlreadyAddedCommission(BillingTransactionId): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.GetAlreadyAddedCommission(BillingTransactionId)
            .map(res => {
                return res;
            });
    }
    public DeleteReferralCommission(ReferralCommissionId): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.DeleteReferralCommission(ReferralCommissionId)
            .map(res => {
                return res;
            });
    }
    public SaveNewReferral(referralComission_DTO: ReferralCommission_DTO): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.SaveNewReferral(referralComission_DTO)
            .map(res => {
                return res;
            });
    }
    public SaveReferringOrganization(referringOrganization_DTO: ReferringOrganization_DTO): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.SaveReferringOrganization(referringOrganization_DTO)
            .map(res => {
                return res;
            });
    }
    public SaveReferringParty(referralParty_DTO: ReferralParty_DTO): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.SaveReferringParty(referralParty_DTO)
            .map(res => {
                return res;
            });
    }
    public UpdateReferringOrganization(referringOrganization_DTO: ReferringOrganization_DTO): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.UpdateReferringOrganization(referringOrganization_DTO)
            .map(res => {
                return res;
            });
    }
    public UpdateReferringParty(referringparty_DTO: ReferralParty_DTO): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.UpdateReferringParty(referringparty_DTO)
            .map(res => {
                return res;
            });
    }
    public ActivateDeactivateOrganization(selectedItem): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.ActivateDeactivateOrganization(selectedItem)
            .map(res => {
                return res;
            });
    }
    public ActivateDeactivateParty(selectedItem): Observable<DsfHTTPResponse> {
        return this.mktreferralDLService.ActivateDeactivateParty(selectedItem)
            .map(res => {
                return res;
            });
    }
}
