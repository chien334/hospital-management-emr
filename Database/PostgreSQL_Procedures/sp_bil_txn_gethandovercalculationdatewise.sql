CREATE OR REPLACE FUNCTION sp_bil_txn_gethandovercalculationdatewise(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS TABLE (
    "EmployeeId" INT,
    "HandOverDate" TIMESTAMP,
    "GivenAmount" DECIMAL,
    "ReceivedAmount" DECIMAL
) AS $$
BEGIN
    /*
     file: sp_bil_txn_gethandovercalculationdatewise
     details: to get total handover given amount and received amount by user on particular date range.
     change history:
     s.no.   date/author           remarks
     1.      16feb'20/Sud          Initial Draft (Needs Revision)
    */
    
    
    RETURN QUERY SELECT EmployeeId, HandOverDate, SUM(GivenAmount) AS "GivenAmount", SUM(ReceivedAmount) AS "ReceivedAmount"
    FROM
    
    (
     Select EmployeeID, HandoverDate 
    , Case WHEN HandOverType='handovergiven' THEN HandoverAmount
       ELSE 0 END AS "GivenAmount"
    ,  Case WHEN HandOverType='handoverreceived' THEN HandoverAmount
       ELSE 0 END AS "ReceivedAmount"
    
    From 
    (
    SELECT 'handovergiven' AS "HandOverType", (CreatedOn)::Date AS "HandOverDate", UserId AS "EmployeeId", SUM(HandoverAmount) AS "HandoverAmount"
    FROM BIL_MST_Handover
    Group By (CreatedOn)::Date,UserId 
    UNION ALL
    SELECT 'handoverreceived' as "handovertype", (createdon)::date AS "HandOverDate", handoveruserid AS "EmployeeId", sum(handoveramount) as "handoveramount"
    from bil_mst_handover
    group by (createdon)::date,handoveruserid 
    ) b
    where handoveramount !=0
     and handoverdate between (p_fromdate)::date and (p_todate)::date
    
    ) overall
    
    group by employeeid, handoverdate
    
    order by handoverdate, employeeid;
END;
$$ LANGUAGE plpgsql;