--Altering SP_Report_BIL_DoctorSummary SP
--changed ProviderId to PerformerId and ProviderName to PerformerName
-- =============================================  
-- Author/Date:  Sud/02Sept'18  
-- Description:  to show doctor summary  
-- Remarks:   
-- =============================================  
CREATE PROCEDURE [dbo].[SP_Report_BIL_DoctorSummary]  
 @FromDate DATETIME = NULL,  
 @ToDate DATETIME = NULL  
AS  
/*  
Change History  
S.No.    UpdatedBy/Date     Remarks  
1.  Sud/02Sept'18        Initial Draft  
2.  Ramavtar/12Nov'18    sorting by doctorname  
3.     Ramavtar/30Nov'18    summary added  
4.  Ramavtar/17Dec'18   change in where condition (checking for credit records)  
5.      Sud/21Feb'19                Changed as per new function <needs revision>  
6.      Dinesh/8Dec'20              Handling of SettlementDiscount Amount (Need Revision)  
7.      Dev/24th_Jan'22         Change NoDoctor to Unassgined in case no doctor is selected  
8.	Krishna,9thJun'22			changed ProviderId to PerformerId and ProviderName to PerformerName
9.	Krishna, 10thAUG'22			SP completely changed according to Performer, Prescriber and Referrer
*/  
BEGIN  
    
SELECT tbl1.Doctor,
	tbl1.DoctorId
	,SUM(ISNULL(tbl1.PerformerNetAmount, 0)) 'NetAmount_Performer'
	,SUM(ISNULL(tbl1.PrescriberNetAmount, 0)) 'NetAmount_Prescriber'
	,SUM(ISNULL(tbl1.ReferrerNetAmount, 0)) 'NetAmount_Referrer'
