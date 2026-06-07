CREATE OR REPLACE FUNCTION sp_report_bill_customreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_reportname VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename: "sp_report_bill_customreport"
    createdby/date: nagesh/2018-08-27
    description: sp for custom report like 100% on opd 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1      nagesh/2018-08-27	        created the script
    2	   ramavtar/12nov'18			correcting parameter passed to fn-> FN_BIL_GetSrvDeptReportingName
    */
     BEGIN
      IF ((p_fromdate IS NOT NULL) and (p_todate IS NOT NULL)) 
    		THEN
    			OPEN ref1 FOR SELECT count(*) as NoOfPatient from BIL_TXN_BillingTransactionItems bil 
    			WHERE (ServiceDepartmentName='opd' and DiscountPercent=100 AND  COALESCE(ReturnStatus,0) != 1)
    			AND (bil.CreatedOn)::date Between p_fromdate AND p_todate;
        RETURN NEXT ref1;
    
    			OPEN ref2 FOR WITH T as 
    			(
    				SELECT  (bil.CreatedOn)::DATE AS "Date",
    				ItemName,FN_BIL_GetSrvDeptReportingName(bil.ServiceDepartmentName,ItemName)as ServDepartmentName,Quantity,TotalAmount 
    				from BIL_TXN_BillingTransactionItems  bil
    				WHERE PatientId in 
    				(   SELECT PatientId FROM BIL_TXN_BillingTransactionItems 
    					WHERE (ServiceDepartmentName='opd' and DiscountPercent=100 and COALESCE(ReturnStatus,0) != 1) 
    					AND (bil.CreatedOn)::DATE Between p_fromdate AND p_todate
    				)   
    			AND (bil.CreatedOn)::date Between p_fromdate AND p_todate
    			AND COALESCE(ReturnStatus,0) != 1      
    			) 
    			SELECT  CASE WHEN  "ItemName"='vitamin d' OR ItemName='health card' THEN ItemName
                   ELSE ServDepartmentName END  as Particulars
    				,SUM(Quantity) AS TotalNumber, 
    				SUM(TotalAmount) AS TotalIncome
    				FROM T
    				GROUP BY ( CASE WHEN  "ItemName"='vitamin d' OR ItemName='health card' then itemname
                   else servdepartmentname end );
        return next ref2;
    		end if;
    end;
END;
$$ LANGUAGE plpgsql;