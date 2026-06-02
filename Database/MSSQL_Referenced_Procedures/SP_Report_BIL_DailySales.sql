CREATE PROCEDURE [dbo].[SP_Report_BIL_DailySales] --- [SP_Report_BIL_DailySales] '2018-11-29','2018-11-29',null,null,1
		@FromDate Datetime=null ,
		@ToDate DateTime=null,
		@CounterId varchar(max)=null,
		@CreatedBy int = null,
		@IsInsurance bit=0
AS
/*
FileName: [sp_Report_BIL_DailySales]
CreatedBy/date: sud/2018-07-27
Description: To Get Sales + Cash Collection details from Invoice and Deposits table between given range. 
Remarks: 
    * Deposits are returned as it is for IsInsurance=1 as well since it's independent of sales
	* We're Returning 4 tables from this Stored Procedure.
	   1. Sales+Sales Return Details
	   2. Settlement Summary only
	   3. Summary of User Collection which has Cash impact in it.
	   4. Summary of Other Payments (eg: Maternity for LPH)
	   5. Collection Segregation as per Payment Methods. (eg: Cash: 5000, Cheque: 4000, e-sewa: 3000, etc...)

Change History
S.No.    UpdatedBy/Date                        Remarks
4.      Sud/15Feb'19                           Format Revised, getting sales summary from a function and then union with Deposit transactions.
5.      Sud/7Aug'19                            Added Filter for IsInsurance
6.      Sud/16Jan'20                           Changed for UserName filter not working because of Salutation
7.      Sud/1-Oct'21                           Changed for CounterName and CounterId comparison.
8.      Sud/23Nov'21                           Settlement Scenarios Revised. (JiraId: EMR-4496)
9.      Sud/25Nov'21                           For Maternity> Payment Handling in User collection report.
10.     Sud/29Nov'21                           BugFix> Maternity payment: User Filter was not handled earlier in Detailed View
11.		Krishna/18thJan'22					   changed the filter of this report from username to its ID (@createdBy varchar to int)
12.		Krishna/21stFeb'22					   Added table 5 to get the collection segregation..
13.		Krishna/5thMay'23					   Change DepositType to TransactionType and Amount to InAmount and OutAmount
14.     Sud:26Jun'23                           Added NepMonthName and EngMonthName in Select List of first table
*/
BEGIN

 IF (@FromDate IS NOT NULL)
  OR (@ToDate IS NOT NULL)
