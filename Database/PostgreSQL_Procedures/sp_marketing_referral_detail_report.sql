DROP FUNCTION IF EXISTS sp_marketing_referral_detail_report(date, date, integer);
DROP FUNCTION IF EXISTS sp_marketing_referral_detail_report(timestamp without time zone, timestamp without time zone, integer);

CREATE OR REPLACE FUNCTION sp_marketing_referral_detail_report(
    p_fromdate timestamp,
    p_todate timestamp,
    p_referringpartyid integer DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref refcursor := 'ref';
BEGIN
    OPEN ref FOR
    SELECT   
        rc."InvoiceNoFormatted",
        rc."InvoiceDate" AS "InvoiceDate",
        pat."ShortName" AS "PatientName",
        pat."PatientCode" AS "HospitalNo",
        rp."ReferringPartyName",
        rpg."GroupName",
        ro."ReferringOrganizationName",
        COALESCE(rp."VehicleNumber", '') AS "VehicleNumber",
        rs."ReferralSchemeName",
        rc."InvoiceNetAmount" AS "InvoiceNetAmount",
        rc."Percentage",	
        rc."ReferralAmount",
        rc."Remarks",
        emp."FullName" AS "EnteredBy",
        rc."CreatedOn" AS "EnteredOn"
    FROM (
        SELECT 
            "PatientId",
            "InvoiceNoFormatted",
            "InvoiceDate",
            "InvoiceNetAmount",
            "Percentage",
            "ReferralAmount",
            "Remarks",
            "CreatedBy",
            "CreatedOn",
            "ReferringPartyId",
            "ReferralSchemeId",
            "FiscalYearId" 
        FROM "MKT_TXN_ReferralCommission"
        WHERE "InvoiceDate"::date BETWEEN p_fromdate::date AND p_todate::date 
          AND "IsActive" = true 
          AND (p_referringpartyid IS NULL OR "ReferringPartyId" = p_referringpartyid)
    ) rc 
    INNER JOIN "PAT_Patient" pat ON rc."PatientId" = pat."PatientId"
    INNER JOIN "MKT_CFG_ReferringParty" rp ON rc."ReferringPartyId" = rp."ReferringPartyId"
    INNER JOIN "MKT_MST_ReferringOrganization" ro ON rp."ReferringOrgId" = ro."ReferringOrganizationId"
    INNER JOIN "MKT_MST_ReferringPartyGroup" rpg ON rp."ReferringPartyGroupId" = rpg."ReferringPartyGroupId"
    INNER JOIN "MKT_MST_ReferralScheme" rs ON rc."ReferralSchemeId" = rs."ReferralSchemeId"
    INNER JOIN "BIL_CFG_FiscalYears" fy ON rc."FiscalYearId" = fy."FiscalYearId"
    INNER JOIN "EMP_Employee" emp ON rc."CreatedBy" = emp."EmployeeId"
    ORDER BY rc."InvoiceDate" DESC;

    RETURN NEXT ref;
END;
$$ LANGUAGE plpgsql;