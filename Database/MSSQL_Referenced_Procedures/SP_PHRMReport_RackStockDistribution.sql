CREATE PROCEDURE [dbo].[SP_PHRMReport_RackStockDistribution] 
    @rackIds varchar(200) = null,
    @locationId int = null
AS
/*
FileName: [SP_PHRMReport_RackStockDistribution] "1;2",2
CreatedBy/date: Sanjit/2020-06-01
Description: 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1        Sanjit/2020-06-01          created the script
2        Sanjit/2020-06-03          updated the script for store
*/
 BEGIN
    IF((@rackIds IS NOT NULL) AND (@locationId IS NOT NULL))
    BEGIN
      DECLARE @rackIdTable TABLE (
        RackId int
      )
      INSERT INTO @rackIdTable
      SELECT value FROM STRING_SPLIT(@rackIds, ';')
      IF(@locationId = 1)
        BEGIN
          SELECT MR.Name RackName,I.ItemId,I.ItemName,DS.AvailableQuantity,DS.BatchNo, DS.ExpiryDate, DS.Price,(CONVERT( decimal(18,1),DS.AvailableQuantity)*(CONVERT(decimal(18,1),DS.Price))) StockValue, 'Dispensary' Location
          FROM PHRM_DispensaryStock AS DS 
          INNER JOIN PHRM_MST_Item AS I ON DS.ItemId = I.ItemId
          INNER JOIN @rackIdTable AS R ON R.RackId = I.Rack
          INNER JOIN PHRM_MST_Rack AS MR ON MR.RackId = R.RackId
          where DS.AvailableQuantity>0


          SELECT SUM(DS.AvailableQuantity) as 'TotalAvailableQuantity', SUM(CONVERT( decimal(18,1),DS.AvailableQuantity)*(CONVERT(decimal(18,1),DS.Price))) AS 'TotalStockValuation'
          FROM PHRM_DispensaryStock AS DS 
          INNER JOIN PHRM_MST_Item AS I ON DS.ItemId = I.ItemId
          INNER JOIN @rackIdTable AS R ON R.RackId = I.Rack
          where DS.AvailableQuantity>0
        END
      ELSE
        BEGIN
          SELECT  x1.RackName,x1.ItemId,x1.ItemName,SUM(InQty- OutQty+FInQty-FOutQty) AvailableQuantity,x1.BatchNo AS BatchNo, x1.ExpiryDate,Round(x1.Price,2,0) AS Price, (SUM(InQty - OutQty + FInQty - FOutQty) * Round(x1.Price,2,0)) StockValue, 'Store' Location
          FROM(SELECT MR.Name RackName,S.ItemId,S.ItemName, S.BatchNo, S.ExpiryDate, S.Price,
            SUM(CASE WHEN S.InOut = 'in' THEN S.Quantity ELSE 0 END) AS 'InQty',
            SUM(CASE WHEN S.InOut = 'out' THEN S.Quantity ELSE 0 END) AS 'OutQty',
            SUM(CASE WHEN S.InOut = 'in' THEN S.FreeQuantity ELSE 0 END) AS 'FInQty',
            SUM(CASE WHEN S.InOut = 'out' THEN S.FreeQuantity ELSE 0 END) AS 'FOutQty'
          FROM [dbo].[PHRM_StoreStock] AS S
          INNER JOIN PHRM_MST_Item AS I ON I.ItemId = S.ItemId
          INNER JOIN @rackIdTable AS R ON R.RackId = I.StoreRackId
          INNER JOIN PHRM_MST_Rack AS MR ON MR.RackId = R.RackId
          GROUP BY S.ItemName,S.ItemId, S.BatchNo , S.ExpiryDate,S.Price,MR.Name)as x1
          GROUP BY x1.ItemId,x1.ItemName, x1.BatchNo, x1.ExpiryDate, x1.Price,x1.RackName
          HAVING SUM(FInQty + InQty - FOutQty - OutQty) > 0  -- filtering out quantity > 0
          ORDER BY x1.ItemName
		  SELECT SUM(x2.AvailableQuantity) TotalAvailableQuantity,SUM(x2.StockValue)  TotalStockValuation
          FROM 
            (SELECT  x1.RackName,x1.ItemId,x1.ItemName,SUM(InQty- OutQty+FInQty-FOutQty) AvailableQuantity,x1.BatchNo AS BatchNo, x1.ExpiryDate,Round(x1.Price,2,0) AS Price, (SUM(InQty - OutQty + FInQty - FOutQty) * Round(x1.Price,2,0)) StockValue, 'Store' Location
          FROM(SELECT MR.Name RackName,S.ItemId,S.ItemName, S.BatchNo, S.ExpiryDate, S.Price,
            SUM(CASE WHEN S.InOut = 'in' THEN S.Quantity ELSE 0 END) AS 'InQty',
            SUM(CASE WHEN S.InOut = 'out' THEN S.Quantity ELSE 0 END) AS 'OutQty',
            SUM(CASE WHEN S.InOut = 'in' THEN S.FreeQuantity ELSE 0 END) AS 'FInQty',
            SUM(CASE WHEN S.InOut = 'out' THEN S.FreeQuantity ELSE 0 END) AS 'FOutQty'
          FROM [dbo].[PHRM_StoreStock] AS S
          INNER JOIN PHRM_MST_Item AS I ON I.ItemId = S.ItemId
          INNER JOIN @rackIdTable AS R ON R.RackId = I.StoreRackId
          INNER JOIN PHRM_MST_Rack AS MR ON MR.RackId = R.RackId
          GROUP BY S.ItemName,S.ItemId, S.BatchNo , S.ExpiryDate,S.Price,MR.Name)as x1
          GROUP BY x1.ItemId,x1.ItemName, x1.BatchNo, x1.ExpiryDate, x1.Price,x1.RackName
          HAVING SUM(FInQty + InQty - FOutQty - OutQty) > 0  -- filtering out quantity > 0
		  )as x2
        END
    END
  END
RETURN