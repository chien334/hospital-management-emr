CREATE OR REPLACE FUNCTION sp_acc_rpt_getreversetranactiondetail(
    p_reversetransactionid INT
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    --exec "sp_acc_rpt_getreversetranactiondetail" v_transactiondate = '2019-07-05 12:07:31.170'
    
    /************************************************************************
    filename: "sp_acc_rpt_getreversetranactiondetail"
    createdby/date: nageshbb/18aug2020
    description: get details of reversed transaction to show in report
    change history
    s.no.    updatedby/date                        remarks
    1       nageshbb / 18aug2020						 scriptcreated 
    *************************************************************************/
    
    	--table1
    		open ref1 for select distinct rtxn.sectionid, rtxn.voucherid,rtxn.fiscalyearid,rtxn.createdby, rtxn.reversedby  
    		,sec.sectionname,fy.fiscalyearname,emp.fullname as reversedbyname,rtxn.reversedon,rtxn.reason,rtxn.transactiondate,--common section
    		rtxn.vouchernumber,vcr.vouchername,rtxn.createdon,emp1.fullname as createdbyname, isrecreated= 0 --table records
    		from fn_acc_get_reverse_transaction_records() rtxn 
    		join acc_mst_sectionlist sec on rtxn.sectionid=sec.sectionid
    		join acc_mst_fiscalyears fy on fy.fiscalyearid=rtxn.fiscalyearid
    		join emp_employee emp on emp.employeeid=rtxn.reversedby
    		join acc_mst_vouchers vcr on vcr.voucherid=rtxn.voucherid
    		join emp_employee emp1 on emp1.employeeid=rtxn.createdby
    		where rtxn.reversetransactionid=p_reversetransactionid;
        return next ref1;
    	--table2
    		open ref2 for select distinct rtxn.sectionid,rtxn.fiscalyearid,rtxn.vouchernumber
    		from fn_acc_get_reverse_transaction_records() rtxn 
    		join acc_transactions txn on rtxn.sectionid=txn.sectionid and rtxn.fiscalyearid=txn.fiscalyearid
    		and rtxn.vouchernumber=txn.vouchernumber
    		where rtxn.reversetransactionid=p_reversetransactionid;
        return next ref2;
END;
$$ LANGUAGE plpgsql;