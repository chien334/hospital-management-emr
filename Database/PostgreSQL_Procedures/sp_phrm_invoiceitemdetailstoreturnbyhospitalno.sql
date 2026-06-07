CREATE OR REPLACE FUNCTION sp_phrm_invoiceitemdetailstoreturnbyhospitalno(
    p_hospitalno VARCHAR DEFAULT NULL,
    p_paymentmode VARCHAR DEFAULT NULL,
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_storeid INT DEFAULT NULL,
    p_schemeid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    v_defschemeid INT := (Select SchemeId from BIL_CFG_Scheme WHERE IsSystemDefault = 1);
BEGIN
    /*
     filename: "sp_phrm_invoiceitemdetailstoreturnbyhospitalno"
     created: 30jan'23/Rohit
     Description: To Get the Multiple Invoice Items Details to return by Hospital No.
     Remarks: 
     Change History
     S.No.    Date/User              Change          Remarks
     1.	     30Jan'23/rohit		                     inital draft
     2.      rohit/13feb'23						     MRP-> SalePrice
     3.		 Rohit/14Feb'23							 item which is totally return should not be included (invitm.quantity !=coalesce(retitm.previouslyreturnedqty, 0))
     4.  rohit/sud: 20apr'23 (TEMPORARY REVISION ONLY)   --- Removed PriceCategory Dependency for Manipal UAT ONLY. Need immediate Revision/Correction
     5.  Nirmala/ 6/1/23                              Select Invoice Created Date and VisitType
     6.  Nirmala/29/Jun/23                            Remove COALESCE() in DefaultCreditOrganizationId and DefaultPaymentMode
    */
    BEGIN
    
    
    IF (p_schemeid IS NULL OR p_schemeid = 0)
    THEN
    	p_schemeid := v_defschemeid;
    END IF;
    	
    
    	OPEN ref1 FOR SELECT  pat.PatientId
    		,pat.ShortName AS "PatientName"
    		,COALESCE(visit.VisitType,'outpatient') AS "VisitType"
    		,CASE 
    			WHEN pat.IsOutdoorPat = 1
    				THEN 'outdoor'
    			ELSE 'indoor'
    			END AS PatientType
    		,pat.PatientCode AS "HospitalNo"
    	FROM PAT_Patient pat 
    	LEFT JOIN PAT_PatientVisits visit ON pat.PatientId=visit.PatientId
    	WHERE pat.PatientCode = p_hospitalno LIMIT 1;
        RETURN NEXT ref1;
    
    	OPEN ref2 FOR SELECT pc.SchemeName
    	,pc.SchemeId
    		,COALESCE(pc.IsPharmacyCoPayment,0) AS "IsPharmacyCoPayment"
    		,COALESCE(pc.PharmacyCoPayCashPercent,0) AS "PharmacyCoPayCashPercent"
    		,COALESCE(pc.PharmacyCoPayCreditPercent,0) AS "PharmacyCoPayCreditPercent"
    		,COALESCE(pc.OpPhrmDiscountPercent,0) AS "OpPhrmDiscountPercent"
    		,pc.DefaultCreditOrganizationId AS "DefaultCreditOrganizationId"
    		,pc.DefaultPaymentMode AS "DefaultPaymentMode"
    	 From BIL_CFG_Scheme pc
    	 where COALESCE(pc.SchemeId, 1) = p_schemeid;
        RETURN NEXT ref2;
    
    
    	--SELECT pc.PriceCategoryName
    	--	,COALESCE(pmc.PatientMapPriceCategoryId, 0) 'patientmappricecategoryid'
    	--	,COALESCE(pmc.PriceCategoryId, 0) 'pricecategory'
    	--	,COALESCE(pc.IsCoPayment, 0) 'iscopayment'
    	--	,COALESCE(pc.Copayment_CashPercent, 0) 'copaymentcashpercent'
    	--	,COALESCE(pc.Copayment_CreditPercent, 0) 'copaymentcreditpercent'
    	--FROM PAT_Patient pat
    	--INNER JOIN PAT_Map_PriceCategory pmc ON pat.PatientId = pmc.PatientId
    	--INNER JOIN BIL_CFG_PriceCategory pc ON pmc.PriceCategoryId = pc.PriceCategoryId
    	--WHERE pat.PatientCode = p_hospitalno
    	--	AND COALESCE(pc.PriceCategoryId, 1) = v_pricecategoryid
    
    
    	OPEN ref3 FOR SELECT invitm.ItemId
    		,invitm.ItemName
    		,invitm.BatchNo
    		,invitm.SalePrice
    		,invitm.Quantity
    		,invitm.Quantity AS "SoldQty"
    		,COALESCE(retitm.PreviouslyReturnedQty, 0) AS "PreviouslyReturnedQty"
    		,0 AS "SubTotal"
    		,0 AS "DiscountAmount"
    		,0 AS "VATAmount"
    		,0 AS "TotalAmount"
    		,invitm.DiscountPercentage
    		,invitm.VATPercentage
    		,'ph' || (inv.invoiceprintid)::varchar as "billno"
    		,inv.invoiceid
    		,invitm.invoiceitemid
    		,invitm.createdon
    		,inv.fiscalyearid
    		,inv.invoiceprintid as "invoiceno"
    		,inv.settlementid
    	from pat_patient pat
    	inner join phrm_txn_invoice inv on pat.patientid = inv.patientid
    	inner join phrm_txn_invoiceitems invitm on inv.invoiceid = invitm.invoiceid
    	left join (
    		select invoiceitemid
    			,coalesce(sum(returnedqty), 0) as "previouslyreturnedqty"
    		from phrm_txn_invoicereturnitems
    		group by invoiceitemid
    		) retitm on invitm.invoiceitemid = retitm.invoiceitemid
    	where pat.patientcode = p_hospitalno
    		and inv.paymentmode = p_paymentmode
    		and (inv.createon)::date between p_fromdate and p_todate
    		and inv.storeid = p_storeid
    		--and coalesce(invitm.pricecategoryid, 1) = v_pricecategoryid
    		and invitm.quantity !=coalesce(retitm.previouslyreturnedqty, 0)
    	order by inv.createon desc;
        return next ref3;
    
    end;
END;
$$ LANGUAGE plpgsql;