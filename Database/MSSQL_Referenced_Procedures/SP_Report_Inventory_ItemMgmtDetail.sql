-- =============================================
-- Author:		<Sanjesh>
-- Create date: <14/02/20>
-- Description:	<To get the item management detail report>
-- =============================================
CREATE PROCEDURE [dbo].[SP_Report_Inventory_ItemMgmtDetail] 
	
AS
BEGIN
    BEGIN
	
	select 	
	 itm.ItemName,
	 usr.UserName AS CreatedBy,
	 itm.CreatedOn,
	 usr1.UserName As ModifiedBy,
	 itm.ModifiedOn  
	 from INV_MST_Item itm
	left join  RBAC_User usr on itm.CreatedBy= usr.UserId
	left join  RBAC_User usr1 on itm.ModifiedBy = usr1.UserId
   END
END