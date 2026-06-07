CREATE OR REPLACE FUNCTION sp_er_getertriagedpatientlist(
    p_selectedcase INT
)
RETURNS TABLE (
    "ERPatientId" INT,
    "ERPatientNumber" VARCHAR,
    "PatientId" INT,
    "PatientVisitId" INT,
    "PatientCode" VARCHAR,
    "VisitDateTime" TIMESTAMP,
    "FirstName" VARCHAR,
    "MiddleName" INT,
    "LastName" VARCHAR,
    "Gender" VARCHAR,
    "Age" VARCHAR,
    "AgeSex" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "ContactNo" TIMESTAMP,
    "Address" VARCHAR,
    "ReferredBy" VARCHAR,
    "ReferredTo" VARCHAR,
    "PerformerId" INT,
    "PerformerName" VARCHAR,
    "ConditionOnArrival" TIMESTAMP,
    "ModeOfArrivalName" DECIMAL,
    "ModeOfArrivalId" INT,
    "CareOfPerson" TIMESTAMP,
    "ERStatus" VARCHAR,
    "TriageCode" VARCHAR,
    "TriagedBy" VARCHAR,
    "TriagedOn" TIMESTAMP,
    "CreatedBy" VARCHAR,
    "CreatedOn" TIMESTAMP,
    "ModifiedBy" VARCHAR,
    "ModifiedOn" TIMESTAMP,
    "IsActive" BOOLEAN,
    "OldPatientId" INT,
    "IsExistingPatient" BOOLEAN,
    "FullName" VARCHAR,
    "CountryId" INT,
    "CountrySubDivisionId" INT,
    "TriagedByName" VARCHAR,
    "PatientCases" VARCHAR,
    "SchemeId" INT,
    "PriceCategoryId" INT,
    "SchemeName" VARCHAR,
    "PriceCategoryName" DECIMAL
) AS $$
BEGIN
    /*  
     filename: "sp_er_getertriagedpatientlist"   
     created: 2nd-oct'23/Sanjeev  
     Description: To Get the Emergency Triage Patient List
     Change History  
     S.No.    Date/User              Change          Remarks  
     1.      2nd-Oct'23/sanjeev                      get the emergency triage patient list passing the input parameter 'SelectedCase'
     2.		 3rd-oct'23/Sanjeev						 Add SchemeName and PriceCategoryName in select query.
    */
    
    	RETURN QUERY SELECT erPat.ERPatientId
    		, erPat.ERPatientNumber
    		, erpat.PatientId
    		, erpat.PatientVisitId
    		, pat.PatientCode
    		, erpat.VisitDateTime
    		, erpat.FirstName
    		, erpat.MiddleName
    		, erpat.LastName
    		, erpat.Gender
    		, erpat.Age
    		, erpat.Age || '/' || SUBSTRING(erpat.Gender, 1, 1) AS "AgeSex"
    		, erpat.DateOfBirth
    		, erpat.ContactNo
    		, erpat.Address
    		, erpat.ReferredBy
    		, erpat.ReferredTo
    		, erpat.PerformerId
    		, erpat.PerformerName
    		--, erpat.Case
    		, erpat.ConditionOnArrival
    		, moa.ModeOfArrivalName
    		, moa.ModeOfArrivalId
    		, erpat.CareOfPerson
    		, erpat.ERStatus
    		, erpat.TriageCode
    		, erpat.TriagedBy
    		, erpat.TriagedOn
    		, erpat.CreatedBy
    		, erpat.CreatedOn
    		, erpat.ModifiedBy
    		, erpat.ModifiedOn
    		, erpat.IsActive
    		, erpat.OldPatientId
    		, erpat.IsExistingPatient
    		, pat.ShortName AS "FullName"
    		, pat.CountryId
    		, pat.CountrySubDivisionId
    		, (
    			SELECT  employee.FullName
    			FROM ER_Patient emrPat
    			INNER JOIN EMP_Employee employee ON emrPat.TriagedBy = employee.EmployeeId
    			WHERE emrPat.ERPatientId = emrPat.ERPatientId
    				AND emrPat.ERStatus = 'triaged' LIMIT 1
    			) AS "TriagedByName"
    		, (
    			(SELECT row_to_json(t) FROM (SELECT patC.*
    			FROM ER_Patient_Cases patC
    			INNER JOIN PAT_Patient patient ON patC.ERPatientId = patient.PatientId
    			WHERE patC.IsActive = 1
    				AND patC.ERPatientId = erPat.ERPatientId
    			ORDER BY patC.PatientCaseId DESC) AS "t")::text
    			) AS "PatientCases"
    		, patientSchemeMap.SchemeId
    		, patientSchemeMap.PriceCategoryId
    		, scheme.SchemeName
    		, priceCat.PriceCategoryName
    	FROM ER_Patient erPat
    	INNER JOIN PAT_Patient pat ON erPat.PatientId = pat.PatientId
    	LEFT JOIN ER_ModeOfArrival moa ON erPat.ModeOfArrival = moa.ModeOfArrivalId
    	INNER JOIN PAT_PatientVisits visit ON erPat.PatientVisitId = visit.PatientVisitId
    	LEFT JOIN PAT_MAP_PatientSchemes patientSchemeMap ON visit.PatientId = patientSchemeMap.PatientId
    		AND visit.SchemeId = patientSchemeMap.SchemeId
    	INNER JOIN BIL_CFG_Scheme scheme ON patientSchemeMap.SchemeId = scheme.SchemeId
    	LEFT JOIN BIL_CFG_PriceCategory priceCat ON patientSchemeMap.PriceCategoryId = priceCat.PriceCategoryId
    	WHERE erPat.ERStatus = 'triaged'
    		AND erPat.IsActive = 1
    		AND COALESCE(erPat.FinalizedStatus, '') = ''
    		and (
    			p_selectedcase = 0
    			or p_selectedcase = (
    				select  maincase
    				from er_patient_cases epc
    				where epc.erpatientid = erpat.erpatientid
    					and epc.isactive = 1
    				order by patientcaseid desc limit 1
    				)
    			)
    	order by erpat.erpatientid desc;
END;
$$ LANGUAGE plpgsql;