CREATE OR REPLACE FUNCTION sp_phrm_getinvoicesbetweendaterange(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS TABLE (
    "InvoiceId" INT,
    "InvoicePrintId" INT,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "VATAmount" DECIMAL,
    "PaidAmount" INT,
    "BilStatus" VARCHAR,
    "TotalCredit" DECIMAL,
    "CreateOn" TIMESTAMP,
    "IsOutdoorPat" BOOLEAN,
    "PatientType" VARCHAR,
    "PaymentMode" VARCHAR,
    "FiscalYear" VARCHAR,
    "NSHINumber" VARCHAR,
    "ClaimCode" VARCHAR
) AS $$
BEGIN
    /*
    filename:sp_phrm_getinvoicesbetweendaterange
    createdby/date: sud,sanjit/8apr'21 
    Description:Get Invoice Details for Pharmacy-> Duplicate Print 
    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.      Sud,Sanjit/8Apr'21                   initial draft
    2.		rusha/ramesh/08 june,21				patientshortname correction
    */
    begin
    p_fromdate := coalesce(p_fromdate,(current_timestamp)::date);
    p_todate := coalesce(p_todate,(current_timestamp)::date);
    
    RETURN QUERY SELECT
    	 inv.invoiceid,
    	 inv.invoiceprintid,
    	 --pat.shortname 'PatientName',
    	 pat.firstname || coalesce(' ' || pat.middlename, '') || ' ' || pat.lastname AS "PatientName",
    	 pat.patientcode,
    	 inv.subtotal,
    	 inv.discountamount,
    	 inv.vatamount,
    	 inv.paidamount,
    	 inv.bilstatus,
    	 inv.creditamount AS "TotalCredit",
    	 inv.createon,
    	 pat.isoutdoorpat,
    	 case when coalesce(pat.isoutdoorpat,0)=0 then 'Indoor'
    	   else 'Outdoor' end AS "PatientType",
    	inv.paymentmode,
    	fy.fiscalyearformatted AS "FiscalYear",
    	 pat.ins_nshinumber AS "NSHINumber",
    	 inv.claimcode AS "ClaimCode"
    
    	 from phrm_txn_invoice inv
    	 inner join bil_cfg_fiscalyears fy 
    	 on inv.fiscalyearid=fy.fiscalyearid
    	inner join pat_patient pat
    	on inv.patientid=pat.patientid
    
    where (inv.createon)::date between   p_fromdate and p_todate
    and inv.storeid = p_storeid
    order by inv.createon desc;
    end;
END;
$$ LANGUAGE plpgsql;