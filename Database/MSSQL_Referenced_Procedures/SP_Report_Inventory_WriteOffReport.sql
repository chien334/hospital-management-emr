CREATE PROCEDURE [dbo].[SP_Report_Inventory_WriteOffReport] 
		@ItemId int = 0 
AS
/*
Change History
S.No.	UpdatedBy/Date			Remarks
1.		Rusha/ 05-29-2019					Created Script for writeoff report
*/
BEGIN
		If(@ItemId > 0)
			BEGIN
				SELECT witm.WriteOffDate,itm.ItemName, witm.BatchNO, witm.WriteOffQuantity,witm.ItemRate,witm.TotalAmount, 			
				unit.UOMName,Itm.Code,
				CONCAT_WS(' ',emp.FirstName,emp.MiddleName,emp.LastName) AS RequestedBy,witm.Remark 
				FROM INV_TXN_WriteOffItems AS witm
				JOIN INV_MST_Item AS itm ON itm.ItemId = witm.ItemId
				JOIN EMP_Employee AS emp ON emp.EmployeeId = witm.CreatedBy
				left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
				WHERE witm.ItemId = @ItemId
			END
        ELSE 
		    BEGIN
				SELECT witm.WriteOffDate,itm.ItemName, witm.BatchNO, witm.WriteOffQuantity,witm.ItemRate,witm.TotalAmount, 
				unit.UOMName,Itm.Code,
				CONCAT_WS(' ',emp.FirstName,emp.MiddleName,emp.LastName) AS RequestedBy,witm.Remark 
				FROM INV_TXN_WriteOffItems AS witm
				JOIN INV_MST_Item AS itm ON itm.ItemId = witm.ItemId
				JOIN EMP_Employee AS emp ON emp.EmployeeId = witm.CreatedBy
				left join INV_MST_UnitOfMeasurement unit on itm.UnitOfMeasurementId = unit.UOMId
			END 
END