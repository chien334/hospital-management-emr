CREATE OR REPLACE FUNCTION sp_report_bildsb_monthlybillingtrend(

)
RETURNS TABLE (
    "month" TIMESTAMP,
    "Paid" INT,
    "Unpaid" INT,
    "Tax" VARCHAR
) AS $$
BEGIN
    /*
      need to check the data correctness of this storedproc: sudarshan:9jul2017
    */
    
    --dividing by thousand since we're showing 'amount in thousands in the dashboards.'
     RETURN QUERY SELECT SUBSTRING(mth.MthName,1,8) AS "month",
    		(COALESCE(paid.Paid,0))::float/1000 AS "Paid",
    		(COALESCE(unpaid.Unpaid,0))::float/1000 AS "Unpaid",
    		(COALESCE(Tax.Tax,0))::float/1000 AS "Tax"
      from 
     
      --output format of date is: 2017-July, 2017-June, etc
    	( select (EXTRACT(YEAR FROM Dates))::VARCHAR ||'-'|| trim(to_char(Dates, 'month')) AS "MthName", EXTRACT(YEAR FROM Dates)*12+EXTRACT(MONTH FROM Dates) AS "seq"
    	   from "FN_Temp_GetLast7Months" () ) mth
    
    	LEFT OUTER JOIN
    	(
    		 --output format of date is: 2017-July, 2017-June, etc
    		select (EXTRACT(YEAR FROM PaidDate))::VARCHAR ||'-'|| trim(to_char(PaidDate, 'month')) AS "MthName", Sum(TotalAmount) AS "Paid" 
    		from BIL_TXN_BillingTransactionItems
    		where PaidDate is not null
    		Group by (EXTRACT(YEAR FROM PaidDate))::VARCHAR ||'-'|| trim(to_char(PaidDate, 'month'))
    	) paid
    	  ON mth.MthName = paid.MthName
    
    	LEFT OUTER JOIN
    		(
          --output format of date is: 2017-July, 2017-June, etc
    		   select (EXTRACT(YEAR FROM CreatedOn))::VARCHAR ||'-'|| trim(to_char(CreatedOn, 'month')) AS "MthName", Sum(TotalAmount) AS "Unpaid" 
    		   from BIL_TXN_BillingTransactionItems
    		   where PaidDate is NULL OR ( (paiddate)::date != (createdon)::date )
    		   Group by (EXTRACT(YEAR FROM CreatedOn))::VARCHAR ||'-'|| trim(to_char(CreatedOn, 'month'))
    		) unpaid
    
    	  ON mth.MthName = unpaid.MthName
    
    	LEFT OUTER JOIN
    		(
    		 --output format of date is: 2017-July, 2017-June, etc
    		  select (EXTRACT(YEAR FROM PaidDate))::VARCHAR ||'-'|| trim(to_char(PaidDate, 'month')) AS "MthName", Sum(Tax) AS "Tax" 
    		   from BIL_TXN_BillingTransactionItems
    		   where PaidDate is not null
    		   Group by (EXTRACT(YEAR FROM PaidDate))::VARCHAR ||'-'|| trim(to_char(PaidDate, 'month'))
    		) tax
    
    	on mth.mthname = tax.mthname
    order by mth.seq desc;
    
    
    
    /****** object:  storedprocedure "sp_report_bill_departmentsalesdaybook"    script date: 5/2/2018 2:24:13 pm ******/
END;
$$ LANGUAGE plpgsql;