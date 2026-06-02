CREATE PROCEDURE [dbo].[SP_Report_BILDSB_MonthlyBillingTrend]
AS
/*
  Need to check the data correctness of this storedProc: sudarshan:9Jul2017
*/
BEGIN
--dividing by thousand since we're showing 'Amount in Thousands in the dashboards.'
 Select SUBSTRING(mth.MthName,1,8) 'month',
		convert(float,ISNULL(paid.Paid,0))/1000 'Paid',
		convert(float,ISNULL(unpaid.Unpaid,0))/1000 'Unpaid',
		convert(float,ISNULL(Tax.Tax,0))/1000 'Tax'
  from 
 
  --output format of date is: 2017-July, 2017-June, etc
	( select convert(varchar(4), Year(Dates)) +'-'+ DATENAME(MONTH,Dates) MthName, YEAR(Dates)*12+MONTH(Dates) seq
	   from [FN_Temp_GetLast7Months] () ) mth

	LEFT OUTER JOIN
	(
		 --output format of date is: 2017-July, 2017-June, etc
		select convert(varchar(4), Year(PaidDate)) +'-'+ DATENAME(MONTH,PaidDate) MthName, Sum(TotalAmount) 'Paid' 
		from BIL_TXN_BillingTransactionItems
		where PaidDate is not null
		Group by convert(varchar(4), Year(PaidDate)) +'-'+ DATENAME(MONTH,PaidDate)
	) paid
	  ON mth.MthName = paid.MthName

	LEFT OUTER JOIN
		(
      --output format of date is: 2017-July, 2017-June, etc
		   select convert(varchar(4), Year(CreatedOn)) +'-'+ DATENAME(MONTH,CreatedOn) MthName, Sum(TotalAmount) 'Unpaid' 
		   from BIL_TXN_BillingTransactionItems
		   where PaidDate is NULL OR ( convert(date,paiddate) != convert(date,createdon) )
		   Group by convert(varchar(4), Year(CreatedOn)) +'-'+ DATENAME(MONTH,CreatedOn)
		) unpaid

	  ON mth.MthName = unpaid.MthName

	LEFT OUTER JOIN
		(
		 --output format of date is: 2017-July, 2017-June, etc
		  select convert(varchar(4), Year(PaidDate)) +'-'+ DATENAME(MONTH,PaidDate) MthName, Sum(Tax) 'Tax' 
		   from BIL_TXN_BillingTransactionItems
		   where PaidDate is not null
		   Group by convert(varchar(4), Year(PaidDate)) +'-'+ DATENAME(MONTH,PaidDate)
		) Tax

	ON mth.MthName = Tax.MthName
Order by mth.seq desc
END


/****** Object:  StoredProcedure [dbo].[SP_Report_BILL_DepartmentSalesDaybook]    Script Date: 5/2/2018 2:24:13 PM ******/
SET ANSI_NULLS ON