CREATE OR REPLACE FUNCTION sp_report_adt_diagnosiswisereport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_diagnosis VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "Diagnosis" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_report_adt_diagnosiswisereport"   '2019-09-29','2019-09-29', 'typhoid'
    createdby/date: dinesh/2019-09-29
    description: to get the no of patient's count diagnosis wise
    Remarks:    
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       Dinesh 2019-09-29					to get the no of patient's count diagnosis wise
    */
    begin
    		if(p_fromdate is not null or p_todate is not null or len(p_fromdate)>=0 or len(p_todate)>=0 and (p_diagnosis is not null)
            or (len(p_diagnosis) > 0 ))
    	then 
    			RETURN QUERY SELECT (x."date")::date AS "Date",x.patientcode AS "PatientCode",x.patientname AS "PatientName", x.phonenumber, x.diagnosis
    			
    			 from (
    select pt.firstname ||' '|| coalesce(pt.middlename,'') || ' '||pt.lastname AS "PatientName",discharge.diagnosis AS "Diagnosis"
    ,pt.patientcode,pt.phonenumber,discharge.createdon AS "Date" from 
    adt_dischargesummary discharge join pat_patientvisits visit on discharge.patientvisitid=visit.patientvisitid 
    inner join pat_patient  pt on pt.patientid=visit.patientid
    where discharge.diagnosis like '%' || coalesce(p_diagnosis, '') || '%' and 
    (discharge.createdon)::date between p_fromdate and p_todate
      )as x
      group by x.diagnosis, x.patientname,x. patientcode,phonenumber,"date"
      order by diagnosis asc;
    	end if;	
    end;
END;
$$ LANGUAGE plpgsql;