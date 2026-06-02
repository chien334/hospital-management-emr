CREATE PROCEDURE [dbo].[SP_INV_RPT_GetSubstoreDispConsumption_Summary ] 
  @StoreIds NVARCHAR(400) = '' ,
  @FromDate Datetime = null,
  @ToDate DateTime = null
AS
/*
Change History
S.No.    UpdatedBy/Date          Remarks
1    Anjana/12/18/2020        Initial Draft
2	 Sud/01/05/2021			  Made Corrections 
*/
 BEGIN
 
 
  Declare @StoreIdTbl Table(StoreId int)
  Insert into @StoreIdTbl
  SELECT value FROM STRING_SPLIT(@StoreIds, ',') WHERE RTRIM(value) <> ''
  
   SELECT 
       sub.SubCategoryName,
      itm.ItemName, 
      itm.ItemId,
      itm.Code,
      itm.ItemType,
      unit.UOMName as Unit,
      dis.DispatchQuantity,
      dis.DispatchValue,
      con.ConsumptionQuantity,
      con.ConsumptionValue
    From 
	INV_MST_Item itm 
	  inner join INV_MST_ItemSubCategory sub on itm.SubCategoryId = sub.SubCategoryId
	  left join  INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId 
      left join ( Select ItemId, Sum(Quantity) 'DispatchQuantity', Sum(ISNULL(Price,0)*ISNULL(Quantity,0)) 'DispatchValue' 
	        from WARD_INV_Transaction txn
			where TransactionType = 'dispatched-items' 
                  and Convert(Date, TransactionDate) between ISNULL(@FromDate, Convert(Date, GETDATE())) AND ISNULL(@ToDate, Convert(DATE, GETDATE())) 
				  and txn.StoreId IN (Select StoreId from @StoreIdTbl)
			group by ItemId
			) dis 
			on itm.ItemId = dis.ItemId

     left join ( Select ItemId, Sum(Quantity) 'ConsumptionQuantity', Sum(ISNULL(Price,0)*ISNULL(Quantity,0)) 'ConsumptionValue' 
	      from WARD_INV_Transaction  txn
		  where TransactionType = 'consumption-items' 
		        and Convert(Date, TransactionDate) between ISNULL(@FromDate, Convert(Date, GETDATE())) AND ISNULL(@ToDate, Convert(DATE, GETDATE())) 
		       and txn.StoreId IN (Select StoreId from @StoreIdTbl)
		  group by ItemId )con 
		  on itm.ItemId = con.ItemId
   
     where (
	  ISNULL(dis.DispatchQuantity,0) !=0 
	  OR ISNULL(con.ConsumptionQuantity,0) !=0 
	)

    ORDER BY sub.SubCategoryName, itm.ItemName 

 END