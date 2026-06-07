CREATE OR REPLACE FUNCTION sp_invreport_supplierinforeport(

)
RETURNS TABLE (
    "VendorName" VARCHAR,
    "ContactNo" TIMESTAMP,
    "ContactAddress" TIMESTAMP,
    "PanNo" VARCHAR,
    "Email" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_invreport_supplierinforeport" 
    createdby/date: avanti/2021-10-10
    description: to get the each supplier information 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       avanti/2021-10-10	                     created the script
    
    */
    
    begin
        
    	 RETURN QUERY SELECT 
    	 vendorname,
    	 contactno, 
    	 contactaddress,
    	 case when panno= 'NULL' then '' else panno end
    	 AS "PanNo",
    	 email 
    	  from  "inv_mst_vendor";
    end;
END;
$$ LANGUAGE plpgsql;