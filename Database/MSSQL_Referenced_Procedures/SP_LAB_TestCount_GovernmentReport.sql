CREATE PROCEDURE [dbo].[SP_LAB_TestCount_GovernmentReport] 
	@FromDate date = NULL,
	@ToDate date = NULL
AS
/*
-- =============================================
-- Author:    	<ANish Bhattarai>
-- Create date: <27 August 2020>
-- Description:	<Get the count of each test of Government Lab Report>
-- =============================================
Change Log:
S.N.		Name/Date							Remarks
1.			Anish/27Aug,20						initial draft		
2.			Krishna/Rusha / 08Dec,22			Add IsActive true to get data 
*/
BEGIN

  (SELECT
    masterData.SerialNumber,
    masterData.GroupName,
    masterData.TestName,
    masterData.DisplayName,
    masterData.HasInnerItems,
    masterData.InnerTestGroupName,
    COUNT(*) AS 'Total'
  FROM (SELECT
    LabItemId,
    IsComponentBased,
    PositiveIndicator,
    IsResultCount,
    SerialNumber,
    TestName,
    GroupName,
    DisplayName,
    HasInnerItems,
    InnerTestGroupName
  FROM Lab_Gov_Report_Mapping map
  JOIN Lab_Mst_Gov_Report_Items item
    ON map.ReportItemId = item.ReportItemId
  WHERE map.IsComponentBased = 0
  AND item.IsActive = 1 AND map.IsActive = 1) masterData
  JOIN LAB_TestRequisition req
    ON req.LabTestId = masterData.LabItemId
  WHERE req.IsActive = 1
  AND CONVERT(date, req.OrderDateTime) BETWEEN CONVERT(date, @FromDate) AND CONVERT(date, @ToDate)
  AND (req.BillingStatus NOT IN ('returned', 'cancel'))
  GROUP BY masterData.SerialNumber,
           masterData.TestName,
		   masterData.LabItemId,
           masterData.GroupName,
           masterData.DisplayName,
           masterData.HasInnerItems,
           masterData.InnerTestGroupName
  )
  UNION
  (SELECT
    masterData.SerialNumber,
    masterData.GroupName,
    masterData.TestName,
    masterData.DisplayName,
    masterData.HasInnerItems,
    masterData.InnerTestGroupName,
    COUNT(*) AS 'Total'
  FROM (SELECT
    LabItemId,
    IsComponentBased,
    PositiveIndicator,
    IsResultCount,
    SerialNumber,
    TestName,
    GroupName,
    DisplayName,
    HasInnerItems,
    InnerTestGroupName,
    ComponentId,
    ReportMapId,
    map.ReportItemId
  FROM Lab_Gov_Report_Mapping map
  JOIN Lab_Mst_Gov_Report_Items item
    ON map.ReportItemId = item.ReportItemId
  WHERE map.IsComponentBased = 1
  AND item.IsActive = 1 AND map.IsActive = 1
  AND map.IsResultCount = 1) masterData
  JOIN (SELECT
    res.RequisitionId,
    res.ComponentName,
    res.[Value],
    res.LabTestId,
	res.ComponentId
  FROM LAB_TXN_TestComponentResult res
  JOIN LAB_TestRequisition req
    ON res.RequisitionId = req.RequisitionId
  WHERE res.IsActive = 1 AND req.IsActive = 1
  AND CONVERT(date, req.OrderDateTime) BETWEEN CONVERT(date, @FromDate) AND CONVERT(date, @ToDate)
  AND req.BillingStatus NOT IN ('returned', 'cancel')) labData
    ON (labData.ComponentId = masterData.ComponentId AND labData.LabTestId = masterData.LabItemId)
	AND LTRIM(RTRIM((LOWER(labData.[Value])))) = LTRIM(RTRIM((LOWER(masterData.PositiveIndicator))))
  GROUP BY masterData.SerialNumber,
           masterData.TestName,
		   masterData.LabItemId,
           masterData.GroupName,
           masterData.DisplayName,
           masterData.HasInnerItems,
           masterData.InnerTestGroupName
  )
  UNION
  (SELECT
    masterData.SerialNumber,
    masterData.GroupName,
    masterData.TestName,
    masterData.DisplayName,
    masterData.HasInnerItems,
    masterData.InnerTestGroupName,
    COUNT(*) AS 'Total'
  FROM (SELECT
    LabItemId,
    IsComponentBased,
    PositiveIndicator,
    IsResultCount,
    SerialNumber,
    TestName,
    GroupName,
    DisplayName,
    HasInnerItems,
    InnerTestGroupName,
    ComponentId
  FROM Lab_Gov_Report_Mapping map
  JOIN Lab_Mst_Gov_Report_Items item
    ON map.ReportItemId = item.ReportItemId
  WHERE map.IsComponentBased = 1
  AND item.IsActive = 1 AND map.IsActive = 1
  AND map.IsResultCount = 0) masterData
  JOIN (SELECT
    res.RequisitionId,
    res.ComponentName,
    res.Value,
    res.LabTestId,
	res.ComponentId
  FROM LAB_TXN_TestComponentResult res
  JOIN LAB_TestRequisition req
    ON res.RequisitionId = req.RequisitionId
  WHERE res.IsActive = 1
  AND CONVERT(date, req.OrderDateTime) BETWEEN CONVERT(date, @FromDate) AND CONVERT(date, @ToDate)
  AND req.BillingStatus NOT IN ('returned', 'cancel')) labData
    ON labData.ComponentId = masterData.ComponentId
  GROUP BY masterData.SerialNumber,
           masterData.TestName,
		   masterData.LabItemId,
           masterData.GroupName,
           masterData.DisplayName,
           masterData.HasInnerItems,
           masterData.InnerTestGroupName
  )
END