CREATE PROCEDURE [dbo].[SP_DSB_Emergency_DashboardStatistics]
AS
/*
=============================================================================================
FileName: [SP_DSB_Emergency_DashboardStatistics]
CreatedBy/date: ramavtar/2019-03-03
=============================================================================================
*/
BEGIN

--Table1
	SELECT * FROM 
		(SELECT count(*) 'TotalRegisteredPatients' FROM ER_Patient WHERE CONVERT(DATE,CreatedOn) = CONVERT(DATE,GETDATE())) TotalRegistered,
		(SELECT count(*) 'TotalTriagedPatients' FROM ER_Patient WHERE CONVERT(DATE,TriagedOn) = CONVERT(DATE,GETDATE())) TotalTriaged,
		(SELECT count(*) 'MildPatients' FROM ER_Patient WHERE CONVERT(DATE,TriagedOn) = CONVERT(DATE,GETDATE()) AND TriageCode = 'mild') Mild,
		(SELECT count(*) 'ModeratePatients' FROM ER_Patient WHERE CONVERT(DATE,TriagedOn) = CONVERT(DATE,GETDATE()) AND TriageCode = 'moderate') Moderate,
		(SELECT count(*) 'CriticalPatients' FROM ER_Patient WHERE CONVERT(DATE,TriagedOn) = CONVERT(DATE,GETDATE()) AND TriageCode = 'critical') Critical,
		(SELECT count(*) 'TotalFinalizedPatients' FROM ER_Patient WHERE CONVERT(DATE, FinalizedOn) = CONVERT(DATE,GETDATE())) TotalFinalized,
		(SELECT count(*) 'LAMAPatients' FROM ER_Patient WHERE CONVERT(DATE, FinalizedOn) = CONVERT(DATE,GETDATE()) AND FinalizedStatus='lama') LAMA,
		(SELECT count(*) 'AdmittedPatients' FROM ER_Patient WHERE CONVERT(DATE, FinalizedOn) = CONVERT(DATE,GETDATE()) AND FinalizedStatus='admitted') Admitted,
		(SELECT count(*) 'DischargedPatients' FROM ER_Patient WHERE CONVERT(DATE, FinalizedOn) = CONVERT(DATE,GETDATE()) AND FinalizedStatus='discharged') Discharged,
		(SELECT count(*) 'TransferredPatients' FROM ER_Patient WHERE CONVERT(DATE, FinalizedOn) = CONVERT(DATE,GETDATE()) AND FinalizedStatus='transferred') Transferred,
		(SELECT count(*) 'DeathPatients' FROM ER_Patient WHERE CONVERT(DATE, FinalizedOn) = CONVERT(DATE,GETDATE()) AND FinalizedStatus='death') Death
END