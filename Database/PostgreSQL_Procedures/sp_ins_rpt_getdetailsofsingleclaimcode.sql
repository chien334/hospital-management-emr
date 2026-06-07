CREATE OR REPLACE FUNCTION sp_ins_rpt_getdetailsofsingleclaimcode(
    p_patientid INT DEFAULT NULL,
    p_claimcode INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
BEGIN
    /*
     filename: "sp_ins_rpt_getdetailsofsingleclaimcode" 
     created: 28 oct'21/Swapnil
     Description: To get Details Of Single Claim Code with PatientId and Claim Code.
     Change History
     S.No.    Date/User                         Change Remarks
     1.       06Oct'21/swapnil                  inital draft
     2.       sud/sanjit: 31-oct'21             Corrected Pharmacy Data
     3.       Sud/18Jan'21                      added invoicenumber in billing and pharmacy details
    										    added  for uncommitted read (performance improvement)
     4.       sud/03feb'21                      Added InvoiceDate, Price, MRP, 
                                                Removed Grouping since it's no longer required
    */
    
    
       
    
    
    open ref1 for select  adm.admissiondate, adm.dischargedate, adm.admissionstatus
      from pat_patientvisits vis 
         inner join adt_patientadmission adm  
      on vis.patientvisitid=adm.patientvisitid
      where vis.patientid=p_patientid
          and vis.visittype='inpatient'
          and vis.claimcode=p_claimcode limit 1;
        return next ref1;
    
    
    open ref2 for select 
    		txn.patientid,
    		txn.claimcode,
    		txn.invoiceno,
    		(txn.createdon)::date as "invoicedate",
    		txnitm.servicedepartmentname,
    		txnitm.itemid,
    		txnitm.itemname,
    		txnitm.price,
    		coalesce(txnitm.quantity,0) as "sales_quantity",
    		coalesce(txnitm.subtotal,0) as "sales_subtotal",
    		coalesce(txnitm.discountamount,0) as "sales_discount",
    		coalesce(txnitm.totalamount,0) as "sales_totalamount",
    		coalesce(retitm.retqty,0) as "ret_quantity",
    		coalesce(retitm.retsubtotal,0) as "ret_subtotal",
    		coalesce(retitm.retdiscountamount,0) as "ret_discount",
    		coalesce(retitm.rettotalamount,0) as "ret_totalamount",
    		txnitm.totalamount - coalesce(retitm.rettotalamount,0) as "net_totalamount"
    
    		from bil_txn_billingtransaction txn  
    		   inner join bil_txn_billingtransactionitems txnitm  
    		       on txn.billingtransactionid=txnitm.billingtransactionid
    		left join 
    			(select billingtransactionitemid, patientid, 
    			 sum(coalesce(retquantity,0)) as "retqty",
    			 sum(coalesce(retsubtotal,0)) as "retsubtotal",
    			 sum(coalesce(retdiscountamount,0)) as "retdiscountamount",
    			 sum(coalesce(rettotalamount,0)) as "rettotalamount"
    			 from bil_txn_invoicereturnitems  
    			 where patientid=p_patientid 
    			 group by billingtransactionitemid, patientid
    		 ) retitm 		on txnitm.billingtransactionitemid=retitm.billingtransactionitemid
    
    		where txn.isinsurancebilling=1 
    		     and txn.patientid=p_patientid
    			 and txn.claimcode=p_claimcode;
        return next ref2;
    
     open ref3 for select
    	  inv.patientid,
    	  inv.claimcode,
    	  inv.invoiceprintid as "invoiceno",
    	  (inv.createon)::date as "invoicedate",
    	  invitm.itemname, gen.genericname,
    	  invitm.itemid,  invitm.batchno, invitm.expirydate, 
    	  invitm.mrp,
    	  invitm.quantity as "salesquantity",
    	  invitm.subtotal,
    	  invitm.totalamount as "salesamount",
    	  coalesce(invrt.ret_quantity,0) as "ret_quantity",
    	  coalesce(invrt.ret_totalamount,0)as returnamount, 
    	  coalesce(invitm.totalamount,0) - coalesce(invrt.ret_totalamount,0) as netamount  -- subtract return amount here..
      
      from
         phrm_mst_store store inner join 
         phrm_txn_invoice inv   on inv.storeid=store.storeid
         inner join phrm_txn_invoiceitems invitm    on inv.invoiceid=invitm.invoiceid
         inner join phrm_mst_item itm on invitm.itemid=itm.itemid
         left join phrm_mst_generic gen on itm.genericid = gen.genericid
    	 left join (
    	                  select invoiceitemid, 
    					   sum(coalesce(retitm.returnedqty,0)) as "ret_quantity", 
    					   sum(coalesce(retitm.subtotal,0)) as "ret_subtotal",  
    					   sum(coalesce(retitm.discountamount,0)) as "ret_discountamt", 
    					   sum(coalesce(retitm.totalamount,0)) as "ret_totalamount"
    					from phrm_txn_invoicereturnitems retitm  
    					     inner join phrm_txn_invoicereturn ret  
    					     on retitm.invoicereturnid = ret.invoicereturnid
    					where ret.patientid=p_patientid
    					group by invoiceitemid
    			    ) invrt 
    				on invitm.invoiceitemid = invrt.invoiceitemid  
    
      where 
      store.subcategory='insurance'  -- take only invoices created from insurance dispensaries. 
            and  inv.patientid=p_patientid and inv.claimcode = p_claimcode;
        return next ref3;
END;
$$ LANGUAGE plpgsql;