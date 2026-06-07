CREATE OR REPLACE FUNCTION sp_rpt_bil_ehsbillingreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_servicedepartmentname VARCHAR DEFAULT NULL,
    p_itemname VARCHAR DEFAULT NULL,
    p_userid INT DEFAULT NULL,
    p_performerid INT DEFAULT NULL,
    p_prescriberid INT DEFAULT NULL
)
RETURNS TABLE (
    "TransactionDate" TIMESTAMP,
    "ReceiptNo" VARCHAR,
    "BillingType" VARCHAR,
    "VisitType" VARCHAR,
    "HospitalNumber" VARCHAR,
    "PatientName" VARCHAR,
    "ServiceDepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "Price" DECIMAL,
    "Quantity" INT,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL,
    "PerformerName" VARCHAR,
    "PrescriberName" VARCHAR,
    "Remarks" VARCHAR,
    "ReferenceReceiptNo" VARCHAR,
    "UserName" VARCHAR,
    "DiscountScheme" INT,
    "IsInsurance" BOOLEAN
) AS $$
BEGIN
    /*  
    filename: sp_rpt_bil_ehsbillingreport  
    createdby/date: pratik:21nov'2021  
    Description:   
    Remarks:      
    Change History  
    S.No.    UpdatedBy/Date               Remarks  
    1.       Pratik:21Nov'2021            initial draft  
    2.       pratik:9dec'2021             Added ProviderId and RequestedBy filter   
    */  
      
       
      
    RETURN QUERY SELECT * from   
      
    (  
     Select   
      (txn.CreatedOn)::Date AS "TransactionDate",  
         txn.InvoiceCode||'-'||(txn.InvoiceNo)::VARCHAR AS "ReceiptNo",  
      Case WHEN txn.PaymentMode ='credit' THEN 'creditsales'  
       ELSE 'cashsales' END AS "BillingType",  
            txnItm.VisitType AS "VisitType",  
      p.PatientCode AS "HospitalNumber",  
      p.ShortName AS "PatientName",   
      srv.ServiceDepartmentName,  
      txnItm.ItemName,  
      txnItm.Price,  
      txnItm.Quantity,  
      txnItm.SubTotal AS "SubTotal",  
      txnItm.DiscountAmount AS "DiscountAmount",  
      txnItm.TotalAmount AS "TotalAmount",  
      CASE WHEN  COALESCE(txnItm.PerformerId,0)=0 THEN 'nodoctor'   
       ELSE empAssign.FullName END AS "PerformerName",  
      CASE WHEN  COALESCE(txnItm.PrescriberId,0)=0 THEN 'self'   
       ELSE empRef.FullName END AS "PrescriberName",  
      txnItm.Remarks AS "Remarks",  
      'na' AS "ReferenceReceiptNo",  
      empUsr.FullName AS "UserName",  
      COALESCE(memb.MembershipTypeName,'general') AS "DiscountScheme",  --if not found then it's general  
      case when coalesce(txn.isinsurancebilling,0)=1 then 'YES'  
           else 'NO' end AS "IsInsurance"  
      
     from  bil_txn_billingtransaction txn   
       inner join bil_txn_billingtransactionitems txnitm on txn.billingtransactionid = txnitm.billingtransactionid  
       inner join bil_mst_servicedepartment srv on txnitm.servicedepartmentid=srv.servicedepartmentid  
       inner join  pat_patient p  on txn.patientid =p.patientid  
       inner join emp_employee empusr on empusr.employeeid = txn.createdby   
       left join emp_employee empref on empref.employeeid = txnitm.prescriberid  
       left join emp_employee empassign on empassign.employeeid = txnitm.performerid  
       left join pat_cfg_membershiptype memb on txnitm.discountschemeid=memb.membershiptypeid  
         
     where  (txn.createdon)::date between p_fromdate and p_todate and txnitm.pricecategory='EHS'  
      and (srv.servicedepartmentname like '%' || coalesce(p_servicedepartmentname, srv.servicedepartmentname) || '%')  
            and (txnitm.itemname like '%' || coalesce(p_itemname, txnitm.itemname) || '%')  
      and (coalesce(p_userid, coalesce(txn.createdby, 0)) = coalesce(txn.createdby, 0))  
      and (coalesce(p_performerid, coalesce(txnitm.performerid, 0)) = coalesce(txnitm.performerid, 0))  
      and (coalesce(p_prescriberid, coalesce(txnitm.prescriberid, 0)) = coalesce(txnitm.prescriberid, 0))  
      
     union all  
      
     select   
      (ret.createdon)::date AS "TransactionDate",  
         'CRN-'||(ret.creditnotenumber)::varchar as "creditnotenumber",  
      case when ret.paymentmode ='credit' then 'ReturnCreditSales'  
       else 'ReturnCashSales' end AS "BillingType",  
            retitm.visittype AS "VisitType",  
      p.patientcode AS "HospitalNumber",  
      p.shortname AS "PatientName",   
      srv.servicedepartmentname,  
      retitm.itemname,  
      retitm.price,  
      retitm.retquantity,  
      retitm.retsubtotal AS "SubTotal",  
      retitm.retdiscountamount AS "DiscountAmount",  
      retitm.rettotalamount AS "TotalAmount",  
      case when  coalesce(retitm.performerid,0)=0 then 'NoDoctor'   
       else empassign.fullname end AS "PerformerName",  
      case when  coalesce(retitm.prescriberid,0)=0 then 'SELF'   
       else empref.fullname end AS "PrescriberName",  
      retitm.retremarks AS "Remarks",  
      ret.invoicecode||'-'||(ret.refinvoicenum)::varchar AS "ReferenceReceiptNo",  
      empusr.fullname AS "UserName",  
      coalesce(memb.membershiptypename,'General') AS "DiscountScheme",  --if not found then it's General  
      Case WHEN COALESCE(ret.IsInsuranceBilling,0)=1 THEN 'yes'  
           ELSE 'no' END AS "IsInsurance"  
      
     From  BIL_TXN_InvoiceReturn ret   
       INNER JOin BIL_TXN_InvoiceReturnItems retItm on ret.BillReturnId = retItm.BillReturnId  
       INNER JOIN BIL_MST_ServiceDepartment srv ON retItm.ServiceDepartmentId=srv.ServiceDepartmentId  
       INNER JOIN  PAT_Patient P  on ret.PatientId =p.PatientId  
       INNER JOIN EMP_Employee empUsr ON empUsr.EmployeeId = ret.CreatedBy   
       LEFT JOIN EMP_Employee empRef on empRef.EmployeeId = retItm.PrescriberId  
       LEFT JOIN EMP_Employee empAssign on empAssign.EmployeeId = retItm.PerformerId  
       LEFT JOIN PAT_CFG_MembershipType memb on retItm.DiscountSchemeId=memb.MembershipTypeId  
      
     WHERE  (ret.CreatedOn)::Date between p_fromdate and p_todate and retItm.PriceCategory='ehs'  
     AND (srv.ServiceDepartmentName LIKE '%' || COALESCE(p_servicedepartmentname, srv.ServiceDepartmentName) || '%')  
        AND (retItm.ItemName LIKE '%' || COALESCE(p_itemname, retItm.ItemName) || '%')    
     and (coalesce(p_userid, coalesce(ret.createdby, 0)) = coalesce(ret.createdby, 0))  
     and (coalesce(p_performerid, coalesce(retitm.performerid, 0)) = coalesce(retitm.performerid, 0))  
      and (coalesce(p_prescriberid, coalesce(retitm.prescriberid, 0)) = coalesce(retitm.prescriberid, 0))  
      
    ) itmdetails  
      
      
    order by transactiondate, hospitalnumber;
END;
$$ LANGUAGE plpgsql;