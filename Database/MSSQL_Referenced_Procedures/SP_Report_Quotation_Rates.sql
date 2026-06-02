--END: 19th Jan, 2021 Ramesh: Added columns in Purchase Request for PRCategory and Purchase Order for POCategory


--START: 22th Jan, 2021 Rajib:SP_Report_Quotation_Rates 

CREATE PROCEDURE [dbo].[SP_Report_Quotation_Rates] 
		@PurchaseOrderId int
AS

/*
FileName: [SP_Report_Quotation_Rates] 
CreatedBy/date: Rajib/22-01-2021
Description: To get the Details of report Quotion rates
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rajib/22-01-2021						created the script
*/

DECLARE 
    @columns NVARCHAR(MAX) = '', @sql     NVARCHAR(MAX) = '';
BEGIN
	SELECT @columns += QUOTENAME(V.VendorName) + ',' 
	FROM
	  (SELECT 
		DISTINCT Q.VendorName
		from INV_TXN_PurchaseOrderItems POI 
		left join INV_QuotationItems QI on QI.ItemId = POI.ItemId
		join INV_Quotation Q on QI.QuotationId = Q.QuotationId
		where POI.PurchaseOrderId = @PurchaseOrderId
    )  V

	-- remove the last comma
	SET @columns = LEFT(@columns, LEN(@columns) - 1);

	SET @sql = 'select * from (
	select QI.ItemName, Q.VendorName, QI.Price
	from INV_TXN_PurchaseOrder PO
	join INV_TXN_PurchaseOrderItems POI on PO.PurchaseOrderId = POI.PurchaseOrderId
	left join INV_QuotationItems QI on QI.ItemId = POI.ItemId
	join INV_Quotation Q on QI.QuotationId = Q.QuotationId
	where POI.PurchaseOrderId = '+ CONVERT(NVARCHAR,@PurchaseOrderId) +'
	) t
	PIVOT( SUM(t.Price) 
	FOR t.VendorName IN ('+ @columns + ')
	) AS pivot_table';

	-- execute the dynamic SQL
	EXECUTE sp_executesql @sql;
END