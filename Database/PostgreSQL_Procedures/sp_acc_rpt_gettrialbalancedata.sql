CREATE OR REPLACE FUNCTION sp_acc_rpt_gettrialbalancedata(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_hospitalid INT,
    p_openingfiscalyearid INT
)
RETURNS TABLE (
    "PrimaryGroup" VARCHAR,
    "COA" VARCHAR,
    "LedgerGroupName" VARCHAR,
    "LedgerName" VARCHAR,
    "LedgerId" INT,
    "Code" VARCHAR,
    "OpeningBalDr" VARCHAR,
    "OpeningBalCr" VARCHAR,
    "OpeningDr" VARCHAR,
    "OpeningCr" VARCHAR,
    "CurrentDr" VARCHAR,
    "CurrentCr" VARCHAR
) AS $$
DECLARE
    v_fiscalyearstartdate TIMESTAMP;
BEGIN
    --exec "sp_acc_rpt_gettrialbalancedata" p_fromdate = '2020-07-08  18:00:21.657', p_todate ='2020-07-09 18:00:21.657', p_hospitalid=3, p_openingfiscalyearid=3
    /************************************************************************
    	filename: "sp_acc_rpt_gettrialbalancedata"
    	createdby/date: nagesh /11'June2020
    	Description: get records for trail balance report of accounting
    	Change History
    	S.No.    UpdatedBy/Date                        Remarks
    	1       Nagesh /11'june2020						created script for get trial balance records
    	2.      sud/nagesh: 20jun'20					Added HospitalId for Phrm separation
    	3.		Nagesh/Vikas: 07Jul'20					changed script for opening balance as per fiscalyearid and input openingfiscalyearid 
    	4.		nagesh: 09 jul 2020						fixed issue of opening balance after fiscal year closed and reopened
    	5.      dev narayan 26'March'23                 added isverified filter in acc_transactions table.
    	*************************************************************************/
    begin
    	if (
    			p_fromdate is not null
    			and p_todate is not null
    			)
    	then
    		--here we are getting plain records all grouping and data modification as per need we will do in controller 
    		--using linq we will do all modification this will return plain records only
    		--now we are getting ledger opening balance from ledger table later we will update sp
    		--and we will get data from ledger balance history table 
    		
    
    		v_fiscalyearstartdate := (
    				select  startdate
    				from acc_mst_fiscalyears
    				where hospitalid = p_hospitalid
    					and fiscalyearid = p_openingfiscalyearid limit 1
    				);
    
    		RETURN QUERY SELECT ledinfo.primarygroup
    			,ledinfo.coa
    			,ledinfo.ledgergroupname
    			,ledinfo.ledgername
    			,ledinfo.ledgerid
    			,ledinfo.code
    			,openingbaldr
    			,openingbalcr
    			,coalesce(openingdr, 0) AS "OpeningDr"
    			,coalesce(openingcr, 0) AS "OpeningCr"
    			,coalesce(currentdr, 0) AS "CurrentDr"
    			,coalesce(currentcr, 0) AS "CurrentCr"
    		from (
    			select l.ledgerid
    				,l.ledgername
    				,l.code
    				,lg.primarygroup
    				,lg.coa
    				,lg.ledgergroupname
    				,case 
    					when lbh.openingdrcr = 1
    						then lbh.openingbalance
    					else 0
    					end AS "OpeningBalDr"
    				,case 
    					when lbh.openingdrcr = 0
    						then lbh.openingbalance
    					else 0
    					end AS "OpeningBalCr"
    			from acc_ledgerbalancehistory lbh
    			join acc_ledger l on lbh.ledgerid = l.ledgerid
    			inner join acc_mst_ledgergroup lg on l.ledgergroupid = lg.ledgergroupid
    			where lbh.hospitalid = p_hospitalid
    				and lbh.fiscalyearid = p_openingfiscalyearid
    			) ledinfo
    		left join (
    			select ledgerid
    				,sum(openingdr) AS "OpeningDr"
    				,sum(openingcr) AS "OpeningCr"
    				,sum(currentdr) AS "CurrentDr"
    				,sum(currentcr) AS "CurrentCr"
    			from (
    				select ti.ledgerid
    					,(
    						case 
    							when ti.drcr = 1
    								and (t.transactiondate)::date < (p_fromdate)::date
    								then coalesce(ti.amount, 0)
    							else 0
    							end
    						) AS "OpeningDr"
    					,(
    						case 
    							when ti.drcr = 0
    								and (t.transactiondate)::date < (p_fromdate)::date
    								then coalesce(ti.amount, 0)
    							else 0
    							end
    						) AS "OpeningCr"
    					,(
    						case 
    							when ti.drcr = 1
    								and (t.transactiondate)::date >= (p_fromdate)::date
    								then coalesce(ti.amount, 0)
    							else 0
    							end
    						) AS "CurrentDr"
    					,(
    						case 
    							when ti.drcr = 0
    								and (t.transactiondate)::date >= (p_fromdate)::date
    								then coalesce(ti.amount, 0)
    							else 0
    							end
    						) AS "CurrentCr"
    				from acc_transactionitems ti
    				inner join acc_transactions t on ti.transactionid = t.transactionid
    				where t.hospitalid = p_hospitalid
    					and (t.transactiondate)::date between (v_fiscalyearstartdate)::date
    						and (p_todate)::date
    					and t.isverified = 1
    				) a
    			group by ledgerid
    			) ledtxndetails on ledinfo.ledgerid = ledtxndetails.ledgerid
    		order by ledinfo.ledgername;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;