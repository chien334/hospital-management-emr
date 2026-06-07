CREATE OR REPLACE FUNCTION sp_phrm_userwisecollectionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_counterid VARCHAR DEFAULT NULL,
    p_createdby VARCHAR DEFAULT NULL,
    p_storeid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
BEGIN
    /*
     sp_phrm_userwisecollectionreport '2020-04-01','2022-01-01','1','admin',22
    filename: "[sp_phrm_userwisecollectionreport"]
    createdby/date: nagesh/vikas/2018-07-31
    description: .
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1      nagesh/vikas/2018-07-31                       created the script
    2      abhishek/2018-08-06           return and netamount calculation
    3     salakha/2019-08-26          billing type wise calculation 
    4.     dinesh /abhishek 2nd sept 2019    counter corrected for pharmacy 
    5.      shankar 23rd march 2020             included deposit deduct and deposit refund
    6.    sanjit/ramesh 12 april 2021      added storeid as parameter for filtering by dispensary
    7.      sanjit/16jun2021                    added storename to show in grid
    8:      ramesh/rohit 12dec'21               New Fxn added for Summary View, Case changed for Settlement Details ie Newly SP Changes for User Collection Report
    9.    Rohit/14th Jan'22          passed new parameter 'CreatedBy' in fn_phrm_getusercollectionsummaryindaterange
    10.    rohit/31th may'22          Added Employee Cash Transaction Details.
    */
     BEGIN
        IF ((p_fromdate IS NOT NULL) AND (p_todate IS NOT NULL)) 
        THEN
            OPEN ref1 FOR SELECT
                bills.Date,
                bills.InvoiceNo AS "ReceiptNo",
                pat.PatientCode AS "HospitalNo",
                pat.FirstName || COALESCE(' ' || pat.MiddleName, '') || ' ' || pat.LastName AS PatientName,
                bills.TransactionType AS "TransactionType",
                bills.SubTotal,
                bills.DiscountAmount,
                bills.VATAmount,
                bills.TotalAmount,
                bills.CashCollection,
                bills.DepositReceived,
                bills.DepositRefund,
                bills.DepositDeduct,
                bills.CreditReceived,
                bills.CreditAmount,
                bills.CounterId,
                cntr.CounterName,
                bills.StoreId,
                str.Name AS "StoreName",
                bills."EmployeeId",
                bills.Remarks,
                emp.FirstName || COALESCE(' ' || emp.MiddleName, '') || ' ' || emp.LastName AS CreatedBy
            FROM ( 
    
                              SELECT *
                    FROM FN_PHRM_PharmacyTxn_ByBillingType_UserCollection(p_fromdate,p_todate,p_storeid)
    
                UNION ALL
    
                    --All Deposits Transactions---
                    SELECT (CreatedOn)::Date AS "Date",
                        'dr'|| (COALESCE(ReceiptNo,''))::VARCHAR AS "InvoiceNo",
                        Patientid,
                        0 AS "InvoiceId",
                        CASE WHEN DepositType='deposit' THEN 'advancereceived' 
                    WHEN DepositType='depositdeduct' OR DepositType='depositreturn' THEN 'advancesettled' END AS "TransactionType",
    
                        0 AS SubTotal, 0 AS DiscountAmount, 0 AS VATAmount, 0 AS TotalAmount,
                        CASE WHEN DepositType='deposit' THEN DepositAmount WHEN DepositType='depositdeduct' OR DepositType='depositreturn' THEN (-DepositAmount) END AS "CashCollection",
                        CASE WHEN DepositType='deposit' THEN DepositAmount ELSE 0 END AS "DepositReceived",
                        CASE WHEN  DepositType='depositreturn' THEN DepositAmount ELSE 0 END AS "DepositRefund",
    					CASE WHEN  DepositType='depositdeduct' THEN DepositAmount ELSE 0 END AS "DepositDeduct"
                   , 0 AS CreditReceived, 0 AS "CreditAmount",
                        CounterId AS "CounterId", StoreId, CreatedBy AS "EmployeeId", Remark AS "Remarks", 6 AS DisplaySeq
                    FROM PHRM_Deposit
                    WHERE (StoreId = p_storeid OR p_storeid IS NULL) AND (CreatedOn)::Date BETWEEN p_fromdate AND p_todate  
    
    
          ) bills,
    
                EMP_Employee emp,
                PAT_Patient pat,
                PHRM_MST_Counter cntr,
                PHRM_MST_Store str
            WHERE bills.PatientId = pat.PatientId
                AND emp.EmployeeId = bills.EmployeeId
                AND bills.CounterId = cntr.CounterId
                AND bills.StoreId = str.StoreId
                AND (bills.CounterId LIKE '%' || COALESCE(p_counterid, bills.CounterId) || '%')
                AND (emp.FirstName || COALESCE(' ' || emp.MiddleName, '') || ' ' || emp.LastName LIKE '%' || COALESCE(p_createdby, emp.FirstName || COALESCE(' ' || emp.MiddleName, '') || ' ' || emp.LastName) || '%')
    
            ORDER BY bills.DisplaySeq;
        RETURN NEXT ref1;
    
    
            --Table2: For Settlement Details---
            --Need: CollectionFromReceivable,  CashDiscount and Return Cash Discount in given date range for given counter, user--
            --Getting Total(SUM) for all given criterias-- no need to separate for each user/counters/dates---
            OPEN ref2 FOR SELECT
                --Case When sett.PayableAmount > 0 then PayableAmount - ( DepositDeducted + COALESCE(DiscountAmount,0) + COALESCE(DueAmount,0)) ELSE 0 END AS PaidAmount, 
                --SUM(Case When sett.PayableAmount > 0 then sett.PaidAmount ELSE 0 END) AS "SettlPaidAmount", 
                --SUM( Case WHEN sett.RefundableAmount > 0 THEN sett.ReturnedAmount ELSE 0 END ) AS "SettlReturnAmount",
                --SUM( Case WHEN sett.DueAmount > 0 THEN sett.DueAmount ELSE 0 END ) AS "SettlDueAmount",
                --SUM( Case WHEN  sett.DiscountAmount > 0 THEN sett.DiscountAmount ELSE 0 END  ) 'settldiscountamount'
    
                Sum(COALESCE(sett.CollectionFromReceivable,0)) AS "CollectionFromReceivables",
                Sum(COALESCE(sett.DiscountAmount,0)) AS "CashDiscountGiven",
                Sum(COALESCE(sett.DiscountReturnAmount,0)) AS "CashDiscountReceived"
    
            FROM PHRM_TXN_Settlement sett,
                EMP_Employee emp,
                PHRM_MST_Counter cntr,
          PHRM_MST_Store store
    
    
            WHERE sett.CreatedBy=emp.EmployeeId
                AND sett.CounterId=cntr.CounterId
          AND sett.StoreId = store.StoreId
                AND (sett.CounterId LIKE '%' || COALESCE(p_counterid, sett.CounterId) || '%')
                AND (emp.FirstName || COALESCE(' ' || emp.MiddleName, '') || ' ' || emp.LastName LIKE '%' || COALESCE(p_createdby, emp.FirstName || COALESCE(' ' || emp.MiddleName, '') || ' ' || emp.LastName) || '%')
                AND (sett.CreatedOn)::Date BETWEEN (p_fromdate)::Date AND (p_todate)::Date;
        RETURN NEXT ref2;
            --Group By sett.CreatedBy, sett.CounterId,emp.FirstName + COALESCE(' ' + emp.MiddleName, '') + ' ' + emp.LastName 
    
            --table:3--Gets User Collection Summary for all users in the given date range---
            OPEN ref3 FOR SELECT *
            FROM FN_PHRM_GetUserCollectionSummaryInDateRange(p_fromdate,p_todate,p_storeid,p_createdby);
        RETURN NEXT ref3;
    
        --table:4--Get Pharmacy Employee Cash Transaction Details for all users in the given date range----------
        OPEN ref4 FOR SELECT 
           pm.PaymentSubCategoryId
          ,pm.PaymentSubCategoryName
          ,SUM(empTxn.InAmount - empTxn.OutAmount) AS "Collection"
        FROM PHRM_EmployeeCashTransaction empTxn
          INNER JOIN MST_PaymentModes pm ON empTxn.PaymentModeSubCategoryId = pm.PaymentSubCategoryId
        INNER JOIN EMP_Employee emp ON empTxn.EmployeeId=emp.EmployeeId
        WHERE 
         pm.PaymentSubCategoryName != 'deposit'
        AND (empTxn.TransactionDate)::DATE BETWEEN (p_fromdate)::Date AND (p_todate)::Date
        AND (emp.FirstName || COALESCE(' ' || emp.MiddleName, '') || ' ' || emp.LastName LIKE '%' || COALESCE(p_createdby, emp.FirstName || COALESCE(' ' || emp.MiddleName, '') || ' ' || emp.LastName) || '%')
        group by 
         pm.paymentsubcategoryid,
         pm.paymentsubcategoryname;
        return next ref4;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;