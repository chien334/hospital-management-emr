CREATE OR REPLACE FUNCTION sp_dsb_home_deptwiseappointmentcount(
    p_todaysdate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "DepartmentName" VARCHAR,
    "AppointmentCount" INT
) AS $$
BEGIN
    --"sp_dsb_home_deptwiseappointmentcount"  '2018-12-12'
    /*
    filename: "sp_dsb_home_deptwiseappointmentcount"
    createdby/date: sudarshan/2017-07-09
    description: to get all the appointment counts till date acc to departments.
    remarks:  check data correctness once again..
             --add departmentid in visit/appointment table for dept wise assignment later on.
    change history
    s.no.    updatedby/date                        remarks
    1        sudarshan/2017-07-09	               created
    2        umed/2018-04-18                    modified sp
                                            corrected sp data should be per day departmentwise appointment count
    3        dinesh (13th dec_2018)			as per the hams requirement
    4        sud/pawan (22 dec 2021)        sql performance tuning. count is taken from pat_vist table
                                             previuosly was taking from bil_txn_items table.
                                             
    */
    begin
    
        if (p_todaysdate is not null)
    		then
    		
    		
    		
            RETURN QUERY SELECT ms.departmentname, count(*) AS "AppointmentCount"
            from pat_patientvisits vis
                join mst_department ms on ms.departmentid = vis.departmentid
            where vis.billingstatus != 'returned'
                and (vis.visitdate)::date=p_todaysdate and vis.visittype != 'inpatient'
            group by ms.departmentname;
        end if;
    end;
END;
$$ LANGUAGE plpgsql;