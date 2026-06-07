CREATE OR REPLACE FUNCTION sp_report_bil_dailysales(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_counterid VARCHAR DEFAULT NULL,
    p_createdby INT DEFAULT NULL,
    p_isinsurance BOOLEAN DEFAULT FALSE
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
BEGIN
    /*
    filename: "sp_report_bil_dailysales"
    createdby/date: sud/2018-07-27
    description: to get sales + cash collection details from invoice and deposits table between given range. 
    remarks: 
        * deposits are returned as it is for isinsurance=1 as well since it's independent of sales
    	* We're returning 4 tables from this stored procedure.
    	   1. sales+sales return details
    	   2. settlement summary only
    	   3. summary of user collection which has cash impact in it.
    	   4. summary of other payments (eg: maternity for lph)
    	   5. collection segregation as per payment methods. (eg: cash: 5000, cheque: 4000, e-sewa: 3000, etc...)
    
    change history
    s.no.    updatedby/date                        remarks
    4.      sud/15feb'19                           Format Revised, getting sales summary from a function and then union with Deposit transactions.
    5.      Sud/7Aug'19                            added filter for isinsurance
    6.      sud/16jan'20                           Changed for UserName filter not working because of Salutation
    7.      Sud/1-Oct'21                           changed for countername and counterid comparison.
    8.      sud/23nov'21                           Settlement Scenarios Revised. (JiraId: EMR-4496)
    9.      Sud/25Nov'21                           for maternity> payment handling in user collection report.
    10.     sud/29nov'21                           BugFix> Maternity payment: User Filter was not handled earlier in Detailed View
    11.		Krishna/18thJan'22					   changed the filter of this report from username to its id (p_createdby varchar to int)
    12.		krishna/21stfeb'22					   Added table 5 to get the collection segregation..
    13.		Krishna/5thMay'23					   change deposittype to transactiontype and amount to inamount and outamount
    14.     sud:26jun'23                           Added NepMonthName and EngMonthName in Select List of first table
    */
    BEGIN
    
     IF (p_fromdate IS NOT NULL)
      OR (p_todate IS NOT NULL)
    THEN
    	
    	 --Table:1 - For Usercollection Details---
    	 --Return Columns: BillingDate, ReceiptNo, HospitalNo, patientName, BillingType, SubTotal, DiscountAmount, 
    	 --TaxTotal, TotalAmount, CashCollection, DepositReceived, DepositRefund, CreditReceived,CreditAmount, CounterId, EmployeeId, Remarks, User (CreatedBy)
    
       OPEN ref1 FOR SELECT
    			bills.BillingDate,
    			nepDate.NepMonthName,
    			nepDate.EngMonthShortName AS "EngMonthName",
    			bills.InvoiceNo AS "ReceiptNo",
    			pat.PatientCode AS "HospitalNo",
    			pat.ShortName AS PatientName,
    			bills.BillingType AS "BillingType",
    			bills.SubTotal,
    			bills.DiscountAmount,
    			bills.TaxTotal,
    			bills.TotalAmount, 
    			bills.CashCollection, 
    			bills.DepositReceived,
    			bills.DepositRefund,
    			bills.CreditReceived,
    			bills.CreditAmount,
    			bills.CounterId, 
    			cntr.CounterName,
    			bills."EmployeeId",
    			bills.Remarks,
    			emp.FullName AS CreatedBy
    		
    
    		FROM (
    					Select * from FN_BILL_BillingTxnSegregation_ByBillingType_DailySales(p_fromdate,p_todate)
    					WHERE COALESCE(IsInsuranceBilling,0) = p_isinsurance
    	    
    					UNION ALL
    
    					--All Deposits Transactions---
    					Select   (CreatedOn)::Date AS "BillingDate", 
    							 'dr'||(COALESCE(ReceiptNo,''))::VARCHAR AS "InvoiceNo", 
    							 Patientid,
    							 CASE WHEN TransactionType='deposit' THEN 'advancereceived' 
    								WHEN TransactionType='depositdeduct' OR TransactionType='returndeposit' THEN 'advancesettled' END AS "BillingType",
    			
    							 0 As SubTotal,0 AS DiscountAmount,0 AS TaxTotal, 0 AS TotalAmount, 
    							 CASE WHEN TransactionType='deposit' THEN InAmount WHEN TransactionType='depositdeduct' OR TransactionType='returndeposit' THEN (-OutAmount) END AS "CashCollection",
    							  CASE WHEN TransactionType='deposit' THEN InAmount ELSE 0 END AS "DepositReceived",
    							CASE WHEN  TransactionType='depositdeduct' OR TransactionType='returndeposit' THEN OutAmount ELSE 0 END AS "DepositRefund"
    						   
    							 , 0 AS CreditReceived,  0 AS "CreditAmount",
    							 CounterId AS "CounterId", CreatedBy AS "EmployeeId", Remarks, 0 AS IsInsuranceBilling, 6 as DisplaySeq 
    					from BIL_TXN_Deposit
    					WHERE (CreatedOn)::Date BETWEEN p_fromdate and p_todate	
    
    
    			) bills
    			INNER JOIN EngNepaliDateMapped nepDate on bills.BillingDate = nepDate.EngFullDate
    			,
    
    
    		EMP_Employee emp,
    		PAT_Patient pat,
    		BIL_CFG_Counter cntr
    		WHERE bills.PatientId = pat.PatientId
    				AND emp.EmployeeId = bills.EmployeeId
    				AND bills.CounterId = cntr.CounterId
    
    				AND (p_counterid is null OR p_counterid=0 OR bills.CounterId = p_counterid ) 
    				AND emp.EmployeeId = COALESCE(p_createdby, emp.EmployeeId) --updated Krishna : 18th JAN.22
    				--AND emp.FullName like '%'+COALESCE(p_createdby,emp.FullName)+'%'  -- updated sud: 16Jan'20
    		        --and (emp.firstname + coalesce(' ' + emp.middlename, '') + ' ' + emp.lastname like '%' + coalesce(p_createdby, emp.firstname + coalesce(' ' + emp.middlename, '') + ' ' + emp.lastname) + '%')
    		
           order by bills.displayseq;
        return next ref1;
    
    
        --table2: for settlement details---
       --need: collectionfromreceivable,  cashdiscount and return cash discount in given date range for given counter, user--
       --getting total(sum) for all given criterias-- no need to separate for each user/counters/dates---
    	 open ref2 for select 
    	        --below fields kept for backup---
    	       --sum(case when sett.payableamount > 0 then sett.paidamount else 0 end) as "settlpaidamount", 
    			--sum( case when sett.refundableamount > 0 then sett.returnedamount else 0 end ) as "settlreturnamount",
    			--sum( case when sett.dueamount > 0 then sett.dueamount else 0 end ) as "settldueamount",
    			--sum( case when  sett.discountamount > 0 then sett.discountamount else 0 end  ) 'SettlDiscountAmount'
    	        
    			sum(coalesce(sett.collectionfromreceivable,0)) as "collectionfromreceivables",
    			sum(coalesce(sett.discountamount,0)) as "cashdiscountgiven",
    			sum(coalesce(sett.discountreturnamount,0)) as "cashdiscountreceived"
    
    	from bil_txn_settlements sett, 
    	    emp_employee emp,
    		bil_cfg_counter cntr 
    
    	where sett.createdby=emp.employeeid
    	      and sett.counterid=cntr.counterid
    		  and (p_counterid is null or p_counterid=0 or sett.counterid = p_counterid )
    		  --and emp.fullname like '%'+coalesce(p_createdby,emp.fullname)+'%' -- updated sud: 16jan'20
    		  AND emp.EmployeeId = COALESCE(p_createdby, EmployeeId)--updated Krishna : 18th JAN.22
    		  AND (sett.CreatedOn)::Date BETWEEN (p_fromdate)::Date AND (p_todate)::Date;
        RETURN NEXT ref2; 
    
    
    	 --table:3--Gets User Collection Summary for all users in the given date range---
    	 OPEN ref3 FOR Select * from FN_BILL_GetUserCollectionSummaryInDateRange(p_fromdate,p_todate) 
    	 WHERE EmployeeId = COALESCE(p_createdby, EmployeeId);
        RETURN NEXT ref3;--updated Krishna : 18th JAN.22
    
    
    
          --Right now we only have Maternity Payment feature, 
        --need to create separate function when we have other Cash payments to patient---
        OPEN ref4 FOR SELECT  SUM(COALESCE(OutAmount,0)) - SUM(COALESCE(InAmount,0)) AS "OtherPaymentsGiven"
        FROM MAT_TXN_PatientPayments pmt inner join EMP_Employee emp on pmt.CreatedBy=emp.EmployeeId
        WHERE (pmt.CreatedOn)::DATE Between p_fromdate and p_todate
         --AND emp.FullName like '%'+COALESCE(p_createdby,emp.FullName)+'%'
    	 AND EmployeeId = COALESCE(p_createdby, EmployeeId);
        RETURN NEXT ref4;--updated Krishna : 18th JAN.22
    
    	OPEN ref5 FOR SELECT 
    			PaymentModeSubCategoryId
    			,modes.PaymentSubCategoryName
    			,SUM(COALESCE(InAmount,0)) - SUM(COALESCE(OutAmount,0)) AS "Collection"
    	FROM TXN_EmpCashTransaction cashTxn
    	INNER JOIN MST_PaymentModes modes ON cashTxn.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
    	WHERE modes.PaymentSubCategoryName != 'deposit'
    		  AND cashTxn.TransactionType != 'handovergiven'
    		  and (cashtxn.transactiondate)::date between (p_fromdate)::date and (p_todate)::date
    		  and cashtxn.employeeid = coalesce(p_createdby, cashtxn.employeeid)
    	group by cashtxn.paymentmodesubcategoryid, modes.paymentsubcategoryname
    	order by cashtxn.paymentmodesubcategoryid asc;
        return next ref5;
    
    
     end if; -- end of if
    
    end; -- end of sp
END;
$$ LANGUAGE plpgsql;