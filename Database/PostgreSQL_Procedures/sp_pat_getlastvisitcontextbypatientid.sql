CREATE OR REPLACE FUNCTION sp_pat_getlastvisitcontextbypatientid(
    p_patientid INT DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientVisitId" INT,
    "VisitCode" VARCHAR,
    "SchemeId" INT,
    "PriceCategoryId" INT,
    "VisitDate" TIMESTAMP,
    "VisitType" VARCHAR,
    "DepartmentId" INT,
    "PerformerId" INT,
    "IsCurrentlyAdmitted" BOOLEAN,
    "DischargeDate" TIMESTAMP
) AS $$
BEGIN
    /*
    change log
    
    filename: sp_pat_getlastvisitcontextbypatientid
    createdby: sud,9sep'21--To get latest visit COntext.
    
    Example: EXEC SP_PAT_GetLastVisitContextByPatientId 5
    Description:
    			This SP will return the Latest Patient Visit Context,
    			We have other similar functions as well, but none of them seem to give consistant result.
    History:
    S.N				Name						Remarks
    1.			  Sud,9Sep'21					initial draft
    2.			  krishna,13thapril'23	        Read Scheme and PrieCategoryId and 
    											return IsCurrentlyAdmitted as Boolean
    */
    BEGIN
      RETURN QUERY SELECT vis.PatientId, vis.PatientVisitId, vis.VisitCode , vis.SchemeId, vis.PriceCategoryId,
    	vis.VisitDate, 
    	vis.VisitType, vis.DepartmentId, vis.PerformerId, 
    	Case WHEN adm.AdmissionStatus is null then (0)::BOOLEAN
    	     when adm.AdmissionStatus = 'discharged' then (0)::BOOLEAN
    		 else (1)::BOOLEAN end AS "IsCurrentlyAdmitted",
    		 (adm.DischargeDate)::Date AS "DischargeDate"
    		  from 
    		  (
    		  SELECT 
    			 ROW_NUMBER() OVER (
    			PARTITION BY patientid
    			ORDER BY PatientVisitId desc  --to get latest first, we need to order by visitid descending
    			 ) AS "row_num",
    			 PatientId, PatientVisitId,VisitCode, (VisitDate)::Date AS "VisitDate", 
    			 VisitType, DepartmentId, PerformerId, SchemeId, PriceCategoryId
    
    		  FROM  PAT_PatientVisits
    		  Where PatientId=p_patientid AND BillingStatus != 'returned'
    		  ) vis
    		  left join adt_patientadmission adm 
    		  on vis.patientvisitid=adm.patientvisitid
    	where row_num=1;
    end;
END;
$$ LANGUAGE plpgsql;