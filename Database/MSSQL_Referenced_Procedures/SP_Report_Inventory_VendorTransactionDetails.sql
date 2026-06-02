/*
FileName: [SP_Report_Inventory_VendorTransactionDetails]
CreatedBy/date: 
Description: 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1      	Vikas:28th Jan 2020					Details transaction script for vendor transaction more than 100000	

*/
Create PROCEDURE [dbo].[SP_Report_Inventory_VendorTransactionDetails]
@fiscalYearId int = null,
@VendorId int = null
AS
BEGIN

	Select 
		VendorId,		
		ItemId,
		ItemName,
		SUM(A.SubTotal) as 'Sales_SubTotal',
		SUM(A.VATTotal) as 'Sales_VatAmount',
		SUM(A.DiscountAmount) as 'Sales_DiscountAmount',
		SUM(A.TotalAmount) as 'Sales_TotalAmount',

		SUM(A.Ret_SubTotal) as 'Ret_SubTotal',
		SUM(A.Ret_VATTotal) as 'Ret_VATTotal',
		SUM(A.Ret_DiscountAmount) as 'Ret_DiscountAmount',
		SUM(A.Ret_TotalAmount) as 'Ret_TotalAmount',
		(SUM(A.TotalAmount)-SUM(A.Ret_TotalAmount)) as 'Total'

	 from (
				select
						ved.VendorId,
						item.ItemName,
						item.ItemId,
						(gd.SubTotal) as 'SubTotal',
						(gd.VATTotal) as 'VATTotal',
						(gd.DiscountAmount) as 'DiscountAmount',
						(gd.TotalAmount) as 'TotalAmount',

						0 as 'Ret_SubTotal',
						0 as 'Ret_VATTotal',
						0 as 'Ret_DiscountAmount',
						0 as 'Ret_TotalAmount'

					from INV_TXN_GoodsReceipt gd 
						left join BIL_CFG_FiscalYears fs on fs.FiscalYearId = @fiscalYearId
						left join INV_MST_Vendor ved on gd.VendorId = ved.VendorId 
						left join INV_TXN_GoodsReceiptItems gritem on gd.GoodsReceiptID= gritem.GoodsReceiptId
						left join INV_MST_Item item on gritem.ItemId = item.ItemId	
					where  
						gd.CreatedOn>Convert(date,fs.StartYear) and gd.CreatedOn<Convert(date,fs.EndYear)
						and gd.IsCancel = 0 
						and (gritem.GoodsReceiptItemId not in (select GoodsReceiptItemId from INV_TXN_ReturnToVendorItems))

				  UNION ALL
						select 
								ret.VendorId,
								item.ItemName,
								item.ItemId,
								0 as 'SubTotal',
								0 as 'VATTotal',
								0 as 'DiscountAmount',
								0 as 'TotalAmount',
								((ret.TotalAmount + (gritm.DiscountAmount/gritm.ReceivedQuantity * ret.Quantity ))) as 'Ret_SubTotal',								 
								((gritm.VATAmount/gritm.ReceivedQuantity * ret.Quantity)) as 'Ret_VATTotal',
								((gritm.DiscountAmount/gritm.ReceivedQuantity * ret.Quantity )) as 'Ret_DiscountAmount',								 
								(ret.TotalAmount) as 'Ret_TotalAmount'
						from INV_TXN_ReturnToVendorItems ret
						join INV_TXN_GoodsReceiptItems gritm on  ret.GoodsReceiptItemId = gritm.GoodsReceiptItemId 
						left join BIL_CFG_FiscalYears fs on fs.FiscalYearId = @fiscalYearId
						left join INV_MST_Item item on gritm.ItemId = item.ItemId
					where
						ret.CreatedOn>Convert(date,fs.StartYear) and ret.CreatedOn<Convert(date,fs.EndYear)	
	) A
	where VendorId = @VendorId OR ISNULL(@VendorId, '') = ''
	group by VendorId , ItemName,ItemId
END