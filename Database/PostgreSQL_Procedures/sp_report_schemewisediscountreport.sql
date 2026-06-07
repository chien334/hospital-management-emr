CREATE OR REPLACE FUNCTION sp_report_schemewisediscountreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_schemeid INT DEFAULT NULL
)
RETURNS TABLE (
    "SchemeId" INT,
    "SchemeName" VARCHAR,
    "SchemeCode" VARCHAR,
    "CashAmount" DECIMAL,
    "CreditAmount" DECIMAL,
    "Total" DECIMAL,
    "Free_Cons_Amount" TIMESTAMP,
    "NetRefundAmount" DECIMAL,
    "DiscountRefund" INT,
    "NetAmount" DECIMAL
) AS $$
BEGIN
    /*
      filename: "sp_report_schemewisediscountreport"
      createdby/date: pratik/2021-09-21
      description: to get the scheme wise discount report for the hospital
      remarks:    
      change history
      s.no.    updatedby/date                        remarks
      1       pratik/2021-09-21				created the script
      2       krishna/2022-04-08			updated script by adding where condtion on membership id to filter out data
      3		  sanjeev/2023-08-28			according to new structure, discard pat_cfg_membershiptype table.
    										instead use bil_cfg_scheme table.
    										replace membershiptypeid with schemeid, memebershiptypename with schemename, communityname with schemecode.
      */
    begin
    	if (p_schemeid = 0)
    	then
    		p_schemeid := null;
    	end if;
    
    	RETURN QUERY SELECT *
    	from (
    		select scheme.schemeid
    			,scheme.schemename
    			,scheme.schemecode
    			,cashtotalamount AS "CashAmount"
    			,credittotalamount AS "CreditAmount"
    			,coalesce(sales.totalamount, 0) AS "Total"
    			,
    			--coalesce(sales.subtotal,0) as salessubtotal, 
    			coalesce(sales.discountamount, 0) AS "Free_Cons_Amount"
    			,coalesce(ret.rettotalamount, 0) AS "NetRefundAmount"
    			,coalesce(ret.retdiscountamount, 0) AS "DiscountRefund"
    			,coalesce(sales.totalamount, 0) - coalesce(ret.rettotalamount, 0) AS "NetAmount"
    		from bil_cfg_scheme scheme
    		left join (
    			select itm.discountschemeid
    				,sum(itm.subtotal) as "subtotal"
    				,sum(coalesce(itm.discountamount, 0)) as "discountamount"
    				,sum(itm.totalamount) as "totalamount"
    				,sum((
    						case 
    							when txn.paymentmode = 'cash'
    								then itm.totalamount
    							else 0
    							end
    						)) as cashtotalamount
    				,sum((
    						case 
    							when txn.paymentmode = 'credit'
    								then itm.totalamount
    							else 0
    							end
    						)) as credittotalamount
    			from bil_txn_billingtransaction txn
    			inner join bil_txn_billingtransactionitems itm on txn.billingtransactionid = itm.billingtransactionid
    			where (txn.createdon)::date between p_fromdate
    					and p_todate
    			group by itm.discountschemeid
    			) sales on scheme.schemeid = sales.discountschemeid
    		left join (
    			select retitm.discountschemeid
    				,sum(retitm.retsubtotal) as "retsubtotal"
    				,sum(coalesce(retitm.retdiscountamount, 0)) as "retdiscountamount"
    				,sum(retitm.rettotalamount) as "rettotalamount"
    			from bil_txn_invoicereturnitems retitm
    			where (retitm.createdon)::date between p_fromdate
    					and p_todate
    			group by retitm.discountschemeid
    			) ret on scheme.schemeid = ret.discountschemeid
    		) tbl
    	where (
    			--coalesce(salessubtotal,0) !=0
    			coalesce(cashamount, 0) != 0
    			or coalesce(creditamount, 0) != 0
    			or coalesce(total, 0) != 0
    			or coalesce(free_cons_amount, 0) != 0
    			or coalesce(netrefundamount, 0) != 0
    			or coalesce(discountrefund, 0) != 0
    			)
    		and tbl.schemeid = coalesce(p_schemeid, tbl.schemeid);
    end;
END;
$$ LANGUAGE plpgsql;