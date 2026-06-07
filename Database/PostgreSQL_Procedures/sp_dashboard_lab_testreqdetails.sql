CREATE OR REPLACE FUNCTION sp_dashboard_lab_testreqdetails(

)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    
    /************************************************************************
    filename: "sp_dashboard_lab_trendinglabtest"   
    createdby/date: prem: 3rd jan,2023
    description: to get details of  test completed for dashboard
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.    prem						initial daft
    	  table-1: for lab req till date
    	  table-2: for lab req today
    *************************************************************************/
    	
    
    --negative
    open ref1 for select 'Negative' as "result",'TillNow' as "daterange", 'All' as "patientvisittype" , count(distinct(requisitionid)) as totalcount from lab_txn_testcomponentresult where requisitionid not in
    (
    select distinct(requisitionid) from   lab_txn_testcomponentresult res 
    where  value='Positive'
    
    ) and value='Negative' and  isactive=1
    
    --positive
    union all
    select 'Positive' as "result",'TillNow' as "daterange", 'All' as "patientvisittype" , count(distinct(requisitionid)) as totalcount from   lab_txn_testcomponentresult res 
    where  value='Positive' and  isactive=1
    union all
    --pending
    select 'Pending' as "result" ,'TillNow' as "daterange", 'All' as "patientvisittype" , coalesce(sum(resultnotfinalized),0) as totalcount
    from(
    select
     case when orderstatus in ('active','pending') then 1 else 0 end as resultnotfinalized 
    from   lab_testrequisition  
    where   billingstatus in ('paid','unpaid','provisional') and  isactive=1
    )res
    --total
    union all
    select 'Total' as "result" ,'TillNow' as "daterange", 'All' as "patientvisittype" , count(distinct(requisitionid)) as totalcount from   lab_txn_testcomponentresult res 
    where   isactive=1
    
    
    --new visit
    --complete
    union all
    select 'Complete' as "result",'TillNow' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 and (labreq.orderstatus='result-added' or labreq.orderstatus='report-generated') 
    	and (labreq.billingstatus='unpaid' or labreq.billingstatus='paid')
    	and pat.appointmenttype='New'
    
    --pending
    union all
    select 'Pending' as "result",'TillNow' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 and labreq.orderstatus='pending'
    	and (labreq.billingstatus='unpaid' or labreq.billingstatus='paid')
    	and pat.appointmenttype='New'
    --returned
    union all
    select 'Returned' as "result",'TillNow' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 
    	and labreq.billingstatus='returned'
    	and pat.appointmenttype='New'
    --cancelled
    union all
    
    select 'Cancelled' as "result",'TillNow' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 
    	and labreq.billingstatus='cancelled'
    	and pat.appointmenttype='New'
    
    --total
    union all
    
    select 'Total' as "result",'TillNow' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 
    	and pat.appointmenttype='New';
        return next ref1;
    
    
    
    
    --negative
    open ref2 for select 'Negative' as "result",'Today' as "daterange", 'All' as "patientvisittype" , count(distinct(requisitionid)) as totalcount from lab_txn_testcomponentresult where requisitionid not in
    (
    select distinct(requisitionid) from   lab_txn_testcomponentresult res 
    where  value='Positive'
    
    ) and value='Negative' and  isactive=1 and (createdon)::date=current_timestamp
    
    --positive
    union all
    select 'Positive' as "result",'Today' as "daterange", 'All' as "patientvisittype" , count(distinct(requisitionid)) as totalcount from   lab_txn_testcomponentresult res 
    where  value='Positive' and  isactive=1 and (createdon)::date=current_timestamp
    union all
    --pending
    select 'Pending' as "result" ,'Today' as "daterange", 'All' as "patientvisittype" , coalesce(sum(resultnotfinalized),0) as totalcount
    from(
    select
     case when orderstatus in ('active','pending') then 1 else 0 end as resultnotfinalized 
    from   lab_testrequisition  
    where   billingstatus in ('paid','unpaid','provisional') and  isactive=1 and (orderdatetime)::date=current_timestamp
    )res
    --total
    union all
    select 'Total' as "result" ,'Today' as "daterange", 'All' as "patientvisittype" , count(distinct(requisitionid)) as totalcount from   lab_txn_testcomponentresult res 
    where  isactive=1  and (createdon)::date=current_timestamp
    
    
    --today
    union all
    --complete
    select 'Complete' as "result",'Today' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 and (labreq.orderstatus='result-added' or labreq.orderstatus='report-generated') 
    	and (labreq.billingstatus='unpaid' or labreq.billingstatus='paid')
    	and labreq.resultaddedon=current_timestamp
    	and pat.appointmenttype='New'
    
    --pending
    union all
    select 'Pending' as "result",'Today' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 and labreq.orderstatus='pending'
    	and (labreq.billingstatus='unpaid' or labreq.billingstatus='paid')
    	and labreq.resultaddedon=current_timestamp
    	and pat.appointmenttype='New'
    --return
    union all
    select 'Returned' as "result",'Today' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 
    	and labreq.billingstatus='returned'
    	and labreq.resultaddedon=current_timestamp
    	and pat.appointmenttype='New'
    --cancelled
    union all
    
    select 'Cancelled' as "result",'Today' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 
    	and labreq.billingstatus='cancelled'
    	and labreq.resultaddedon=current_timestamp
    	and pat.appointmenttype='New'
    
    --total
    union all
    
    select 'Total' as "result",'Today' as "daterange", 'New' as "patientvisittype" , 
    	count(requisitionid) as totalcount
    	from lab_testrequisition labreq 
    	join pat_patientvisits pat
    	on pat.patientvisitid=labreq.patientvisitid
    	where labreq.isactive=1 
    	and labreq.resultaddedon=current_timestamp
    	and pat.appointmenttype='New';
        return next ref2;
END;
$$ LANGUAGE plpgsql;