FROM (
	SELECT tbl.Doctor,
	tbl.DoctorId
		,CASE 
			WHEN DoctorType = 'Performer'
				THEN SUM(ISNULL(NetAmount, 0))
			END AS 'PerformerNetAmount'
		,CASE 
			WHEN DoctorType = 'Prescriber'
				THEN SUM(ISNULL(NetAmount, 0))
			END AS 'PrescriberNetAmount'
		,CASE 
			WHEN DoctorType = 'Referrer'
				THEN SUM(ISNULL(NetAmount, 0))
			END AS 'ReferrerNetAmount'
	FROM (
	

	Select 
			'Performer' AS DoctorType,
			ISNULL(emp.FullName,'Unassigned') 'Doctor',
			ISNULL(billingData.PerformerId,0) 'DoctorId',
			SUM(billingData.SalesAmount) 'SalesAmt',
			SUM(billingData.ReturnAmount) 'RetAmount',
			SUM(billingData.NetAmount) 'NetAmount'

		from
		(

			Select ISNULL(invItm.PerformerId,retItm.PerformerId) 'PerformerId'
			, ISNULL(invItm.SalesAmount,0) 'SalesAmount'
			, ISNULL(retItm.ReturnAmount,0) 'ReturnAmount'
			, ISNULL(invItm.SalesAmount,0) - ISNULL(retItm.ReturnAmount,0) AS 'NetAmount'
			from 
			( Select itm.BillingTransactionItemId, PerformerId
				, itm.TotalAmount 'SalesAmount'
				from BIL_TXN_BillingTransactionItems itm
				INNER JOIN BIL_TXN_BillingTransaction txn on itm.BillingTransactionId=txn.BillingTransactionId
				Where   Convert(Date,txn.CreatedOn) between @FromDate and @ToDate
   
				) invItm 
			FULL OUTER JOIN 
				( Select rti.BillingTransactionItemId, sum(RettotalAmount) 'ReturnAmount' 
				, itm.PerformerId
				from BIL_TXN_InvoiceReturnItems rti inner join BIL_TXN_BillingTransactionItems itm
					on rti.BillingTransactionItemId=itm.BillingTransactionItemId
					INNER JOIN BIL_TXN_InvoiceReturn ret on rti.BillReturnId=ret.BillReturnId
				Where Convert(Date,ret.CreatedOn) between @FromDate and @ToDate
				Group by rti.BillingTransactionItemId, itm.PerformerId
			) retItm
			on invItm.BillingTransactionItemId=retItm.BillingTransactionItemId
		) billingData
		LEFT JOIN EMP_Employee emp on billingData.PerformerId=emp.EmployeeId

		Group by ISNULL(emp.FullName,'Unassigned'), billingData.PerformerId


		
		UNION ALL
		(
			Select 
				 'Prescriber' AS DoctorType,
				 ISNULL(emp.FullName,'Unassigned') 'Doctor',
				 ISNULL(billingData.PrescriberId,0) 'DoctorId',
				 SUM(billingData.SalesAmount) 'SalesAmt',
				 SUM(billingData.ReturnAmount) 'RetAmount',
				 SUM(billingData.NetAmount) 'NetAmount'

				from
				(

					Select ISNULL(invItm.PrescriberId,retItm.PrescriberId) 'PrescriberId'
					, ISNULL(invItm.SalesAmount,0) 'SalesAmount'
					, ISNULL(retItm.ReturnAmount,0) 'ReturnAmount'
					, ISNULL(invItm.SalesAmount,0) - ISNULL(retItm.ReturnAmount,0) AS 'NetAmount'
					from 
					( Select itm.BillingTransactionItemId, PrescriberId
					  , itm.TotalAmount 'SalesAmount'
					  from BIL_TXN_BillingTransactionItems itm
					   INNER JOIN BIL_TXN_BillingTransaction txn on itm.BillingTransactionId=txn.BillingTransactionId
					  Where   Convert(Date,txn.CreatedOn) between @FromDate and @ToDate
   
					  ) invItm 
					FULL OUTER JOIN 
					   ( Select rti.BillingTransactionItemId, sum(RettotalAmount) 'ReturnAmount' 
						, itm.PrescriberId
						from BIL_TXN_InvoiceReturnItems rti inner join BIL_TXN_BillingTransactionItems itm
							on rti.BillingTransactionItemId=itm.BillingTransactionItemId
						  INNER JOIN BIL_TXN_InvoiceReturn ret on rti.BillReturnId=ret.BillReturnId
						Where Convert(Date,ret.CreatedOn) between @FromDate and @ToDate
						Group by rti.BillingTransactionItemId, itm.PrescriberId
					) retItm
					on invItm.BillingTransactionItemId=retItm.BillingTransactionItemId
				) billingData
				LEFT JOIN EMP_Employee emp on billingData.PrescriberId=emp.EmployeeId

				Group by ISNULL(emp.FullName,'Unassigned'), billingData.PrescriberId

			)---end of Prescriber section
		
		UNION ALL
		
		(
		 Select 
				'Referrer' AS DoctorType,
				ISNULL(emp.FullName,'Unassigned') 'Doctor',
				ISNULL(billingData.ReferredById,0) 'DoctorId',
				SUM(billingData.SalesAmount) 'SalesAmt',
				SUM(billingData.ReturnAmount) 'RetAmount',
				SUM(billingData.NetAmount) 'NetAmount'

			from
			(

				Select ISNULL(invItm.ReferredById,retItm.ReferredById) 'ReferredById'
				, ISNULL(invItm.SalesAmount,0) 'SalesAmount'
				, ISNULL(retItm.ReturnAmount,0) 'ReturnAmount'
				, ISNULL(invItm.SalesAmount,0) - ISNULL(retItm.ReturnAmount,0) AS 'NetAmount'
				from 
				( Select itm.BillingTransactionItemId, ReferredById
					, itm.TotalAmount 'SalesAmount'
					from BIL_TXN_BillingTransactionItems itm
					INNER JOIN BIL_TXN_BillingTransaction txn on itm.BillingTransactionId=txn.BillingTransactionId
					Where   Convert(Date,txn.CreatedOn) between @FromDate and @ToDate
   
					) invItm 
				FULL OUTER JOIN 
					( Select rti.BillingTransactionItemId, sum(RettotalAmount) 'ReturnAmount' 
					, itm.ReferredById
					from BIL_TXN_InvoiceReturnItems rti inner join BIL_TXN_BillingTransactionItems itm
						on rti.BillingTransactionItemId=itm.BillingTransactionItemId
						INNER JOIN BIL_TXN_InvoiceReturn ret on rti.BillReturnId=ret.BillReturnId
					Where Convert(Date,ret.CreatedOn) between @FromDate and @ToDate
					Group by rti.BillingTransactionItemId, itm.ReferredById
				) retItm
				on invItm.BillingTransactionItemId=retItm.BillingTransactionItemId
			) billingData
			LEFT JOIN EMP_Employee emp on billingData.ReferredById=emp.EmployeeId

			Group by ISNULL(emp.FullName,'Unassigned'), billingData.ReferredById


			)


		) tbl
	GROUP BY tbl.DoctorId,tbl.Doctor,tbl.DoctorType

	) tbl1
GROUP BY tbl1.Doctor, tbl1.DoctorId
ORDER BY tbl1.Doctor
END