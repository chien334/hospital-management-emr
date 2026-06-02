/*
FileName: [sp_Report_TransferredPatient]
CreatedBy/date: Ramavtar/2018-06-06
Description: to get no of transferred patient's bed and its details
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Ramavtar/2018-06-06					changed the whole script .. for getting no of bedTransfer and its details(ward-wise count, total patient transfer and total transfer for single day)					
*/
CREATE PROCEDURE [dbo].[sp_Report_TransferredPatient]
@FromDate Date=null ,
@ToDate Date= null
AS
BEGIN
	IF(@FromDate IS NOt NULL OR @ToDate IS NOT NULL or LEN(@FromDate)>0 OR LEN(@ToDate)>0)
	BEGIN
		SELECT
			CONVERT(date, StartedOn) 'Date',
			COUNT(DISTINCT (PatientId)) 'TotalPatientTransfer',
			SUM(1) 'TotalNumberTransferred',
			SUM(CASE WHEN WardId = 1 THEN 1 ELSE 0 END) 'OrthoSurgeryWardTransfer',
			SUM(CASE WHEN WardId = 2 THEN 1 ELSE 0 END) 'MedicineGynoWardTransfer',
			SUM(CASE WHEN WardId = 3 THEN 1 ELSE 0 END) 'Pre-OperationWardTransfer',
			SUM(CASE WHEN WardId = 4 THEN 1 ELSE 0 END) 'ICU&POST-OPWardTransfer',
			SUM(CASE WHEN WardId = 5 THEN 1 ELSE 0 END) 'EmergencyWardTransfer'
		FROM ADT_TXN_PatientBedInfo
		WHERE Action = 'transfer'
		AND CONVERT(DATE, StartedOn) BETWEEN @FromDate AND @ToDate
		GROUP BY CONVERT(DATE, StartedOn)
	END	
END