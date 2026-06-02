CREATE PROCEDURE [dbo].[SP_PHRM_ReturnToSupplierReport] 
	@FromDate datetime=null,
	@ToDate datetime=null
AS
 /*
FileName: [dbo].[SP_PHRM_ReturnToSupplierReport] 
CreatedBy/date:Rusha/04-08-2019
Description: To get report of stock detials return to supplier from Pharmacy store 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		 Naveed/2019-12-13				      updated script for exclude zero quantity Items from Report
2.       Sanjesh/2021-02-22                   Updated script for supplier name 
3.       Rusha/21thJuly22				      Added Generic name in column
*/
 BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL)) 
		BEGIN
			select CONVERT(date,rtnitm.CreatedOn) as [Date]
			,(Cast(ROW_NUMBER() OVER (ORDER BY  supp.SupplierName)  as int)) as SN
			,supp.SupplierName
			,gen.GenericName
			,grp.ItemName
			,rtn.ReturnDate
			,rtnitm.Quantity + rtnitm.FreeQuantity as Qty,rtnitm.SubTotal
			,rtn.DiscountAmount
			,rtn.VATAmount
			,rtnitm.TotalAmount
			,rtn.CreditNoteId as SupplierCreditNoteNum
			,rtn.CreditNotePrintId as CreditNoteNum
			,rtn.Remarks
			from PHRM_ReturnToSupplierItems as rtnitm
			join PHRM_ReturnToSupplier as rtn on rtnitm.ReturnToSupplierId=rtn.ReturnToSupplierId
			join PHRM_GoodsReceiptItems as grp on rtnitm.GoodReceiptItemId=grp.GoodReceiptItemId
			join PHRM_MST_Generic as gen on grp.GenericId = gen.GenericId
			join PHRM_MST_Supplier as supp on supp.SupplierId = rtn.SupplierId
			where CONVERT(date, rtnitm.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1 AND rtnitm.Quantity>0 
			group by CONVERT(date,rtnitm.CreatedOn)
			,supp.SupplierName
			,gen.GenericName
			,grp.ItemName
			,rtn.ReturnDate
			,rtnitm.Quantity
			,rtnitm.FreeQuantity
			,rtnitm.SubTotal
			,rtn.DiscountAmount
			,rtn.VATAmount
			, rtnitm.TotalAmount
			,rtn.CreditNoteId
			,rtn.CreditNotePrintId
			,rtn.Remarks
	   END
END