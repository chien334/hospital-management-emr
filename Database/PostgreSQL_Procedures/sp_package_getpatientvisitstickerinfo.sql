CREATE OR REPLACE FUNCTION sp_package_getpatientvisitstickerinfo(
    p_billingtransactionid INT DEFAULT NULL
)
RETURNS TABLE (
    "AppointmentType" VARCHAR,
    "VisitType" VARCHAR,
    "VisitCode" VARCHAR,
    "ProviderName" INT,
    "SaleDate" TIMESTAMP,
    "SaleTime" TIMESTAMP,
    "PatientName" VARCHAR,
    "PatientCode" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "Address" VARCHAR,
    "MunicipalityName" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "CountryName" INT,
    "District" VARCHAR,
    "DoctorName" VARCHAR,
    "Department" VARCHAR,
    "RoomNo" VARCHAR,
    "User" VARCHAR,
    "PackageName" VARCHAR,
    "BillingDate" TIMESTAMP
) AS $$
BEGIN
    /*
    filename: sp_package_getpatientvisitstickerinfo
    createdby/date: sanjit / 2019-12-2
    description: get patient's package billing details. 
    Change History
    S.No.    UpdatedBy/Date                     Change History
    1.		Krishna/09thJun'22					change to performer, prescriber 
    2.		rusha/05thsept'2022					Added Municipalityname	
    */
          
             RETURN QUERY SELECT DISTINCT
                visit.AppointmentType AS "AppointmentType",
                visit.VisitType AS "VisitType",
                visit.VisitCode AS "VisitCode",
                visit.PerformerName AS "ProviderName",
                to_char(bilTxn.CreatedOn, 'mm/dd/yyyy') AS "SaleDate",
                to_char(bilTxn.CreatedOn, 'yyyy-mm-dd') AS "SaleTime",
                CONCAT_WS(' ', pat.firstname, pat.middlename, pat.lastname) AS "PatientName",
                pat.patientcode AS "PatientCode",
                pat.dateofbirth AS "DateOfBirth",
                pat.gender AS "Gender",
                pat.address AS "Address",
                mun.municipalityname AS "MunicipalityName",
                pat.phonenumber AS "PhoneNumber",
                con.countryname AS "CountryName",
                subcounty.countrysubdivisionname AS "District",
                doc.fullname AS "DoctorName",
                dep.departmentname AS "Department",
                doc.roomno AS "RoomNo",
                usr.username AS "User",
                biltxn.packagename AS "PackageName",
                biltxn.createdon AS "BillingDate" 
             from
                bil_txn_billingtransaction biltxn 
                join
                   pat_patient pat 
                   on pat.patientid = biltxn.patientid 
                join
                   mst_countrysubdivision subcounty 
                   on subcounty.countrysubdivisionid = pat.countrysubdivisionid 
                join
                   mst_country con 
                   on con.countryid = pat.countryid 
                left join
                   mst_municipality mun 
                   on mun.municipalityid = pat.municipalityid 
                join
                   bil_txn_billingtransactionitems biltxnitms 
                   on biltxn.billingtransactionid = biltxnitms.billingtransactionid 
                join
                   rbac_user usr 
                   on usr.employeeid = biltxn.createdby 
                left join
                   pat_patientvisits visit 
                   on biltxn.patientvisitid = visit.patientvisitid 
                left join
                   mst_department dep 
                   on dep.departmentid = visit.departmentid 
                left join
                   emp_employee doc 
                   on doc.employeeid = biltxnitms.prescriberid 
             where
                biltxn.billingtransactionid = p_billingtransactionid 
             order by
                biltxn.createdon desc; 
          
    -- end of sp
END;
$$ LANGUAGE plpgsql;