CREATE OR REPLACE FUNCTION sp_report_discount(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_counterid INT DEFAULT NULL,
    p_createdby INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ReferenceReceipt" VARCHAR,
    "ReceiptNo" VARCHAR,
    "HospitalNumber" VARCHAR,
    "PatientName" VARCHAR,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "TotalAmount" DECIMAL,
    "User" VARCHAR,
    "Remarks" VARCHAR,
    "CounterName" INT,
    "SchemeName" VARCHAR,
    "VisitType" VARCHAR,
    "Contact" TIMESTAMP,
    "Address" VARCHAR,
    "DischargeDate" TIMESTAMP,
    "Age" VARCHAR,
    "Gender" VARCHAR
) AS $$
BEGIN
    /*
    filename: "[sp_report_discount"]
    createdby/date: dinesh/2018-07-05
    description: to get the discount report for the hospital
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       dinesh/2018-07-05					created the script
    2		krishna/2022-07-21					modified the sp with new query
    3		krishna/2022-04-08					modified the sp in created by and counter id
    4		sanjeev/2023-08-28					add schemename in select query
    5		krishna/24thsept'23					Read TransactionType AS "VisitType"
    6		Krishna/10thOct'23					read phonenumber and address
    7		krishna/16thoct'23					Read DischargeDate for inpatient invoices
    8		Krishna/7thNov'23					read age and gender
    */
    begin
    if p_counterid = 0
    			then
    			p_counterid := null;
    		end if;
    	if (p_fromdate is not null) or (p_todate is not null) 
    		then
    					
    			RETURN QUERY SELECT 
    				txn.createdon AS "Date",
    				'N/A' AS "ReferenceReceipt",
    				concat(txn.invoicecode,(invoiceno)::varchar) AS "ReceiptNo",
    				pat.patientcode AS "HospitalNumber",
    				pat.shortname AS "PatientName",
    				subtotal AS "SubTotal",
    				discountamount AS "DiscountAmount",
    				totalamount AS "TotalAmount",
    				emp.fullname AS "User",
    				txn.remarks AS "Remarks",
    				cntr.countername AS "CounterName",
    				scheme.schemename AS "SchemeName",
    				txn.transactiontype AS "VisitType",
    				pat.phonenumber AS "Contact",
    				coalesce(pat.address,'') || coalesce(', '|| mun.municipalityname,'') || coalesce(', '|| country.countrysubdivisionname,'') AS "Address",
    				iif(coalesce(((adm.dischargedate)::date)::varchar,'') = '','',((adm.dischargedate)::date)::varchar)  AS "DischargeDate",
    				concat((datediff(year, pat.dateofbirth, current_timestamp))::varchar, 'Y') AS "Age",
    				pat.gender AS "Gender"
    			from bil_txn_billingtransaction txn
    				left join adt_patientadmission adm on txn.patientvisitid = adm.patientvisitid
    				inner join pat_patient pat on pat.patientid = txn.patientid
    				left join mst_municipality mun on pat.municipalityid = mun.municipalityid
    				inner join mst_countrysubdivision country on pat.countrysubdivisionid = country.countrysubdivisionid
    				inner join emp_employee emp on emp.employeeid = txn.createdby
    				inner join bil_cfg_counter cntr on cntr.counterid = txn.counterid
    				inner join bil_cfg_scheme scheme on txn.schemeid = scheme.schemeid
    			where coalesce(discountamount,0) > 0
    				and (txn.createdon)::date between (p_fromdate)::date and (p_todate)::date 
    				and txn.counterid = coalesce(p_counterid, txn.counterid) and txn.createdby = coalesce(p_createdby, txn.createdby)
    
    			union
    			(
    				select 
    				ret.createdon AS "Date",
    				'BL-'||(ret.refinvoicenum)::varchar AS "ReferenceReceipt",
    				'CR-'||(ret.creditnotenumber)::varchar AS "ReceiptNo",
    				pat.patientcode AS "HospitalNumber",
    				pat.shortname AS "PatientName",
    				tbl.subtotal,
    				tbl.discountamount,
    				tbl.totalamount,
    				emp.fullname AS "User",
    				ret.remarks AS "Remarks",
    				cntr.countername AS "CounterName",
    				tbl.schemename,
    				tbl.billingtype AS "VisitType",
    				pat.phonenumber AS "Contact",
    				coalesce(pat.address,'') || coalesce(', '|| mun.municipalityname,'') || coalesce(', '|| country.countrysubdivisionname,'') AS "Address",
    				'' AS "DischargeDate",
    				concat((datediff(year, pat.dateofbirth, current_timestamp))::varchar, 'Y') AS "Age",
    				pat.gender AS "Gender"
    			from bil_txn_invoicereturn ret
    			inner join (
    					select 
    							sum(coalesce(retitems.retsubtotal,0)) AS "SubTotal",
    							sum(coalesce(retitems.retdiscountamount,0)) AS "DiscountAmount",
    							sum(coalesce(retitems.rettotalamount,0)) AS "TotalAmount",
    							retitems.billreturnid,
    							retitems.billingtype,
    							scheme.schemename
    					from bil_txn_invoicereturnitems retitems
    					inner join bil_cfg_scheme scheme on retitems.discountschemeid = scheme.schemeid
    					where (retitems.createdon)::date between (p_fromdate)::date and (p_todate)::date 
    			and retitems.retcounterid = coalesce(p_counterid, retitems.retcounterid) and retitems.createdby = coalesce(p_createdby, retitems.createdby)
    				group by retitems.billingtransactionid, retitems.billreturnid, scheme.schemename, retitems.billingtype)tbl
    				on tbl.billreturnid = ret.billreturnid
    				inner join pat_patient pat
    				left join mst_municipality mun on pat.municipalityid = mun.municipalityid
    				inner join mst_countrysubdivision country on pat.countrysubdivisionid = country.countrysubdivisionid
    				on pat.patientid = ret.patientid
    				inner join emp_employee emp
    				on emp.employeeid = ret.createdby
    				inner join bil_cfg_counter cntr
    				on cntr.counterid = ret.counterid
    			where coalesce(tbl.discountamount,0) > 0
    				and (ret.createdon)::date between (p_fromdate)::date and (p_todate)::date 
    				and ret.counterid = coalesce(p_counterid, ret.counterid) and ret.createdby = coalesce(p_createdby, ret.createdby)
    			);
    		end if;
    end;
END;
$$ LANGUAGE plpgsql;