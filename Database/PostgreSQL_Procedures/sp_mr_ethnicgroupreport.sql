CREATE OR REPLACE FUNCTION sp_mr_ethnicgroupreport(
    p_fromdate DATE,
    p_todate DATE
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_childageindays INT := (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification 
							WHERE ReportType = 'DepartmentWiseStatReport' AND AgeName = 'Child');
BEGIN
    /*
    filename: exec sp_mr_ethnicgroupreport <fromdate,todate> 
    createdby/date: bikesh:22aug2023  
    usage eg: sp_mr_ethnicgroupreport
    description: 
       to get ethnicgroup wise appointment countof male and female 
    remarks:    
       > count all male/female on the basis of fromto date filter grouped by ethinic group
    change history
    s.no.    updatedby/date                        remarks
    1        bikesh/9sept'23                   Initial Draft
    2		 Krishna/18thSept'23			   fix for inpatients visit, need discharged patients only
    3		 krishna/16thoct'23				   Rewrite the script according to new report format.
    */
      
    
    
    OPEN ref1 FOR SELECT   
    	COALESCE(pat.EthnicGroup,'others') AS "EthnicGroup",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,adm.AdmissionDate) <= v_childageindays) AND pat.Gender = 'male',1, 0)) AS "Total_MaleChildren",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,adm.AdmissionDate) <= v_childageindays) AND pat.Gender = 'female',1, 0)) AS "Total_FemaleChildren",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,adm.AdmissionDate) > v_childageindays) AND pat.Gender = 'male',1, 0)) AS "Total_MaleCount",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,adm.AdmissionDate) > v_childageindays) AND pat.Gender = 'female',1, 0)) AS "Total_FemaleCount",
    	COALESCE(SUM(1),0) AS "Total"
    FROM (SELECT VisitType, BillingStatus, PatientVisitId, VisitDate, PatientId 
    		FROM PAT_PatientVisits WHERE VisitType = 'inpatient'
    		AND BillingStatus NOT IN('cancel','returned')) AS vis  
    INNER JOIN (SELECT PatientVisitId, DischargeDate, AdmissionDate FROM ADT_PatientAdmission 
    				WHERE AdmissionStatus = 'discharged') adm 
    	ON vis.PatientVisitId = adm.PatientVisitId
    INNER JOIN PAT_Patient pat ON vis.PatientId = pat.PatientId
    WHERE (adm.DischargeDate)::date BETWEEN p_fromdate  AND  p_todate   
    GROUP BY COALESCE(pat.EthnicGroup, 'others');
        RETURN NEXT ref1;
    
    OPEN ref2 FOR SELECT
    	COALESCE(pat.EthnicGroup, 'others') AS "EthnicGroup",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= v_childageindays) AND pat.Gender = 'male' AND vis.AppointmentType = 'new' AND vis.RowNum = 1,1, 0)) AS "Total_MaleChildrenNew",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= v_childageindays) AND pat.Gender = 'female' AND vis.AppointmentType = 'new' AND vis.RowNum = 1,1, 0)) AS "Total_FemaleChildrenNew",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= v_childageindays) AND pat.Gender = 'male' AND vis.AppointmentType = 'new' AND vis.RowNum > 1,1, 0)) AS "Total_MaleChildrenOld",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= v_childageindays) AND pat.Gender = 'female' AND vis.AppointmentType = 'new' AND vis.RowNum > 1,1, 0)) AS "Total_FemaleChildrenOld",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= v_childageindays) AND pat.Gender = 'male' AND vis.AppointmentType = 'followup',1, 0)) AS "Total_MaleChildrenFollowup",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) <= v_childageindays) AND pat.Gender = 'female' AND vis.AppointmentType = 'followup',1, 0)) AS "Total_FemaleChildrenFollowup",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > v_childageindays) AND pat.Gender = 'male' AND vis.AppointmentType = 'new' AND vis.RowNum = 1,1, 0)) AS "Total_MaleNew",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > v_childageindays) AND pat.Gender = 'female' AND vis.AppointmentType = 'new' AND vis.RowNum = 1,1, 0)) AS "Total_FemaleNew",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > v_childageindays) AND pat.Gender = 'male' AND vis.AppointmentType = 'new' AND vis.RowNum > 1,1, 0)) AS "Total_MaleOld",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > v_childageindays) AND pat.Gender = 'female' AND vis.AppointmentType = 'new' AND vis.RowNum > 1,1, 0)) AS "Total_FemaleOld",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > v_childageindays) AND pat.Gender = 'male' AND vis.AppointmentType = 'followup',1, 0)) AS "Total_MaleFollowup",
    	SUM(IIF((DATEDIFF(DAY,pat.DateOfBirth,vis.VisitDate) > v_childageindays) AND pat.Gender = 'female' AND vis.AppointmentType = 'followup',1, 0)) AS "Total_FemaleFollowup",
    	COALESCE(SUM(1),0) AS "Total"
    FROM (SELECT VisitType, PatientVisitId, VisitDate, PatientId, AppointmentType, 
    	   ROW_NUMBER() OVER(Partition BY PatientId, AppointmentType ORDER BY PatientVisitId) AS "RowNum"
    	  FROM PAT_PatientVisits
    	  WHERE VisitType != 'inpatient' AND BillingStatus NOT IN('cancel','returned')
    	  AND AppointmentType NOT IN('transfer', 'referral')) AS vis  
    INNER JOIN PAT_Patient pat ON vis.PatientId = pat.PatientId  
    WHERE (vis.VisitDate)::date BETWEEN p_fromdate  AND  p_todate   
    GROUP BY COALESCE(pat.EthnicGroup, 'others');
        return next ref2;
END;
$$ LANGUAGE plpgsql;