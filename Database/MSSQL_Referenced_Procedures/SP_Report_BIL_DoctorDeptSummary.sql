--Altering  SP_Report_BIL_DoctorDeptSummary SP
--Changed ProviderId to PerformerId and ProviderName to PerformerName
CREATE PROCEDURE [dbo].[SP_Report_BIL_DoctorDeptSummary] --SP_Report_BIL_DoctorDeptSummary '2018-07-01', '2018-11-22'  
  @FromDate DATETIME = NULL,  
  @ToDate DATETIME = NULL,  
  @DoctorId INT = NULL  
AS  
/*  
Change History  
S.No.    UpdatedBy/Date          Remarks  
1    Sud/02Sept'18           Initial Draft  
2  Ramavtar/30Nov'18   summary added   
3  Ramavtar/17Dec'18   change in where condition (checking for credit records)  
4    sud: 21Feb'19           Updated as per new function  
5    sud:13Mar'19            Join with FN_BIL_GetSrvDeptReportingName_DoctorSummary to get actual service department name,   
                             since it's now removed from  FN_BILL_Get_BillingTxnItemSeggregation_ByBillingType_NoProvisional  
6.	Krishna/8thJun'22		Changed ProviderId to PerformerId and ProviderName to PerformerName
7.	Krishna/10thAUG'22		Changed SP as per Performer,Prescriber and Referrer
*/  
BEGIN  
  
  
SELECT tbl1.Doctor
	,tbl1.DepartmentName
	,tbl1.ServiceDepartmentName
	,tbl1.ServiceDepartmentId
	,SUM(ISNULL(tbl1.PerformerNetAmount, 0)) 'NetAmount_Performer'
	,SUM(ISNULL(tbl1.PrescriberNetAmount, 0)) 'NetAmount_Prescriber'
	,SUM(ISNULL(tbl1.ReferrerNetAmount, 0)) 'NetAmount_Referrer'
