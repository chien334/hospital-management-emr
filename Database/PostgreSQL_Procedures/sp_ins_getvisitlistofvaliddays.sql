CREATE OR REPLACE FUNCTION sp_ins_getvisitlistofvaliddays(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_rowcounts INT DEFAULT 200,
    p_dayslimit INT DEFAULT 1
)
RETURNS TABLE (
    "PatientVisitId" INT,
    "ParentVisitId" INT,
    "DepartmentId" INT,
    "DepartmentName" VARCHAR,
    "PerformerId" INT,
    "PerformerName" VARCHAR,
    "VisitDate" TIMESTAMP,
    "VisitTime" TIMESTAMP,
    "VisitType" VARCHAR,
    "AppointmentType" VARCHAR,
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "FirstName" VARCHAR,
    "MiddleName" INT,
    "LastName" VARCHAR,
    "ShortName" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "CountryId" INT,
    "PANNumber" VARCHAR,
    "MembershipTypeId" INT,
    "Address" VARCHAR,
    "Email" VARCHAR,
    "LandLineNumber" VARCHAR,
    "ClaimCode" VARCHAR,
    "Ins_NshiNumber" VARCHAR,
    "Ins_HasInsurance" VARCHAR,
    "QueueNo" VARCHAR,
    "BillStatus" VARCHAR
) AS $$
DECLARE
    v_now DATE;
    v_validdate DATE;
BEGIN
    /*
    	 filename: "sp_ins_getvisitlistofvaliddays" 
    	 created: 22-dec'21/Krishna
    	 Description: To Get the Patients visit list
    				-- Returns upto 200 patients
    				--Match fields: ShortName, PatientCode (HospitalNo), PhoneNumber
    	 Remarks:   
    	 Change History
    	 S.No.    Date/User              Change          Remarks
    	 1.       22-Dec'21/krishna                      inital draft 
    	 2.       25-dec'21/Sud                          Can search also from Insurance NSHI Number.
    	*/
    	
    	
    		v_now := CURRENT_TIMESTAMP;
    	
    		v_validdate := DATEADD(DAY, -p_dayslimit, v_now); --takes date p_dayslimit(eg: 7 days) days less than the current date.
    		
    	BEGIN 
    		IF(p_searchtxt = 'null') 
    	THEN 
    		p_searchtxt := null; 
    	END IF; 
    		p_rowcounts := COALESCE(p_rowcounts, 200); --default rowscount=200
    
    	RETURN QUERY SELECT  
    	  visit.PatientVisitId, 
    	  visit.ParentVisitId, 
    	  dept.DepartmentId,
    	  dept.DepartmentName,
    	  visit.PerformerId, 
    	  visit.PerformerName, 
    	  visit.VisitDate, 
    	  visit.VisitTime, 
    	  visit.VisitType, 
    	  visit.AppointmentType, 
    	  pat.PatientId, 
    	  pat.PatientCode, 
    	  pat.FirstName, 
    	  pat.MiddleName, 
    	  pat.LastName, 
    	  pat.ShortName, 
    	  pat.PhoneNumber, 
    	  pat.DateOfBirth, 
    	  pat.Gender, 
    	  pat.CountryId, 
    	  pat.PANNumber, 
    	  pat.MembershipTypeId, 
    	  pat."Address", 
    	  pat.Email, 
    	  pat.LandLineNumber,
    	  visit.ClaimCode,
    	  pat.Ins_NshiNumber,
    	  visit.Ins_HasInsurance,
    	  visit.QueueNo, 
    	  visit.BillingStatus AS "BillStatus"
    
    
    	FROM PAT_PatientVisits AS visit
    		INNER JOIN MST_Department AS dept ON visit.DepartmentId = dept.DepartmentId
    		INNER JOIN PAT_Patient AS pat ON visit.PatientId = pat.PatientId
    	WHERE 
    	  pat.IsActive = 1
    	  AND visit.IsActive=1
    	  AND COALESCE(visit.Ins_HasInsurance, 0) = 1
    	  AND (visit.VisitDate)::DATE BETWEEN (v_validdate)::DATE AND (v_now)::DATE
    	  AND LOWER(visit.VisitType) != 'inpatient'
    	  AND LOWER(visit.BillingStatus) != 'returned'
    	  AND (
    		pat.PatientCode LIKE '%' || COALESCE(p_searchtxt, '') || '%' 
    		OR COALESCE(pat.Ins_NshiNumber,'') LIKE '%' || COALESCE(p_searchtxt, '') || '%'   --sud:25Dec'21: additional where clause for insurance patients.
    		or pat.shortname like '%' || coalesce(p_searchtxt, '') || '%' 
    		or coalesce(pat.phonenumber, '') like '%' || coalesce(p_searchtxt, '') || '%'
    	  ) 
    	 
    	order by 
    	  visit.patientvisitid desc limit p_rowcounts; --show recent visit at top.. 
    	  end;
END;
$$ LANGUAGE plpgsql;