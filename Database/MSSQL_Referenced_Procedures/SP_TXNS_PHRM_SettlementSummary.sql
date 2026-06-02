CREATE PROCEDURE [dbo].[SP_TXNS_PHRM_SettlementSummary] 
     @StoreId INT = NULL,
	 @OrganizationId INT = NULL
AS
/*
FileName: [SP_TXNS_PHRM_SettlementSummary] 40
CreatedBy/date: sanjit:24Nov2019
Description: to get CreditTotal, DepositBalance of patients
Remarks:   We're selecting only those patients, who has balance amount in any of above types.
       : I've kept amount > 1 in filter list, otherwise it'll show a lot of un-necessary data.. 
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Shankar/28thFeb2020				Added provisional amount as well
2.		VIKAS/1st Sep 2020				Added BilStatus, and SettlementId and get paid and unpaid credit bills data
3.		Shankar/7th Dec 2020			Subtracted Credit invoice return from CreditTotal
4.      Ramesh/7th Sep'21               Added Store Id Filter 
5.      Rohit/5th Dec'21				Added BillStatus condition to get all pending/unpaid settlement 
6.		Rohit/27th Dec'21				Returned Invoice before Settlement  is filtered using SettlementId is Null.
7.      Dev Narayan/7thJune'22          Added Credit Organization Filter.
8.		Rohit/6Jul'23					PaidAmount -> CreditAmount in credit table
*/
BEGIN
 
Select pat.PatientId, pat.PatientCode, 
       pat.FirstName+' '+ISNULL(pat.MiddleName+' ','')+ pat.LastName 'PatientName', 
	   pat.DateOfBirth,
	   pat.Gender,pat.PhoneNumber,	   
       CAST(ISNULL(credit.CreditTotal,0) - ISNULL(invretn.PaidAmount,0) as numeric(16,2)) 'CreditTotal',
	   CAST(ROUND(ISNULL(provisional.ProvisionalTotal,0),2) as numeric(16,2)) 'ProvisionalTotal',
	   CAST(
	      ROUND( 
	           (ISNULL(dep.TotalDeposit,0)- ISNULL(dep.DepositDeduction,0) - ISNULL(dep.DepositReturn,0))
	         ,2) as numeric(16,2)) 'DepositBalance',
			 credit.CreatedOn 'CreditDate' ,dep.CreatedOn 'DepositDate',
	credit.BilStatus, credit.SettlementId -- VIKAS:1st Sep 2020: added BilStatus , and  SettlementId
	
from PAT_Patient pat
LEFT JOIN
( 
  Select txn.PatientId, max(txn.CreateOn) CreatedOn, txn.BilStatus,txn.SettlementId,txn.OrganizationId,
  SUM(txn.CreditAmount) 'CreditTotal'  from PHRM_TXN_Invoice txn
  where txn.BilStatus ='unpaid' and
   txn.PaymentMode = 'credit' 
  AND ISNULL(txn.IsReturn,0) != 1
  AND txn.StoreId = @StoreId 
  AND txn.OrganizationId = @OrganizationId
  Group by txn.PatientId,txn.BilStatus, txn.SettlementId,txn.OrganizationId
) credit on pat.PatientId = credit.PatientId


LEFT JOIN
(
select invret.PatientId,SUM(invret.PaidAmount) 'PaidAmount' from PHRM_TXN_Invoice inv
join PHRM_TXN_InvoiceReturn invret on inv.InvoiceId = invret.InvoiceId --and invret.PaymentMode = 'credit'
where invret.PaymentMode = 'credit' AND inv.StoreId = @StoreId AND invret.SettlementId IS NULL
AND inv.OrganizationId =@OrganizationId
group by invret.PatientId
) invretn on pat.PatientId = invretn.PatientId


LEFT JOIN
(--select * from PHRM_TXN_Invoice where BilStatus = 'provisional'
  Select invitms.PatientId, max(invitms.CreatedOn) CreatedOn,
  SUM(invitms.TotalAmount) 'ProvisionalTotal' from PHRM_TXN_InvoiceItems invitms
  where invitms.BilItemStatus='provisional' or invitms.BilItemStatus='wardconsumption' AND invitms.StoreId = @StoreId
  Group by invitms.PatientId
) provisional on pat.PatientId = provisional.PatientId

LEFT JOIN
( 
  Select dep.PatientId,max(dep.CreatedOn) CreatedOn,
    SUM(Case WHEN dep.DepositType='deposit' THEN ISNULL(dep.DepositAmount,0) ELSE 0  END ) AS 'TotalDeposit',
    SUM(Case WHEN dep.DepositType='depositdeduct' THEN ISNULL(dep.DepositAmount,0) ELSE 0  END ) AS 'DepositDeduction',
	SUM(Case WHEN dep.DepositType='depositreturn' THEN ISNULL(dep.DepositAmount,0) ELSE 0  END ) AS 'DepositReturn'
   FROM PHRM_Deposit dep
   where dep.StoreId = @StoreId
   Group by dep.PatientId
) dep
ON dep.PatientId = pat.PatientId

where 
	  credit.OrganizationId = @OrganizationId AND
	  CAST(ISNULL(credit.CreditTotal,0) - ISNULL(invretn.PaidAmount,0) as numeric(16,2)) > 1 
	  OR ( dep.TotalDeposit-dep.DepositDeduction - dep.DepositReturn) > 1
--to get the latest first
	  order by
  CASE
      WHEN ISNULL(dep.CreatedOn,0) >= ISNULL(credit.CreatedOn,0)
          THEN  dep.CreatedOn
      ELSE  credit.CreatedOn 
  END
 DESC
END