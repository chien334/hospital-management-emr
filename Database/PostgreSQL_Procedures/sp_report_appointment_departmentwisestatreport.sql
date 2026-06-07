CREATE OR REPLACE FUNCTION sp_report_appointment_departmentwisestatreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_departmentid INT DEFAULT NULL,
    p_gender VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "*" VARCHAR,
    "Total" DECIMAL
) AS $$
DECLARE
    v_minageindaysforchild INT := (SELECT MinAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Child');
    v_maxageindaysforchild INT := (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Child');
    v_minageindaysforadult INT := (SELECT MinAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Adult');
    v_maxageindaysforadult INT := (SELECT MaxAgeInDays FROM CORE_MST_AgeClassification WHERE AgeName = 'Adult');
BEGIN
    /*
    filename: "sp_report_appointment_departmentwisestatreport"
    createdby/date: 
    description: to get departmentwise total stat (new,followup) on a given date range
    remarks:    
    change history
    s.no.    updatedby/date            remarks
    1     santosh:21june'23               Complete rewrite as per new requirement to show sum in the given date range
    */
    
        
        
    
        
        
    
        RETURN QUERY SELECT *, "NewMaleChild" + "NewFemaleChild" + "NewMaleAdult" + "NewFemaleAdult" + "FollowupMaleChild" + "FollowupFemaleChild" + "FollowupMaleAdult" + "FollowupFemaleAdult" AS "Total"
        FROM (
            SELECT
                "DepartmentName",
                COUNT(CASE WHEN "agecategory" = 'newmalechild' THEN 1 END) AS "NewMaleChild",
                COUNT(CASE WHEN "agecategory" = 'newfemalechild' THEN 1 END) AS "NewFemaleChild",
                COUNT(CASE WHEN "agecategory" = 'newmaleadult' THEN 1 END) AS "NewMaleAdult",
                COUNT(CASE WHEN "agecategory" = 'newfemaleadult' THEN 1 END) AS "NewFemaleAdult",
                COUNT(CASE WHEN "agecategory" = 'followupmalechild' THEN 1 END) AS "FollowupMaleChild",
                COUNT(CASE WHEN "agecategory" = 'followupfemalechild' THEN 1 END) AS "FollowupFemaleChild",
                COUNT(CASE WHEN "agecategory" = 'followupmaleadult' THEN 1 END) AS "FollowupMaleAdult",
                COUNT(CASE WHEN "agecategory" = 'followupfemaleadult' THEN 1 END) AS "FollowupFemaleAdult"
            FROM (
                
            SELECT
                DepartmentName,
                CASE
                    WHEN AgeDays >= v_minageindaysforchild AND AgeDays <= v_maxageindaysforchild AND Gender = 'male' AND AppointmentType = 'new' THEN 'newmalechild'
                    WHEN AgeDays >= v_minageindaysforchild AND AgeDays <= v_maxageindaysforchild AND Gender = 'female' AND AppointmentType = 'new' THEN 'newfemalechild'
                    WHEN AgeDays >= v_minageindaysforadult AND AgeDays <= v_maxageindaysforadult AND Gender = 'male' AND AppointmentType = 'new' THEN 'newmaleadult'
                    WHEN AgeDays >= v_minageindaysforadult AND AgeDays <= v_maxageindaysforadult AND Gender = 'female' AND AppointmentType = 'new' THEN 'newfemaleadult'
                    WHEN AgeDays >= v_minageindaysforchild AND AgeDays <= v_maxageindaysforchild AND Gender = 'male' AND AppointmentType = 'followup' THEN 'followupmalechild'
                    WHEN AgeDays >= v_minageindaysforchild AND AgeDays <= v_maxageindaysforchild AND Gender = 'female' AND AppointmentType = 'followup' THEN 'followupfemalechild'
                    WHEN AgeDays >= v_minageindaysforadult AND AgeDays <= v_maxageindaysforadult AND Gender = 'male' AND AppointmentType = 'followup' THEN 'followupmaleadult'
                    WHEN AgeDays >= v_minageindaysforadult AND AgeDays <= v_maxageindaysforadult AND Gender = 'female' AND AppointmentType = 'followup' THEN 'followupfemaleadult'
                END AS AgeCategory
            FROM (
                SELECT
                    dept.DepartmentName,
                    DATEDIFF(day, pat.DateOfBirth, CURRENT_TIMESTAMP) AS AgeDays,
                    vis.AppointmentType,
                    pat.Gender
                FROM
                    PAT_Patient pat
                    INNER JOIN PAT_PatientVisits vis ON pat.PatientId = vis.PatientId 
                    INNER JOIN MST_Department dept ON vis.DepartmentId = dept.DepartmentId
                WHERE
                    dept.IsAppointmentApplicable = 1 
                    AND vis.VisitType != 'inpatient' 
                    AND (vis.VisitDate)::DATE BETWEEN p_fromdate AND p_todate 
                    AND (pat.Gender = p_gender OR p_gender IS NULL OR p_gender = 'all' ) 
                    AND (dept.DepartmentId = p_departmentid OR p_departmentid IS NULL)
    				AND vis.AppointmentType IN ('new','followup') 
    				AND vis.BillingStatus != 'returned'
            ) tbl
        
            ) src
            group by "departmentname"
        ) piv;
END;
$$ LANGUAGE plpgsql;