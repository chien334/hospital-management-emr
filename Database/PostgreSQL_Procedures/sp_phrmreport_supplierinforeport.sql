CREATE OR REPLACE FUNCTION sp_phrmreport_supplierinforeport(

)
RETURNS TABLE (
    "SupplierName" VARCHAR,
    "ContactNo" TIMESTAMP,
    "City" VARCHAR,
    "PANNumber" VARCHAR,
    "ContactAddress" TIMESTAMP,
    "Email" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_phrmreport_supplierinforeport"
    createdby/date: umed/2018-02-16
    description: to get the each supplier information 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2018-02-16	                     created the script
    2       rohit/2021-09-29                     pin column renamed AS "PANNumber"
    
    */
    
    
        
    	 RETURN QUERY SELECT suppliername, contactno, city, pannumber , contactaddress, email 
    	  from  "phrm_mst_supplier";
END;
$$ LANGUAGE plpgsql;