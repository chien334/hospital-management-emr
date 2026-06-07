CREATE OR REPLACE FUNCTION sp_ird_phrm_invoicedetails(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Fiscal_Year" VARCHAR,
    "Bill_No" VARCHAR,
    "Customer_name" VARCHAR,
    "PANNumber" VARCHAR,
    "BillDate" TIMESTAMP,
    "BillType" VARCHAR,
    "Amount" DECIMAL,
    "DiscountAmount" INT,
    "Total_Amount" DECIMAL,
    "Tax_Amount" DECIMAL,
    "Taxable_Amount" DECIMAL,
    "NonTaxable_Amount" TIMESTAMP,
    "SyncedWithIRD" VARCHAR,
    "Is_Printed" BOOLEAN,
    "Printed_Time" TIMESTAMP,
    "Entered_By" VARCHAR,
    "Printed_by" VARCHAR,
    "Print_Count" INT,
    "Is_Realtime" TIMESTAMP,
    "Is_Bill_Active" BOOLEAN,
    "Payment_Method" VARCHAR,
    "TransactionId" INT
) AS $$
BEGIN
    /*
    filename: "sp_ird_phrm_invoicedetails"
    createdby/date: vikas/2018-10-24
    description: to get the pharmacy invoice details as per ird requirements 
     change history:
     s.no      modifiedby/date                     remarks
     1.			vikas/2018-10-24					 created
     2.        22 nov 2018 by nageshbb               update for fiscal year, and other columns
     3.			ajay/04 dec 2018					 changed invoiceid to invoiceprintid
     4.			vikas/02 jan 2019					 modify patient shortname(firstname and last name) to fullname(first,middle, and lastname)
     5.         sud/2jul'21                        * Setting Is_Bill_Active=False if One or more CreditNote generated from current invoice.
    								               * Taking Customer_name from Patient>ShortName field
    								               * Corrected Double Columns (Is_Realtime, and Isbillactive were returned twice)
    											   * Corrected SourceColumns for EmpName and PatientName.
     6.         Shankar/20thSept'21                  update for payment_method and transactionid columns(revised as per new ird requirements)
    */
    
    begin
      if (p_fromdate is not null) or (p_todate is not null)  
    	 then
    	 
    RETURN QUERY SELECT 
           fisc.fiscalyearformatted AS "Fiscal_Year",
    		(inv.invoiceprintid)::varchar AS "Bill_No",
    		pat.shortname AS "Customer_name",	
    		pat.pannumber,		
    	    to_char(inv.createon, 'YYYY-MM-DD') AS "BillDate",
    		'ItemTransaction' AS "BillType", --here only for ird details need to handle into pharmacy table also
    	    inv.subtotal AS "Amount",
            inv.discountamount AS "DiscountAmount",
    	   ((inv.subtotal-inv.discountamount)+inv.vatamount) AS "Total_Amount",
    	   (inv.vatamount) AS "Tax_Amount" ,
    	   case when inv.vatamount >0 or inv.vatamount is null then inv.subtotal-inv.discountamount else 0 end AS "Taxable_Amount" ,
    	   case when inv.vatamount <=0 or inv.vatamount is null then inv.subtotal-inv.discountamount else 0 end AS "NonTaxable_Amount"  ,
    	   case when inv.isremotesynced=1 then 'Yes' else 'No' end AS "SyncedWithIRD",
    	   case when inv.printcount > 0  then 'Yes' else 'No' end AS "Is_Printed",	
    	   case when inv.printcount >0 then   to_char((inv.createon)::time, 'YYYY-MM-DD') else '' end AS "Printed_Time",
    
    	   emp.fullname AS "Entered_By",				   
    	   emp.fullname  AS "Printed_by",
    	   inv.printcount AS "Print_Count",
    	   case when coalesce(inv.isrealtime,0)=1 then 'Yes' else 'No' end AS "Is_Realtime",		
    		case
    			when coalesce(ret.returninvoiceid, 0) = 0 then 'True'
    			else 'False' 
    		end AS "Is_Bill_Active",
    		inv.paymentmode AS "Payment_Method",
    		inv.invoiceid AS "TransactionId"
    
    
      from phrm_txn_invoice inv 
    	  inner join	emp_employee emp on emp.employeeid=inv.createdby
    	  inner join    pat_patient pat on pat.patientid=inv.patientid
    	  inner join bil_cfg_fiscalyears fisc on inv.fiscalyearid=fisc.fiscalyearid
    	  left join(select distinct invoiceid as "returninvoiceid" from phrm_txn_invoicereturn )ret 
    		  on inv.invoiceid = ret.returninvoiceid
    
      where (  
            (inv.createon)::date between (p_fromdate)::date 
         and (p_todate)::date 
         ); 
    	  end if;
    end;
END;
$$ LANGUAGE plpgsql;