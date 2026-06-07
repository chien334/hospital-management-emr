CREATE OR REPLACE FUNCTION phrm_rpt_ins_patient_bima(
    p_fromdate DATE,
    p_todate DATE,
    p_counterid INT DEFAULT NULL,
    p_userid INT DEFAULT NULL,
    p_claimcode VARCHAR DEFAULT NULL,
    p_nshinumber VARCHAR DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
BEGIN
    -- =============================================
    -- author:    sanjit
    -- create date: 18/06/2021
    -- description: generated insurance patient bima report
    -- example to execute the stored procedure we just created
    -- execute phrm_rpt_ins_patient_bima '2021-06-15','2022-07-15',null,null,'',''
    -- =============================================
    /* change history
    s.no.    updatedby/date                        remarks
    1.    sanjit/sud/2021-08-10    checked for insurance store
    2.    sud/sanjit: 5sept'21     Convert TIMESTAMP to Date Comparison on Invoice>CreteOn 
    */
    
        -- body of the stored procedure
        OPEN ref1 FOR SELECT (I.CreateOn)::Date AS "Date", I.InvoiceId, I.InvoicePrintId, PAT.PatientCode AS "HospitalNo", 
    		PAT.ShortName AS "PatientName", PAT.ShortName, 
    		PAT.Ins_NshiNumber, 
    		I.ClaimCode, 
    		I.SubTotal, 
    		I.TotalAmount, 
    		E.FullName AS "CreatedByName", 
    		C.CounterName
        FROM PHRM_TXN_Invoice I
            JOIN PAT_Patient PAT ON I.PatientId = PAT.PatientId
            JOIN EMP_Employee E ON I.CreatedBy = E.EmployeeId
            JOIN PHRM_MST_Counter C ON I.CounterId = C.CounterId
            JOIN PHRM_MST_Store STORE ON I.StoreId = STORE.StoreId
        WHERE I.ClaimCode IS NOT NULL AND I.PatientId > 0 -- INSURANCE PATIENT FILTER
            AND (I.CreateOn)::Date BETWEEN p_fromdate AND p_todate
            AND (I.CounterId = p_counterid OR COALESCE(p_counterid,0)=0)
            AND (I.CreatedBy = p_userid OR COALESCE(p_userid,0)=0)
            AND (I.ClaimCode = p_claimcode OR COALESCE(p_claimcode,'') = '')
            AND (PAT.Ins_NshiNumber = p_nshinumber OR COALESCE(p_nshinumber,'') = '')
            AND STORE.SubCategory = 'insurance';
        return next ref1;
END;
$$ LANGUAGE plpgsql;