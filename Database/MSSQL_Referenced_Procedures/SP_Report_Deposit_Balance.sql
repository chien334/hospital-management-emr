CREATE PROCEDURE [dbo].[SP_Report_Deposit_Balance]   
AS
/*
FileName: [SP_Report_Deposit_Balance]
CreatedBy/date: dinesh/2017-07-19
Description: To get the deposit Balance of the Patient
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2017-05-25                     created the script
2       Umed/2018-04-23                  Apply Round Off on Deposit Balance Because During Export it Dont Require
3.     Ramavtar/2018-06-05              change the whole SP.. bring deposit amount of patients
4.     Narayan/2019-09-16               added  DepositId column.
5.     Arpan/Shankar/2020-03-24         deduct both depositdeduct and returndeposit from deposit
6.     Sud/5-oct-2020                   Adding PhoneNumber to deposit balance report
7.     Sud/Pratik: 12Sep'21             Showing Deposits of only patient having some deposits remaining.
*/
BEGIN
Declare @FromDate DATE= '2015-01-01' -- Need to get from the beginning of the Software..
, @ToDate Date= Convert(Date,Getdate()) --Need to check UPTO-Today.

  Select * from 
  (
    Select PatientId, PatientCode, PatientName, DateOfBirth,
      Gender, PhoneNumber, SUM(ISNULL(DepositReceived,0)) 'TotalDeposit',
    SUM(ISNULL(DepositDeducted,0)) 'TotalDeducted',
    SUM(ISNULL(DepositReturned,0)) 'TotalRefunded',
    SUM(ISNULL(DepositReceived,0))- SUM((ISNULL(DepositDeducted,0)+ISNULL(DepositReturned,0))) 'Balance'
    from FN_RPT_BIL_GetDepositTransationsInDatRange (@FromDate,@ToDate,null,null)
    Group by PatientId, PatientCode, PatientName, DateOfBirth, Gender, PhoneNumber
  ) A
  Where Balance !=0 
END