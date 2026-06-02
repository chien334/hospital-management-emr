-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_LAB_GetLatestBarCodeNumber]
AS
BEGIN
select COALESCE(MAX(BarCodeNumber)+1,1000000) as Value from LAB_BarCode
END