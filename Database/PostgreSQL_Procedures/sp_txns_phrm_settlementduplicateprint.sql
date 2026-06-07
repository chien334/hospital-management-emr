CREATE OR REPLACE FUNCTION sp_txns_phrm_settlementduplicateprint(

)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "SettlementId" INT,
    "CreditTotal" DECIMAL,
    "DepositBalance" DECIMAL,
    "CreditDate" TIMESTAMP,
    "DepositDate" TIMESTAMP
) AS $$
BEGIN
    /*
    filename: "sp_txns_phrm_settlementduplicateprint"
    createdby/date: vikas: 4th march 2020
    description: script for pharmacy duplicate settlement records
    remarks: 
    change history
    s.no.    updatedby/date                        remarks
    */
    
     
    RETURN QUERY SELECT pat.patientid, pat.patientcode, 
           pat.firstname||' '||coalesce(pat.middlename||' ','')|| pat.lastname AS "PatientName", 
    	   pat.dateofbirth,
    	   pat.gender,pat.phonenumber, credit.settlementid,
         coalesce( credit.credittotal,0) AS "CreditTotal",
    	 cast(
    	      round( 
    	           (coalesce(dep.totaldeposit,0)- coalesce(dep.depositdeduction,0) - coalesce(dep.depositreturn,0))
    	         ,2) as numeric(16,2)) AS "DepositBalance",
    			 credit.createdon AS "CreditDate" ,dep.createdon AS "DepositDate"
    from pat_patient pat
    left join
    (
       select txn.patientid, max(txn.createon) as "createdon", txn.settlementid,
      sum(txn.totalamount) AS "CreditTotal"  from phrm_txn_invoice txn
      where txn.bilstatus ='paid' and txn.settlementid is not null and coalesce(txn.isreturn,0) != 1
      group by txn.patientid,txn.settlementid 
    ) credit on pat.patientid = credit.patientid
    left join
    ( 
      select dep.patientid,max(dep.createdon) as "createdon",
        sum(case when dep.deposittype='deposit' then coalesce(dep.depositamount,0) else 0  end ) as "totaldeposit",
        sum(case when dep.deposittype='depositdeduct' then coalesce(dep.depositamount,0) else 0  end ) as "depositdeduction",
    	sum(case when dep.deposittype='depositreturn' then coalesce(dep.depositamount,0) else 0  end ) as "depositreturn"
       from phrm_deposit dep
       group by dep.patientid
    ) dep
    on dep.patientid = pat.patientid
    
    where coalesce(credit.credittotal,0) > 1 
    	  or ( dep.totaldeposit-dep.depositdeduction - dep.depositreturn) > 1
    --to get the latest first
    	  order by credit.settlementid desc;
END;
$$ LANGUAGE plpgsql;