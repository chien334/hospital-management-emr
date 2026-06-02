CREATE PROCEDURE [dbo].[SP_IRD_PHRM_InvoiceDetails]
		@FromDate Datetime=null ,
		@ToDate DateTime=null	
AS
/*
FileName: [SP_IRD_PHRM_InvoiceDetails]
CreatedBy/date: Vikas/2018-10-24
Description: to get the Pharmacy Invoice Details as per IRD requirements 
 Change History:
 S.No      ModifiedBy/Date                     Remarks
 1.			Vikas/2018-10-24					 Created
 2.        22 Nov 2018 By NageshBB               Update for fiscal year, and other columns
 3.			Ajay/04 Dec 2018					 Changed InvoiceId to InvoicePrintId
 4.			Vikas/02 Jan 2019					 modify patient shortname(firstname and last name) to fullname(first,middle, and lastName)
 5.         Sud/2Jul'21                        * Setting Is_Bill_Active=False if One or more CreditNote generated from current invoice.
								               * Taking Customer_name from Patient>ShortName field
								               * Corrected Double Columns (Is_Realtime, and Isbillactive were returned twice)
											   * Corrected SourceColumns for EmpName and PatientName.
 6.         Shankar/20thSept'21                  Update for Payment_Method and TransactionId columns(revised as per new ird requirements)
*/

BEGIN
  IF (@FromDate IS NOT NULL) OR (@ToDate IS NOT NULL)  
	 BEGIN
	 SET NOCOUNT ON
select 
       fisc.FiscalYearFormatted AS Fiscal_Year,
		Convert(varchar(20),inv.InvoicePrintId) as Bill_No,
		pat.ShortName as Customer_name,	
		pat.PANNumber,		
	    CONVERT(VARCHAR(10), inv.CreateOn, 120) As BillDate,
		'ItemTransaction' as BillType, --here only for ird details need to handle into pharmacy table also
	    inv.SubTotal AS Amount,
        inv.DiscountAmount as DiscountAmount,
	   ((inv.SubTotal-inv.DiscountAmount)+inv.VATAmount) As Total_Amount,
	   (inv.VATAmount) as Tax_Amount ,
	   case when inv.VATAmount >0 or inv.VATAmount is null then inv.SubTotal-inv.DiscountAmount else 0 end As Taxable_Amount ,
	   case when inv.VATAmount <=0 or inv.VATAmount is null then inv.SubTotal-inv.DiscountAmount else 0 end As  NonTaxable_Amount  ,
	   CASE When inv.IsRemoteSynced=1 then 'Yes' else 'No' END AS SyncedWithIRD,
	   CASE WHEN inv.PrintCount > 0  THEN 'Yes' ELSE 'No' END AS Is_Printed,	
	   CASE WHEN inv.PrintCount >0 Then   convert(varchar(20),convert(time,inv.CreateOn),100) Else '' END AS Printed_Time,

	   emp.FullName as Entered_By,				   
	   emp.FullName  as Printed_by,
	   inv.PrintCount as Print_Count,
	   CASE When ISNULL(inv.IsRealtime,0)=1 then 'Yes' ELSE 'No' END as Is_Realtime,		
		CASE
			WHEN ISNULL(ret.ReturnInvoiceId, 0) = 0 THEN 'True'
			ELSE 'False' 
		END AS Is_Bill_Active,
		inv.PaymentMode as Payment_Method,
		inv.InvoiceId as TransactionId


  from PHRM_TXN_Invoice inv 
	  inner join	EMP_Employee emp on emp.EmployeeId=inv.CreatedBy
	  inner join    PAT_Patient pat on pat.PatientId=inv.PatientId
	  inner join BIL_CFG_FiscalYears fisc on inv.FiscalYearId=fisc.FiscalYearId
	  left join(Select distinct InvoiceId 'ReturnInvoiceId' from PHRM_TXN_InvoiceReturn )ret 
		  ON inv.InvoiceId = ret.ReturnInvoiceId

  WHERE (  
        CONVERT(DATE,inv.CreateOn) BETWEEN CONVERT(DATE,@FromDate) 
     AND CONVERT(DATE,@ToDate) 
     ) 
	  END
END