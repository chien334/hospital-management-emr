/****** Object:  StoredProcedure [dbo].[SP_Danphe_Audit_List]    Script Date: 28-01-2019 17:52:57 ******/

CREATE PROCEDURE [dbo].[SP_Danphe_Audit_List]
AS

 /*
Change History
S.No.    UpdatedBy/Date					Remarks
1.		Rajesh/28Jan'19			     Created 

*/

begin
select  distinct Table_Name From dbo.[Fn_Danphe_Audit]() 
end