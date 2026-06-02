CREATE PROCEDURE [dbo].[PHRM_RPT_INS_PATIENT_BIMA]
    @FromDate DATE,
    @ToDate DATE,
    @CounterId INT = NULL,
    @UserId INT = NULL,
    @ClaimCode NVARCHAR(100) = '',
    @NSHINumber NVARCHAR(100) = ''
AS
-- =============================================
-- Author:    Sanjit
-- Create date: 18/06/2021
-- Description: generated insurance patient bima report
-- example to execute the stored procedure we just created
-- EXECUTE dbo.PHRM_RPT_INS_PATIENT_BIMA '2021-06-15','2022-07-15',null,null,'',''
-- =============================================
/* Change History
S.No.    UpdatedBy/Date                        Remarks
1.    sanjit/sud/2021-08-10    checked for insurance store
2.    Sud/Sanjit: 5Sept'21     Convert DateTime to Date Comparison on Invoice>CreteOn 
*/
BEGIN
    -- body of the stored procedure
    SELECT Convert(Date, I.CreateOn) 'Date', I.InvoiceId, I.InvoicePrintId, PAT.PatientCode 'HospitalNo', 
		PAT.ShortName 'PatientName', PAT.ShortName, 
		PAT.Ins_NshiNumber, 
		I.ClaimCode, 
		I.SubTotal, 
		I.TotalAmount, 
		E.FullName 'CreatedByName', 
		C.CounterName
    FROM PHRM_TXN_Invoice I
        JOIN PAT_Patient PAT ON I.PatientId = PAT.PatientId
        JOIN EMP_Employee E ON I.CreatedBy = E.EmployeeId
        JOIN PHRM_MST_Counter C ON I.CounterId = C.CounterId
        JOIN PHRM_MST_Store STORE ON I.StoreId = STORE.StoreId
    WHERE I.ClaimCode IS NOT NULL AND I.PatientId > 0 -- INSURANCE PATIENT FILTER
        AND COnvert(Date, I.CreateOn) BETWEEN @FromDate AND @ToDate
        AND (I.CounterId = @CounterId OR ISNULL(@CounterId,0)=0)
        AND (I.CreatedBy = @UserId OR ISNULL(@UserId,0)=0)
        AND (I.ClaimCode = @ClaimCode OR ISNULL(@ClaimCode,'') = '')
        AND (PAT.Ins_NshiNumber = @NSHINumber OR ISNULL(@NSHINumber,'') = '')
        AND STORE.SubCategory = 'insurance'
END