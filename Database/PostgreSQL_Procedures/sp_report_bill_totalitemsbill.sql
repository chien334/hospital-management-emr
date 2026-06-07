CREATE OR REPLACE FUNCTION sp_report_bill_totalitemsbill(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_billingtype VARCHAR DEFAULT 'all',
    p_servicedepartmentname VARCHAR DEFAULT NULL,
    p_itemname VARCHAR DEFAULT NULL,
    p_performerid INT DEFAULT NULL,
    p_prescriberid INT DEFAULT NULL
)
RETURNS TABLE (
    "NepMonthName" TIMESTAMP,
    "EngMonthName" TIMESTAMP,
    "itmDetails.*" VARCHAR
) AS $$
DECLARE
    v_isinsurance BOOLEAN;
BEGIN
    /*  
    filename: "sp_report_totalitemsbill"  
    createdby/date: sud:20aug'21  
    Description: To get details of sales and returnsales at item level  
    Remarks:      
    Change History  
    S.No.    UpdatedBy/Date               Remarks  
    1.       Sud:20Aug'21                 complete re-write as per new logic  
    2.       dev/24th_jan'22         Change NoDoctor to Unassgined in case no doctor is selected  
    3.       Krishna/9thJun'22      changed requestedby to prescriberid and providerid to performerid
    4.       krishna/18thaug'22     Performer and Prescriber null condition revised 
    5.		 Krishna/19thOct'22		performedid changed to prescriberid in where condition
    6.       sud:26jun'23           Added NepaliMonthName and EngMonthName in select query.
    */
    BEGIN
    
     IF(LOWER(p_billingtype)='insurance')
    THEN
     v_isinsurance := 1;
      
    ELSIF(LOWER(p_billingtype)='normal')
    THEN
     v_isinsurance := 0;
      
    ELSIF(LOWER(p_billingtype)='all')
    THEN
     v_isinsurance := NULL;
    END IF; 
    
    --sud: 26Jun'23-- joining with engnepdatemapped table to get nepalimonth and english month name
    RETURN QUERY SELECT nepdate.nepmonthname,
    nepdate.engmonthshortname AS "EngMonthName",
    itmdetails.*
    from
    (
     select
      (txn.createdon)::date as "transactiondate",
         txn.invoicecode||'-'||(txn.invoiceno)::varchar as "receiptno",
      case when txn.paymentmode ='credit' then 'CreditSales'
       else 'CashSales' end as billingtype,
            txnitm.visittype as "visittype",
      p.patientcode as "hospitalnumber",
      p.shortname as "patientname",
      srv.servicedepartmentname,
      txnitm.itemname,
      txnitm.price,
      txnitm.quantity,
      txnitm.subtotal as "subtotal",
      txnitm.discountamount as "discountamount",
      txnitm.totalamount as "totalamount",
      txnitm.performerid,
      txnitm.prescriberid,
      case when  coalesce(txnitm.performerid,0)=0 then 'Unassigned'
       else empassign.fullname end as performer,
      case when  coalesce(txnitm.prescriberid,0)=0 then 'SELF'
       else empref.fullname end as prescribername,
      txnitm.remarks as "remarks",
      'NA' as "referencereceiptno",
      empusr.fullname as "username",
      coalesce(memb.membershiptypename,'General') as "discountscheme",  --if not found then it's General  
      Case WHEN COALESCE(txn.IsInsuranceBilling,0)=1 THEN 'yes'
           ELSE 'no' END AS IsInsurance  
     From  BIL_TXN_BillingTransaction txn   
       INNER JOin BIL_TXN_BillingTransactionItems txnItm on txn.BillingTransactionId = txnItm.BillingTransactionId  
       INNER JOIN BIL_MST_ServiceDepartment srv ON txnItm.ServiceDepartmentId=srv.ServiceDepartmentId  
       INNER JOIN  PAT_Patient P  on txn.PatientId =p.PatientId  
       INNER JOIN EMP_Employee empUsr ON empUsr.EmployeeId = txn.CreatedBy   
       LEFT JOIN EMP_Employee empRef on empRef.EmployeeId = txnItm.PrescriberId  
       LEFT JOIN EMP_Employee empAssign on empAssign.EmployeeId = txnItm.PerformerId  
       LEFT JOIN PAT_CFG_MembershipType memb on txnItm.DiscountSchemeId=memb.MembershipTypeId  
     where  (txn.CreatedOn)::Date between p_fromdate and p_todate
      and  (COALESCE(v_isinsurance, COALESCE(txn.IsInsuranceBilling, 0)) = COALESCE(txn.IsInsuranceBilling, 0))
      AND (srv.ServiceDepartmentName LIKE '%' || COALESCE(p_servicedepartmentname, srv.ServiceDepartmentName) || '%')
            AND (txnItm.ItemName LIKE '%' || COALESCE(p_itemname, txnItm.ItemName) || '%')
     UNION ALL
     Select
      (ret.CreatedOn)::Date AS "TransactionDate",
         'crn-'||(ret.CreditNoteNumber)::VARCHAR AS "CreditNoteNumber",
      Case WHEN ret.PaymentMode ='credit' THEN 'returncreditsales'
       ELSE 'returncashsales' END AS BillingType,
            retItm.VisitType AS "VisitType",
      p.PatientCode AS "HospitalNumber",
      p.ShortName AS "PatientName",
      srv.ServiceDepartmentName,
      retItm.ItemName,
      retItm.Price,
      retItm.RetQuantity,
      retItm.RetSubTotal AS "SubTotal",
      retItm.RetDiscountAmount AS "DiscountAmount",
      retItm.RetTotalAmount AS "TotalAmount",
      retItm.PerformerId,
      retItm.PrescriberId,
      CASE WHEN  COALESCE(retItm.PerformerId,0)=0 THEN 'unassigned'
       ELSE empAssign.FullName END AS Performer,
      CASE WHEN  COALESCE(retItm.PrescriberId,0)=0 THEN 'self'
       ELSE empRef.FullName END AS PrescriberName,
      retItm.RetRemarks AS "Remarks",
      ret.InvoiceCode||'-'||(ret.RefInvoiceNum)::VARCHAR AS "ReferenceReceiptNo",
      empUsr.FullName AS "UserName",
      COALESCE(memb.MembershipTypeName,'general') AS "DiscountScheme",  --if not found then it's general  
      case when coalesce(ret.isinsurancebilling,0)=1 then 'YES'
           else 'NO' end as isinsurance  
     from  bil_txn_invoicereturn ret   
       inner join bil_txn_invoicereturnitems retitm on ret.billreturnid = retitm.billreturnid  
       inner join bil_mst_servicedepartment srv on retitm.servicedepartmentid=srv.servicedepartmentid  
       inner join  pat_patient p  on ret.patientid =p.patientid  
       inner join emp_employee empusr on empusr.employeeid = ret.createdby   
       left join emp_employee empref on empref.employeeid = retitm.prescriberid  
       left join emp_employee empassign on empassign.employeeid = retitm.performerid  
       left join pat_cfg_membershiptype memb on retitm.discountschemeid=memb.membershiptypeid  
     where  (ret.createdon)::date between p_fromdate and p_todate
     and  (coalesce(v_isinsurance, coalesce(ret.isinsurancebilling, 0)) = coalesce(ret.isinsurancebilling, 0))
     and (srv.servicedepartmentname like '%' || coalesce(p_servicedepartmentname, srv.servicedepartmentname) || '%')
        and (retitm.itemname like '%' || coalesce(p_itemname, retitm.itemname) || '%')
    ) itmdetails 
    inner join engnepalidatemapped nepdate 
        on itmdetails.transactiondate =  nepdate.engfulldate 
    where
          coalesce(itmdetails.performerid,0) = coalesce(p_performerid, coalesce(itmdetails.performerid,0))
          or coalesce(itmdetails.prescriberid,0) = coalesce(p_prescriberid, coalesce(itmdetails.prescriberid,0))
    order by transactiondate;--, hospitalnumber
    end;
END;
$$ LANGUAGE plpgsql;