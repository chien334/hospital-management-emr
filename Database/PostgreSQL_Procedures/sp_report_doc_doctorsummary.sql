CREATE OR REPLACE FUNCTION sp_report_doc_doctorsummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_performerid INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "USG" VARCHAR,
    "OrthoProcedures" VARCHAR,
    "CT" VARCHAR,
    "OPD" VARCHAR,
    "Referral" VARCHAR,
    "FollowUp" VARCHAR,
    "GeneralSurgery" VARCHAR,
    "GynSurgery" VARCHAR,
    "ENT" VARCHAR,
    "Dental" VARCHAR,
    "OT" VARCHAR
) AS $$
BEGIN
    /*  
     filename: sp_report_doc_doctorsummary  
     created: 05april'18 <Ashim>  
     Description: To Get Doctor's summary count from different activities.  
     remarks:   
     change history  
     s.no.    date/user              change          remarks  
     1.      05april'18               created     
     2.		 Krishna,9thJun'22		 alter			changed providerid to performerid
    */  
    begin  
      
      
      
      if (p_fromdate is not null) or (p_todate is not null)  
     then  
      
    --start: get data from bil_txn_billingtransactionitems and pat_patientvisits and store into temptable---  
    create temp table temp_temptable(txndate timestamp, itemname text, quantity int,performerid int);  
    insert into temp_temptable (txndate,itemname,quantity,performerid)  
    (select createdon as "txndate",  
     servicedepartmentname as "itemname",  
     --this is active quantity--  
     quantity-coalesce(returnquantity,0) as "quantity",  
     performerid   
    from bil_txn_billingtransactionitems  
    where performerid is not null  
    and billstatus !='cancel'  
    and quantity-coalesce(returnquantity,0) != 0);  
      
    insert into temp_temptable (txndate,itemname,quantity,performerid)  
    (select visitdate as "txndate", appointmenttype as "itemname", 1 as "quantity", performerid  
    from pat_patientvisits);  
    --end: get data from bil_txn_billingtransactionitems and pat_patientvisits and store into temptable---  
      
      
     RETURN QUERY SELECT (t.txndate)::date AS "Date"  
     ,sum(case when t.itemname='USG' then t.quantity else 0 end) AS "USG"  
     ,sum(case when t.itemname='Ortho Procedures' then t.quantity else 0 end) AS "OrthoProcedures"  
     ,sum(case when t.itemname='CT Scan' then t.quantity else 0 end) AS "CT"  
     ,sum(case when t.itemname='New' then t.quantity else 0 end) AS "OPD"  
     ,sum(case when t.itemname='referral' then t.quantity else 0 end) AS "Referral"  
     ,sum(case when t.itemname='followup' then t.quantity else 0 end) AS "FollowUp"  
     ,sum(case when t.itemname='General Surgery Charges' then t.quantity else 0 end) AS "GeneralSurgery"  
     ,sum(case when t.itemname='OBS/GYN Surgery' then t.quantity else 0 end) AS "GynSurgery"  
     ,sum(case when t.itemname='ENT Operation' then t.quantity else 0 end) AS "ENT"  
     ,sum(case when t.itemname='Dental' then t.quantity else 0 end) AS "Dental"  
     ,sum(case when t.itemname='OT' then t.quantity else 0 end) AS "OT"  
     from temp_temptable t  
     where  t.txndate between  p_fromdate and p_todate+1   
      and t.performerid =p_performerid  
         
     group by (t.txndate)::date  
     order by date;  
     drop table if exists temp_temptable;  
      end if;--end of if  
    end;--end of sp
END;
$$ LANGUAGE plpgsql;