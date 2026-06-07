CREATE OR REPLACE FUNCTION sp_inctv_viewtxn_invoiceitemlevel(
    p_billingtansactionid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*
     file: sp_inctv_viewtxn_invoiceitemlevel
     description: 
     conditions/checks: 
    
     remarks: we're returning 2 tables from here
     Change History:
     S.No.    ChangeDate/By					Remarks
     1.      24Jan'20/pratik          initial draft (needs revision)
     2.      16feb'20/Sud			  Rewrite after change in logic.. 
     3.      11June2020/Pratik		  GroupDistribution Impacts on Existing Functionalities 
     4.      14Aug2023/Nirmala        Fetch ServiceItemId And IntegrationItemId
     5.		 22ndSept'23/krishna	  read pricecategory 
    */
    
    	--table:1 -- get billingtransactionitem information---
    	open ref1 for select patientid
    		,billingtransactionitemid
    		,billingtransactionid
    		,integrationitemid
    		,itemname
    		,quantity
    		,price
    		,subtotal
    		,discountamount
    		,totalamount
    		,serviceitemid
    		,pricecat.pricecategoryid
    		,pricecat.pricecategoryname
    	from (select patientid,billingtransactionitemid,billingtransactionid, integrationitemid, itemname, quantity,
    			price, subtotal, discountamount, totalamount, serviceitemid, pricecategoryid
    			from bil_txn_billingtransactionitems
    	where billingtransactionid = p_billingtansactionid) itms
    	inner join bil_cfg_pricecategory pricecat on itms.pricecategoryid = pricecat.pricecategoryid;
        return next ref1;
    
    	--table:2 -- get fraction information---
    	open ref2 for select *
    	from inctv_txn_incentivefractionitem
    	where billingtransactionid = p_billingtansactionid;
        return next ref2;
END;
$$ LANGUAGE plpgsql;