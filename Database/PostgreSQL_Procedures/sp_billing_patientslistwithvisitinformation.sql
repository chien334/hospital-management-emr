CREATE OR REPLACE FUNCTION sp_billing_patientslistwithvisitinformation(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_showinpatient BOOLEAN DEFAULT FALSE
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
DECLARE
    v_showhideipparam VARCHAR;
    v_showhideipindicator BOOLEAN;
BEGIN
    /*
     filename: "sp_billing_patientslistwithvisitinformation" 
     created:  nirmala/18nov'22
     Description: Patient can be searched through phone number
     Change History
     S.No.    Date/User              Change          Remarks
     1.       29Jan2021/pratik                    inital draft
     2.      26Jul'21/ramesh                      isoutdoorpat is also shown in billing/adt
     3.      8aug'21/Anish                        Getting Latest VisitId and Code for OP-Billing 
     4.      22Dec'21/sud                         added top(200) 
     5.		 18th,jul'22/Krishna				  Address selection with Municipality and CountrySubDivision
     6.      18th,Nov'22/nirmala                  patient can be searched through phone number
     7.		 8th,jan'23/Krishna					  Added MedicareMemberNo in Select Statement.
     8.	     23rdMarch'23/krishna				  remove join with pat_cfg_membershiptype and make a join with bil_cfg_scheme
     9.		 31stmarch'23/Sanjeev				  Add JOIN with PAT_MAP_PatientSchemes, Add MedicareEmployeeName, MedicareDegination, 
    											  PolicyNumber and Relation in Select Statement
     10.     5th April'23/devn                    added new parameter p_showinpatient. if not supplied default value is false
    											  if supplied manaually it will show inpatient detail irrespective of the paramerter
    											  showipinsearchpatient.
    11.		 16thapril'23/Bibek 				  Added Visit type to display in the change visit scheme		
    12.		 15thMay'23/krishna					  handle null check for address field
    13.		 5thjune'23/Krishna					  Add PriceCategory in the select Query
    14.		 23rdJune'23/krishna				  read visitdate to verify followup days in client side
    */
    begin  
    
    
    
    v_showhideipparam := (select parametervalue from core_cfg_parameters where parametername='ShowIPInSearchPatient');
    v_showhideipindicator := (select case when lower(v_showhideipparam)='true' or v_showhideipparam='1' then 1 else 0 end);
    if(p_showinpatient = true)
    then
    	v_showhideipindicator := 1;
    end if;
    
    
    
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
     --scheme.discountpercent 'MembershipDiscountPercent',
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
    AND 
    ((adm.PatientId IS NULL) OR (v_showhideipindicator=1)) 
     AND (pat.ShortName LIKE '%' || COALESCE(p_searchtxt,'') || '%' 
           or pat.PatientCode LIKE '%' || COALESCE(p_searchtxt,'') || '%'
    	   or pat.PhoneNumber LIKE '%' || COALESCE(p_searchtxt,'')||'%'
    	   ) limit 200;
    end;
END;
$$ LANGUAGE plpgsql;