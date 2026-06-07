CREATE OR REPLACE FUNCTION sp_txns_phrm_settlementsummary(
    p_storeid INT DEFAULT NULL,
    p_organizationid INT DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "CreditTotal" DECIMAL,
    "ProvisionalTotal" TIMESTAMP,
    "DepositBalance" DECIMAL,
    "CreditDate" TIMESTAMP,
    "DepositDate" TIMESTAMP,
    "BilStatus" VARCHAR,
    "SettlementId" INT
) AS $$
BEGIN
    /*
    filename: "sp_txns_phrm_settlementsummary" 40
    createdby/date: sanjit:24nov2019
    description: to get credittotal, depositbalance of patients
    remarks:   we're selecting only those patients, who has balance amount in any of above types.
           : I've kept amount > 1 in filter list, otherwise it'll show a lot of un-necessary data.. 
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.		Shankar/28thFeb2020				Added provisional amount as well
    2.		VIKAS/1st Sep 2020				Added BilStatus, and SettlementId and get paid and unpaid credit bills data
    3.		Shankar/7th Dec 2020			Subtracted Credit invoice return from CreditTotal
    4.      Ramesh/7th Sep'21               added store id filter 
    5.      rohit/5th dec'21				Added BillStatus condition to get all pending/unpaid settlement 
    6.		Rohit/27th Dec'21				returned invoice before settlement  is filtered using settlementid is null.
    7.      dev narayan/7thjune'22          Added Credit Organization Filter.
    8.		Rohit/6Jul'23					paidamount -> creditamount in credit table
    */
    begin
     
    RETURN QUERY SELECT pat.patientid, pat.patientcode, 
           pat.firstname||' '||coalesce(pat.middlename||' ','')|| pat.lastname AS "PatientName", 
    	   pat.dateofbirth,
    	   pat.gender,pat.phonenumber,	   
           cast(coalesce(credit.credittotal,0) - coalesce(invretn.paidamount,0) as numeric(16,2)) AS "CreditTotal",
    	   cast(round(coalesce(provisional.provisionaltotal,0),2) as numeric(16,2)) AS "ProvisionalTotal",
    	   cast(
    	      round( 
    	           (coalesce(dep.totaldeposit,0)- coalesce(dep.depositdeduction,0) - coalesce(dep.depositreturn,0))
    	         ,2) as numeric(16,2)) AS "DepositBalance",
    			 credit.createdon AS "CreditDate" ,dep.createdon AS "DepositDate",
    	credit.bilstatus, credit.settlementid -- vikas:1st sep 2020: added bilstatus , and  settlementid
    	
    from pat_patient pat
    left join
    ( 
      select txn.patientid, max(txn.createon) as "createdon", txn.bilstatus,txn.settlementid,txn.organizationid,
      sum(txn.creditamount) AS "CreditTotal"  from phrm_txn_invoice txn
      where txn.bilstatus ='unpaid' and
       txn.paymentmode = 'credit' 
      and coalesce(txn.isreturn,0) != 1
      and txn.storeid = p_storeid 
      and txn.organizationid = p_organizationid
      group by txn.patientid,txn.bilstatus, txn.settlementid,txn.organizationid
    ) credit on pat.patientid = credit.patientid
    
    
    left join
    (
    select invret.patientid,sum(invret.paidamount) as "paidamount" from phrm_txn_invoice inv
    join phrm_txn_invoicereturn invret on inv.invoiceid = invret.invoiceid --and invret.paymentmode = 'credit'
    where invret.paymentmode = 'credit' and inv.storeid = p_storeid and invret.settlementid is null
    and inv.organizationid =p_organizationid
    group by invret.patientid
    ) invretn on pat.patientid = invretn.patientid
    
    
    left join
    (--select * from phrm_txn_invoice where bilstatus = 'provisional'
      select invitms.patientid, max(invitms.createdon) as "createdon",
      sum(invitms.totalamount) AS "ProvisionalTotal" from phrm_txn_invoiceitems invitms
      where invitms.bilitemstatus='provisional' or invitms.bilitemstatus='wardconsumption' and invitms.storeid = p_storeid
      group by invitms.patientid
    ) provisional on pat.patientid = provisional.patientid
    
    left join
    ( 
      select dep.patientid,max(dep.createdon) as "createdon",
        sum(case when dep.deposittype='deposit' then coalesce(dep.depositamount,0) else 0  end ) as "totaldeposit",
        sum(case when dep.deposittype='depositdeduct' then coalesce(dep.depositamount,0) else 0  end ) as "depositdeduction",
    	sum(case when dep.deposittype='depositreturn' then coalesce(dep.depositamount,0) else 0  end ) as "depositreturn"
       from phrm_deposit dep
       where dep.storeid = p_storeid
       group by dep.patientid
    ) dep
    on dep.patientid = pat.patientid
    
    where 
    	  credit.organizationid = p_organizationid and
    	  cast(coalesce(credit.credittotal,0) - coalesce(invretn.paidamount,0) as numeric(16,2)) > 1 
    	  or ( dep.totaldeposit-dep.depositdeduction - dep.depositreturn) > 1
    --to get the latest first
    	  order by
      case
          when coalesce(dep.createdon,0) >= coalesce(credit.createdon,0)
              then  dep.createdon
          else  credit.createdon 
      end
     desc;
    end;
END;
$$ LANGUAGE plpgsql;