FROM (
	SELECT tbl.Doctor
		,tbl.DepartmentName
		,tbl.ServiceDepartmentName
		,tbl.ServiceDepartmentId
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
			ISNULL(emp.FullName,'Unassigned') 'Doctor',
			billingData.ServiceDepartmentId,
			billingData.ServiceDepartmentName,
			billingData.DepartmentName,
			'Performer' AS DoctorType,
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
			,invItm.ServiceDepartmentId
			,invItm.ServiceDepartmentName
			,invItm.DepartmentName
			from 
			( Select itm.BillingTransactionItemId, PerformerId
				, itm.TotalAmount 'SalesAmount',
				serv.ServiceDepartmentId,serv.ServiceDepartmentName, dep.DepartmentName
				from BIL_TXN_BillingTransactionItems itm
				INNER JOIN BIL_TXN_BillingTransaction txn on itm.BillingTransactionId=txn.BillingTransactionId
				INNER JOIN BIL_MST_ServiceDepartment serv on serv.ServiceDepartmentId = itm.ServiceDepartmentId
				INNER JOIN MST_Department dep on dep.DepartmentId = serv.DepartmentId
				Where   Convert(Date,txn.CreatedOn) between @FromDate and @ToDate
				AND ISNULL(itm.PerformerId,0) = ISNULL(@DoctorId,0)
   
				) invItm 
			FULL OUTER JOIN 
				( Select rti.BillingTransactionItemId, sum(RettotalAmount) 'ReturnAmount' 
				, itm.PerformerId
				from BIL_TXN_InvoiceReturnItems rti inner join BIL_TXN_BillingTransactionItems itm
					on rti.BillingTransactionItemId=itm.BillingTransactionItemId
					INNER JOIN BIL_TXN_InvoiceReturn ret on rti.BillReturnId=ret.BillReturnId
				Where Convert(Date,ret.CreatedOn) between @FromDate and @ToDate
				AND ISNULL(itm.PerformerId,0) = ISNULL(@DoctorId,0)
				Group by rti.BillingTransactionItemId, itm.PerformerId
			) retItm
			on invItm.BillingTransactionItemId=retItm.BillingTransactionItemId
		) billingData
		LEFT JOIN EMP_Employee emp on billingData.PerformerId=emp.EmployeeId
		Group by ISNULL(emp.FullName,'Unassigned'), billingData.PerformerId, billingData.ServiceDepartmentId,billingData.ServiceDepartmentName, billingData.DepartmentName

		
		UNION ALL
		(
	
	Select 
			ISNULL(emp.FullName,'Unassigned') 'Doctor',
			billingData.ServiceDepartmentId,
			billingData.ServiceDepartmentName,
			billingData.DepartmentName,
			'Prescriber' AS DoctorType,
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
			,invItm.ServiceDepartmentId
			,invItm.ServiceDepartmentName
			,invItm.DepartmentName
			from 
			( Select itm.BillingTransactionItemId, PrescriberId
				, itm.TotalAmount 'SalesAmount',
				serv.ServiceDepartmentId,serv.ServiceDepartmentName, dep.DepartmentName
				from BIL_TXN_BillingTransactionItems itm
				INNER JOIN BIL_TXN_BillingTransaction txn on itm.BillingTransactionId=txn.BillingTransactionId
				INNER JOIN BIL_MST_ServiceDepartment serv on serv.ServiceDepartmentId = itm.ServiceDepartmentId
				INNER JOIN MST_Department dep on dep.DepartmentId = serv.DepartmentId
				Where   Convert(Date,txn.CreatedOn) between @FromDate and @ToDate
				AND ISNULL(itm.PrescriberId,0) = ISNULL(@DoctorId,0)
   
				) invItm 
			FULL OUTER JOIN 
				( Select rti.BillingTransactionItemId, sum(RettotalAmount) 'ReturnAmount' 
				, itm.PrescriberId
				from BIL_TXN_InvoiceReturnItems rti inner join BIL_TXN_BillingTransactionItems itm
					on rti.BillingTransactionItemId=itm.BillingTransactionItemId
					INNER JOIN BIL_TXN_InvoiceReturn ret on rti.BillReturnId=ret.BillReturnId
				Where Convert(Date,ret.CreatedOn) between @FromDate and @ToDate
				AND ISNULL(itm.PrescriberId,0) = ISNULL(@DoctorId,0)
				Group by rti.BillingTransactionItemId, itm.PrescriberId
			) retItm
			on invItm.BillingTransactionItemId=retItm.BillingTransactionItemId
		) billingData
		LEFT JOIN EMP_Employee emp on billingData.PrescriberId=emp.EmployeeId
		Group by ISNULL(emp.FullName,'Unassigned'), billingData.PrescriberId, billingData.ServiceDepartmentId,billingData.ServiceDepartmentName, billingData.DepartmentName
			)
		
		UNION ALL
		
		(
	
	Select 
			ISNULL(emp.FullName,'Unassigned') 'Doctor',
			billingData.ServiceDepartmentId,
			billingData.ServiceDepartmentName,
			billingData.DepartmentName,
			'Referrer' AS DoctorType,
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
			,invItm.ServiceDepartmentId
			,invItm.ServiceDepartmentName
			,invItm.DepartmentName
			from 
			( Select itm.BillingTransactionItemId, ReferredById
				, itm.TotalAmount 'SalesAmount',
				serv.ServiceDepartmentId,serv.ServiceDepartmentName, dep.DepartmentName
				from BIL_TXN_BillingTransactionItems itm
				INNER JOIN BIL_TXN_BillingTransaction txn on itm.BillingTransactionId=txn.BillingTransactionId
				INNER JOIN BIL_MST_ServiceDepartment serv on serv.ServiceDepartmentId = itm.ServiceDepartmentId
				INNER JOIN MST_Department dep on dep.DepartmentId = serv.DepartmentId
				Where   Convert(Date,txn.CreatedOn) between @FromDate and @ToDate
				AND ISNULL(itm.ReferredById,0) = ISNULL(@DoctorId,0)
   
				) invItm 
			FULL OUTER JOIN 
				( Select rti.BillingTransactionItemId, sum(RettotalAmount) 'ReturnAmount' 
				, itm.ReferredById
				from BIL_TXN_InvoiceReturnItems rti inner join BIL_TXN_BillingTransactionItems itm
					on rti.BillingTransactionItemId=itm.BillingTransactionItemId
					INNER JOIN BIL_TXN_InvoiceReturn ret on rti.BillReturnId=ret.BillReturnId
				Where Convert(Date,ret.CreatedOn) between @FromDate and @ToDate
				AND ISNULL(itm.ReferredById,0) = ISNULL(@DoctorId,0)
				Group by rti.BillingTransactionItemId, itm.ReferredById
			) retItm
			on invItm.BillingTransactionItemId=retItm.BillingTransactionItemId
		) billingData
		LEFT JOIN EMP_Employee emp on billingData.ReferredById=emp.EmployeeId
		Group by ISNULL(emp.FullName,'Unassigned'), billingData.ReferredById, billingData.ServiceDepartmentId,billingData.ServiceDepartmentName, billingData.DepartmentName
			)
		) tbl
	GROUP BY tbl.DepartmentName,tbl.ServiceDepartmentId
		,tbl.ServiceDepartmentName
		,tbl.Doctor
		,tbl.DoctorType
	) tbl1
GROUP BY tbl1.DepartmentName,tbl1.ServiceDepartmentId
	,tbl1.ServiceDepartmentName
	,tbl1.Doctor
ORDER BY tbl1.Doctor
   
END