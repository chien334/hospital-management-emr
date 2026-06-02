CREATE PROCEDURE [dbo].[SP_Report_Inventory_ReturnToVendorReport] 
		@VendorId int = 0 
AS

/*
Change History
S.No.	UpdatedBy/Date			Remarks
1.		Rusha/ 05-29-2019					Created Script for Return to Vendor Report
*/

BEGIN
		If(@VendorId > 0)
			BEGIN
				SELECT rtn.CreatedOn,ven.VendorName,rtn.CreditNoteNo,itm.ItemName, rtn.Quantity,rtn.ItemRate,rtn.TotalAmount,
				rtn.Remark,CONCAT_WS(' ',emp.FirstName,emp.MiddleName,emp.LastName) AS ReturnedBy,
				unit.UOMName,itm.Code
				FROM INV_TXN_ReturnToVendorItems AS rtn
				JOIN INV_MST_Vendor AS ven ON ven.VendorId = rtn.VendorId
				JOIN EMP_Employee AS emp ON emp.EmployeeId = rtn.CreatedBy
				JOIN INV_MST_Item AS itm ON itm.ItemId = rtn.ItemId
				left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
				WHERE rtn.VendorId = @VendorId
			END
        ELSE 
		    BEGIN
				SELECT rtn.CreatedOn,ven.VendorName,rtn.CreditNoteNo,itm.ItemName, rtn.Quantity,rtn.ItemRate,rtn.TotalAmount,
				rtn.Remark,CONCAT_WS(' ',emp.FirstName,emp.MiddleName,emp.LastName) AS ReturnedBy,
				unit.UOMName,itm.Code
				FROM INV_TXN_ReturnToVendorItems AS rtn
				JOIN INV_MST_Vendor AS ven ON ven.VendorId = rtn.VendorId
				JOIN EMP_Employee AS emp ON emp.EmployeeId = rtn.CreatedBy
				JOIN INV_MST_Item AS itm ON itm.ItemId = rtn.ItemId
				left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
			END 
END