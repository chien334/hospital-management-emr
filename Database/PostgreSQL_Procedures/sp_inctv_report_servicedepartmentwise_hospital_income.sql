CREATE OR REPLACE FUNCTION sp_inctv_report_servicedepartmentwise_hospital_income(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_servicedepartmentid INT DEFAULT NULL
)
RETURNS TABLE (
    "IncentiveReceiverName" VARCHAR,
    "TransactionDate" TIMESTAMP,
    "InvoiceNoFormatted" VARCHAR,
    "IncomeType" VARCHAR,
    "PatientId" INT,
    "PatientName" VARCHAR,
    "HospitalNum" VARCHAR,
    "ItemName" VARCHAR,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL,
    "IncentiveAmount" DECIMAL,
    "TDSAmount" DECIMAL,
    "NetPayableAmt" VARCHAR,
    "InctvTxnItemId" INT,
    "IsPaymentProcessed" BOOLEAN,
    "PriceCategoryId" INT,
    "PriceCategoryName" DECIMAL
) AS $$
BEGIN
    /*    
    author: krishna,8th,july'22 
    Description: To get Incentive reports at items level for servide department.    
    Change History-----    
    S.No. Date/Author				Remarks    
    1.   Krishna,8th,July'22		initial draft   
    2.	 krisihna,22ndsept'23		Read PriceCategory
    
    */    
        
     RETURN QUERY SELECT emp.FullName AS "IncentiveReceiverName",  
      incItm.TransactionDate,   
      incItm.InvoiceNoFormatted,   
      incItm.IncentiveType AS "IncomeType",   
      incItm.PatientId,   
      pat.FirstName||' '||pat.LastName AS "PatientName",  
      pat.PatientCode AS "HospitalNum",   
      incItm.ItemName,  
       txnitm.SubTotal,
     txnitm.DiscountAmount,
     incItm.TotalBillAmount AS "TotalAmount",   
     incItm.IncentiveAmount,       
      --Here TDS Percent is hard-coded, we need to add them to Fractionitem table and calculate from there, not from here--sud: 12Feb'20    
      incitm.tdsamount AS "TDSAmount",   
      incitm.incentiveamount - incitm.tdsamount AS "NetPayableAmt",   
      incitm.inctvtxnitemid,  
      incitm.ispaymentprocessed,
      pricecat.pricecategoryid,
      pricecat.pricecategoryname  
        
     from inctv_txn_incentivefractionitem incitm    
     inner join pat_patient pat    
     on incitm.patientid=pat.patientid    
     inner join emp_employee emp    
     on incitm.incentivereceiverid=emp.employeeid    
     inner join bil_txn_billingtransactionitems txnitm    
     on incitm.billingtransactionitemid = txnitm.billingtransactionitemid  
     inner join bil_cfg_pricecategory pricecat on txnitm.pricecategoryid = pricecat.pricecategoryid
        
     where    
      servicedepartmentid = p_servicedepartmentid    
      and coalesce(incitm.isactive,0)=1    
      and (incitm.transactiondate)::date between p_fromdate and p_todate;
END;
$$ LANGUAGE plpgsql;