CREATE OR REPLACE FUNCTION sp_dsb_home_patientdistributionmap_nepal(

)
RETURNS TABLE (
    "MapAreaCode" VARCHAR,
    "PatientCount" INT
) AS $$
BEGIN
    /*
    filename: "sp_dsb_home_patientdistributionmap_nepal"
    createdby/date: sudarshan/2017-07-09
    description: to get zone wise patient distribution--only for nepal now.
    remarks: 
    change history
    s.no.    updatedby/date                        remarks
    1       sudarshan/2017-07-09	               created
    */
    
    
    	RETURN QUERY SELECT a.mapareacode, coalesce(b.patientcount,0) AS "PatientCount"
    	from 
    	(
    	  select distinct mapareacode from mst_countrysubdivision
    	  where countryid=(select countryid from mst_country where countryname='Nepal') 
    			and mapareacode is not null
    	) a
    
    	left join 
    	(
    		 select csd.mapareacode, count(patientid) AS "PatientCount" 
    		 from mst_countrysubdivision csd,pat_patient pat
    		 where pat.countrysubdivisionid=csd.countrysubdivisionid
    		 and pat.countryid=(select countryid from mst_country where countryname='Nepal')
    		 group by csd.mapareacode
    	) b
    	on 
    	a.mapareacode=b.mapareacode;
END;
$$ LANGUAGE plpgsql;