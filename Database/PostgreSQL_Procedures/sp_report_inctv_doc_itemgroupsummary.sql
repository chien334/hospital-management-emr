CREATE OR REPLACE FUNCTION sp_report_inctv_doc_itemgroupsummary(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_employeeid INT DEFAULT NULL,
    p_isrefferalonly BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    "ItemName" VARCHAR,
    "TotalQty" INT,
    "TotalBillAmt" DECIMAL,
    "TotalIncentiveAmount" DECIMAL,
    "TotalTDSAmount" DECIMAL
) AS $$
BEGIN
    /*
    author: 18mar'20/Pratik 
    Description: To get incentive report group by Items for Selected Doctor between selected range.
    Change History
    S.No.   Date/Author							Remarks
    1.     18Mar'20/pratik						initial draft
    2.     6june'21/Pratik						Correcting Total Qty of Incentive Fraction Item
    3.     23Aug'22/dev narayan					added filter incentivetype = 'referral' for new report ->
    											'Incentive Referral Summary'
    */
    
    
    	
    RETURN QUERY SELECT itemname,
    	--count(*) 'TotalQty_old',
    	sum(case when coalesce(isreturntxn,0)=0 then 1 else -1 end) AS "TotalQty",
    	sum(totalbillamount) AS "TotalBillAmt",
    	sum(incentiveamount) AS "TotalIncentiveAmount", sum(tdsamount) AS "TotalTDSAmount"
    
    from inctv_txn_incentivefractionitem incitm
    
    where  incentivereceiverid = p_employeeid 
    and (incitm.transactiondate)::date between p_fromdate and p_todate
    and coalesce(isactive,0)=1
    and ((p_isrefferalonly = true and incitm.incentivetype = 'referral')
    or (p_isrefferalonly = false)
    )
    
    group by itemname;
END;
$$ LANGUAGE plpgsql;