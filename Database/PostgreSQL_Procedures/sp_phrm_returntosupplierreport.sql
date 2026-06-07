CREATE OR REPLACE FUNCTION sp_phrm_returntosupplierreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "SN" VARCHAR,
    "SupplierName" VARCHAR,
    "GenericName" VARCHAR,
    "ItemName" VARCHAR,
    "ReturnDate" TIMESTAMP,
    "Qty" INT,
    "SubTotal" DECIMAL,
    "DiscountAmount" INT,
    "VATAmount" DECIMAL,
    "TotalAmount" DECIMAL,
    "SupplierCreditNoteNum" VARCHAR,
    "CreditNoteNum" VARCHAR,
    "Remarks" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_phrm_returntosupplierreport" 
    createdby/date:rusha/04-08-2019
    description: to get report of stock detials return to supplier from pharmacy store 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		 naveed/2019-12-13				      updated script for exclude zero quantity items from report
    2.       sanjesh/2021-02-22                   updated script for supplier name 
    3.       rusha/21thjuly22				      added generic name in column
    */
     begin
      if ((p_fromdate is not null) and (p_todate is not null)) 
    		then
    			RETURN QUERY SELECT (rtnitm.createdon)::date AS "Date"
    			,(cast(row_number() over (order by  supp.suppliername)  as int)) AS "SN"
    			,supp.suppliername
    			,gen.genericname
    			,grp.itemname
    			,rtn.returndate
    			,rtnitm.quantity + rtnitm.freequantity AS "Qty",rtnitm.subtotal
    			,rtn.discountamount
    			,rtn.vatamount
    			,rtnitm.totalamount
    			,rtn.creditnoteid AS "SupplierCreditNoteNum"
    			,rtn.creditnoteprintid AS "CreditNoteNum"
    			,rtn.remarks
    			from phrm_returntosupplieritems as rtnitm
    			join phrm_returntosupplier as rtn on rtnitm.returntosupplierid=rtn.returntosupplierid
    			join phrm_goodsreceiptitems as grp on rtnitm.goodreceiptitemid=grp.goodreceiptitemid
    			join phrm_mst_generic as gen on grp.genericid = gen.genericid
    			join phrm_mst_supplier as supp on supp.supplierid = rtn.supplierid
    			where (rtnitm.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1 and rtnitm.quantity>0 
    			group by (rtnitm.createdon)::date
    			,supp.suppliername
    			,gen.genericname
    			,grp.itemname
    			,rtn.returndate
    			,rtnitm.quantity
    			,rtnitm.freequantity
    			,rtnitm.subtotal
    			,rtn.discountamount
    			,rtn.vatamount
    			, rtnitm.totalamount
    			,rtn.creditnoteid
    			,rtn.creditnoteprintid
    			,rtn.remarks;
    	   end if;
    end;
END;
$$ LANGUAGE plpgsql;