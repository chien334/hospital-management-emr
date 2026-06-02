CREATE PROCEDURE [dbo].[SP_PHRMReport_SupplierInfoReport]  
	
AS
/*
FileName: [SP_PHRMReport_SupplierInfoReport]
CreatedBy/date: Umed/2018-02-16
Description: To get the Each Supplier Information 
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Umed/2018-02-16	                     created the script
2       Rohit/2021-09-29                     Pin column renamed as PANNumber

*/

BEGIN
    
	 Select SupplierName, ContactNo, City, PANNumber , ContactAddress, Email 
	  From  [dbo].[PHRM_MST_Supplier]
End