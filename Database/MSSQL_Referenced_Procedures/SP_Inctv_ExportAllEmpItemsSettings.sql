CREATE PROCEDURE [dbo].[SP_Inctv_ExportAllEmpItemsSettings]  
AS
/*
 FileName: [SP_Inctv_ExportAllEmpItemsSettings] 
 Created: 16th Dec 2020/Pratik
 Description: To export all Data from incentive setting (i.e. EmployeeItemsSetup page)
 Remarks: 
 Change History
 S.No.    Date/User               Change          Remarks
 1.		Pratik:16th Dec 2020					inital draft
 2.		Krishna,2Jun'22				alter		changed AssignedToPercent to PerformerPercent and ReferredByPercent to PrescriberPercent	
*/
BEGIN	   
SELECT 
emp.EmployeeId,emp.FullName AS EmployeeName ,
inctvInfo.TDSPercent,
billItmPrice.ServiceDepartmentId,
servDeprt.ServiceDepartmentName,
billItmPrice.ItemId,
billItmPrice.ItemName,
empbillitmMap.PerformerPercent,
empbillitmMap.PrescriberPercent,
--empbillitmMap.HasGroupDistribution,
CASE
    WHEN empbillitmMap.HasGroupDistribution =1 THEN 'Yes'
    ELSE 'No'
END AS HasGroupDistribution,

groupDist.DistributionInfo
from INCTV_EmployeeIncentiveInfo inctvInfo
     join EMP_Employee emp  
        on inctvInfo.EmployeeId=emp.EmployeeId 

left join INCTV_MAP_EmployeeBillItemsMap empbillitmMap
     on inctvInfo.EmployeeId=empbillitmMap.EmployeeId 

join BIL_CFG_BillItemPrice billItmPrice
    on billItmPrice.BillItemPriceId=empbillitmMap.BillItemPriceId  
	
join BIL_MST_ServiceDepartment servDeprt
    on billItmPrice.ServiceDepartmentId=servDeprt.ServiceDepartmentId  and servDeprt.IsActive=1

left join (
		SELECT x.EmployeeBillItemsMapId, DistributionInfo = STUFF((
				SELECT N', ' + emp1.FullName+': ' +Convert(varchar(20),dist1.DistributionPercent)+'%'
				FROM INCTV_CFG_ItemGroupDistribution dist1 inner join EMP_Employee emp1
					  on dist1.DistributeToEmployeeId = emp1.EmployeeId and dist1.IsActive=1
				WHERE EmployeeBillItemsMapId = x.EmployeeBillItemsMapId
				FOR XML PATH(''), TYPE).value(N'.[1]', N'nvarchar(max)'), 1, 2, N'')

			  FROM INCTV_MAP_EmployeeBillItemsMap AS x
			  where Isnull(x.HasGroupDistribution,0)=1
			  GROUP BY x.EmployeeBillItemsMapId

	  )groupDist

   on empbillitmMap.EmployeeBillItemsMapId = groupDist.EmployeeBillItemsMapId 
   where empbillitmMap.IsActive=1 and inctvInfo.IsActive=1
order by emp.FirstName, emp.LastName , ServiceDepartmentName, ItemName

END