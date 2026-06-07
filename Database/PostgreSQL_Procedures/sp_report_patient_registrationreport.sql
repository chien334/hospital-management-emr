CREATE OR REPLACE FUNCTION sp_report_patient_registrationreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_gender VARCHAR DEFAULT NULL,
    p_country VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "RegisteredDate" TIMESTAMP,
    "PatientName" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "CountryName" INT,
    "Address" VARCHAR,
    "SchemeName" VARCHAR,
    "BloodGroup" VARCHAR,
    "Email" VARCHAR,
    "InsuranceNumber" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_report_patient_registrationreport"
    description: to get the patient registration report for the hospital.
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       sanjeev/2023-09-07					add schemename in select query for the registration report
    */
    begin
    	if (
    			(p_fromdate is not null)
    			and (p_todate is not null)
    			)
    	then
    		RETURN QUERY SELECT 
    			  (pat.createdon)::date AS "RegisteredDate"
    			, pat.shortname AS "PatientName"
    			, pat.dateofbirth
    			, pat.age
    			, pat.gender
    			, pat.phonenumber
    			, pat.countryname
    			, pat.address
    			, latestvisit.schemename
    			, pat.bloodgroup
    			, pat.email
    			, ins.insurancenumber
    		from 
    		(select 
    			patient.patientid,
    			patient.createdon,
    			patient.shortname, 
    			patient.dateofbirth,
    			patient.age,
    			patient.gender,
    			patient.phonenumber,
    			patient.address,
    			patient.bloodgroup,
    			patient.email,
    			country.countryname
    		from pat_patient patient
    			inner join (select ltrim(rtrim(value)) AS "Gender" 
    						from string_split(p_gender, ',')) gen on patient.gender = gen.gender
    			inner join mst_country as country on country.countryid = patient.countryid
    		 where ((patient.createdon)::date between (p_fromdate)::date and (p_todate)::date)
    			   and (country.countryname = p_country or p_country is null)
    		)pat
    		left join (
    			select * from
    				(select 
    				patientid, patientvisitid,innervisit.schemeid, scheme.schemename, 
    				row_number() over( partition by patientid order by patientvisitid desc) as "row_num"
    				from pat_patientvisits innervisit
    				inner join bil_cfg_scheme as scheme on innervisit.schemeid = scheme.schemeid
    				)visit
    				where visit.row_num = 1
    			) as latestvisit on pat.patientid = latestvisit.patientid
    		left join pat_patientinsuranceinfo as ins on pat.patientid = ins.patientid		
    		order by ((pat.createdon)::date) desc;
    	end if;
    end;
END;
$$ LANGUAGE plpgsql;