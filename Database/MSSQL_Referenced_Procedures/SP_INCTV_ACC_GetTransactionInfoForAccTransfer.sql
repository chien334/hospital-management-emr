Create Procedure SP_INCTV_ACC_GetTransactionInfoForAccTransfer
	  @TransactionDate DATE
	AS
	/*
	 File: SP_INCTV_ACC_GetTransactionInfoForAccTransfer
	 Description: To get the list Doctor's TotalAmount and TDSAmont for given date for Accounting Transfer.
	 Remarks:
		* These data will be used in accounting to create a single voucher for that day, where Both Consultant and TDS will be in Credit part.
		* only those data which are not transferred to accounting will be returned (columnname:  IsTransferToAcc)
	 Change History:
	 S.No.   Author/Date               Remarks
	 1.      Sud/15Mar'20             Initial Draft

	*/
	BEGIN
 
	select 
	 Convert(Date, TransactionDate) 'TransactionDate',
	  IncentiveReceiverId 'EmployeeId',
	  emp.FullName 'EmployeeName',

	  'ConsultantIncentive' as TransactionType,
	SUM(ISNULL(IncentiveAmount,0)-ISNULL(TDSAmount,0)) 'TotalAmount',
	SUM(ISNULL(TDSAmount,0)) 'TotalTDS',

	Null AS Remarks,
	STUFF((SELECT ',' + CAST(InctvTxnItemId AS varchar) 
	 FROM INCTV_TXN_IncentiveFractionItem innerTbl 
	where innerTbl.IncentiveReceiverId= outerTbl.IncentiveReceiverId
		  and Convert(Date, innerTbl.TransactionDate) = Convert(Date, outerTbl.TransactionDate) 

	 FOR XML PATH('')), 1 ,1, '') 

	AS ReferenceIds

	from INCTV_TXN_IncentiveFractionItem outerTbl INNER JOIN EMP_Employee emp
	   ON outerTbl.IncentiveReceiverId=emp.EmployeeId

	Where Convert(Date,outerTbl.TransactionDate)=@TransactionDate
	  AND ISNULL(IsTransferToAcc,0) = 0
	  and ISNULL(outerTbl.IsActive,0) = 1

	Group By IncentiveReceiverId, Convert(Date, TransactionDate), emp.FullName
	Order by Convert(Date, outerTbl.TransactionDate)

	END