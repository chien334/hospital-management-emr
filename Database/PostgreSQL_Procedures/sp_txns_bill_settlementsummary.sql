CREATE OR REPLACE FUNCTION sp_txns_bill_settlementsummary(
    p_organizationid INT
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "CreditTotal" DECIMAL,
    "ProvisionalTotal" TIMESTAMP,
    "DepositBalance" DECIMAL,
    "LastTxnDate" TIMESTAMP
) AS $$
BEGIN
    /*
    filename: sp_txns_bill_settlementsummary
    createdby/date: deepak,sud: 24march'20
    Description: to get Deposit, Provisional, Credit Total for Settlement Details.
    Remarks: 
    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1.        Deepak,Sud/24Apr'20                provisional issue, emr-1989
    2.		  krishna 28thnov'21				 Returned bill populating issue resolved (EMR:4365)
    3.		  Krishna 03,Feb,22					 Added OrganizationId Parameter to get the grid data organization wise
    4.        sud/Krishna:26Jul'22               organizationid check in return as well.
    5.		  krishna/21stapril'23				 Bring Credit Invoices from BIL_TXN_CreditBillStatus Table
    6.		  Krishna/24thApril'23				 fetch pharmacy credits and provisional amounts
    */
    
    begin 
    	RETURN QUERY SELECT 
    		pat.patientid, pat.patientcode, 
    		pat.firstname||' '||coalesce(pat.middlename||' ','')|| pat.lastname AS "PatientName", 
    		pat.dateofbirth,
    		pat.gender,		
    		(coalesce(credit.billcredittotal,0) + coalesce(phrmcredits.phrmcredittotal, 0)) AS "CreditTotal", 
    		(cast(round(coalesce(prov.billprovisionaltotal,0),2) as numeric(16,2)) + cast(round(coalesce(phrmprov.phrmprovisionaltotal,0),2) as numeric(16,2)))  AS "ProvisionalTotal", 
    		cast(round((coalesce(dep.totaldeposit,0)- coalesce(dep.depositdeduction,0) - coalesce(dep.depositreturn,0)),2) as numeric(16,2)) AS "DepositBalance",
    
    	case when coalesce(dep_createdon,'2010-01-01') > coalesce(bill_prov_createdon,'2010-01-01') 
    			and  coalesce(dep_createdon,'2010-01-01') > coalesce(bill_inv_createdon,'2010-01-01')
    			and coalesce(dep_createdon, '2010-01-01') > coalesce(phrm_inv_createdon, '2010-01-01') 
    			and coalesce(dep_createdon,'2010-01-01') > coalesce(bill_prov_createdon,'2010-01-01')  then dep_createdon
    		when coalesce(bill_prov_createdon,'2010-01-01') > coalesce(dep_createdon,'2010-01-01')  
    			and coalesce(bill_prov_createdon,'2010-01-01') >coalesce(bill_inv_createdon,'2010-01-01')
    			and coalesce(bill_prov_createdon,'2010-01-01') >coalesce(phrm_inv_createdon,'2010-01-01')
    			and coalesce(bill_prov_createdon,'2010-01-01') >coalesce(phrm_prov_createdon,'2010-01-01') then bill_prov_createdon
    		when coalesce(phrm_prov_createdon,'2010-01-01') > coalesce(dep_createdon,'2010-01-01')  
    			and coalesce(phrm_prov_createdon,'2010-01-01') >coalesce(bill_inv_createdon,'2010-01-01')
    			and coalesce(phrm_prov_createdon,'2010-01-01') >coalesce(phrm_inv_createdon,'2010-01-01')
    			and coalesce(phrm_prov_createdon,'2010-01-01') >coalesce(bill_prov_createdon,'2010-01-01') then phrm_prov_createdon
    		when coalesce(phrm_inv_createdon,'2010-01-01') > coalesce(dep_createdon,'2010-01-01')  
    			and coalesce(phrm_inv_createdon,'2010-01-01') >coalesce(bill_inv_createdon,'2010-01-01')
    			and coalesce(phrm_inv_createdon,'2010-01-01') >coalesce(phrm_prov_createdon,'2010-01-01')
    			and coalesce(phrm_inv_createdon,'2010-01-01') >coalesce(bill_prov_createdon,'2010-01-01') then phrm_inv_createdon
    	else bill_inv_createdon end  
    	AS "LastTxnDate"
    
    --credit.createdondate
    	from pat_patient pat
    
    	left join
    	(
    		select 
    			txn.patientid,
    			txn.creditorganizationid as "organizationid",
    			max(txn.createdon) as "billcreatedondate" ,
    			sum(netreceivableamount) as "billcredittotal",  --need to check calculation for credittotal 
    			max(txn.createdon) as "bill_inv_createdon" 
    		from bil_txn_creditbillstatus txn
    		join bil_mst_credit_organization org 
    		on txn.creditorganizationid = org.organizationid
    		where txn.settlementstatus ='pending' and org.isclaimmanagementapplicable = 0 --do not take claim management applilcable
    			and coalesce(txn.creditorganizationid,0) = p_organizationid
    		group by txn.patientid, txn.creditorganizationid
    	) credit on pat.patientid = credit.patientid 
    
    	left join
    	(
    		select 
    			txnitm.patientid, 
    			sum(txnitm.totalamount) as "billprovisionaltotal", 
    			max(createdon) as "bill_prov_createdon"   -- sud
    		from bil_txn_billingtransactionitems txnitm
    		where 
    			txnitm.billstatus ='provisional'  -- this takes only provisional
    			and txnitm.billingtype !='inpatient'
    			--and txnitm.billingtransactionid is not null  -- this takes invoice created
    			and coalesce(txnitm.returnstatus,0) != 1 and coalesce(txnitm.isinsurance,0) != 1 
    
    		group by txnitm.patientid
    	) prov on pat.patientid = prov.patientid
    
    	left join
    	( 
    		select 
    			dep.patientid,
    			sum(case when dep.transactiontype='Deposit' then coalesce(dep.inamount,0) else 0  end ) as "totaldeposit",
    			sum(case when dep.transactiontype='depositdeduct' then coalesce(dep.outamount,0) else 0  end ) as "depositdeduction",
    			sum(case when dep.transactiontype='ReturnDeposit' then coalesce(dep.outamount,0) else 0  end ) as "depositreturn",
    			max(dep.createdon) as "dep_createdon"   -- sud
    		from bil_txn_deposit dep where dep.organizationorpatient = 'patient'
    		group by dep.patientid
    	) dep on dep.patientid = pat.patientid
    
    	left join
    	(
    		select 
    			phrmcredit.patientid,
    			phrmcredit.creditorganizationid as "organizationid",
    			max(phrmcredit.createdon) as "phrmcreatedondate" ,
    			sum(netreceivableamount) as "phrmcredittotal",  --need to check calculation for credittotal 
    			max(phrmcredit.createdon) as "phrm_inv_createdon" 
    		from phrm_txn_creditbillstatus phrmcredit
    		join bil_mst_credit_organization org 
    		on phrmcredit.creditorganizationid = org.organizationid
    		where phrmcredit.settlementstatus ='pending' and org.isclaimmanagementapplicable = 0 --do not take claim management applilcable
    			and coalesce(phrmcredit.creditorganizationid,0) = p_organizationid
    		group by phrmcredit.patientid, phrmcredit.creditorganizationid
    	) phrmcredits on pat.patientid = phrmcredits.patientid 
    
    	left join
    	(
    		select 
    			patcons.patientid, 
    			(sum(coalesce(patcons.totalamount,0)) - sum(coalesce(retpatcons.phrmreturntotalamount,0))) as "phrmprovisionaltotal", 
    			max(createdon) as "phrm_prov_createdon"  
    		from phrm_txn_patientconsumptionitem patcons
    		left join (select patientconsumptionitemid,sum(totalamount) as "phrmreturntotalamount" from phrm_txn_patientconsumptionreturnitem
    		group by patientconsumptionitemid) retpatcons
    		on retpatcons.patientconsumptionitemid = patcons.patientconsumptionitemid
    		where 
    			patcons.isfinalize = 0  -- this takes only provisional
    			and patcons.visittype !='inpatient'
    		group by patcons.patientid
    	) phrmprov on pat.patientid = phrmprov.patientid
    
    	where credit.organizationid = p_organizationid
    		and (coalesce(credit.billcredittotal,0) > 1 
    		or coalesce(prov.billprovisionaltotal,0) > 1  
    		or (dep.totaldeposit-dep.depositdeduction - dep.depositreturn) > 1)
    		or (coalesce(phrmcredits.phrmcredittotal,0)) > 1
    		or (coalesce(phrmprov.phrmprovisionaltotal,0) > 1)
    	order by lasttxndate desc;
    end;
END;
$$ LANGUAGE plpgsql;