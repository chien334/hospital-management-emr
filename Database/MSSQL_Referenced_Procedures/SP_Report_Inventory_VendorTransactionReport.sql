CREATE  PROCEDURE [dbo].[SP_Report_Inventory_VendorTransactionReport]
@fiscalYearId int = null,
@VendorId int = null
AS
BEGIN
	Select 
		FiscalYearId,
		VendorId,
		SUM(A.SubTotal) as 'SubTotal',
		SUM(A.VATTotal) as 'VATTotal',
		SUM(A.DiscountAmount) as 'DiscountAmount',
		SUM(A.TotalAmount) as 'TotalAmount'
	 from (
				select
						fs.FiscalYearName,
						fs.FiscalYearId,
						ved.VendorId,
						(gd.SubTotal) as 'SubTotal',
						(gd.VATTotal) as 'VATTotal',
						(gd.DiscountAmount) as 'DiscountAmount',
						(gd.TotalAmount) as 'TotalAmount',
						'gr_sale' as 'TxnType'
					from INV_TXN_GoodsReceipt gd 
						left join BIL_CFG_FiscalYears fs on fs.FiscalYearId = @fiscalYearId
						left join INV_MST_Vendor ved on gd.VendorId = ved.VendorId 
					where  
						gd.CreatedOn>Convert(date,fs.StartYear) and gd.CreatedOn<Convert(date,fs.EndYear)
						and gd.IsCancel = 0 
				  UNION ALL

						select 
								fs.FiscalYearName,
								fs.FiscalYearId,
								ret.VendorId,
								-(ret.TotalAmount + (gritm.DiscountAmount/gritm.ReceivedQuantity * ret.Quantity )) as 'SubTotal',								 
								-(gritm.VATAmount/gritm.ReceivedQuantity * ret.Quantity) as 'VatAmount',
								-(gritm.DiscountAmount/gritm.ReceivedQuantity * ret.Quantity ) as 'DiscountAmount',								 
								-ret.TotalAmount as 'TotalAmount',
								'gr_return' as 'TxnType'
						from INV_TXN_ReturnToVendorItems ret
						join INV_TXN_GoodsReceiptItems gritm on  ret.GoodsReceiptItemId = gritm.GoodsReceiptItemId 
						left join BIL_CFG_FiscalYears fs on fs.FiscalYearId =@fiscalYearId
					where
						ret.CreatedOn>Convert(date,fs.StartYear) and ret.CreatedOn<Convert(date,fs.EndYear)	
				

	) A
	where  (A.TotalAmount>= 100000) and (VendorId = @VendorId OR ISNULL(@VendorId, '') = '')	
	group by FiscalYearId,VendorId 
END