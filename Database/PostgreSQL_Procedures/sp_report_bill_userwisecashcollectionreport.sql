/*
FileName: [SP_Report_BILL_UserWiseCashCollectionReport] 
CreatedBy/date: Aniket/17-10-2021
Description: To get the Details of User Wise Cash Collection report
Remarks:    
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Aniket/17-10-2021                    created the script
*/
CREATE OR REPLACE FUNCTION sp_report_bill_userwisecashcollectionreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_userid INT DEFAULT NULL
)
RETURNS TABLE (
    "UserName" VARCHAR,
    "OP_Collection" TIMESTAMP,
    "OP_Discount" INT,
    "OP_Refund" VARCHAR,
    "OP_ReturnDiscount" INT,
    "OP_NetTotal" DECIMAL,
    "IP_Collection" TIMESTAMP,
    "IP_Discount" INT,
    "IP_Refund" VARCHAR,
    "IP_ReturnDiscount" INT,
    "IP_NetTotal" DECIMAL,
    "Grand_Total" DECIMAL,
    "DepositAmount" DECIMAL,
    "DepositReturn" VARCHAR
) AS $$
BEGIN
    
    
    RETURN QUERY SELECT
      coalesce(opd.username, ipd.username) AS "UserName",
      coalesce(opd.subtotal, 0) AS "OP_Collection",
      coalesce(opd.discount, 0) AS "OP_Discount",
      coalesce(opd.refund, 0) AS "OP_Refund",
      coalesce(opd.returndiscount, 0) AS "OP_ReturnDiscount",
      coalesce(opd.nettotal, 0) AS "OP_NetTotal",
      coalesce(ipd.subtotal, 0) AS "IP_Collection",
      coalesce(ipd.discount, 0) AS "IP_Discount",
      coalesce(ipd.refund, 0) AS "IP_Refund",
      coalesce(ipd.returndiscount, 0) AS "IP_ReturnDiscount",
      coalesce(ipd.nettotal, 0) AS "IP_NetTotal",
      ((coalesce(opd.nettotal, 0) + coalesce(ipd.nettotal, 0))) + ((coalesce(depout.advancereceived, 0) - coalesce(depout.advancesettled, 0))) AS "Grand_Total",
      coalesce(depout.advancereceived, 0) AS "DepositAmount",
      coalesce(depout.advancesettled, 0) AS "DepositReturn"
    
    from (select
    		case
    			when userid is not null then username
    			else 'NoDoctor'
    		end AS "UserName",
    		sum(coalesce(subtotal, 0)) as "subtotal",
    		sum(coalesce(discountamount, 0)) as "discount",
    		sum(coalesce(returnamount, 0)) as "refund",
    		sum(coalesce(returndiscount, 0)) as "returndiscount",
    		sum(coalesce(totalamount, 0) - coalesce(returnamount, 0)) as "nettotal"
    	from fn_bil_gettxnitemsinfowithdateseparationforusercashcollectionreport(p_fromdate, p_todate)
    	where billingtype = 'OutPatient' and billstatus != 'cancelled'
    		and (coalesce(p_userid, coalesce(userid, 0)) = coalesce(userid, 0))
    	group by userid,username) opd
    full outer join (
    	select
    		case
    			when userid is not null then username
    			else 'NoUser'
    		end AS "UserName",
    		sum(coalesce(subtotal, 0)) as "subtotal",
    		sum(coalesce(discountamount, 0)) as "discount",
    		sum(coalesce(returnamount, 0)) as "refund",
    		sum(coalesce(returndiscount, 0)) as "returndiscount",
    		sum(coalesce(totalamount, 0) - coalesce(returnamount, 0)) as "nettotal"
    	from fn_bil_gettxnitemsinfowithdateseparationforusercashcollectionreport(p_fromdate, p_todate) tbl
    	where billingtype = 'Inpatient' and billstatus != 'cancelled'
    		and (coalesce(p_userid, coalesce(userid, 0)) = coalesce(userid, 0))
    		and (tbl.userid = p_userid or p_userid is null)
    	group by userid,username) ipd
    on opd.username = ipd.username
    left join 
    (select
            sum(case when deposittype = 'Deposit' then amount else 0 end) as "advancereceived",
            sum(case when deposittype = 'depositdeduct' or deposittype = 'ReturnDeposit' then amount else 0 end) as "advancesettled",
    		emp.fullname
        from bil_txn_deposit as dep1
    	join emp_employee as emp on dep1.createdby= emp.employeeid
        where (dep1.createdon)::date between (coalesce(p_fromdate, current_timestamp))::date and (coalesce(p_todate, current_timestamp))::date
    	group by fullname) as depout on opd.username = depout.fullname
    order by username;
END;
$$ LANGUAGE plpgsql;