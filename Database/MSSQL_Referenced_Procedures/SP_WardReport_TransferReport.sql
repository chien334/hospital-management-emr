CREATE PROCEDURE [dbo].[SP_WardReport_TransferReport]  		
	@FromDate datetime=null,
	@ToDate datetime=null,
	@StoreId int = null
	--@Status int = null					--Ward to Ward report is shown in case of 1 and Ward to Pharmacy report in case of 0	
AS
/*
FileName: [SP_WardReport_TransferReport] '1/7/2020','1/8/2020',13
CreatedBy/date: Rusha/03-26-2019
Description: To get the Details of report of Ward to Ward Tranfer and Ward to Pharmacy Trannsfer of stock 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.		Rusha/03-29-2019						shows report of Ward to ward transfer and ward to pharmacy transfer
2.		Sanjit/01-09-2020						added Received by field in both transfer cases.
3.		Sanjit/05-22-2020						corrected Date format
*/

BEGIN
  IF ((@FromDate IS NOT NULL) and (@ToDate IS NOT NULL)) 
		BEGIN
		--if (@Status = 1)
			--select convert(date,transc.CreatedOn) as [Date],ItemName, transc.Quantity as TransferQty, Remarks,transc.CreatedBy as 'TransferedBy',transc.ReceivedBy as 'ReceivedBy' from WARD_Transaction as transc
			--join PHRM_MST_Item as itm on transc.ItemId=itm.ItemId
			--where TransactionType = 'WardtoWard' and CONVERT(date, transc.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
			--group by itm.ItemName, transc.Quantity,transc.Remarks, convert(date,transc.CreatedOn),transc.CreatedBy,transc.ReceivedBy
		
		--else if (@Status =0)
			(select convert(varchar,transc.CreatedOn) as [Date],ItemName, transc.Quantity as TransferQty,transc.Remarks,transc.CreatedBy as 'TransferedBy',transc.ReceivedBy as 'ReceivedBy' 
			from WARD_Transaction as transc
			join PHRM_MST_Item as itm on transc.ItemId=itm.ItemId
			where transc.StoreId = @StoreId and TransactionType = 'WardToPharmacy' and CONVERT(date, transc.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
			group by itm.ItemName, transc.Quantity,transc.Remarks,transc.CreatedOn,transc.CreatedBy,transc.ReceivedBy
			)

		--else
			--select convert(date,transc.CreatedOn) as [Date],ItemName, transc.Quantity as TransferQty, Remarks,transc.CreatedBy as 'TransferedBy',transc.ReceivedBy as 'ReceivedBy' from WARD_Transaction as transc
			--join PHRM_MST_Item as itm on transc.ItemId=itm.ItemId
			--where TransactionType in ('WardToPharmacy','WardtoWard') and CONVERT(date, transc.CreatedOn) BETWEEN ISNULL(@FromDate,GETDATE())  AND ISNULL(@ToDate,GETDATE())+1
			--group by itm.ItemName, transc.Quantity,transc.Remarks, convert(date,transc.CreatedOn),transc.CreatedBy,transc.ReceivedBy
		END	
END