CREATE OR REPLACE FUNCTION sp_dsb_patient_genderwisecount(

)
RETURNS TABLE (
    "Gender" VARCHAR,
    "Count" INT
) AS $$
BEGIN
    /*
    filename: "sp_dsb_patient_genderwisecount"
    createdby/date: sudarshan/2017-07-09
    description: to get gender wise count of all registered patients.
    remarks:  
    change history
    s.no.    updatedby/date                        remarks
    1        sudarshan/2017-07-09	               created
    */
    
      RETURN QUERY SELECT gender, coalesce( count(*),0) AS "Count" from pat_patient
      group by gender;
END;
$$ LANGUAGE plpgsql;