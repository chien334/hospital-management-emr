CREATE PROCEDURE SP_PHRM_GetDispensaryAvailableStock
     @DispensaryId INT=NULL,
	 @PriceCategoryId INT =NULL
AS
/*  
FileName: SP_PHRM_GetAvailableStockByStoreId  
CreatedBy/date: Rohit / 25Apr'23  
Description: Get All Available Stock By DispensaryId.
Logic Used (IMPORTANT):
   * When PharmacyRateIsDifferent for Current PriceCategory, Bring the SalePrice from Mapping Table
   * When PharmacyRate is NOT-DIfferent for current Price Category, bring the SalePrice from StoreStock Table
   * Additional Field (NormalSalePrice) is required to filter Stock during StockOut in FEFO LOGIC, don't change that.
  
Change History  
S.No.    UpdatedBy/Date                        Remarks  
1.      Rohit/26Apr'23						  Initial Script.  
*/  
BEGIN
Declare @IsPhrmRateDifferent BIT = 0;
SET @IsPhrmRateDifferent=ISNULL((SELECT IsPharmacyRateDifferent from BIL_CFG_PriceCategory where PriceCategoryId=@PriceCategoryId),0)

IF (@IsPhrmRateDifferent=0) 
BEGIN
   SELECT stkMst.ItemId, stkMst.BatchNo, stkMst.ExpiryDate, stkMst.ItemName,
   stkMst.SalePrice, 
   --Rohit/Sud:IMPORTANT !!! We need below (NormalSalePrice) for Comparision during StockOut action for Sale, Don't Change this
   stkMst.SalePrice AS 'NormalSalePrice', 
   stkMst.Unit, stkMst.CostPrice,stkMst.AvailableQuantity, stkMst.IsActive, stkMst.GenericName, stkMst.GenericId, 
   stkMst.IsNarcotic, stkMst.IsVATApplicable,stkMst.SalesVATPercentage
   FROM FN_PHRM_GetDispensaryAvailableStock(@DispensaryId) stkMst

END
ELSE
BEGIN
   SELECT stkMst.ItemId, stkMst.BatchNo, stkMst.ExpiryDate, stkMst.ItemName,
   ISNULL(priceMap.Price, 0) AS 'SalePrice',   -- Taking SalePrice from Map table
  --Rohit/Sud:IMPORTANT !!! We need below (NormalSalePrice) for Comparision during StockOut action for Sale, Don't Change this
   stkMst.SalePrice AS 'NormalSalePrice',  
   stkMst.AvailableQuantity,
   stkMst.Unit, stkMst.CostPrice, stkMst.IsActive, stkMst.GenericName, stkMst.GenericId, 
   stkMst.IsNarcotic, stkMst.IsVATApplicable,stkMst.SalesVATPercentage
   FROM FN_PHRM_GetDispensaryAvailableStock(@DispensaryId) stkMst
     INNER JOIN (SELECT * FROM PHRM_MAP_MSTItemPriceCategory priceMap WHERE PriceCategoryId=@PriceCategoryId) priceMap
	    ON stkMst.ItemId=priceMap.ItemId
END
END