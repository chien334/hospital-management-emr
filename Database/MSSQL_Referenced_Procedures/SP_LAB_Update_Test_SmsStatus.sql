-- =============================================
-- Author:		<Anjana Sharma>
-- Create date: <26th April, 2021>
-- Description:	<Update IsSmsSend column in Lab_TestRequisition table>
-- =============================================
CREATE PROCEDURE [dbo].[SP_LAB_Update_Test_SmsStatus]  
	@RequistionIds NVARCHAR(max) = '' 
AS
BEGIN
	DECLARE @ReqIdTbl Table(RequisitionId int)
	Insert into @ReqIdTbl
	SELECT value FROM STRING_SPLIT(@RequistionIds, ',') WHERE RTRIM(value) <> ''

	Update LAB_TestRequisition
	set IsSmsSend = 1
	where RequisitionId IN (Select RequisitionId from @ReqIdTbl)
	
END