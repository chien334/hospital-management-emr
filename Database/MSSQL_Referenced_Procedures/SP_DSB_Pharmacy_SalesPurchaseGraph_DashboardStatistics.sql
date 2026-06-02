CREATE PROCEDURE [dbo].[SP_DSB_Pharmacy_SalesPurchaseGraph_DashboardStatistics]  
         @FromDate DateTime=null,
	     @ToDate DateTime=null,
		 @Status varchar(100),
		 @ItemIdCommaSeprated varchar(100)
AS


BEGIN
DECLARE @DynamicPivotQuery AS NVARCHAR(MAX),
		@PivotColumnNames AS NVARCHAR(MAX),
		@PivotSelectColumnNames AS NVARCHAR(MAX)


CREATE TABLE #TempTable(
 ItemId int,
 ItemName varchar(200))
 
 Insert into #TempTable  (ItemId , ItemName )
  SELECT ItemId, ItemName
      FROM PHRM_MST_Item
      WHERE ItemId IN(
	         SELECT Item
            FROM dbo.SplitString(@ItemIdCommaSeprated, ',')
      )



--If Status is Sales then this SQL -----
if (@Status != 'sales')
    BEGIN
	             SELECT @PivotColumnNames= ISNULL(@PivotColumnNames + ',','')
					+ QUOTENAME(ItemName)
					FROM ( 
					      Select DISTINCT ItemName from #TempTable
						 )   AS dep
				 
					 SELECT 'Date'+ISNULL(','+REPLACE(REPLACE(@PivotColumnNames,'[',''),']',''),'') as ColumnName

					SET @DynamicPivotQuery = N'SELECT [Date], ' + @PivotColumnNames + '
							FROM (
									  SELECT convert(date,grItm.CreatedOn) as [Date], itm.ItemName, ISNULL(grItm.ReceivedQuantity,0) as Qty       
									  FROM PHRM_GoodsReceipt gr           
									      Inner join PHRM_GoodsReceiptItems grItm on gr.GoodReceiptId = grItm.GoodReceiptId       
										  Inner Join PHRM_MST_Item itm on grItm.ItemId = itm.ItemId
										  WHERE convert(date,grItm.CreatedOn) 
										  BETWEEN  CONVERT(Datetime,'''+ Convert(varchar(20),ISNULL(@FromDate,GETDATE()))  + ''') and CONVERT(DATETIME,'''+Convert(varchar(20),ISNULL(@ToDate,GETDATE()))+''')+1
								) A
							PIVOT(sum(Qty) for ItemName in (' + @PivotColumnNames + ')) as pvt';


					EXEC SP_executesql @DynamicPivotQuery

    END

Else 
	   BEGIN
                  SELECT @PivotColumnNames= ISNULL(@PivotColumnNames + ',','')
					+ QUOTENAME(ItemName)
					FROM ( 
					      Select DISTINCT ItemName from #TempTable
						)   AS dep
				 
					 SELECT 'Date'+ISNULL(','+REPLACE(REPLACE(@PivotColumnNames,'[',''),']',''),'') as ColumnName

					SET @DynamicPivotQuery = N'SELECT [Date], ' + @PivotColumnNames + '
							FROM (
									 SELECT  convert(date,txInvItm.CreatedOn) as [Date], itm.ItemName 
				                            , txInvItm.Quantity as Qty         
									  FROM PHRM_TXN_Invoice txInv  
			                          Inner join PHRM_TXN_InvoiceItems txInvItm on txInv.InvoiceId = txInvItm.InvoiceId
			                          Inner Join PHRM_MST_Item itm on txInvItm.ItemId = itm.ItemId 
									   where convert(date,txInvItm.CreatedOn) 
										  BETWEEN  CONVERT(Datetime,'''+ Convert(varchar(20),ISNULL(@FromDate,GETDATE()))  + ''') and CONVERT(DATETIME,'''+Convert(varchar(20),ISNULL(@ToDate,GETDATE()))+''')+1
										        and txInv.BilStatus = ''paid''
								) A
							PIVOT(sum(Qty) for ItemName in (' + @PivotColumnNames + ')) as pvt';


					EXEC SP_executesql @DynamicPivotQuery

	   END

drop table #TempTable

END