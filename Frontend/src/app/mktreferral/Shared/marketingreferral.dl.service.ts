import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { Observable } from "rxjs";
import { DsfHTTPResponse } from "../../shared/common-models";
import { ReferralCommission_DTO } from "./DTOs/referral-commission.dto";
import { ReferringOrganization_DTO } from "./DTOs/referral-organization.dto";
import { ReferralParty_DTO } from "./DTOs/referral-party.dto";


@Injectable()
export class MarketingReferralDLService {
    public optionsJson = {
        headers: new HttpHeaders({ 'Content-Type': 'application/json' })
    };
    constructor(public http: HttpClient) {

    }

    public GetInvoiceList(fromDate, toDate): Observable<DsfHTTPResponse> {
        return this.http.get<DsfHTTPResponse>(`/api/MarketingReferral/Invoices?FromDate=${fromDate}&ToDate=${toDate}`, this.optionsJson);
    }
    public GetMarketingReferralDetailReport(fromDate, toDate, ReferringPartyId): Observable<DsfHTTPResponse> {
        return this.http.get<DsfHTTPResponse>(`/api/MarketingReferral/MarketingreferralDetailReport?FromDate=${fromDate}&ToDate=${toDate}&ReferringPartyId=${ReferringPartyId}`, this.optionsJson);
    }
    public GetBillDetails(billTransactionId): Observable<DsfHTTPResponse> {
        return this.http.get<DsfHTTPResponse>(`/api/MarketingReferral/BillDetails?billTransactionId=${billTransactionId}`, this.optionsJson);
    }
    public GetReferralScheme(): Observable<DsfHTTPResponse> {
        return this.http.get<DsfHTTPResponse>("/api/MarketingReferral/ReferralScheme", this.optionsJson);
    }
    public GetReferringParty(): Observable<DsfHTTPResponse> {
        return this.http.get<DsfHTTPResponse>("/api/MarketingReferral/ReferringParty", this.optionsJson);
    }
    public GetReferringPartyGroup(): Observable<DsfHTTPResponse> {
        return this.http.get<DsfHTTPResponse>("/api/MarketingReferral/ReferringPartyGroup", this.optionsJson);
    }
    public GetReferringOrganization(): Observable<DsfHTTPResponse> {
        return this.http.get<DsfHTTPResponse>("/api/MarketingReferral/ReferringOrganization", this.optionsJson);
    }
    public GetAlreadyAddedCommission(BillingTransactionId): Observable<DsfHTTPResponse> {
        return this.http.get<DsfHTTPResponse>(`/api/MarketingReferral/AlreadyAddedCommission?BillingTransactionId=${BillingTransactionId}`, this.optionsJson);
    }
    public DeleteReferralCommission(ReferralCommissionId): Observable<DsfHTTPResponse> {
        return this.http.delete<DsfHTTPResponse>(`/api/MarketingReferral/ReferralCommission?ReferralCommissionId=${ReferralCommissionId}`, this.optionsJson);
    }
    public SaveNewReferral(referralComission_DTO: ReferralCommission_DTO): Observable<DsfHTTPResponse> {
        return this.http.post<DsfHTTPResponse>("/api/MarketingReferral/NewReferralComission", referralComission_DTO, this.optionsJson);
    }
    public SaveReferringOrganization(referringOrganization_DTO: ReferringOrganization_DTO): Observable<DsfHTTPResponse> {
        return this.http.post<DsfHTTPResponse>("/api/MarketingReferral/NewReferringOrganization", referringOrganization_DTO, this.optionsJson);
    }
    public SaveReferringParty(referralParty_DTO: ReferralParty_DTO): Observable<DsfHTTPResponse> {
        return this.http.post<DsfHTTPResponse>("/api/MarketingReferral/NewReferringParty", referralParty_DTO, this.optionsJson);
    }
    public UpdateReferringOrganization(referringOrganization_DTO: ReferringOrganization_DTO): Observable<DsfHTTPResponse> {
        return this.http.put<DsfHTTPResponse>("/api/MarketingReferral/ReferringOrganization", referringOrganization_DTO, this.optionsJson);
    }
    public UpdateReferringParty(referringParty_DTO: ReferralParty_DTO): Observable<DsfHTTPResponse> {
        return this.http.put<DsfHTTPResponse>("/api/MarketingReferral/ReferringParty", referringParty_DTO, this.optionsJson);
    }
    public ActivateDeactivateOrganization(selectedItem): Observable<DsfHTTPResponse> {
        return this.http.put<DsfHTTPResponse>("/api/MarketingReferral/ActivateDeactivateOrganization", selectedItem, this.optionsJson);
    }
    public ActivateDeactivateParty(selectedItem): Observable<DsfHTTPResponse> {
        return this.http.put<DsfHTTPResponse>("/api/MarketingReferral/ActivateDeactivateParty", selectedItem, this.optionsJson);
    }
}