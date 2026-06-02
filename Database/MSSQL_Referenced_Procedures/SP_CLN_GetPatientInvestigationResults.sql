CREATE PROCEDURE [dbo].[SP_CLN_GetPatientInvestigationResults] 
@FromDate DATE=NULL ,
@ToDate DATE= NULL,
@PatientId INT= NULL,
@PatientVisitId INT = NULL
AS
/*
FileName: [SP_PatVisit_GetPatientInvestigationResults]
CreatedBy/date: SANTOSH/01Aug'23
Description: To get Patient's Investigation Results of Current Visit
Remarks:  
NOTE:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1        SANTOSH/301Aug'23					   Created
*/
BEGIN

    SELECT test.LabTestName AS Test, comp.ComponentName, comp.Unit, result.Value , CONVERT(DATE, result.CreatedOn) AS [ResultDate]
    FROM LAB_LabTests test
    INNER JOIN LAB_TXN_TestComponentResult result ON test.LabTestId = result.LabTestId
	INNER JOIN LAB_TestRequisition labReq ON result.RequisitionId = labReq.RequisitionId
	INNER JOIN Lab_MST_Components comp ON result.ComponentId= comp.ComponentId
	WHERE CONVERT(DATE,result.CreatedOn) BETWEEN CONVERT(DATE, @FromDate) AND CONVERT(DATE, @ToDate) AND  labReq.PatientId = @PatientId AND labReq.PatientVisitId = @PatientVisitId 
	AND comp.ControlType <> 'Label'
    GROUP BY test.LabTestName,comp.ComponentName,comp.Unit, result.VALUE, CONVERT(DATE, result.CreatedOn)

    UNION ALL

	SELECT imgrep.ImagingTypeName AS Test, '' AS ComponentName, '' AS Unit,'YES' AS Value, CONVERT(DATE, CreatedOn) AS [ResultDate]
    FROM RAD_PatientImagingReport imgrep  Where imgrep.OrderStatus = 'final' AND
	CONVERT(DATE,imgrep.CreatedOn) BETWEEN CONVERT(DATE, @FromDate) AND CONVERT(DATE, @ToDate) AND  PatientId = @PatientId AND PatientVisitId = @PatientVisitId 
	GROUP BY imgrep.ImagingTypeName,imgrep.OrderStatus, CONVERT(DATE, CreatedOn)
	
    UNION ALL

    SELECT 'Input' AS Test, '' AS ComponentName, Unit, CAST(SUM(TotalIntake) AS NVARCHAR(50)) AS Value, CONVERT(DATE, CreatedOn) AS [ResultDate]
    FROM CLN_InputOutput cln
	INNER JOIN (SELECT TOP 1 PatientId,PatientVisitId FROM PAT_PatientVisits WHERE  PatientId = @PatientId AND PatientVisitId =@PatientVisitId ) v ON cln.PatientVisitId = v.PatientVisitId
    WHERE IntakeType IS NOT NULL AND CONVERT(DATE,cln.CreatedOn) BETWEEN CONVERT(DATE, @FromDate) AND CONVERT(date, @ToDate) AND  PatientId = @PatientId AND cln.PatientVisitId = @PatientVisitId 
    GROUP BY  Unit, CONVERT(DATE, CreatedOn) 

    UNION ALL

    SELECT 'Output' AS Test,'' AS ComponentName, Unit, CAST(SUM(TotalOutput) AS NVARCHAR(50)) AS Value, CONVERT(DATE, CreatedOn) AS [ResultDate]
    FROM CLN_InputOutput cln
	INNER JOIN (SELECT TOP 1 PatientId,PatientVisitId FROM PAT_PatientVisits WHERE PatientId = @PatientId AND PatientVisitId =@PatientVisitId ) v ON cln.PatientVisitId = v.PatientVisitId
    WHERE OutputType IS NOT NULL AND Convert(date,cln.CreatedOn) BETWEEN CONVERT(DATE, @FromDate) AND CONVERT(DATE, @ToDate) AND  PatientId = @PatientId AND cln.PatientVisitId = @PatientVisitId 
    GROUP BY Unit, CONVERT(DATE, CreatedOn)
END