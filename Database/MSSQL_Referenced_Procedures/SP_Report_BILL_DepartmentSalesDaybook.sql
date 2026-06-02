CREATE PROCEDURE [dbo].[SP_Report_BILL_DepartmentSalesDaybook]--[SP_Report_BILL_DepartmentSalesDaybook] '2018-08-08','2018-08-08' 
	@FromDate Date=null ,
	@ToDate Date=null	,
	@IsInsurance bit=0
AS
/*
FileName: [SP_Report_BILL_DepartmentSalesDaybook]
CreatedBy/date: Dinesh/2018-08-01
Description: to get the collection department wise 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Dinesh/2018-08-01					NA										
1       Sud/06Aug'29                 Added clause for Insurance

*/


BEGIN
If(@FromDate IS NOT NULL OR @ToDate IS NOT NULL)
	BEGIN 
			;With DepartmentWiseSalesCTE as
  (
  
  select 
  --(Cast(ROW_NUMBER() OVER (ORDER BY  ServiceDepartmentName)   as int)) as SN,
  Convert(date,vwTxnItm.BillingDate) 'Date',
        sd.ServiceDepartmentName, itms.ItemName,
   CASE when (sd.ServiceDepartmentName='Biochemistry' ) 
       OR(sd.ServiceDepartmentName='HEMATOLOGY' )
       OR(sd.ServiceDepartmentName='ATOMIC ABSORTION') 
       OR(sd.ServiceDepartmentName='CLNICAL PATHOLOGY' )
       OR(sd.ServiceDepartmentName='CYTOLOGY'  )
       OR(sd.ServiceDepartmentName='KIDNEY BIOPSY'  )
       OR(sd.ServiceDepartmentName='SKIN BIOPSY'  )
       OR(sd.ServiceDepartmentName='CONJUNCTIVAL BIOPSY' )
	   OR(sd.ServiceDepartmentName='EXTERNAL LAB-3' )
	   OR(sd.ServiceDepartmentName='EXTERNAL LAB - 1' )
	   OR(sd.ServiceDepartmentName='EXTERNAL LAB - 2'  )
	   OR(sd.ServiceDepartmentName='HISTOPATHOLOGY'  )
	   OR(sd.ServiceDepartmentName='IMMUNOHISTROCHEMISTRY'  )
	   OR(sd.ServiceDepartmentName='MOLECULAR DIAGNOSTICS'  )
	   OR(sd.ServiceDepartmentName='SPECIALISED BIOPHYSICS ASSAYS'  )
	   OR(sd.ServiceDepartmentName='SEROLOGY'  )
	   OR(sd.ServiceDepartmentName='LABORATORY'  )
	   OR(sd.ServiceDepartmentName='MICROBIOLOGY'  )



    then 'LABS'  
	when (sd.ServiceDepartmentName='DUCT')
OR(sd.ServiceDepartmentName='MAMMOLOGY')
OR(sd.ServiceDepartmentName='PERFORMANCE TEST') 
OR(sd.ServiceDepartmentName='MRI')
OR(sd.ServiceDepartmentName='C.T. SCAN')
OR(sd.ServiceDepartmentName='ULTRASOUND')
OR(sd.ServiceDepartmentName='ULTRASOUND COLOR DOPPLER')
OR(sd.ServiceDepartmentName='BMD-BONEDENSITOMETRY')
OR(sd.ServiceDepartmentName='OPG-ORTHOPANTOGRAM')
OR(sd.ServiceDepartmentName='MAMMOGRAPHY')
OR(sd.ServiceDepartmentName='X-RAY')
OR(sd.ServiceDepartmentName='DEXA')
OR(sd.ServiceDepartmentName='IMAGING')
then ('RADIOLOGY')
when(sd.ServiceDepartmentName='NON INVASIVE CARDIO VASCULAR INVESTIGATIONS')
OR(sd.ServiceDepartmentName='CARDIOVASCULAR SURGERY')
then 'CTVS'
     ELSE sd.ServiceDepartmentName END as 'ServDeptName',
	 ISNULL(vwTxnItm.PaidQuantity,0)+ISNULL(vwTxnItm.UnpaidQuantity,0) as Quantity ,
     ISNULL(vwTxnItm.PaidSubTotal,0)+ISNULL(vwTxnItm.UnpaidSubTotal,0)  as SubTotal,
     ISNULL(vwTxnItm.PaidTax,0)+ISNULL(vwTxnItm.UnpaidTax,0) as Tax,
     ISNULL(vwTxnItm.PaidDiscountAmount,0)+ISNULL(vwTxnItm.UnpaidDiscountAmount,0) as DiscountAmount,
     ISNULL(vwTxnItm.PaidTotalAmount,0)+ISNULL(vwTxnItm.UnpaidTotalAmount,0) as TotalAmount,
	
	ISNULL(vwTxnItm.CancelSubTotal,0) as CancelSubTotal,
	 ISNULL(vwTxnItm.CancelDiscountAmount,0) as CancelDiscountAmount,
	  --ISNULL(cancelonsameday.CancelTotalAmountDay,0) as CancelTotalAmountDay,
	  --  ISNULL(cancelonsameday.CancelDiscountAmountDay,0) as CancelDiscountDay,
	 
   ISNULL(vwTxnItm.CancelTotalAmount,0) 'CancelAmount',
   ISNULL(vwTxnItm.CancelTax,0) 'CancelTax',
    ( case when BillStatus='return' then (ISNULL(vwTxnItm.ReturnTotalAmount,0)) 
	 ELSE 0 END) as ReturnAmount,
     ISNULL(vwTxnItm.ReturnTax,0) AS ReturnTax
    from BIL_MST_ServiceDepartment sd, BIL_CFG_BillItemPrice itms, VW_BIL_TxnItemsInfo vwTxnItm 

	  where   vwTxnItm.BillingDate between Convert(date, @FromDate) AND  Convert(date, @ToDate) 
       AND vwTxnItm.ServiceDepartmentId  = sd.ServiceDepartmentId
     AND vwTxnItm.ItemId=itms.ItemId
     AND sd.ServiceDepartmentId = itms.ServiceDepartmentId
	 AND  ISNULL(vwTxnItm.IsInsurance,0)= @IsInsurance

      
) 
Select 
convert(date,@FromDate) 'FromDate',
     convert(date,@ToDate) 'ToDate',
     txnItms.ServDeptName 'ServDeptName',
	 sum(txnItms.Quantity) 'Quantity',
     sum(txnItms.SubTotal) 'Price',
     round(sum(txnItms.Tax),2) as 'Tax',
     sum(txnItms.DiscountAmount) 'DiscountAmount',
     sum(txnItms.TotalAmount) 'TotalAmount',
     sum(txnItms.ReturnAmount) 'ReturnAmount',
     sum(txnItms.ReturnTax) 'ReturnTax',
   Sum(txnItms.CancelAmount) 'CancelAmount',
   Sum(txnItms.CancelTax) 'CancelTax',
   Sum(txnItms.TotalAmount)-Sum(txnItms.Tax)-sum(txnItms.ReturnAmount) 'NetSales'
  -- Sum(txnItms.CancelTotalAmountDay) 'CancelTotalAmountDay',
  --Sum (txnItms.CancelDiscountDay) 'CancelDiscountDay'
from DepartmentWiseSalesCTE txnItms 
group by txnItms.ServDeptName

	END	
END