CREATE PROCEDURE [dbo].[SP_ACC_GetIncomeLedgerMappingDetail]
AS
/*
 exec SP_ACC_GetIncomeLedgerMappingDetail

 Change History
SN.                Auther/DateTime                   Description
1.                 DevN/11th June 23                Initial Draft of SP to get IncomeLedger Mapping Detail.
*/
BEGIN
	SELECT 
		ISNULL(ledger.LedgerId,0) AS LedgerId
		,ISNULL(ledger.LedgerGroupId,0) AS LedgerGroupId
		,ISNULL(ledger.LedgerName, '') AS LedgerName
		,ISNULL(map.IsActive,0) AS IsActive
		,ISNULL(ledger.Name,'') AS Name
		,'billingincomeledger' AS LedgerType
		,ledger.Code AS LedgerCode
		,ISNULL(subLedger.SubLedgerId,0 ) AS SubLedgerId
		,ISNULL(subLedger.SubLedgerName,'') AS SubLedgerName
		,ISNULL(map.BillLedgerMappingId,0) AS BillLedgerMappingId
		,CASE 
			WHEN ledger.LedgerId > 0
				THEN 1
			ELSE 0
			END AS IsMapped
		,itemDetail.*
		,billingType.value AS BillingType
	FROM (
		SELECT servDept.ServiceDepartmentId
			,servDept.ServiceDepartmentName
			,item.ServiceItemId AS ItemId
			,item.ItemName
			,item.ItemCode
		FROM BIL_MST_ServiceDepartment servDept
		LEFT JOIN BIL_MST_ServiceItem item ON servDept.ServiceDepartmentId = item.ServiceDepartmentId
		WHERE item.ServiceItemId > 0 AND item.IsActive = 1
		) AS itemDetail
	CROSS JOIN (
		SELECT value
		FROM STRING_SPLIT('outpatient,inpatient', ',')
		) AS billingType
	LEFT JOIN ACC_Bill_LedgerMapping map ON itemDetail.ServiceDepartmentId = map.ServiceDepartmentId AND itemDetail.ItemId = map.ItemId AND billingType.value = map.BillingType
	LEFT JOIN ACC_Ledger ledger ON map.LedgerId = ledger.LedgerId
	LEFT JOIN ACC_MST_SubLedger subLedger ON map.SubLedgerId = subLedger.SubLedgerId
	ORDER BY itemDetail.ItemName
END