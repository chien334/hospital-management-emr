CREATE OR REPLACE FUNCTION sp_lab_statuswise_test_detail(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_orderstatus VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "RequestedOn" TIMESTAMP,
    "PatientName" VARCHAR,
    "HospitalNo" VARCHAR,
    "AgeSex" VARCHAR,
    "WardName" VARCHAR,
    "ReferredBy" VARCHAR,
    "LabTestName" VARCHAR,
    "RunNo" VARCHAR,
    "TestStatus" VARCHAR,
    "BillStatus" VARCHAR,
    "SampleCollectedBy" VARCHAR,
    "ReportPrintedBy" VARCHAR,
    "CancelledByUser" VARCHAR,
    "BillCancelledOn" TIMESTAMP
) AS $$
BEGIN
    DROP TABLE IF EXISTS v_orderstatuslist;
    CREATE TEMP TABLE v_orderstatuslist (
        OrderStatus varchar(20)
    );
    begin
    	
    	insert into v_orderstatuslist
    	select value from string_split(p_orderstatus,',') where rtrim(value) <>'';
    if(p_fromdate is not null or p_todate is not null)
    then
    RETURN QUERY SELECT orderdatetime AS "RequestedOn", pat.shortname AS "PatientName",pat.patientcode AS "HospitalNo",
    (pat.age)::varchar||'/'|| pat.gender AS "AgeSex",
    case when wardname='outpatient' then 'OPD'
    else upper(wardname) end AS "WardName",
    case when req.prescribername is null then 'SELF' 
    else req.prescribername end AS "ReferredBy",
    labtestname,samplecodeformatted AS "RunNo",
    case 
    when req.orderstatus='active' then 'Sample Not Collected' 
    when req.orderstatus='pending' then 'Sample Collected'
    when req.orderstatus='result-added' then 'Result Added'
    when req.orderstatus='report-generated' then 'Report Generated' 
    end AS "TestStatus",
    case 
    when billingstatus in ('paid','unpaid') then 'Paid' 
    when billingstatus='cancel' then 'bill-cancelled'
    when billingstatus = 'returned' then 'bill-returned' 
    when billingstatus = 'provisional' then 'provisional' 
    end AS "BillStatus",
    emp1.fullname AS "SampleCollectedBy",emp4.fullname AS "ReportPrintedBy",
    emp2.fullname AS "CancelledByUser", req.billcancelledon
    from lab_testrequisition req 
    join v_orderstatuslist os on req.orderstatus = os.orderstatus
    left join emp_employee emp1 on req.samplecreatedby = emp1.employeeid
    left join emp_employee emp2 on req.billcancelledby = emp2.employeeid
    left join emp_employee emp3 on req.resultaddedby = emp3.employeeid
    left join lab_txn_labreports report on req.labreportid = report.labreportid
    left join emp_employee emp4 on report.printedby = emp4.employeeid
    join pat_patient pat on req.patientid=pat.patientid
    where (req.orderdatetime)::date between p_fromdate and p_todate
    order by req.orderdatetime desc;
    end if;
    end;
END;
$$ LANGUAGE plpgsql;