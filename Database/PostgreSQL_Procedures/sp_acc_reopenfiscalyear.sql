CREATE OR REPLACE FUNCTION sp_acc_reopenfiscalyear(
    p_fiscalyearid INT,
    p_employeeid INT,
    p_hospitalid INT,
    p_remark VARCHAR
)
RETURNS TABLE (
    "*" VARCHAR
) AS $$
BEGIN
    --exec "sp_acc_reopenfiscalyear" p_fiscalyearid = 2, p_employeeid =1,p_hospitalid=3
    	
    	/************************************************************************
    	filename: "sp_acc_reopenfiscalyear"
    	createdby/date: nagesh /22'June2020
    	Description: reopen fiscal year, add log into fiscalYearLog table and update ledger balance as per opened fiscalYear
    	Change History
    	S.No.    UpdatedBy/Date                        Remarks
    	1       Nagesh /22'june2020						created script for reopen fiscal year, add log and update ledger balance
    	
    	*************************************************************************/
    	begin	
    		if(p_fiscalyearid is not null and p_employeeid is not null and p_hospitalid is not null) 
    		then				  
    		   
    				  
    				
    					--code is here
    					--update fiscal year closed to open 
    					update acc_mst_fiscalyears set isclosed=0
    					where fiscalyearid=p_fiscalyearid and hospitalid=p_hospitalid;
    					
    					--add log into acc_fiscalyear_log table
    					insert into acc_fiscalyear_log(fiscalyearid, logtype, logdetails, createdon, createdby,hospitalid)
    					values(p_fiscalyearid,'reopened',p_remark,current_timestamp,p_employeeid,p_hospitalid);
    					
    					--update acc_ledger opening balance by opened fiscal year opening balance from ledgerbalancehistory table					
    					update acc_ledger
    					set openingbalance=lbh.openingbalance,
    					drcr=lbh.openingdrcr from acc_ledgerbalancehistory lbh
    					join acc_ledger l on lbh.ledgerid=l.ledgerid and lbh.fiscalyearid=p_fiscalyearid and lbh.hospitalid=p_hospitalid;
    					
    					RETURN QUERY SELECT *from acc_mst_fiscalyears where fiscalyearid=p_fiscalyearid and hospitalid=p_hospitalid;
    				end if;		
    	end;
END;
$$ LANGUAGE plpgsql;