CREATE OR REPLACE FUNCTION sp_report_departmentwisediscountschemereport(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_membershiptypeid INT,
    p_servicedepartmentid INT,
    p_paymentmode VARCHAR
)
RETURNS TABLE (
    "MembershipTypeId" INT,
    "MembershipTypeName" VARCHAR,
    "CommunityName" VARCHAR,
    "PaymentMode" VARCHAR,
    "BillingTransactionId" INT,
    "ServiceDepartmentName" VARCHAR,
    "ServiceDepartmentId" INT,
    "CashAmount" DECIMAL,
    "CreditAmount" DECIMAL,
    "TotalAmount" DECIMAL,
    "TotalDiscount" INT,
    "NetAmount" DECIMAL,
    "TotalQuantity" INT,
    "DiscountRefund" INT,
    "NetRefundAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_schemewisediscountreport"
    createdby/date: aniket/2021-10-06
    description: to get the scheme wise discount report for the hospital
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       aniket/2021-10-06					altered the script
    */
    
    		RETURN QUERY SELECT * from 
    (
    select   	
    memb.membershiptypeid AS "MembershipTypeId", 
    memb.membershiptypename, 
    memb.communityname,
    paymentmode,
    billingtransactionid,
    serv.servicedepartmentname AS "ServiceDepartmentName",
    serv.servicedepartmentid AS "ServiceDepartmentId",
    cashtotalamount AS "CashAmount",
    credittotalamount AS "CreditAmount",
    coalesce(sales.totalamount,0) AS "TotalAmount",
    --coalesce(sales.subtotal,0) as salessubtotal, 
    coalesce(sales.discountamount,0) AS "TotalDiscount", 
    coalesce(sales.totalamount,0) - coalesce(netrefundamount,0) AS "NetAmount",
    sales.totalquantity,
    discountrefund,
    netrefundamount
    from 
    pat_cfg_membershiptype  memb
    left join 
    (
    select itm.discountschemeid,
    itm.servicedepartmentid,
    sum(itm.subtotal) as "subtotal",
    sum(coalesce(itm.discountamount,0)) as "discountamount",
    sum(itm.totalamount) AS "TotalAmount",
    sum(itm.quantity) AS "TotalQuantity",
    txn.paymentmode AS "PaymentMode",
    txn.billingtransactionid AS "BillingTransactionId",
    sum(coalesce(rettxnitm.rettotalamount,0)) AS "NetRefundAmount",
    sum(coalesce(rettxnitm.retdiscountamount,0)) AS "DiscountRefund",
    sum( (case when txn.paymentmode ='cash' then itm.totalamount
    else 0 end )) as cashtotalamount,
    sum( (case when txn.paymentmode ='credit' then itm.totalamount
    else 0 end )) as credittotalamount
      
        from bil_txn_billingtransaction txn
        left join bil_txn_billingtransactionitems itm on txn.billingtransactionid = itm.billingtransactionid
    	left join bil_txn_invoicereturnitems rettxnitm
    on itm.billingtransactionitemid = rettxnitm.billingtransactionitemid
    where (txn.createdon)::date between p_fromdate and p_todate
    group by itm.discountschemeid,itm.servicedepartmentid,txn.paymentmode, txn.billingtransactionid
    ) sales
    on memb.membershiptypeid= sales.discountschemeid 
    
    join bil_mst_servicedepartment serv on sales.servicedepartmentid= serv.servicedepartmentid
      
    )tbl
    
    where ( 
            --coalesce(salessubtotal,0) !=0
            coalesce(cashamount,0) !=0
        or  coalesce(creditamount,0) !=0
        or  coalesce(totalamount,0) !=0
        or  coalesce(totaldiscount,0) !=0
        or  coalesce(netrefundamount,0) !=0  
        or  coalesce(discountrefund,0) !=0
        )
    	and ((membershiptypeid = p_membershiptypeid or p_membershiptypeid is null) and (servicedepartmentid = p_servicedepartmentid or p_servicedepartmentid is null) and (paymentmode = p_paymentmode or p_paymentmode is null));
END;
$$ LANGUAGE plpgsql;