--Pratik: Start: 2020-07-30: --> Cancel Bill Reports updated

CREATE PROCEDURE [dbo].[SP_Report_BILL_BillCancelReport] --EXEC SP_Report_BILL_BillCancelReport '2020-06-30','2020-07-30'
@FromDate DateTime=null,
@ToDate DateTime=null
AS
/*
FileName: [[SP_Report_BILL_BillCancelReport]]
CreatedBy/date: Umed/20-07-2017
Description: to get Sum of Total Amount of Cancel Bill of each patient Between Given Dates 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/20-07-2017	                   created the script
2       Umed/31-07-2017                    alter the script added cancel remarks and User
3       pratik/2020-07-30                  Added ItemName,ServiceDepartmentName etc col
*/
BEGIN
    
SELECT  pat.PatientCode AS HospitalNo,
		 pat.ShortName as 'PatientName',
		 bltxnItm.ServiceDepartmentName as 'ServiceDepartmentName',
		 bltxnItm.ItemName as 'ItemName',
		 bltxnItm.Quantity as 'Quantity',
		 ISNULL(bltxnItm.TotalAmount,0) AS TotalAmount,
		 bltxnItm.CreatedOn 'CreatedOn' ,
		 emp.FullName as 'CreatedBy',
		 bltxnItm.CancelledOn 'CancelledOn',
		 empCancel.FullName as 'CancelledBy',
		 bltxnItm.CancelRemarks AS CancelRemarks

FROM BIL_TXN_BillingTransactionItems bltxnItm
INNER JOIN PAT_Patient pat ON pat.PatientId = bltxnItm.PatientId
inner join EMP_Employee emp on emp.EmployeeId = bltxnItm.CreatedBy
inner join EMP_Employee empCancel on empCancel.EmployeeId = bltxnItm.CancelledBy
WHERE  
 CONVERT(date,bltxnItm.CancelledOn) BETWEEN ISNULL(@FromDate,GETDATE()) and ISNULL(@ToDate,GETDATE())
	  and bltxnItm.BillStatus='cancel'
	  and bltxnItm.CancelledOn is not null
order by bltxnItm.CancelledOn desc
END