BEGIN
	
	 --Table:1 - For Usercollection Details---
	 --Return Columns: BillingDate, ReceiptNo, HospitalNo, patientName, BillingType, SubTotal, DiscountAmount, 
	 --TaxTotal, TotalAmount, CashCollection, DepositReceived, DepositRefund, CreditReceived,CreditAmount, CounterId, EmployeeId, Remarks, User (CreatedBy)

   SELECT
			bills.BillingDate,
			nepDate.NepMonthName,
			nepDate.EngMonthShortName 'EngMonthName',
			bills.InvoiceNo 'ReceiptNo',
			pat.PatientCode 'HospitalNo',
			pat.ShortName AS PatientName,
			bills.BillingType 'BillingType',
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
			bills.[EmployeeId],
			bills.Remarks,
			emp.FullName AS CreatedBy
		

		FROM (
					Select * from FN_BILL_BillingTxnSegregation_ByBillingType_DailySales(@FromDate,@ToDate)
					WHERE ISNULL(IsInsuranceBilling,0) = @IsInsurance
	    
					UNION ALL

					--All Deposits Transactions---
					Select   Convert(Date,CreatedOn) 'BillingDate', 
							 'DR'+Convert(varchar(20),ISNULL(ReceiptNo,'')) 'InvoiceNo', 
							 Patientid,
							 CASE WHEN TransactionType='Deposit' THEN 'AdvanceReceived' 
								WHEN TransactionType='depositdeduct' OR TransactionType='ReturnDeposit' THEN 'AdvanceSettled' END AS 'BillingType',
			
							 0 As SubTotal,0 AS DiscountAmount,0 AS TaxTotal, 0 AS TotalAmount, 
							 CASE WHEN TransactionType='Deposit' THEN InAmount WHEN TransactionType='depositdeduct' OR TransactionType='ReturnDeposit' THEN (-OutAmount) END AS 'CashCollection',
							  CASE WHEN TransactionType='Deposit' THEN InAmount ELSE 0 END AS 'DepositReceived',
							CASE WHEN  TransactionType='depositdeduct' OR TransactionType='ReturnDeposit' THEN OutAmount ELSE 0 END AS 'DepositRefund'
						   
							 , 0 AS CreditReceived,  0 AS 'CreditAmount',
							 CounterId 'CounterId', CreatedBy 'EmployeeId', Remarks, 0 AS IsInsuranceBilling, 6 as DisplaySeq 
					from BIL_TXN_Deposit
					WHERE COnvert(Date,CreatedOn) BETWEEN @FromDate and @ToDate	


			) bills
			INNER JOIN EngNepaliDateMapped nepDate on bills.BillingDate = nepDate.EngFullDate
			,


		EMP_Employee emp,
		PAT_Patient pat,
		BIL_CFG_Counter cntr
		WHERE bills.PatientId = pat.PatientId
				AND emp.EmployeeId = bills.EmployeeId
				AND bills.CounterId = cntr.CounterId

				AND (@CounterId is null OR @CounterId=0 OR bills.CounterId = @CounterId ) 
				AND emp.EmployeeId = ISNULL(@CreatedBy, emp.EmployeeId) --updated Krishna : 18th JAN.22
				--AND emp.FullName like '%'+ISNULL(@CreatedBy,emp.FullName)+'%'  -- updated sud: 16Jan'20
		        --AND (emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName LIKE '%' + ISNULL(@CreatedBy, emp.FirstName + ISNULL(' ' + emp.MiddleName, '') + ' ' + emp.LastName) + '%')
		
       Order by bills.DisplaySeq


    --Table2: For Settlement Details---
   --Need: CollectionFromReceivable,  CashDiscount and Return Cash Discount in given date range for given counter, user--
   --Getting Total(SUM) for all given criterias-- no need to separate for each user/counters/dates---
	 Select 
	        --below fields kept for backup---
	       --SUM(Case When sett.PayableAmount > 0 then sett.PaidAmount ELSE 0 END) AS 'SettlPaidAmount', 
			--SUM( Case WHEN sett.RefundableAmount > 0 THEN sett.ReturnedAmount ELSE 0 END ) AS 'SettlReturnAmount',
			--SUM( Case WHEN sett.DueAmount > 0 THEN sett.DueAmount ELSE 0 END ) AS 'SettlDueAmount',
			--SUM( Case WHEN  sett.DiscountAmount > 0 THEN sett.DiscountAmount ELSE 0 END  ) 'SettlDiscountAmount'
	        
			Sum(Isnull(sett.CollectionFromReceivable,0)) 'CollectionFromReceivables',
			Sum(Isnull(sett.DiscountAmount,0)) 'CashDiscountGiven',
			Sum(Isnull(sett.DiscountReturnAmount,0)) 'CashDiscountReceived'

	from BIL_TXN_Settlements sett, 
	    EMP_Employee emp,
		BIL_CFG_Counter cntr 

	WHERE sett.CreatedBy=emp.EmployeeId
	      AND sett.CounterId=cntr.CounterId
		  AND (@CounterId is null OR @CounterId=0 OR sett.CounterId = @CounterId )
		  --AND emp.FullName like '%'+ISNULL(@CreatedBy,emp.FullName)+'%' -- updated sud: 16Jan'20
		  AND emp.EmployeeId = ISNULL(@CreatedBy, EmployeeId)--updated Krishna : 18th JAN.22
		  AND Convert(Date,sett.CreatedOn) BETWEEN Convert(Date, @FromDate) AND Convert(Date, @ToDate) 


	 --table:3--Gets User Collection Summary for all users in the given date range---
	 Select * from FN_BILL_GetUserCollectionSummaryInDateRange(@FromDate,@ToDate) 
	 WHERE EmployeeId = ISNULL(@CreatedBy, EmployeeId)--updated Krishna : 18th JAN.22



      --Right now we only have Maternity Payment feature, 
    --need to create separate function when we have other Cash payments to patient---
    SELECT  SUM(ISNULL(OutAmount,0)) - SUM(ISNULL(InAmount,0)) 'OtherPaymentsGiven'
    FROM MAT_TXN_PatientPayments pmt inner join EMP_Employee emp on pmt.CreatedBy=emp.EmployeeId
    WHERE Convert(DATE,pmt.CreatedOn) Between @FromDate and @ToDate
     --AND emp.FullName like '%'+ISNULL(@CreatedBy,emp.FullName)+'%'
	 AND EmployeeId = ISNULL(@CreatedBy, EmployeeId)--updated Krishna : 18th JAN.22

	SELECT 
			PaymentModeSubCategoryId
			,modes.PaymentSubCategoryName
			,SUM(ISNULL(InAmount,0)) - SUM(ISNULL(OutAmount,0)) 'Collection'
	FROM TXN_EmpCashTransaction cashTxn
	INNER JOIN MST_PaymentModes modes ON cashTxn.PaymentModeSubCategoryId = modes.PaymentSubCategoryId
	WHERE modes.PaymentSubCategoryName != 'Deposit'
		  AND cashTxn.TransactionType != 'HandoverGiven'
		  AND CONVERT(DATE,cashTxn.TransactionDate) BETWEEN Convert(Date, @FromDate) AND Convert(Date, @ToDate)
		  AND cashTxn.EmployeeId = ISNULL(@CreatedBy, cashTxn.EmployeeId)
	GROUP BY cashTxn.PaymentModeSubCategoryId, modes.PaymentSubCategoryName
	ORDER BY cashTxn.PaymentModeSubCategoryId ASC


 END -- end of IF

END -- end of SP