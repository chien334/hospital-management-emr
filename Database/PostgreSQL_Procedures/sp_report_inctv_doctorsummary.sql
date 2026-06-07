CREATE OR REPLACE FUNCTION sp_report_inctv_doctorsummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_isrefferalonly BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
    "PrescriberName" VARCHAR,
    "PrescriberId" INT,
    "DocTotalAmount" DECIMAL,
    "TDSAmount" DECIMAL,
    "NetPayableAmount" DECIMAL,
    "PanNo" VARCHAR
) AS $$
BEGIN
    /************************************************************************
    --altering sp_report_inctv_doctorsummary sp
    --added a column pan no. of the respective doctor   
    -- author: nirmala/18nov'22 
    --Change History:  
    S.No.  Author/Date                   Remarks  
    1.    Pratik/20Nov'19               initial draft  
    2.    sud/26feb'20                  TDSPercentage added in Summary.  
    3.    Pratik/18Mar'20               no need of incentivetype, tdspercent, just show the summary at doctor level for given date range.   
    4.	  krishna,9thjun'22				changed ReferrerName to PrescriberName and ReferredId to PrescriberId
    5.    23Aug'22/dev narayan          added filter incentivetype = 'referral' for new report ->'Incentive Referral Summary'
    6.    nirmala/18nov'22              Add a column Pan No. of the respective doctor
    *************************************************************************/
      
    RETURN QUERY SELECT  emp.FullName AS "PrescriberName", incItm.IncentiveReceiverId AS "PrescriberId"  
       ,SUM(incItm.IncentiveAmount) AS "DocTotalAmount"  
       ,SUM(incItm.TDSAmount) AS "TDSAmount"  
       ,SUM(incItm.IncentiveAmount - incItm.TDSAmount) AS "NetPayableAmount" 
       ,emp.PANNumber AS "PanNo"
       FROM INCTV_TXN_IncentiveFractionItem incItm    
       INNER JOIN EMP_Employee emp  
       ON incItm.IncentiveReceiverId=emp.EmployeeId  
      
     WHERE   
         COALESCE(incItm.IsActive,0)=1  
         AND (incItm.TransactionDate)::Date Between p_fromdate AND p_todate  
    	 AND ((p_isrefferalonly = TRUE AND incItm.IncentiveType = 'referral')
    		or (p_isrefferalonly = false)
    	 )
      
      group by emp.fullname, incitm.incentivereceiverid,pannumber;
END;
$$ LANGUAGE plpgsql;