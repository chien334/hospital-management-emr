/* ***********************************************************************
FileName: [SP_ACC_GetLedgerList]  
CreatedBy/date: NageshBB/22 Dec 2020
Description: Get Ledger list with correct closing balance of every ledger
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Nagesh:20Jun'20                   created sp for get ledger list with closing balance or opening balance as per need
************************************************************************ */
-- Exec [dbo].[SP_ACC_GetLedgerList] 3,2,1
CREATE PROCEDURE [dbo].[SP_ACC_GetLedgerList]  
  @HospitalId INT,@FiscalYearIdForOpeningBal int=null ,@GetClosingBal bit=null
AS
BEGIN
--if @GetClosingBal =1 then we will calculate closing balance from txn table and return with every ledger
--else closing balance will be 0 
 
	If(@GetClosingBal=1)
	Begin
	
	Declare @FromDate datetime=(select top 1 StartDate from ACC_MST_FiscalYears where FiscalYearId=@FiscalYearIdForOpeningBal)
	Declare @ToDate datetime=(select GETDATE())	
	
		--ledger with ledgergroup and all other details
		select 
		led.HospitalId,		led.LedgerId,		led.LedgerGroupId,		ledGroup.PrimaryGroup,		ledGroup.COA,		ledGroup.LedgerGroupName,
		led.LedgerName,		led.LedgerReferenceId,		led.SectionId,		led.Description,		IsActive = led.IsActive,		led.OpeningBalance,
		led.DrCr,		led.CreatedBy,		led.CreatedOn,		led.Name,		led.Code,		led.LedgerType,		led.PANNo,		led.MobileNo,
		led.Address,		led.TDSPercent,		led.CreditPeriod,		led.LandlineNo,			closeBalTbl.DrAmount-closeBalTbl.CrAmount as ClosingBalance 
		from ACC_Ledger led join ACC_MST_LedgerGroup  ledGroup on led.LedgerGroupId=ledGroup.LedgerGroupId		
		join  (
		Select  T.LedgerId, Sum(OpeningDrAmount) + sum(TxnDrAmount) as DrAmount,Sum(OpeningCrAmount)+Sum(TxnCrAmount) as CrAmount
		from (
		--get ledger opening balance from ledger balance history table
	    select 
		led.LedgerId,
		case when ISNULL(lbh.OpeningDrCr, 1)=1 then IsNULL(lbh.OpeningBalance,0) else 0 end as OpeningDrAmount,
		case when lbh.OpeningDrCr=0 then IsNULL(lbh.OpeningBalance,0) else 0 end as OpeningCrAmount,		
		0 as TxnDrAmount,0 as TxnCrAmount
	    from ACC_Ledger led join ACC_LedgerBalanceHistory lbh on led.LedgerId=lbh.LedgerId and led.HospitalId=lbh.HospitalId
		where lbh.HospitalId=@HospitalId and lbh.FiscalYearId=@FiscalYearIdForOpeningBal and
		led.IsActive=1  

		Union

	 -- get transaction calculation amount with ledger
		 select LedgerId ,0 as OpeningDrAmount , 0 as OpeningCrAmount, SUM(txndr)  as TxnDrAmount, SUM(txncr) as TxnCrAmount
		from (
		select 
		ti.LedgerId, --0 as OpeningDrAmount, 0 as OpeningCrAmount, 
		case when ti.DrCr=1 then ISNULL(ti.Amount,0) else 0 end as txndr,
		case when ti.DrCr=0 then ISNULL(ti.Amount,0) else 0 end as txncr
	    from ACC_Transactions t join ACC_TransactionItems ti on t.TransactionId=ti.TransactionId
		where t.HospitalId=@HospitalId and (convert(date,t.TransactionDate) between convert(date,@FromDate) and convert(date,@ToDate))
		)as p
		group by LedgerId
		) as T  Group by T.LedgerId
		) as closeBalTbl  on closeBalTbl.LedgerId=led.LedgerId
		where led.HospitalId=@HospitalId and ledGroup.HospitalId=@HospitalId 
		and led.IsActive=1 and ledGroup.IsActive=1  
		order by led.LedgerId
	End
	Else
	Begin
	--mainly for accounting ledger setting page where IsActive false and true both Ledger r there
		select 
		led.HospitalId,		led.LedgerId,		led.LedgerGroupId,		ledGroup.PrimaryGroup,		ledGroup.COA,		ledGroup.LedgerGroupName,
		led.LedgerName,		led.LedgerReferenceId,		led.SectionId,		led.Description,		IsActive = led.IsActive,		led.OpeningBalance,
		led.DrCr,		led.CreatedBy,		led.CreatedOn,		led.Name,		led.Code,		led.LedgerType,		led.PANNo,		led.MobileNo,
		led.Address,		led.TDSPercent,		led.CreditPeriod,		led.LandlineNo,			0 as ClosingBalance 
		from ACC_Ledger led join ACC_MST_LedgerGroup  ledGroup on led.LedgerGroupId=ledGroup.LedgerGroupId
		where led.HospitalId=@HospitalId and ledGroup.HospitalId=@HospitalId
		order by led.LedgerId
	End
END