Create PROCEDURE [dbo].[SP_ACC_RPT_GetReverseTranactionDetail]			
@ReverseTransactionId int
AS
--EXEC [dbo].[SP_ACC_RPT_GetReverseTranactionDetail] @TransactionDate = '2019-07-05 12:07:31.170'

/************************************************************************
FileName: [SP_ACC_RPT_GetReverseTranactionDetail]
CreatedBy/date: NageshBB/18Aug2020
Description: get details of reversed transaction to show in report
Change History
S.No.    UpdatedBy/Date                        Remarks
1       NageshBB / 18Aug2020						 scriptcreated 
*************************************************************************/
BEGIN
	--Table1
		select distinct rtxn.SectionId, rtxn.VoucherId,rtxn.FiscalYearId,rtxn.CreatedBy, rtxn.ReversedBy  
		,sec.SectionName,fy.FiscalYearName,emp.FullName as ReversedByName,rtxn.ReversedOn,rtxn.Reason,rtxn.TransactionDate,--common section
		rtxn.VoucherNumber,vcr.VoucherName,rtxn.CreatedOn,emp1.FullName as CreatedByName, IsRecreated= 0 --table records
		from FN_ACC_Get_Reverse_Transaction_Records() rtxn 
		join ACC_MST_SectionList sec on rtxn.SectionId=sec.SectionId
		join ACC_MST_FiscalYears fy on fy.FiscalYearId=rtxn.FiscalYearId
		join EMP_Employee emp on emp.EmployeeId=rtxn.ReversedBy
		join ACC_MST_Vouchers vcr on vcr.VoucherId=rtxn.VoucherId
		join EMP_Employee emp1 on emp1.EmployeeId=rtxn.CreatedBy
		where rtxn.ReverseTransactionId=@ReverseTransactionId
	--Table2
		select distinct rtxn.SectionId,rtxn.FiscalYearId,rtxn.VoucherNumber
		from FN_ACC_Get_Reverse_Transaction_Records() rtxn 
		join ACC_Transactions txn on rtxn.SectionId=txn.SectionId and rtxn.FiscalYearId=txn.FiscalYearId
		and rtxn.VoucherNumber=txn.VoucherNumber
		where rtxn.ReverseTransactionId=@ReverseTransactionId			
END