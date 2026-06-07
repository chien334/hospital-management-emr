CREATE OR REPLACE FUNCTION sp_report_dailycollectionvshandoverreport(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS TABLE (
    "EmployeeId" INT,
    "FullName" VARCHAR,
    "CollectionTillDate" TIMESTAMP,
    "HandoverTillDate" TIMESTAMP,
    "DueAmount" DECIMAL,
    "Date" TIMESTAMP
) AS $$
BEGIN
    -- =============================================
    -- author:        <pratik mani lamichhane>
    -- create date: <10 aug 2021>
    -- description:    <dailycollection vs handover report>
    -- =============================================
    
    
     
    
    RETURN QUERY SELECT empmst.employeeid, emp1.fullname,
            coalesce(colln.collectionamount,0) AS "CollectionTillDate", 
            coalesce(deps.handoveramount,0) AS "HandoverTillDate",
            coalesce(colln.collectionamount,0)-coalesce(deps.handoveramount,0) AS "DueAmount",
            empmst.dates AS "Date"
    
     
    
    from 
    (
        select * from (select distinct employeeid from txn_empcashtransaction) employee
        cross join (select * from fn_common_getalldatesbetweenrange(p_fromdate,p_todate)) dates
    ) empmst 
    
     
    
    left join emp_employee emp1  on empmst.employeeid = emp1.employeeid 
    
     
    
    left join
    (
        select employeeid,
        sum(coalesce(inamount,0)) - sum(coalesce(outamount,0)) as "collectionamount",
        (transactiondate)::date as "collectiondate"
        from txn_empcashtransaction  
        where  transactiontype !='HandoverGiven' and (transactiondate)::date between (p_fromdate)::date and (p_todate)::date
        group by employeeid,(transactiondate)::date
    ) colln on empmst.employeeid = colln.employeeid and empmst.dates = collectiondate
    
     
    
    
     left join
    (
        select employeeid,
        sum(coalesce(outamount,0)) as "handoveramount",
        (transactiondate)::date as "handovertransactiondate"
        from txn_empcashtransaction  
        where transactiontype ='HandoverGiven' and (transactiondate)::date between (p_fromdate)::date and (p_todate)::date
        group by employeeid,(transactiondate)::date
    ) deps on empmst.employeeid = deps.employeeid and empmst.dates = handovertransactiondate
    
     where coalesce(colln.collectionamount,0) !=0 or  coalesce(deps.handoveramount,0)!=0
     order by emp1.fullname;
END;
$$ LANGUAGE plpgsql;