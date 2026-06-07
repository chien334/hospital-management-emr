CREATE OR REPLACE FUNCTION sp_report_apf_billdetailreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_billingtype VARCHAR DEFAULT NULL,
    p_itemid INT DEFAULT NULL,
    p_userid INT DEFAULT NULL,
    p_rank VARCHAR DEFAULT NULL,
    p_membershiptypeid INT DEFAULT NULL,
    p_servicedepartmentid INT DEFAULT NULL
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
    "Rank" VARCHAR,
    "MembershipType" VARCHAR,
    "Price" DECIMAL,
    "Quantity" INT,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL,
    "PerformerId" INT,
    "PrescriberId" INT,
    "Performer" VARCHAR,
    "PrescriberName" VARCHAR,
    "Remarks" VARCHAR,
    "ReferenceReceiptNo" VARCHAR,
    "UserName" VARCHAR
) AS $$
DECLARE
    v_isinsurance BOOLEAN;
BEGIN
    /*  
    filename: "sp_report_apf_billdetailreport"  
    createdby/date: rohit/28sept'22  
    Description: To get details of sales and returnsales at item level  
    Remarks:      
    Change History  
    S.No.    UpdatedBy/Date               Remarks  
    1.       Rohit/28Sept'22             created initial script  
    */
    begin
    	
    
    	if (lower(p_billingtype) = 'insurance')
    	then
    		v_isinsurance := 1;
    	
    	elsif (lower(p_billingtype) = 'normal')
    	then
    		v_isinsurance := 0;
    	
    	elsif (lower(p_billingtype) = 'all')
    	then
    		v_isinsurance := null;
    	end if;
    
    	RETURN QUERY SELECT *
    	from (
    		select (txn.createdon)::date AS "TransactionDate"
    			,txn.invoicecode || '-' || (txn.invoiceno)::varchar AS "ReceiptNo"
    			,case 
    				when txn.paymentmode = 'credit'
    					then 'CreditSales'
    				else 'CashSales'
    				end AS "BillingType"
    			,txnitm.visittype AS "VisitType"
    			,p.patientcode AS "HospitalNumber"
    			,p.shortname AS "PatientName"
    			,srv.servicedepartmentname
    			,txnitm.itemname
    			,p.rank
    			,coalesce(memb.membershiptypename, 'General') AS "MembershipType"
    			,txnitm.price
    			,txnitm.quantity
    			,txnitm.subtotal AS "SubTotal"
    			,txnitm.discountamount AS "DiscountAmount"
    			,txnitm.totalamount AS "TotalAmount"
    			,txnitm.performerid
    			,txnitm.prescriberid
    			,case 
    				when coalesce(txnitm.performerid, 0) = 0
    					then 'Unassigned'
    				else empassign.fullname
    				end AS "Performer"
    			,case 
    				when coalesce(txnitm.prescriberid, 0) = 0
    					then 'SELF'
    				else empref.fullname
    				end AS "PrescriberName"
    			,txnitm.remarks AS "Remarks"
    			,'NA' AS "ReferenceReceiptNo"
    			,empusr.fullname AS "UserName"  
    		from bil_txn_billingtransaction txn
    		inner join bil_txn_billingtransactionitems txnitm on txn.billingtransactionid = txnitm.billingtransactionid
    		inner join bil_mst_servicedepartment srv on txnitm.servicedepartmentid = srv.servicedepartmentid
    		inner join pat_patient p on txn.patientid = p.patientid
    		inner join emp_employee empusr on empusr.employeeid = txn.createdby
    		left join emp_employee empref on empref.employeeid = txnitm.prescriberid
    		left join emp_employee empassign on empassign.employeeid = txnitm.performerid
    		left join pat_cfg_membershiptype memb on txnitm.discountschemeid = memb.membershiptypeid
    		where (txn.createdon)::date between p_fromdate and p_todate
    			and (txn.isinsurancebilling=v_isinsurance or v_isinsurance is null)
    			and (txnitm.itemid=p_itemid or p_itemid is null)
    			and (empusr.employeeid=p_userid or p_userid is null)
    			and (p.rank=p_rank or p_rank is null)
    			and (memb.membershiptypeid =p_membershiptypeid or p_membershiptypeid is null)
    			and (srv.servicedepartmentid=p_servicedepartmentid or p_servicedepartmentid is null)
    		
    		union all
    		
    		select (ret.createdon)::date AS "TransactionDate"
    			,'CRN-' || (ret.creditnotenumber)::varchar as "creditnotenumber"
    			,case 
    				when ret.paymentmode = 'credit'
    					then 'ReturnCreditSales'
    				else 'ReturnCashSales'
    				end AS "BillingType"
    			,retitm.visittype AS "VisitType"
    			,p.patientcode AS "HospitalNumber"
    			,p.shortname AS "PatientName"
    			,srv.servicedepartmentname
    			,retitm.itemname
    			,p.rank
    			,coalesce(memb.membershiptypename, 'General') AS "MembershipType"
    			,retitm.price
    			,retitm.retquantity
    			,retitm.retsubtotal AS "SubTotal"
    			,retitm.retdiscountamount AS "DiscountAmount"
    			,retitm.rettotalamount AS "TotalAmount"
    			,retitm.performerid
    			,retitm.prescriberid
    			,case 
    				when coalesce(retitm.performerid, 0) = 0
    					then 'Unassigned'
    				else empassign.fullname
    				end AS "Performer"
    			,case 
    				when coalesce(retitm.prescriberid, 0) = 0
    					then 'SELF'
    				else empref.fullname
    				end AS "PrescriberName"
    			,retitm.retremarks AS "Remarks"
    			,ret.invoicecode || '-' || (ret.refinvoicenum)::varchar AS "ReferenceReceiptNo"
    			,empusr.fullname AS "UserName" 
    		from bil_txn_invoicereturn ret
    		inner join bil_txn_invoicereturnitems retitm on ret.billreturnid = retitm.billreturnid
    		inner join bil_mst_servicedepartment srv on retitm.servicedepartmentid = srv.servicedepartmentid
    		inner join pat_patient p on ret.patientid = p.patientid
    		inner join emp_employee empusr on empusr.employeeid = ret.createdby
    		left join emp_employee empref on empref.employeeid = retitm.prescriberid
    		left join emp_employee empassign on empassign.employeeid = retitm.performerid
    		left join pat_cfg_membershiptype memb on retitm.discountschemeid = memb.membershiptypeid
    		where (ret.createdon)::date between p_fromdate and p_todate
    			and (ret.isinsurancebilling=v_isinsurance or v_isinsurance is null)
    			and (retitm.itemid=p_itemid or p_itemid is null)
    			and (empusr.employeeid=p_userid or p_userid is null)
    			and (p.rank=p_rank or p_rank is null)
    			and (memb.membershiptypeid =p_membershiptypeid or p_membershiptypeid is null)
    			and (srv.servicedepartmentid=p_servicedepartmentid or p_servicedepartmentid is null)
    		) itmdetails
    	order by transactiondate;
    end;
END;
$$ LANGUAGE plpgsql;