CREATE OR REPLACE FUNCTION sp_report_bil_doctorreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_performername VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "Doctor" VARCHAR,
    "HospitalNo" VARCHAR,
    "PatientName" VARCHAR,
    "Department" VARCHAR,
    "Item" VARCHAR,
    "Rate" DECIMAL,
    "Quantity" INT,
    "SubTotal" DECIMAL,
    "Discount" INT,
    "Total" DECIMAL,
    "ReturnAmount" DECIMAL,
    "CancelTotal" DECIMAL,
    "NetAmount" DECIMAL
) AS $$
BEGIN
    /*  
    filename: "sp_report_bil_doctorreport"  
    createdby/date: nagesh/2017-05-25  
    description: to get count of appointments per department between given dates.  
    remarks:      
    change history  
    s.no.    updatedby/date                        remarks  
    1       nagesh/2017-05-25                      created the script  
    2       umed / 2017-06-14                        modify the script i.e format   
                                                     and remove time from paid date    
    3.      dinesh/ 2017-08-04				modified the script and maintained the return as well as cancel status   
    4       umed/2018-04-17                         added order by date in desc order  
    5.  ramavtar/2018-05-31						correction in where condition   
    										(providername didnt had space in between first & last name)  
    6.  ramavtar/2018-08-17					changed the sp,now getting txn values from function 'FN_BIL_GetTxnItemsInfoWithDateSeparation' 
    7.	krishna/9thjun'22					changed ProviderId to PerformerId and ProviderName to PerformerName
    */  
    BEGIN  
        IF (p_fromdate IS NOT NULL)  
            OR (p_todate IS NOT NULL)  
            OR (p_performername IS NOT NULL)  
            OR (LEN(p_performername) > 0)  
        THEN  
            RETURN QUERY SELECT  
                COALESCE(fnItm.ReturnDate, fnItm.CreditDate, fnItm.PaidDate, fnItm.CancelledDate, fnItm.ProvisionalDate) AS "Date",  
                COALESCE(fnItm.PerformerName, 'nodoctor') AS "Doctor",  
                p.PatientCode AS "HospitalNo",  
                p.FirstName || COALESCE(p.MiddleName || ' ', '') || p.LastName AS "PatientName",  
                fnItm.ServiceDepartmentName AS "Department",  
                fnItm.ItemName AS "Item",  
                COALESCE(vmItm.Price, 0) AS "Rate",  
                COALESCE(vmItm.Quantity, 0) AS "Quantity",  
                fnItm.SubTotal AS "SubTotal",  
                fnItm.DiscountAmount AS "Discount",  
                fnItm.TotalAmount AS "Total",  
                fnItm.ReturnAmount AS "ReturnAmount",  
                fnItm.CancelledAmount AS "CancelTotal",  
                COALESCE(fnItm.TotalAmount, 0) - COALESCE(fnItm.CancelledAmount, 0) - COALESCE(fnItm.ReturnAmount, 0) AS "NetAmount"  
            FROM FN_BIL_GetTxnItemsInfoWithDateSeparation(p_fromdate, p_todate) fnItm  
            JOIN VW_BIL_TxnItemsInfoWithDateSeparation vmItm  
                ON fnItm.BillingTransactionItemId = vmItm.BillingTransactionItemId  
            JOIN PAT_Patient p  
                ON fnItm.PatientId = p.PatientId  
            WHERE fnItm.PerformerName LIKE '%' || COALESCE(p_performername, '') || '%'  
            order by coalesce(fnitm.returndate, fnitm.creditdate, fnitm.paiddate, fnitm.cancelleddate, fnitm.provisionaldate) desc;  
        end if;  
    end;
END;
$$ LANGUAGE plpgsql;