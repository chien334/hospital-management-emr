CREATE OR REPLACE FUNCTION sp_report_bil_doctordeptsummary(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_doctorid INT DEFAULT NULL
)
RETURNS TABLE (
    "Doctor" VARCHAR,
    "DepartmentName" VARCHAR,
    "ServiceDepartmentName" VARCHAR,
    "ServiceDepartmentId" INT,
    "NetAmount_Performer" DECIMAL,
    "NetAmount_Prescriber" DECIMAL,
    "NetAmount_Referrer" DECIMAL
) AS $$
BEGIN
    /*  
    change history  
    s.no.    updatedby/date          remarks  
    1    sud/02sept'18           Initial Draft  
    2  Ramavtar/30Nov'18   summary added   
    3  ramavtar/17dec'18   change in where condition (checking for credit records)  
    4    sud: 21Feb'19           updated as per new function  
    5    sud:13mar'19            Join with FN_BIL_GetSrvDeptReportingName_DoctorSummary to get actual service department name,   
                                 since it's now removed from  fn_bill_get_billingtxnitemseggregation_bybillingtype_noprovisional  
    6.	krishna/8thjun'22		Changed ProviderId to PerformerId and ProviderName to PerformerName
    7.	Krishna/10thAUG'22		changed sp as per performer,prescriber and referrer
    */  
      
      
      
    RETURN QUERY SELECT tbl1.doctor
    	,tbl1.departmentname
    	,tbl1.servicedepartmentname
    	,tbl1.servicedepartmentid
    	,sum(coalesce(tbl1.performernetamount, 0)) AS "NetAmount_Performer"
    	,sum(coalesce(tbl1.prescribernetamount, 0)) AS "NetAmount_Prescriber"
    	,sum(coalesce(tbl1.referrernetamount, 0)) AS "NetAmount_Referrer"
    from (
    	select tbl.doctor
    		,tbl.departmentname
    		,tbl.servicedepartmentname
    		,tbl.servicedepartmentid
    		,case 
    			when doctortype = 'Performer'
    				then sum(coalesce(netamount, 0))
    			end as "performernetamount"
    		,case 
    			when doctortype = 'Prescriber'
    				then sum(coalesce(netamount, 0))
    			end as "prescribernetamount"
    		,case 
    			when doctortype = 'Referrer'
    				then sum(coalesce(netamount, 0))
    			end as "referrernetamount"
    	from (
    	select 
    			coalesce(emp.fullname,'Unassigned') AS "Doctor",
    			billingdata.servicedepartmentid,
    			billingdata.servicedepartmentname,
    			billingdata.departmentname,
    			'Performer' as doctortype,
    			coalesce(billingdata.performerid,0) as "doctorid",
    			sum(billingdata.salesamount) as "salesamt",
    			sum(billingdata.returnamount) as "retamount",
    			sum(billingdata.netamount) as "netamount"
    			
    		from
    		(
    
    			select coalesce(invitm.performerid,retitm.performerid) as "performerid"
    			, coalesce(invitm.salesamount,0) as "salesamount"
    			, coalesce(retitm.returnamount,0) as "returnamount"
    			, coalesce(invitm.salesamount,0) - coalesce(retitm.returnamount,0) as "netamount"
    			,invitm.servicedepartmentid
    			,invitm.servicedepartmentname
    			,invitm.departmentname
    			from 
    			( select itm.billingtransactionitemid, performerid
    				, itm.totalamount as "salesamount",
    				serv.servicedepartmentid,serv.servicedepartmentname, dep.departmentname
    				from bil_txn_billingtransactionitems itm
    				inner join bil_txn_billingtransaction txn on itm.billingtransactionid=txn.billingtransactionid
    				inner join bil_mst_servicedepartment serv on serv.servicedepartmentid = itm.servicedepartmentid
    				inner join mst_department dep on dep.departmentid = serv.departmentid
    				where   (txn.createdon)::date between p_fromdate and p_todate
    				and coalesce(itm.performerid,0) = coalesce(p_doctorid,0)
       
    				) invitm 
    			full outer join 
    				( select rti.billingtransactionitemid, sum(rettotalamount) as "returnamount" 
    				, itm.performerid
    				from bil_txn_invoicereturnitems rti inner join bil_txn_billingtransactionitems itm
    					on rti.billingtransactionitemid=itm.billingtransactionitemid
    					inner join bil_txn_invoicereturn ret on rti.billreturnid=ret.billreturnid
    				where (ret.createdon)::date between p_fromdate and p_todate
    				and coalesce(itm.performerid,0) = coalesce(p_doctorid,0)
    				group by rti.billingtransactionitemid, itm.performerid
    			) retitm
    			on invitm.billingtransactionitemid=retitm.billingtransactionitemid
    		) billingdata
    		left join emp_employee emp on billingdata.performerid=emp.employeeid
    		group by coalesce(emp.fullname,'Unassigned'), billingdata.performerid, billingdata.servicedepartmentid,billingdata.servicedepartmentname, billingdata.departmentname
    
    		
    		union all
    		(
    	
    	select 
    			coalesce(emp.fullname,'Unassigned') AS "Doctor",
    			billingdata.servicedepartmentid,
    			billingdata.servicedepartmentname,
    			billingdata.departmentname,
    			'Prescriber' as doctortype,
    			coalesce(billingdata.prescriberid,0) as "doctorid",
    			sum(billingdata.salesamount) as "salesamt",
    			sum(billingdata.returnamount) as "retamount",
    			sum(billingdata.netamount) as "netamount"
    			
    		from
    		(
    
    			select coalesce(invitm.prescriberid,retitm.prescriberid) as "prescriberid"
    			, coalesce(invitm.salesamount,0) as "salesamount"
    			, coalesce(retitm.returnamount,0) as "returnamount"
    			, coalesce(invitm.salesamount,0) - coalesce(retitm.returnamount,0) as "netamount"
    			,invitm.servicedepartmentid
    			,invitm.servicedepartmentname
    			,invitm.departmentname
    			from 
    			( select itm.billingtransactionitemid, prescriberid
    				, itm.totalamount as "salesamount",
    				serv.servicedepartmentid,serv.servicedepartmentname, dep.departmentname
    				from bil_txn_billingtransactionitems itm
    				inner join bil_txn_billingtransaction txn on itm.billingtransactionid=txn.billingtransactionid
    				inner join bil_mst_servicedepartment serv on serv.servicedepartmentid = itm.servicedepartmentid
    				inner join mst_department dep on dep.departmentid = serv.departmentid
    				where   (txn.createdon)::date between p_fromdate and p_todate
    				and coalesce(itm.prescriberid,0) = coalesce(p_doctorid,0)
       
    				) invitm 
    			full outer join 
    				( select rti.billingtransactionitemid, sum(rettotalamount) as "returnamount" 
    				, itm.prescriberid
    				from bil_txn_invoicereturnitems rti inner join bil_txn_billingtransactionitems itm
    					on rti.billingtransactionitemid=itm.billingtransactionitemid
    					inner join bil_txn_invoicereturn ret on rti.billreturnid=ret.billreturnid
    				where (ret.createdon)::date between p_fromdate and p_todate
    				and coalesce(itm.prescriberid,0) = coalesce(p_doctorid,0)
    				group by rti.billingtransactionitemid, itm.prescriberid
    			) retitm
    			on invitm.billingtransactionitemid=retitm.billingtransactionitemid
    		) billingdata
    		left join emp_employee emp on billingdata.prescriberid=emp.employeeid
    		group by coalesce(emp.fullname,'Unassigned'), billingdata.prescriberid, billingdata.servicedepartmentid,billingdata.servicedepartmentname, billingdata.departmentname
    			)
    		
    		union all
    		
    		(
    	
    	select 
    			coalesce(emp.fullname,'Unassigned') AS "Doctor",
    			billingdata.servicedepartmentid,
    			billingdata.servicedepartmentname,
    			billingdata.departmentname,
    			'Referrer' as doctortype,
    			coalesce(billingdata.referredbyid,0) as "doctorid",
    			sum(billingdata.salesamount) as "salesamt",
    			sum(billingdata.returnamount) as "retamount",
    			sum(billingdata.netamount) as "netamount"
    			
    		from
    		(
    
    			select coalesce(invitm.referredbyid,retitm.referredbyid) as "referredbyid"
    			, coalesce(invitm.salesamount,0) as "salesamount"
    			, coalesce(retitm.returnamount,0) as "returnamount"
    			, coalesce(invitm.salesamount,0) - coalesce(retitm.returnamount,0) as "netamount"
    			,invitm.servicedepartmentid
    			,invitm.servicedepartmentname
    			,invitm.departmentname
    			from 
    			( select itm.billingtransactionitemid, referredbyid
    				, itm.totalamount as "salesamount",
    				serv.servicedepartmentid,serv.servicedepartmentname, dep.departmentname
    				from bil_txn_billingtransactionitems itm
    				inner join bil_txn_billingtransaction txn on itm.billingtransactionid=txn.billingtransactionid
    				inner join bil_mst_servicedepartment serv on serv.servicedepartmentid = itm.servicedepartmentid
    				inner join mst_department dep on dep.departmentid = serv.departmentid
    				where   (txn.createdon)::date between p_fromdate and p_todate
    				and coalesce(itm.referredbyid,0) = coalesce(p_doctorid,0)
       
    				) invitm 
    			full outer join 
    				( select rti.billingtransactionitemid, sum(rettotalamount) as "returnamount" 
    				, itm.referredbyid
    				from bil_txn_invoicereturnitems rti inner join bil_txn_billingtransactionitems itm
    					on rti.billingtransactionitemid=itm.billingtransactionitemid
    					inner join bil_txn_invoicereturn ret on rti.billreturnid=ret.billreturnid
    				where (ret.createdon)::date between p_fromdate and p_todate
    				and coalesce(itm.referredbyid,0) = coalesce(p_doctorid,0)
    				group by rti.billingtransactionitemid, itm.referredbyid
    			) retitm
    			on invitm.billingtransactionitemid=retitm.billingtransactionitemid
    		) billingdata
    		left join emp_employee emp on billingdata.referredbyid=emp.employeeid
    		group by coalesce(emp.fullname,'Unassigned'), billingdata.referredbyid, billingdata.servicedepartmentid,billingdata.servicedepartmentname, billingdata.departmentname
    			)
    		) tbl
    	group by tbl.departmentname,tbl.servicedepartmentid
    		,tbl.servicedepartmentname
    		,tbl.doctor
    		,tbl.doctortype
    	) tbl1
    group by tbl1.departmentname,tbl1.servicedepartmentid
    	,tbl1.servicedepartmentname
    	,tbl1.doctor
    order by tbl1.doctor;
END;
$$ LANGUAGE plpgsql;