CREATE OR REPLACE FUNCTION sp_report_radiology_film_type_count(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "FilmType" VARCHAR,
    "QuantityUsed" INT
) AS $$
BEGIN
    
    
    -- exec sp_report_radiology_film_type_count '2023-10-08','2023-10-09'
    /************************************************************************
    filename: "sp_report_radiology_film_type_count "
    change history
    s.no.    updatedby/date                        remarks
    1.    prem						sp for film type count in report| radilogy
    2.	  bibek-8th oct'23:			 added fromdate and todate filter
    *************************************************************************/
    
    RETURN QUERY SELECT 
        film.filmtypedisplayname AS "FilmType",
        coalesce(sum(req.filmquantity),0) AS "QuantityUsed"
    from  rad_patientimagingreport rpt
    	left join rad_patientimagingrequisition req on rpt.imagingrequisitionid = req.imagingrequisitionid
    	left join rad_mst_filmtype film on req.filmtypeid = film.filmtypeid 
    where (rpt.createdon)::date between p_fromdate and p_todate
    group by film.filmtypedisplayname
    order by filmtype asc;
END;
$$ LANGUAGE plpgsql;