CREATE OR REPLACE FUNCTION sp_dsb_patient_agerangengender(

)
RETURNS TABLE (
    "AgeRange" VARCHAR,
    "Male" VARCHAR,
    "Female" VARCHAR,
    "Others" VARCHAR
) AS $$
BEGIN
    DROP TABLE IF EXISTS v_tblagegroup;
    CREATE TEMP TABLE v_tblagegroup (
        AgeRange varchar(20), Seq int
    );
    /*
    filename: "sp_dsb_patient_agerangengender"
    createdby/date: sudarshan/2017-07-09
    description: to get gender+age range wise count of all registered patients.
    remarks:  
    change history
    s.no.    updatedby/date                        remarks
    1        sudarshan/2017-07-09	               created
    */
    
    	
    	insert into v_tblagegroup values('0-9 Years',1);
    	insert into v_tblagegroup values('10-19 Years',2);
    	insert into v_tblagegroup values('20-59 Years',3);
    	insert into v_tblagegroup values('>=60 Years',4);
       
    
         RETURN QUERY SELECT  getdobagerange(dateofbirth,current_timestamp) AS "AgeRange", 
    	  coalesce( sum(case when p.gender = 'Male' then 1 end),0) AS "Male",
    	  coalesce( sum(case when p.gender = 'Female' then 1 end),0) AS "Female",
    	  coalesce( sum(case when p.gender = 'Others' then 1 end),0) AS "Others"
    	from pat_patient p, v_tblagegroup tbl
    	where getdobagerange(dateofbirth,current_timestamp) = tbl.agerange
    	group by getdobagerange(dateofbirth,current_timestamp), tbl.seq
    	order by tbl.seq;
END;
$$ LANGUAGE plpgsql;