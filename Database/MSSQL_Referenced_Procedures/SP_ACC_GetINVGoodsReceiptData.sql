Create Proc  [dbo].[SP_ACC_GetINVGoodsReceiptData]
As
/*
FileName: [[SP_ACC_GetINVGoodsReceiptData]]
CreatedBy/date: NageshBB/2018 July 03
Description:GEt all inventory goods receipt records group by date for transfer to accounting
Remarks:    
Change History
S.No.    CreatedBy/UpdatedBy/Date                        Remarks
1       NageshBB/2018 July 03							created the script
*/
Begin

select Round(sum(gri.TotalAmount-gri.VATAmount),2) as TotalAmount
,sum(gri.VATAmount)as VAT
,convert(date,gri.CreatedOn) as CreatedOn,
'Inventory Goods Receipt entries to accounting on '+convert(varchar(100),convert(date,gri.CreatedOn)) as Remarks
,STUFF((SELECT ',' + convert(varchar(100),GoodsReceiptId)        
       FROM   dbo.INV_TXN_GoodsReceipt AS g
       WHERE (convert(date, gri.CreatedOn)= convert(date,g.CreatedOn))           
       FOR XML PATH('')), 1, 1, '') as ReferenceIds
 from INV_TXN_GoodsReceipt gr
join INV_TXN_GoodsReceiptItems gri
on gr.GoodsReceiptID=gri.GoodsReceiptId
where gr.istransferredToACC !=1 or gr.istransferredToACC is null
group by convert(date,gri.CreatedOn)
End