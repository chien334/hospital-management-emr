CREATE PROCEDURE [dbo].[SP_PHRMReport_DepositBalanceReport] 	
		
AS
/*
FileName: [SP_PHRMReport_DepositBalanceReport]
CreatedBy/date: Kushal/2019-07-08
Description: To get the deposit Balance of the Patient in Pharmacy
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Kushal/2019-07-08	                   created the script
*/
BEGIN
select (Cast(ROW_NUMBER() OVER (ORDER BY  s.PatientCode)  as int)) as SN,*
from(
SELECT  distinct d.PatientId, d.PatientCode, d.PatientName, d.DepositBalance 
	FROM 
	(SELECT
		dep.PatientId,
		pat.PatientCode,
		pat.FirstName + ' ' + ISNULL(pat.MiddleName + ' ', '') + pat.LastName 'PatientName',
		LAST_VALUE( dep.DepositBalance) over (partition by dep.PatientId order by dep.PatientId) 'DepositBalance' 
		--dep.DepositBalance
	FROM PHRM_Deposit as dep
	JOIN PAT_Patient pat ON dep.PatientId = pat.PatientId
		) d
WHERE d.DepositBalance > 0)
s

END