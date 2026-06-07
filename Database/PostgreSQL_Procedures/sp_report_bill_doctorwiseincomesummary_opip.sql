CREATE OR REPLACE FUNCTION sp_report_bill_doctorwiseincomesummary_opip(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_performerid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*  
    change history  
    s.no.    updatedby/date     remarks  
    1  sud/08aug'18   created the script  
    2  Ramavtar/08Aug'18  getting doctor name from employee table  
    3.      sud/22aug'18            updated for IP Records  
    4.      Dev/24th_Jan'22         change nodoctor to unassgined in case no doctor is selected  
    5.	krishna/9thjun'22			changed ProviderId to PerformerId and ProviderName to PerformerName
    */  
      
      
    OPEN ref1 FOR SELECT  
      COALESCE(OPD.PerformerName, IPD.PerformerName) AS "DoctorName",  
      COALESCE(OPD.SubTotal, 0) AS "OP_Collection",  
      COALESCE(OPD.Discount, 0) AS "OP_Discount",  
      COALESCE(OPD.Refund, 0) AS "OP_Refund",  
      COALESCE(OPD.NetTotal, 0) AS "OP_NetTotal",  
      COALESCE(IPD.SubTotal, 0) AS "IP_Collection",  
      COALESCE(IPD.Discount, 0) AS "IP_Discount",  
      COALESCE(IPD.Refund, 0) AS "IP_Refund",  
      COALESCE(IPD.NetTotal, 0) AS "IP_NetTotal",  
      COALESCE(OPD.NetTotal, 0) + COALESCE(IPD.NetTotal, 0) AS "Grand_Total"  
    FROM (SELECT  
      CASE  
       WHEN PerformerId IS NOT NULL THEN PerformerName  
       ELSE 'unassigned'  
      END AS "PerformerName",  
      SUM(COALESCE(SubTotal, 0)) AS "SubTotal",  
      SUM(COALESCE(DiscountAmount, 0)) AS "Discount",  
      SUM(COALESCE(ReturnAmount, 0)) AS "Refund",  
      SUM(COALESCE(TotalAmount, 0) - COALESCE(ReturnAmount, 0)) AS "NetTotal"  
     FROM FN_BIL_GetTxnItemsInfoWithDateSeparation(p_fromdate, p_todate)  
     WHERE BillingType = 'outpatient' AND BillStatus != 'cancelled'  
      AND (COALESCE(p_performerid, COALESCE(PerformerId, 0)) = COALESCE(PerformerId, 0))  
     GROUP BY PerformerId,PerformerName) OPD  
    FULL OUTER JOIN (  
     SELECT  
      CASE  
       WHEN PerformerId IS NOT NULL THEN PerformerName  
       ELSE 'unassigned'  
      END AS "PerformerName",  
      SUM(COALESCE(SubTotal, 0)) AS "SubTotal",  
      SUM(COALESCE(DiscountAmount, 0)) AS "Discount",  
      SUM(COALESCE(ReturnAmount, 0)) AS "Refund",  
      SUM(COALESCE(TotalAmount, 0) - COALESCE(ReturnAmount, 0)) AS "NetTotal"  
     FROM FN_BIL_GetTxnItemsInfoWithDateSeparation(p_fromdate, p_todate)  
     WHERE BillingType = 'inpatient' AND BillStatus != 'cancelled'  
      AND (COALESCE(p_performerid, COALESCE(PerformerId, 0)) = COALESCE(PerformerId, 0))  
     GROUP BY PerformerId,PerformerName) IPD  
    ON OPD.PerformerName = IPD.PerformerName  
    ORDER BY DoctorName;
        RETURN NEXT ref1;  
      
    OPEN ref2 FOR SELECT   
      SUM(CASE WHEN BillStatus='provisional' THEN ProvisionalAmount ELSE 0 END) AS "ProvisionalAmount",  
      SUM(CASE WHEN BillStatus='cancelled' THEN CancelledAmount ELSE 0 END) AS "CancelledAmount",  
      SUM(CASE WHEN BillStatus='credit' then creditamount else 0 end) as "creditamount",  
      (select sum(coalesce(advancereceived,0)) from fn_bil_getdepositnprovisionalbetndaterange(p_fromdate,p_todate)) as "advancereceived",  
      (select sum(coalesce(advancesettled,0)) from fn_bil_getdepositnprovisionalbetndaterange(p_fromdate,p_todate)) as "advancesettled"  
     from fn_bil_gettxnitemsinfowithdateseparation(p_fromdate, p_todate)  
     where (coalesce(p_performerid, coalesce(performerid, 0)) = coalesce(performerid, 0));
        return next ref2;
END;
$$ LANGUAGE plpgsql;