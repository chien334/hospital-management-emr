CREATE OR REPLACE FUNCTION sp_phrm_transfertostorereport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ItemName" VARCHAR,
    "BatchNo" VARCHAR,
    "Quantity" INT,
    "ExpiryDate" TIMESTAMP,
    "TotalAmount" DECIMAL,
    "StoreName" VARCHAR,
    "FullName" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_phrm_transfertostorereport" '05/05/2020','05/05/2020'
    createdby/date:shankar/05-01-2020
    description: to get report of stock details transfer to store from dispensary 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.
    */
     begin
      if ((p_fromdate is not null) and (p_todate is not null)) 
    		then
    			RETURN QUERY SELECT (stk.createdon)::date AS "Date",itemname,batchno,quantity,expirydate,totalamount,storename,emp.fullname
    			from phrm_storestock as stk
    			join emp_employee emp on stk.createdby = emp.employeeid
    			where (stk.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1 and transactiontype='Sent From Dispensary';
    			
    	   end if;
    end;
END;
$$ LANGUAGE plpgsql;