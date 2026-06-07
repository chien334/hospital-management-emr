CREATE OR REPLACE FUNCTION sp_report_radiology_revenuegenerated(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "TotalPrice" DECIMAL,
    "TotalPaidAmount" INT,
    "TotalTax" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_radiology_revenuegenerated"
    createdby/date: sagar/2017-05-25
    description: to get the total of price , totalpaid amount, and total tax between given dates
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       sagar/2017-05-25	                   created the script
    2       umed / 2017-06-09                      modify the script i.e format and alias of table 
                                                 and also remove the hard coded departmentid with dynamically of radiology department
    */
    begin
    		if(p_fromdate is not null or p_todate is not null or len(p_fromdate)>0 or len(p_todate)>0)
    			then
    					RETURN QUERY SELECT  (d.paiddate)::date AS "Date",
    					        sum(d.price) AS "TotalPrice",
    							sum(d.totalamount) AS "TotalPaidAmount",
    							sum(d.tax) AS "TotalTax"
    					from    bil_mst_servicedepartment t
    					inner join
    					       bil_txn_billingtransactionitems d on 
    					       d.servicedepartmentname=t.servicedepartmentname
    					where (d.paiddate)::date between p_fromdate and p_todate and departmentid=(select  departmentid from mst_department where departmentname='Radiology' limit 1)
    					group by (d.paiddate)::date; 
    			end if;
    end;
END;
$$ LANGUAGE plpgsql;