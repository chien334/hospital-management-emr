CREATE OR REPLACE FUNCTION sp_report_bil_doctorreferrals(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_performername VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "VisitDate" TIMESTAMP,
    "PerformerName" VARCHAR,
    "TotalReferrals" DECIMAL,
    "ReferralCount" INT,
    "ReferralAmount" DECIMAL
) AS $$
BEGIN
    /*  
    filename: sp_report_bil_doctorreferrals  
    createdby/date: umed/2017-09-04 (yyyy-mm-dd)  
    description: to get the referral count of patient by doctor wise along with other details  
    remarks:      
    change history  
    s.no.    updatedby/date                        remarks  
    1       umed/2017-09-04                      created the script  
    2       sud/12dec'17                         altered output columns   
    3       Umed/16April-18                     Alter Script (Added OrderBy Date in Desc) 
    4		Krishna/9thJun'22					changed providerid to performerid and providername to performername
    */  
      
      
      RETURN QUERY SELECT  visitdate,  
             coalesce(nullif(emp.salutation,'')||'. ','') || emp.firstname||coalesce(' '||emp.middlename,'')||' '||emp.lastname AS "PerformerName",  
          (sum(1))::float AS "TotalReferrals",  
          (sum( 1/(totalreferrals)::float))::float AS "ReferralCount",  
             (sum( bttxit.totalamount/(totalreferrals)::float))::float AS "ReferralAmount"  
    from bil_txn_billingtransactionitems bttxit,  
           fn_appt_getreferalvisitinformation() vis,  
        emp_employee emp  
    where   
      bttxit.servicedepartmentname='OPD' and  
      bttxit.requisitionid = vis.initialvisitid and  
      vis.performerid=emp.employeeid and  
      visitdate between coalesce(p_fromdate,(current_timestamp)::date)  and coalesce(p_todate+1,(current_timestamp)::date)  
      and coalesce(nullif(emp.salutation,'')||'. ','') || emp.firstname||coalesce(' '||emp.middlename,'')||' '||emp.lastname like '%'||coalesce(p_performername,'')||'%'  
    group by visitdate, vis.performerid  
         ,coalesce(nullif(emp.salutation,'')||'. ','') || emp.firstname||coalesce(' '||emp.middlename,'')||' '||emp.lastname  
    order by visitdate desc;
END;
$$ LANGUAGE plpgsql;