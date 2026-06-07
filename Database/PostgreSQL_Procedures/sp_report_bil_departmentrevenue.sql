CREATE OR REPLACE FUNCTION sp_report_bil_departmentrevenue(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "DepartmentId" INT,
    "DepartmentName" VARCHAR,
    "ServiceDepartmentId" INT,
    "ServiceDepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "SubTotal" DECIMAL,
    "Discount" INT,
    "Refund" VARCHAR,
    "NetTotal" DECIMAL
) AS $$
BEGIN
    /*  
    change history  
    —------------------------------------------------------—  
    s.no.    updatedby/date						remarks  
    —------------------------------------------------------—  
    1.    nageshbb-ajay/23 jan 2019           created sp  
    2.    krishna/8thjun'22					  changed RquesyedById to PrescriberId
    —------------------------------------------------------—  
    */  
      
    RETURN QUERY SELECT   
    reportData.DepartmentId,  
    d.DepartmentName,  
    sd.ServiceDepartmentId,  
    sd.ServiceDepartmentName,     
    reportData.ItemName,  
    SUM(COALESCE(reportData.SubTotal, 0)) AS "SubTotal",  
    SUM(COALESCE(reportData.DiscountAmount, 0)) AS "Discount",  
    SUM(COALESCE(reportData.ReturnAmount, 0)) AS "Refund",  
    SUM(COALESCE(reportData.TotalAmount, 0) - COALESCE(reportData.ReturnAmount, 0)) AS "NetTotal"  
    FROM   
     (SELECT  
      (CASE  
       WHEN   
        f.BillingType='outpatient' AND bi.PrescriberId IS NULL  
       THEN d.DepartmentId  
       WHEN   
        (f.BillingType='outpatient' OR f.BillingType='inpatient') AND bi.PrescriberId IS NOT NULL  
       THEN (SELECT DepartmentId FROM EMP_Employee WHERE EmployeeId = bi.PrescriberId)  
       WHEN   
        f.BillingType='inpatient' AND bi.PrescriberId IS NULL   
       THEN (SELECT ee.DepartmentId  FROM ADT_PatientAdmission ad  
         JOIN EMP_Employee ee ON ad.AdmittingDoctorId = ee.EmployeeId  
         WHERE PatientVisitId = bi.PatientVisitId AND PatientId = bi.PatientId)  
      END) AS "DepartmentId",  
     f.*  
     FROM FN_BIL_GetTxnItemsInfoWithDateSeparation(p_fromdate, p_todate) f  
     JOIN BIL_TXN_BillingTransactionItems bi ON f.BillingTransactionItemId = bi.BillingTransactionItemId  
     JOIN BIL_MST_ServiceDepartment sd ON sd.ServiceDepartmentId = f.ServiceDepartmentId  
     JOIN MST_Department d  ON d.DepartmentId = sd.DepartmentId) AS reportData  
    JOIN BIL_MST_ServiceDepartment sd ON reportData.ServiceDepartmentId=sd.ServiceDepartmentId  
    JOIN MST_Department d ON reportData.DepartmentId=d.DepartmentId  
    WHERE reportData.BillStatus != 'cancelled'   
          AND reportData.BillStatus != 'provisional'  
          AND (reportData.PaymentMode != 'credit' or reportdata.creditdate is not null)  
        group by   
        reportdata.departmentid,  
        d.departmentname,  
        sd.servicedepartmentid,  
        sd.servicedepartmentname,    
        reportdata.itemname  
      
      order by 2;
END;
$$ LANGUAGE plpgsql;