CREATE PROCEDURE [dbo].[SP_TXNS_PHRM_SettlementDuplicatePrint] 
AS
/*
FileName: [SP_TXNS_PHRM_SettlementDuplicatePrint]
CreatedBy/date: Vikas: 4th March 2020
Description: script for pharmacy duplicate settlement records
Remarks: 
Change History
S.No.    UpdatedBy/Date                        Remarks
*/
BEGIN
 
Select pat.PatientId, pat.PatientCode, 
       pat.FirstName+' '+ISNULL(pat.MiddleName+' ','')+ pat.LastName 'PatientName', 
	   pat.DateOfBirth,
	   pat.Gender,pat.PhoneNumber, credit.SettlementId,
     ISNULL( credit.CreditTotal,0) 'CreditTotal',
	 cast(
	      round( 
	           (ISNULL(dep.TotalDeposit,0)- ISNULL(dep.DepositDeduction,0) - ISNULL(dep.DepositReturn,0))
	         ,2) as numeric(16,2)) 'DepositBalance',
			 credit.CreatedOn 'CreditDate' ,dep.CreatedOn 'DepositDate'
from PAT_Patient pat
LEFT JOIN
(
   Select txn.PatientId, max(txn.CreateOn) CreatedOn, txn.SettlementId,
  SUM(txn.TotalAmount) 'CreditTotal'  from PHRM_TXN_Invoice txn
  where txn.BilStatus ='paid' AND txn.SettlementId is not null AND ISNULL(txn.IsReturn,0) != 1
  Group by txn.PatientId,txn.SettlementId 
) credit on pat.PatientId = credit.PatientId
LEFT JOIN
( 
  Select dep.PatientId,max(dep.CreatedOn) CreatedOn,
    SUM(Case WHEN dep.DepositType='deposit' THEN ISNULL(dep.DepositAmount,0) ELSE 0  END ) AS 'TotalDeposit',
    SUM(Case WHEN dep.DepositType='depositdeduct' THEN ISNULL(dep.DepositAmount,0) ELSE 0  END ) AS 'DepositDeduction',
	SUM(Case WHEN dep.DepositType='depositreturn' THEN ISNULL(dep.DepositAmount,0) ELSE 0  END ) AS 'DepositReturn'
   FROM PHRM_Deposit dep
   Group by dep.PatientId
) dep
ON dep.PatientId = pat.PatientId

where ISNULL(credit.CreditTotal,0) > 1 
	  OR ( dep.TotalDeposit-dep.DepositDeduction - dep.DepositReturn) > 1
--to get the latest first
	  order by credit.SettlementId DESC
END