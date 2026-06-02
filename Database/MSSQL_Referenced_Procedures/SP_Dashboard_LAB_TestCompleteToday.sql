CREATE PROCEDURE [dbo].[SP_Dashboard_LAB_TestCompleteToday]
AS
BEGIN
/************************************************************************
FileName: [SP_Dashboard_LAB_TrendingLabTest]   
CreatedBy/date: Prem: 3rd Jan,2023
Description: To get details of  Test Completed for Dashboard
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Prem						Initial Daft
*************************************************************************/
	SELECT labRpt.ReportTemplateShortName,
			COUNT(RequisitionId) AS TestCount 
	FROM LAB_TestRequisition labReq 
			 JOIN Lab_ReportTemplate labRpt ON labReq.ReportTemplateId = labRpt.ReportTemplateID				
	WHERE labReq.IsActive=1 AND (OrderStatus='result-added' OR OrderStatus='report-generated') 
	AND (BillingStatus='unpaid' OR	BillingStatus='paid')
	AND ResultAddedOn BETWEEN(CONVERT(date, GETDATE())) and CONVERT(date, DATEADD(DAY, 1, GETDATE()))
	GROUP BY labRpt.ReportTemplateShortName 
END