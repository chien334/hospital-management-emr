CREATE PROCEDURE [dbo].[SP_INVReport_SupplierInfoReport]   
	
AS
/*
FileName: [SP_INVReport_SupplierInfoReport] 
CreatedBy/date: Avanti/2021-10-10
Description: To get the Each Supplier Information 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Avanti/2021-10-10	                     created the script

*/

BEGIN
    
	 Select 
	 VendorName,
	 ContactNo, 
	 ContactAddress,
	 CASE WHEN PanNo= 'NULL' THEN '' ELSE PanNo END
	 PanNo,
	 Email 
	  From  [dbo].[INV_MST_Vendor]
End