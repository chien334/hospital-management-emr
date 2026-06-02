/* ***********************************************************************
  FileName: [SP_UserWiseHandoverReport]
  exec [SP_TransferHandoverReport] '2022-11-13','2022-12-13','all','all'
  S.No.    UpdatedBy/Date                        Remarks
  1.      Dev Narayan 30'Nov'22               SP Script created for Transfer Handover Report
  ************************************************************************ */
CREATE PROCEDURE [dbo].[SP_TransferHandoverReport] @FromDate DATETIME
	,@ToDate DATETIME
	,@Status VARCHAR(100)
	,@HandoverType VARCHAR(100)
AS
BEGIN
	SELECT handover.CreatedOn AS 'HandoverDate'
		,transferer.FullName AS 'HandoverBy'
		,handover.HandoverAmount AS 'Amount'
		,receiver.FullName AS 'ReceivedBy'
		,handover.HandoverStatus AS 'Status'
		,handover.ReceivedOn AS 'ReceivedDate'
		,handover.HandoverRemarks AS 'HandoverRemark'
		,handover.ReceiveRemarks AS 'ReceiveRemark'
		,handover.HandoverType
	FROM BIL_TXN_CashHandover handover
	JOIN EMP_Employee transferer ON handover.HandoverByEmpId = transferer.EmployeeId
	LEFT JOIN EMP_Employee receiver ON handover.ReceivedById = receiver.EmployeeId
	WHERE CONVERT(DATE, handover.CreatedOn) BETWEEN CONVERT(DATE, @FromDate)
			AND CONVERT(DATE, @ToDate)
		AND (
			@Status = 'all'
			OR handover.HandoverStatus = @Status
			)
		AND (
			@HandoverType = 'all'
			OR handover.HandoverType = @HandoverType
			)
END