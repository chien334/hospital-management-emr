CREATE OR REPLACE FUNCTION sp_ins_medicare_getmedicarepatientlist()
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor;
BEGIN
    OPEN ref FOR
    SELECT 
        mem."MemberNo" AS "MedicareNo",
        mem."FullName" AS "Name",
        pat."Gender" AS "Gender",
        mem."HospitalNo" AS "HospitalNo",
        mectype."MedicareTypeName" AS "Category",
        inst."InstituteName" AS "Institution",
        mem."IsDependent" AS "IsDependent",
        dept."DepartmentName" AS "Department",
        role."EmployeeRoleName" AS "Designation",
        mem."Relation" AS "Relation",
        mem."InsurancePolicyNo" AS "InsurancePolicyNo",
        mem."Remarks" AS "Remarks",
        CASE 
            WHEN mem."IsDependent" = TRUE THEN parent."FullName" 
            ELSE '' 
        END AS "Employee",
        mem."IsActive" AS "IsActive",
        mem."DesignationId" AS "DesignationId",
        CAST(mem."DateOfBirth" AS TIMESTAMP) AS "DateOfBirth",
        mem."PatientId" AS "PatientId",
        mem."MedicareTypeId" AS "MedicareTypeId",
        mem."DepartmentId" AS "DepartmentId",
        mem."InsuranceProviderId" AS "InsuranceProviderId",
        CAST(mem."MedicareStartDate" AS TIMESTAMP) AS "MedicareStartDate",
        mem."MedicareMemberId" AS "MedicareMemberId",
        mem."ParentMedicareMemberId" AS "ParentMedicareMemberId",
        mem."IsIpLimitExceeded" AS "IsIpLimitExceeded",
        mem."IsOpLimitExceeded" AS "IsOpLimitExceeded"
    FROM "INS_MedicareMember" mem
    LEFT JOIN "PAT_Patient" pat ON mem."PatientId" = pat."PatientId"
    LEFT JOIN "INS_MST_MedicareType" mectype ON mem."MedicareTypeId" = mectype."MedicareTypeId"
    LEFT JOIN "INS_MST_MedicareInstitute" inst ON mem."MedicareInstituteCode" = inst."MedicareInstituteCode"
    LEFT JOIN "MST_Department" dept ON mem."DepartmentId" = dept."DepartmentId"
    LEFT JOIN "EMP_EmployeeRole" role ON mem."DesignationId" = role."EmployeeRoleId"
    LEFT JOIN "INS_MedicareMember" parent ON mem."ParentMedicareMemberId" = parent."MedicareMemberId";
    
    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;
