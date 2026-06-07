CREATE OR REPLACE FUNCTION sp_report_bill_counternuserscollectiondaily(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
    filename: "sp_report_bill_countercollection"
    createdby/date: dinesh/2017-07-09
    description: to get countercollection between given range..
    remarks:
     * removed usage of fn_bill_getcounternusercollectiondaily after cashtransactiontable is introduced..
     * we can remove above function if above doesn't have any other dependencies.. 
    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       dinesh/2017-07-09	                   created
    2        sudarshan/2017-07-15                 modified to re-use this SP for both Counter and UserCollections
    3       sud/29May'18                        updated as per new billing structure
    4.      sud/5may'21                         Updated after adding EMPCashTransaction table structure. 
    5.      Sud/13Jun'21                        excluding handovergiven amount from deduction.
    */
    
    	open ref1 for select (transactiondate)::date as "billdate" 
    	, cash.employeeid, emp.fullname as "employeename",
    	sum(coalesce(inamount,0)- coalesce(outamount,0)) as "userdaycollection"
    	from txn_empcashtransaction cash inner join emp_employee emp 
    	   on cash.employeeid=emp.employeeid
    	where (transactiondate)::date between p_fromdate and p_todate
    	and transactiontype not in ('HandoverGiven') -- add other txntype here as required.
    
    	group by (transactiondate)::date, cash.employeeid, emp.fullname;
        return next ref1;
    
    	open ref2 for select (transactiondate)::date as "billdate" 
    	, cash.counterid, cntr.countername,
    	sum(coalesce(inamount,0)- coalesce(outamount,0)) as "counterdaycollection"
    	from txn_empcashtransaction cash inner join bil_cfg_counter cntr 
    	   on cash.counterid=cntr.counterid
    	where (transactiondate)::date between p_fromdate and p_todate
    	and transactiontype not in ('HandoverGiven') -- add other txntype here as required.
    	group by (transactiondate)::date, cash.counterid, cntr.countername;
        return next ref2;
END;
$$ LANGUAGE plpgsql;