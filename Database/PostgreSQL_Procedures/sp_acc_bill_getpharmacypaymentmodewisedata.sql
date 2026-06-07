CREATE OR REPLACE FUNCTION sp_acc_bill_getpharmacypaymentmodewisedata(
    p_transactiondate DATE,
    p_hospitalid INT
)
RETURNS TABLE (
    "PaymentSubCategoryName" VARCHAR,
    "TransactionType" TIMESTAMP,
    "TotalAmount" DECIMAL,
    "LedgerId" INT,
    "OrganizationId" INT,
    "SubLedgerId" INT
) AS $$
DECLARE
    v_billtxnidscsv VARCHAR;
        
    v_depositidscsv VARCHAR;
        
    v_depositdeductidscsv VARCHAR;
        
    v_depositreturnidscsv VARCHAR;
        
    v_settlementidscsv VARCHAR;
        
    v_salesreturnidscsv VARCHAR;
        
    v_cashdiscountreturnsettlementidscsv VARCHAR;
BEGIN
    -- =============================================
    -- author:      <dev narayan chaudhary>
    -- create date: <2022-05-18>
    -- description: <it porvides paymentmode wise cash segregation from pharmacy module>
    --exec "sp_acc_bill_getpharmacypaymentmodewisedata" '2022-12-28',3
    -- =============================================
    --change history
    /*
    sn.                auther/timestamp                   description
    1.                 devn/19th may 23                  use bil_txn_deposit table for pharmacydeposit scenerios.
    */
    
        
        v_billtxnidscsv := (
                        select string_agg(cast(invoiceid as text), ',')
                        from phrm_txn_invoice
                        where coalesce(istransferredtoacc, 0) = 0
    					and paymentmode = 'cash'
                            and (createon)::date = (p_transactiondate)::date
                );
        --setting depositids into v_depositidscsv 
        v_depositidscsv := (
                select string_agg(cast(depositid as text), ',')
                from bil_txn_deposit
                where transactiontype = 'deposit'
                    and coalesce(isdepositsync, 0) = 0
                    and (createdon)::date = (p_transactiondate)::date
    				and modulename = 'Pharmacy'
                );
        --setting depositdeductids into v_depositdeductidscsv 
        v_depositdeductidscsv := (
                select string_agg(cast(depositid as text), ',')
                from bil_txn_deposit
                where depositid in (
                        select distinct depositid
                        from bil_txn_deposit
                        where transactiontype = 'depositdeduct'
                            and coalesce(isdepositsync, 0) = 0
                            and (createdon)::date = (p_transactiondate)::date
    						and modulename = 'Pharmacy'
                        )
                );
        --setting depositreturnids into v_depositreturnidscsv 
        v_depositreturnidscsv := (
                select string_agg(cast(depositid as text), ',')
                from bil_txn_deposit
                where transactiontype = 'depositreturn'
                    and coalesce(isdepositsync, 0) = 0
                    and (createdon)::date = (p_transactiondate)::date
    				and modulename = 'Pharmacy'
                );
        --setting settlementids into v_settlementidscsv 
        v_settlementidscsv := (
                select string_agg(cast(settlementid as text), ',')
                from phrm_txn_settlement
                where settlementid in (
                        select distinct settlementid
                        from phrm_txn_settlement
                        where coalesce(istransferredtoacc, 0) = 0
                            and coalesce(collectionfromreceivable,0)>0
                            and (createdon)::date = (p_transactiondate)::date
                        )
                );
    --setting settlementids for  into v_cashdiscountreturnsettlementidscsv
        v_cashdiscountreturnsettlementidscsv := (
                select string_agg(cast(settlementid as text), ',')
                from phrm_txn_settlement
                where settlementid in (
                        select distinct settlementid
                        from phrm_txn_settlement
                        where coalesce(istransferredtoacc, 0) = 0
                            and coalesce(collectionfromreceivable,0)=0
                            and coalesce(discountreturnamount,0)>0
                            and (createdon)::date = (p_transactiondate)::date
                        )
                );
        --setting invoicereturnids into v_salesreturnidscsv
        v_salesreturnidscsv := (
                select string_agg(cast(invoicereturnid as text), ',')
                from phrm_txn_invoicereturn
                where invoicereturnid in (
                        select distinct invoicereturnid
                        from phrm_txn_invoicereturn
                        where coalesce(istransferredtoacc, 0) = 0
                            and (createdon)::date = (p_transactiondate)::date
                        )
                );
        RETURN QUERY SELECT modes.paymentsubcategoryname
            ,'PHRMCashInvoice' AS "TransactionType"
            ,coalesce(sum(inamount),0) AS "TotalAmount"
            ,ledgerid
            ,null AS "OrganizationId"
    		,coalesce(lm.subledgerid,0) AS "SubLedgerId"
        from phrm_employeecashtransaction cash
        inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
        left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
        where transactiontype = 'CashSales'
            and referenceno in (
                select value
                from string_split(v_billtxnidscsv, ',')
                )
        group by modes.paymentsubcategoryname, lm.ledgerid, lm.subledgerid
        union all
        select modes.paymentsubcategoryname
            ,'PHRMDepositAdd' AS "TransactionType"
            ,coalesce(sum(inamount),0)  AS "TotalAmount"
            ,ledgerid
            ,null AS "OrganizationId"
    		,coalesce(lm.subledgerid,0) AS "SubLedgerId"
        from phrm_employeecashtransaction cash
        inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
        left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
        where transactiontype = 'DepositAdd'
            and referenceno in (
                select value
                from string_split(v_depositidscsv, ',')
                )
        group by modes.paymentsubcategoryname,lm.ledgerid, lm.subledgerid
        union all
        select modes.paymentsubcategoryname
            ,'DepositDeduct' AS "TransactionType"
            ,coalesce(sum(outamount),0)  AS "TotalAmount"
            , ledgerid
            ,null AS "OrganizationId"
    		,coalesce(lm.subledgerid,0) AS "SubLedgerId"
        from phrm_employeecashtransaction cash
        inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
        left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
        where transactiontype = 'depositdeduct'
            and referenceno in (
                select value
                from string_split(v_depositdeductidscsv, ',')
                )
        group by modes.paymentsubcategoryname, lm.ledgerid, lm.subledgerid
        union all
        select modes.paymentsubcategoryname
            ,'PHRMDepositReturn' AS "TransactionType"
            ,coalesce(sum(outamount),0)  AS "TotalAmount"
            ,ledgerid
            ,null AS "OrganizationId"
    		,coalesce(lm.subledgerid,0) AS "SubLedgerId"
        from phrm_employeecashtransaction cash
        inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
        left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
        where transactiontype = 'ReturnDeposit'
            and referenceno in (
                select value
                from string_split(v_depositreturnidscsv, ',')
                )
        group by modes.paymentsubcategoryname, lm.ledgerid, lm.subledgerid
        union all
        select modes.paymentsubcategoryname
            ,'PHRMCreditBillPaid' AS "TransactionType"
            ,coalesce(sum(inamount),0) - coalesce(sum(outamount),0) AS "TotalAmount"
            ,lm.ledgerid
            ,sett.organizationid   
    		,coalesce(lm.subledgerid,0) AS "SubLedgerId"
        from phrm_txn_settlement sett
        join phrm_employeecashtransaction cash
        on sett.settlementid= cash.referenceno
        inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
        left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
        where transactiontype in  ('CollectionFromReceivable','CashDiscountGiven')
            and referenceno in (
                select value
                from string_split(v_settlementidscsv, ',') -- settlementid ref
                )
        group by modes.paymentsubcategoryname, lm.ledgerid, sett.organizationid, lm.subledgerid
        union all
        select modes.paymentsubcategoryname
            ,'CashBillReturn' AS "TransactionType"
            ,coalesce(sum(outamount),0)  AS "TotalAmount"
            ,ledgerid
            ,null AS "OrganizationId"
    		,coalesce(lm.subledgerid,0) AS "SubLedgerId"
        from phrm_employeecashtransaction cash
        inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
        left join acc_ledger_mapping lm on modes.paymentsubcategoryid = lm.referenceid and lm.ledgertype ='paymentmodes' and lm.hospitalid =p_hospitalid
        where transactiontype = 'SalesReturn'
            and referenceno in (
                select value
                from string_split(v_salesreturnidscsv, ',')
                )
        group by modes.paymentsubcategoryname, lm.ledgerid, lm.subledgerid
        union all
        select modes.paymentsubcategoryname
            ,'DiscountReturn' AS "TransactionType"
            ,coalesce(sum(inamount),0)  AS "TotalAmount"
            , 0 AS "LedgerId"
            ,null AS "OrganizationId"
    		,0 AS "SubLedgerId"
        from phrm_employeecashtransaction cash
        inner join mst_paymentmodes modes on cash.paymentmodesubcategoryid = modes.paymentsubcategoryid
        where transactiontype = 'CashDiscountReceived'
            and referenceno in (
                select value
                from string_split(v_cashdiscountreturnsettlementidscsv, ',') -- settlementid ref
                )
        group by modes.paymentsubcategoryname;
END;
$$ LANGUAGE plpgsql;