/****** Object:  StoredProcedure [dbo].[SP_Dsf_Audit]    Script Date: 28-01-2019 17:16:46 ******/

 CREATE PROCEDURE [dbo].[SP_Dsf_Audit]
  @FromDate datetime=null ,
		@ToDate datetime=null,
		@Table_Name varchar(100) = null,
		@UserName varchar(100)= null
AS
/*
Change History
S.No.    UpdatedBy/Date					Remarks
1.		Rajesh/23Jan'19			     Created 
2.      Rajesh/28Jan'19				 Updated    
*/

--IF (@FromDate IS NOT NULL) OR (@ToDate IS NOT NULL) or (@Table_Name IS NOT NULL) or (@UserName IS NOT NULL)
begin
SELECT *
FROM [DsfAdmin].[dbo].[Fn_Dsf_Audit]() tbl1
    INNER JOIN [AuditTrail_DsfEMR].[dbo].[RBAC_User] tbl2
	on tbl1.ChangedByUserName = tbl2.UserName
	WHERE (  
        CONVERT(DATE,tbl1.InsertedDate) BETWEEN CONVERT(DATE,@FromDate) 
     AND CONVERT(DATE,@ToDate) 
   and tbl1.Table_Name = @Table_Name and tbl2.UserName = @UserName ) 	        
end