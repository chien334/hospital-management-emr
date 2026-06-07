CREATE OR REPLACE FUNCTION sp_pat_echspatientslistwithvisitinformation(
    p_searchtxt VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "ShortName" VARCHAR,
    "FirstName" VARCHAR,
    "LastName" VARCHAR,
    "MiddleName" INT,
    "Age" VARCHAR,
    "CountryName" INT,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "DateOfBirth" TIMESTAMP,
    "Address" VARCHAR,
    "IsOutdoorPat" BOOLEAN,
    "CreatedOn" TIMESTAMP,
    "CountryId" INT,
    "CountrySubDivisionId" INT,
    "CountrySubDivisionName" TIMESTAMP,
    "MembershipTypeId" INT,
    "SchemeName" VARCHAR,
    "SchemeId" INT,
    "PANNumber" VARCHAR,
    "BloodGroup" VARCHAR,
    "DialysisCode" VARCHAR,
    "IsAdmitted" BOOLEAN,
    "WardName" VARCHAR,
    "BedCode" VARCHAR,
    "BedNumber" VARCHAR,
    "VisitCode" VARCHAR,
    "PatientVisitId" INT,
    "Insurance" VARCHAR,
    "MedicareMemberNo" VARCHAR,
    "PolicyNo" VARCHAR,
    "MedicareEmployeeName" VARCHAR,
    "Designation" TIMESTAMP,
    "Relation" TIMESTAMP,
    "VisitType" VARCHAR,
    "PriceCategoryId" INT,
    "VisitDate" TIMESTAMP
) AS $$
BEGIN
    /*
     filename: "sp_pat_echspatientslistwithvisitinformation" 
     created:  krishna/26thsept'23
     Description: Search ECHS Patient Only for ECHS Claim Form
     Change History
     S.No.    Date/User							Change					Remarks
     1.       26thSept'23/krishna				create					inital draft
    */
    begin  
    
    
    
    
     RETURN QUERY SELECT 
     pat.patientid,
     pat.patientcode,
     pat.shortname,
     pat.firstname,
     pat.lastname,
     pat.middlename,
     pat.age,
     cntry.countryname,
     pat.gender,
     pat.phonenumber,
     pat.dateofbirth,
     coalesce(pat.address,'') || coalesce(', '|| mun.municipalityname,'') || coalesce(', '|| country.countrysubdivisionname,'') AS "Address",
     pat.isoutdoorpat,
     pat.createdon,
     pat.countryid,
     pat.countrysubdivisionid,
     sub.countrysubdivisionname,
     pat.membershiptypeid,
     scheme.schemename,
     scheme.schemeid,
     pat.pannumber,
     pat.bloodgroup,
     pat.dialysiscode,
     case when adm.patientid is not null then 1
          else 0 end AS "IsAdmitted",
     adm.wardname, 
     adm.bedcode, 
     adm.bednumber,
     coalesce(adm.visitcode,latestvisit.visitcode) AS "VisitCode",
     coalesce(adm.patientvisitid,latestvisit.patientvisitid) AS "PatientVisitId",  
     case when ins.patientid is not null then ins.currentbalance
         else 0 end AS "Insurance",
     medicaremem.memberno AS "MedicareMemberNo",
     patmapscheme.policyno,
     medicaremem.nameofmedicareemployee AS "MedicareEmployeeName",
     medicaremem.designation,
     medicaremem.relation,
     adm.visittype,
     latestvisit.pricecategoryid,
     latestvisit.visitdate
    		from pat_patient pat
    		inner join  mst_country cntry on pat.countryid=cntry.countryid
    		inner join mst_countrysubdivision sub on pat.countrysubdivisionid=sub.countrysubdivisionid
    		left join (
    		    select adm.patientid, adm.patientvisitid,visit.visitcode, visit.visittype,
    		      ward.wardname, bed.bedcode, bed.bednumber, bedinfo.startedon 
    		    from adt_patientadmission adm
    		    inner join  pat_patientvisits visit
    		     on  adm.patientvisitid= visit.patientvisitid
    		    inner join (select * from adt_txn_patientbedinfo 
    		         where isactive=1 and outaction is null) bedinfo
    		      on adm.patientvisitid=bedinfo.patientvisitid
    		        inner join adt_mst_ward ward on bedinfo.wardid=ward.wardid
    		      inner join adt_bed bed on bedinfo.bedid = bed.bedid
    		         where adm.admissionstatus='admitted'
    		 )adm on pat.patientid=adm.patientid
    		 left join (
    		   select patins.patientid, patins.currentbalance
    				  from pat_patientinsuranceinfo patins inner join ins_cfg_insuranceproviders insprov
    				  on patins.insuranceproviderid = insprov.insuranceproviderid
    		 where insprov.insuranceprovidername='Government Insurance'
    		  ) ins on pat.patientid = ins.patientid
    		  left join(
    		   select patientid, patientvisitid, visitcode, schemeid, pricecategoryid, visitdate
    		     from 
    		     (
    		     select row_number() over (partition by patientid order by patientvisitid desc) as "row_num",
    					patientid, 
    					patientvisitid,
    					visitcode, 
    					schemeid,
    					pricecategoryid,
    					visitdate
    		     from 
    		        pat_patientvisits
    		     ) a
    		     where row_num=1
    		  ) latestvisit on pat.patientid=latestvisit.patientid
    		  --krishna, 23rdmarch'23 Bwloe Join Should not be a left join here,
    		  --When there would be Visit compulsory we need to make both Visit and Scheme as Inner Joins..
    		  LEFT JOIN BIL_CFG_Scheme scheme ON scheme.SchemeId = latestVisit.SchemeId 
    		  LEFT JOIN MST_Municipality mun ON mun.MunicipalityId = pat.MunicipalityId
    		  LEFT JOIN MST_CountrySubDivision country ON country.CountrySubDivisionId = pat.CountrySubDivisionId
    		  LEFT JOIN (
    			SELECT MemberNo, '' AS "Relation", '' AS "NameOfMedicareEmployee",EmployeeRoleName AS "Designation",memb.PatientId FROM INS_MedicareMember memb
    			JOIN  EMP_EmployeeRole role ON memb.DesignationId = role.EmployeeRoleId WHERE IsDependent = 0
    			UNION ALL
    			SELECT dependent.MemberNo, dependent.Relation, member.FullName AS "NameOfMedicareEmployee", EmployeeRoleName AS "Designation",dependent.PatientId FROM INS_MedicareMember member
    			JOIN INS_MedicareMember dependent on member.MedicareMemberId = dependent.ParentMedicareMemberId
    			JOIN  EMP_EmployeeRole role ON dependent.DesignationId = role.EmployeeRoleId
    			WHERE dependent.IsDependent = 1
    		  ) AS medicareMem ON medicareMem.PatientId = pat.PatientId
     
    		  LEFT JOIN PAT_MAP_PatientSchemes patMapScheme ON patMapScheme.SchemeId = scheme.SchemeId AND patMapScheme.LatestPatientVisitId = latestVisit.PatientVisitId
    WHERE pat.IsActive=1 
    	   AND scheme.ApiIntegrationName = 'echs' 
    	   AND (pat.ShortName LIKE '%' || COALESCE(p_searchtxt,'') || '%' 
           OR pat.PatientCode LIKE '%' || COALESCE(p_searchtxt,'') || '%'
    	   OR pat.PhoneNumber LIKE '%' || COALESCE(p_searchtxt,'')||'%'
    	) limit 200;
    end;
END;
$$ LANGUAGE plpgsql;