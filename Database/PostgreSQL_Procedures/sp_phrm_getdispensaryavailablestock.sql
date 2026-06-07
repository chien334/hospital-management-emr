CREATE OR REPLACE FUNCTION sp_phrm_getdispensaryavailablestock(
    p_dispensaryid INT DEFAULT NULL,
    p_pricecategoryid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_isphrmratedifferent BOOLEAN := FALSE;
BEGIN
    /*  
    filename: sp_phrm_getavailablestockbystoreid  
    createdby/date: rohit / 25apr'23  
    Description: Get All Available Stock By DispensaryId.
    Logic Used (IMPORTANT):
       * When PharmacyRateIsDifferent for Current PriceCategory, Bring the SalePrice from Mapping Table
       * When PharmacyRate is NOT-DIfferent for current Price Category, bring the SalePrice from StoreStock Table
       * Additional Field (NormalSalePrice) is required to filter Stock during StockOut in FEFO LOGIC, don't change that.
      
    change history  
    s.no.    updatedby/date                        remarks  
    1.      rohit/26apr'23						  Initial Script.  
    */  
    BEGIN
    
    v_isphrmratedifferent := COALESCE((SELECT IsPharmacyRateDifferent from BIL_CFG_PriceCategory where PriceCategoryId=p_pricecategoryid),0);
    
    IF (v_isphrmratedifferent=0) 
    THEN
       OPEN ref1 FOR SELECT stkMst.ItemId, stkMst.BatchNo, stkMst.ExpiryDate, stkMst.ItemName,
       stkMst.SalePrice, 
       --Rohit/Sud:IMPORTANT !!! We need below (NormalSalePrice) for Comparision during StockOut action for Sale, Don't change this
       stkmst.saleprice as "normalsaleprice", 
       stkmst.unit, stkmst.costprice,stkmst.availablequantity, stkmst.isactive, stkmst.genericname, stkmst.genericid, 
       stkmst.isnarcotic, stkmst.isvatapplicable,stkmst.salesvatpercentage
       from fn_phrm_getdispensaryavailablestock(p_dispensaryid) stkmst;
        return next ref1;
    
    
    else
    
       open ref2 for select stkmst.itemid, stkmst.batchno, stkmst.expirydate, stkmst.itemname,
       coalesce(pricemap.price, 0) as "saleprice",   -- taking saleprice from map table
      --rohit/sud:important !!! we need below (normalsaleprice) for comparision during stockout action for sale, don't change this
       stkmst.saleprice as "normalsaleprice",  
       stkmst.availablequantity,
       stkmst.unit, stkmst.costprice, stkmst.isactive, stkmst.genericname, stkmst.genericid, 
       stkmst.isnarcotic, stkmst.isvatapplicable,stkmst.salesvatpercentage
       from fn_phrm_getdispensaryavailablestock(p_dispensaryid) stkmst
         inner join (select * from phrm_map_mstitempricecategory pricemap where pricecategoryid=p_pricecategoryid) pricemap
    	    on stkmst.itemid=pricemap.itemid;
        return next ref2;
    end if;
    end;
END;
$$ LANGUAGE plpgsql;