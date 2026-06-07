CREATE OR REPLACE FUNCTION sp_dashboard_pat_averagetreatmentcostbyagegroup(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "Gender" VARCHAR,
    "AgeRange" VARCHAR,
    "Total" DECIMAL
) AS $$
DECLARE
    v_zeroto14years VARCHAR := '0-14Years';
		
    v_14to25years VARCHAR := '14-25Years';
		
    v_25to35years VARCHAR := '25-35Years';
		
    v_35to45years VARCHAR := '35-45Years';
		
    v_45to55years VARCHAR := '45-55Years';
		
    v_greaterthan55years VARCHAR := '>55Years';
BEGIN
    /*
     sp_dashboard_pat_averagetreatmentcostbyagegroup '2022-1-05'
    filename: "sp_dashboard_pat_averagetreatmentcostbyagegroup"
    createdby/date: nirmala/rohit/2022-1-05
    description: .
    remarks:    a
    change history
    s.no.    updatedby/date                        remarks
    1      nirmala/rohit/2022-1-05                created the script
    */
    
    	
    
    	RETURN QUERY SELECT gender
    		,agerange
    		,count(agenum) AS "Total"
    	from (
    		select agenum
    			,gender
    			,case 
    				when ageunit = 'D'
    					then v_zeroto14years
    				when ageunit = 'M'
    					then v_zeroto14years
    				when (
    						ageunit = 'Y'
    						and agenum < 14
    						)
    					then v_zeroto14years
    				when (
    						ageunit = 'Y'
    						and (
    							agenum between 14
    								and 25
    							)
    						)
    					then v_14to25years
    				when (
    						ageunit = 'Y'
    						and (
    							agenum between 25
    								and 35
    							)
    						)
    					then v_25to35years
    				when (
    						ageunit = 'Y'
    						and (
    							agenum between 35
    								and 45
    							)
    						)
    					then v_35to45years
    				when (
    						ageunit = 'Y'
    						and (
    							agenum between 45
    								and 55
    							)
    						)
    					then v_45to55years
    				when (
    						ageunit = 'Y'
    						and (agenum > 55)
    						)
    					then v_greaterthan55years
    				end AS "AgeRange"
    		from (
    			select tbl.age
    				,(
    					select cast(tbl.ageno as int) as agenum
    					) as "agenum"
    				,tbl.ageunit
    				,tbl.gender
    			from (
    				select age
    					,substring(age, 1, len(age) - 1) as "ageno"
    					,substring(age, len(age), len(age)) as "ageunit"
    					,gender
    				from pat_patient
    				where gender != '0'
    					and (createdon)::date between (p_fromdate)::date
    						and (p_todate)::date
    				) tbl
    			) tbl1
    		) tbl2
    	group by agerange
    		,gender
    	order by agerange;
END;
$$ LANGUAGE plpgsql;