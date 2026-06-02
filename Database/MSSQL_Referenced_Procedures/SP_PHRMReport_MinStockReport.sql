CREATE PROCEDURE [dbo].[SP_PHRMReport_MinStockReport]  
@ItemName varchar(200) = null
AS
/*
FileName: [SP_PHRMReport_MinStockReport]
CreatedBy/date: vikas/2018-08-21
Description: 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
	1.	Vikas/28Aug'18						created the script
	2.	Rusha/04-01-2019					sum up quantity
	3.	Rusha/07-08-2019					updated script
	4.	Naveed/13-12-2019				    updated script for exclude zero quantity Items
*/
Begin 
IF (@ItemName IS NOT NULL)
	BEGIN

	SELECT * FROM
	(
		SELECT a.ItemId ,a.ItemName, SUM(InQty-OutQty+FInQty-FOutQty) as Quantity,convert(date,a.ExpiryDate) AS ExpiryDate,
		a.BatchNo,a.MinStockQuantity 
		FROM 
			(SELECT itm.ItemId ,itm.ItemName,itm.MinStockQuantity,convert(date,stk.ExpiryDate)as ExpiryDate,stk.BatchNo,
					SUM(CASE WHEN stk.InOut = 'in' THEN stk.Quantity ELSE 0 END) AS 'InQty',
					SUM(CASE WHEN stk.InOut = 'out' THEN stk.Quantity ELSE 0 END) AS 'OutQty',
					SUM(CASE WHEN stk.InOut = 'in' THEN stk.FreeQuantity ELSE 0 END) AS 'FInQty',
					SUM(CASE WHEN stk.InOut = 'out' THEN stk.FreeQuantity ELSE 0 END) AS 'FOutQty'
			FROM  PHRM_StockTxnItems stk
			JOIN  PHRM_MST_Item itm
			ON stk.ItemId=itm.ItemId
			WHERE itm.MinStockQuantity != 0 
			GROUP BY itm.ItemId ,itm.ItemName,convert(date,stk.ExpiryDate),stk.BatchNo,itm.MinStockQuantity) a
		WHERE (((@ItemName=a.ItemName OR @ItemName='') or a.ItemName like '%'+ISNULL(@ItemName,'')+'%' )) 
		GROUP BY a.ItemId,a.ItemName,a.BatchNo,a.ExpiryDate,a.MinStockQuantity
	) s		
	WHERE s.Quantity < s.MinStockQuantity and s.Quantity>0
	GROUP BY s.ItemId, s.ItemName,s.Quantity,s.ExpiryDate,s.BatchNo,s.MinStockQuantity

	END
END