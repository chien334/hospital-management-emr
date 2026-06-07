CREATE OR REPLACE FUNCTION sp_report_bil_doctorsummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Doctor" VARCHAR,
    "DoctorId" INT,
    "NetAmount_Performer" DECIMAL,
    "NetAmount_Prescriber" DECIMAL,
    "NetAmount_Referrer" DECIMAL
) AS $$
BEGIN
    /*  
    change history  
    s.no.    updatedby/date     remarks  
    1.  sud/02sept'18        Initial Draft  
    2.  Ramavtar/12Nov'18    sorting by doctorname  
    3.     ramavtar/30nov'18    summary added  
    4.  Ramavtar/17Dec'18   change in where condition (checking for credit records)  
    5.      sud/21feb'19                Changed as per new function <needs revision>  
    6.      Dinesh/8Dec'20              handling of settlementdiscount amount (need revision)  
    7.      dev/24th_jan'22         Change NoDoctor to Unassgined in case no doctor is selected  
    8.	Krishna,9thJun'22			changed providerid to performerid and providername to performername
    9.	krishna, 10thaug'22			SP completely changed according to Performer, Prescriber and Referrer
    */  
      
        
    RETURN QUERY SELECT tbl1.Doctor,
    	tbl1.DoctorId
    	,SUM(COALESCE(tbl1.PerformerNetAmount, 0)) AS "NetAmount_Performer"
    	,SUM(COALESCE(tbl1.PrescriberNetAmount, 0)) AS "NetAmount_Prescriber"
    	,SUM(COALESCE(tbl1.ReferrerNetAmount, 0)) AS "NetAmount_Referrer"
    FROM (
    	SELECT tbl.Doctor,
    	tbl.DoctorId
    		,CASE 
    			WHEN DoctorType = 'performer'
    				THEN SUM(COALESCE(NetAmount, 0))
    			END AS "PerformerNetAmount"
    		,CASE 
    			WHEN DoctorType = 'prescriber'
    				THEN SUM(COALESCE(NetAmount, 0))
    			END AS "PrescriberNetAmount"
    		,CASE 
    			WHEN DoctorType = 'referrer'
    				THEN SUM(COALESCE(NetAmount, 0))
    			END AS "ReferrerNetAmount"
    	FROM (
    	
    
    	Select 
    			'performer' AS DoctorType,
    			COALESCE(emp.FullName,'unassigned') AS "Doctor",
    			COALESCE(billingData.PerformerId,0) AS "DoctorId",
    			SUM(billingData.SalesAmount) AS "SalesAmt",
    			SUM(billingData.ReturnAmount) AS "RetAmount",
    			SUM(billingData.NetAmount) AS "NetAmount"
    
    		from
    		(
    
    			Select COALESCE(invItm.PerformerId,retItm.PerformerId) AS "PerformerId"
    			, COALESCE(invItm.SalesAmount,0) AS "SalesAmount"
    			, COALESCE(retItm.ReturnAmount,0) AS "ReturnAmount"
    			, COALESCE(invItm.SalesAmount,0) - COALESCE(retItm.ReturnAmount,0) AS "NetAmount"
    			from 
    			( Select itm.BillingTransactionItemId, PerformerId
    				, itm.TotalAmount AS "SalesAmount"
    				from BIL_TXN_BillingTransactionItems itm
    				INNER JOIN BIL_TXN_BillingTransaction txn on itm.BillingTransactionId=txn.BillingTransactionId
    				Where   (txn.CreatedOn)::Date between p_fromdate and p_todate
       
    				) invItm 
    			FULL OUTER JOIN 
    				( Select rti.BillingTransactionItemId, sum(RettotalAmount) AS "ReturnAmount" 
    				, itm.PerformerId
    				from BIL_TXN_InvoiceReturnItems rti inner join BIL_TXN_BillingTransactionItems itm
    					on rti.BillingTransactionItemId=itm.BillingTransactionItemId
    					INNER JOIN BIL_TXN_InvoiceReturn ret on rti.BillReturnId=ret.BillReturnId
    				Where (ret.CreatedOn)::Date between p_fromdate and p_todate
    				Group by rti.BillingTransactionItemId, itm.PerformerId
    			) retItm
    			on invItm.BillingTransactionItemId=retItm.BillingTransactionItemId
    		) billingData
    		LEFT JOIN EMP_Employee emp on billingData.PerformerId=emp.EmployeeId
    
    		Group by COALESCE(emp.FullName,'unassigned'), billingData.PerformerId
    
    
    		
    		UNION ALL
    		(
    			Select 
    				 'prescriber' AS DoctorType,
    				 COALESCE(emp.FullName,'unassigned') AS "Doctor",
    				 COALESCE(billingData.PrescriberId,0) AS "DoctorId",
    				 SUM(billingData.SalesAmount) AS "SalesAmt",
    				 SUM(billingData.ReturnAmount) AS "RetAmount",
    				 SUM(billingData.NetAmount) AS "NetAmount"
    
    				from
    				(
    
    					Select COALESCE(invItm.PrescriberId,retItm.PrescriberId) AS "PrescriberId"
    					, COALESCE(invItm.SalesAmount,0) AS "SalesAmount"
    					, COALESCE(retItm.ReturnAmount,0) AS "ReturnAmount"
    					, COALESCE(invItm.SalesAmount,0) - COALESCE(retItm.ReturnAmount,0) AS "NetAmount"
    					from 
    					( Select itm.BillingTransactionItemId, PrescriberId
    					  , itm.TotalAmount AS "SalesAmount"
    					  from BIL_TXN_BillingTransactionItems itm
    					   INNER JOIN BIL_TXN_BillingTransaction txn on itm.BillingTransactionId=txn.BillingTransactionId
    					  Where   (txn.CreatedOn)::Date between p_fromdate and p_todate
       
    					  ) invItm 
    					FULL OUTER JOIN 
    					   ( Select rti.BillingTransactionItemId, sum(RettotalAmount) AS "ReturnAmount" 
    						, itm.PrescriberId
    						from BIL_TXN_InvoiceReturnItems rti inner join BIL_TXN_BillingTransactionItems itm
    							on rti.BillingTransactionItemId=itm.BillingTransactionItemId
    						  INNER JOIN BIL_TXN_InvoiceReturn ret on rti.BillReturnId=ret.BillReturnId
    						Where (ret.CreatedOn)::Date between p_fromdate and p_todate
    						Group by rti.BillingTransactionItemId, itm.PrescriberId
    					) retItm
    					on invItm.BillingTransactionItemId=retItm.BillingTransactionItemId
    				) billingData
    				LEFT JOIN EMP_Employee emp on billingData.PrescriberId=emp.EmployeeId
    
    				Group by COALESCE(emp.FullName,'unassigned'), billingData.PrescriberId
    
    			)---end of Prescriber section
    		
    		UNION ALL
    		
    		(
    		 Select 
    				'referrer' AS DoctorType,
    				COALESCE(emp.FullName,'unassigned') AS "Doctor",
    				COALESCE(billingData.ReferredById,0) AS "DoctorId",
    				SUM(billingData.SalesAmount) AS "SalesAmt",
    				SUM(billingData.ReturnAmount) AS "RetAmount",
    				SUM(billingData.NetAmount) AS "NetAmount"
    
    			from
    			(
    
    				Select COALESCE(invItm.ReferredById,retItm.ReferredById) AS "ReferredById"
    				, COALESCE(invItm.SalesAmount,0) AS "SalesAmount"
    				, COALESCE(retItm.ReturnAmount,0) AS "ReturnAmount"
    				, COALESCE(invItm.SalesAmount,0) - COALESCE(retItm.ReturnAmount,0) AS "NetAmount"
    				from 
    				( Select itm.BillingTransactionItemId, ReferredById
    					, itm.TotalAmount AS "SalesAmount"
    					from BIL_TXN_BillingTransactionItems itm
    					INNER JOIN BIL_TXN_BillingTransaction txn on itm.BillingTransactionId=txn.BillingTransactionId
    					Where   (txn.CreatedOn)::Date between p_fromdate and p_todate
       
    					) invItm 
    				FULL OUTER JOIN 
    					( Select rti.BillingTransactionItemId, sum(RettotalAmount) AS "ReturnAmount" 
    					, itm.ReferredById
    					from BIL_TXN_InvoiceReturnItems rti inner join BIL_TXN_BillingTransactionItems itm
    						on rti.BillingTransactionItemId=itm.BillingTransactionItemId
    						INNER JOIN BIL_TXN_InvoiceReturn ret on rti.BillReturnId=ret.BillReturnId
    					Where (ret.CreatedOn)::Date between p_fromdate and p_todate
    					Group by rti.BillingTransactionItemId, itm.ReferredById
    				) retItm
    				on invItm.BillingTransactionItemId=retItm.BillingTransactionItemId
    			) billingData
    			LEFT JOIN EMP_Employee emp on billingData.ReferredById=emp.EmployeeId
    
    			Group by COALESCE(emp.FullName,'unassigned'), billingdata.referredbyid
    
    
    			)
    
    
    		) tbl
    	group by tbl.doctorid,tbl.doctor,tbl.doctortype
    
    	) tbl1
    group by tbl1.doctor, tbl1.doctorid
    order by tbl1.doctor;
END;
$$ LANGUAGE plpgsql;