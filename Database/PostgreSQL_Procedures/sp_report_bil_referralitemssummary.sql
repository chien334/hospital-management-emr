CREATE OR REPLACE FUNCTION sp_report_bil_referralitemssummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_prescriberid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*  
    change history  
    s.no.    updatedby/date          remarks  
    1    sud/pratik/13oct'19      initail draft  
    2	 Krishna/9thJun'22		  changed referredby to prescriberid 
    3	 krishna/14thnov'22		  ReferredDoctorName changed to Doctor
    */  
      
       OPEN ref1 FOR SELECT  
           BillingDate AS "Date",  
           COALESCE(fnItems.Doctor, 'no doctor') AS "PrescriberName",  
           pat.PatientCode,  
           pat.FirstName || ' ' || COALESCE(pat.MiddleName || ' ', '') || pat.LastName AS "PatientName",  
          "FN_BIL_GetSrvDeptReportingName_DoctorSummary" (fnItems.ServiceDepartmentName, ItemName) AS "ServiceDepartmentName",  
           fnItems.ItemName,  
           fnItems.Price,  
           COALESCE(fnItems.Quantity, 0) - COALESCE(fnItems.ReturnQuantity, 0) AS "Quantity",  
           fnItems.SubTotal,  
           fnItems.DiscountAmount,  
           fnItems.TotalAmount,  
           fnItems.ReturnTotalAmount AS "ReturnAmount",  
           fnItems.TotalAmount - fnItems.ReturnTotalAmount AS "NetAmount"  
       FROM   
       
         FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional(p_fromdate, p_todate) fnItems  
      
       JOIN PAT_Patient pat ON fnItems.PatientId = pat.PatientId  
       WHERE   
             COALESCE(fnItems.PrescriberId, 0) = p_prescriberid  
        and fnItems.BillingType !='creditreceived'  
       ORDER BY 1 DESC;
        RETURN NEXT ref1;  
      
      
       OPEN ref2 FOR SELECT   
        SUM(CASE WHEN BillStatus='provisional' THEN ProvisionalAmount ELSE 0 END) AS "ProvisionalAmount",  
        SUM(CASE WHEN BillStatus='cancelled' THEN CancelledAmount ELSE 0 END) AS "CancelledAmount",  
        SUM(CASE WHEN BillStatus='credit' then creditamount else 0 end) as "creditamount"  
       from fn_bil_gettxnitemsinfowithdateseparation_doctorsummary(p_fromdate,p_todate)  
       where  coalesce(prescriberid,0) = p_prescriberid;
        return next ref2;  
      
      
      --end of sp
END;
$$ LANGUAGE plpgsql;