CREATE OR REPLACE FUNCTION sp_appt_getvisitlistofvaliddays(
    p_searchtxt VARCHAR DEFAULT NULL,
    p_rowcounts INT DEFAULT 200,
    p_dayslimit INT DEFAULT 7,
    p_searchusinghospitalno BOOLEAN DEFAULT NULL,
    p_searchusingidcardno BOOLEAN DEFAULT NULL
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
    "Age" VARCHAR,
    "Gender" VARCHAR,
    "CountryId" INT,
    "CountrySubDivisionId" INT,
    "CountrySubDivisionName" TIMESTAMP,
    "PANNumber" VARCHAR,
    "MembershipTypeId" INT,
    "SchemeName" VARCHAR,
    "SchemeId" INT,
    "Address" VARCHAR,
    "Email" VARCHAR,
    "LandLineNumber" VARCHAR,
    "DependentId" INT,
    "IDCardNumber" INT,
    "Posting" VARCHAR,
    "Rank" VARCHAR,
    "QueueNo" VARCHAR,
    "BillStatus" VARCHAR,
    "PolicyNo" VARCHAR,
    "PriceCategoryId" INT,
    "IsFreeVisit" BOOLEAN
) AS $$
DECLARE
    v_now DATE;
    v_validdate DATE;
BEGIN
    /*    
      filename: "sp_appt_getvisitlistofvaliddays"     
      created: 21-dec'21/Krishna    
      Description: To Get the Patients visit list    
        -- Returns upto 200 patients    
        --Match fields: ShortName, PatientCode (HospitalNo), PhoneNumber    
      Remarks:       
      Change History    
      S.No.    Date/User              Change          Remarks    
      1.       21-Dec'21/krishna                     inital draft     
      2.       24-feb'22/Dev                         Added CountrySubDivisionName and    
    											     CountrySubDivisionId (Required while refering)    
      3.	   18th,Jul'22/krishna    alter		     age coumn added in the select query  
      4.	   05th,aug'22/Krishna    Alter			 Add DependentId,IdCardNumber,Posting,Rank in select Query  
      5.	   07th,Sept'22/krishna	  alter			 changed the logic of predicates either do exact search with hospitalno or do 
    												 using like
      6.       22th,sept'22/Dev Narayan              Added SSFPolicyNumber in Select Statement.
      7.	   Krishna/17thNov'22					 rename patientvisitid to latestpatientvisitid
      8.	   krishna/1stdec'22					 Read PriceCategoryId from Visit
      9.	   Krishna/24Jan'23  	  alter			 add patient search using idcardno(for apf only) -- (merged from: 2nddec'22/
    											     Krishna)
      10.	   Sanjeev/1stMar'23	  alter			 add membershiptypename
      11.	   krishna/12thmar'23	  Alter			 Rename PAT_MAP_PriceCategory to PAT_MAP_PatientScheme and PAT_CFG_MembershipType
    												 to BIL_CFG_Scheme
      12.	   Krishna/22ndMarch'23   alter	         change join condition of bil_cfg_scheme with patient to visit
      13.	   krishna/10thapril'23	  Alter			 Change condition for Ins_HasInsurance Predicate
      14.	   Sanjeev/18thMay'23	  alter			 add schemeid in select statement
      15.	   krishna/8thoct'23	  Alter		     Read PolicyNo
      16.	   Krishna/7thNov'23	  alter			 read isfreevisit from visit table
     */
    
    
    v_now := current_timestamp;
    
    
    
    v_validdate := dateadd(day, - p_dayslimit, v_now); --takes date p_dayslimit(eg: 7 days) days less than the current date.    
    
    begin
    	if (p_searchtxt = '')
    	then
    		p_searchtxt := null;
    	end if;
    
    	if (p_searchusinghospitalno is null)
    	then
    		p_searchusinghospitalno := 0;
    	end if;
    	if(p_searchusingidcardno is null)
    	then
    		p_searchusingidcardno := 0;
    	end if;
      p_rowcounts := coalesce(p_rowcounts, 200); --default rowscount=200    
        
    
    	p_rowcounts := coalesce(p_rowcounts, 200); --default rowscount=200    
    
    	RETURN QUERY SELECT  visit.patientvisitid
    		,visit.parentvisitid
    		,dept.departmentid
    		,dept.departmentname
    		,visit.performerid
    		,visit.performername
    		,visit.visitdate
    		,visit.visittime
    		,visit.visittype
    		,visit.appointmenttype
    		,pat.patientid
    		,pat.patientcode
    		,pat.firstname
    		,pat.middlename
    		,pat.lastname
    		,pat.shortname
    		,pat.phonenumber
    		,pat.dateofbirth
    		,pat.age
    		,pat.gender
    		,pat.countryid
    		,pat.countrysubdivisionid
    		,countrysubdivision.countrysubdivisionname
    		,pat.pannumber
    		,pat.membershiptypeid
    		,scheme.schemename
    		,scheme.schemeid
    		,pat."address"
    		,pat.email
    		,pat.landlinenumber
    		,pat.dependentid
    		,pat.idcardnumber
    		,pat.posting
    		,pat."rank" AS "Rank"
    		,visit.queueno
    		,visit.billingstatus AS "BillStatus"
    		,map.policyno AS "PolicyNo"
    		,visit.pricecategoryid
    		,visit.isfreevisit
    	from pat_patientvisits as visit
    	inner join mst_department as dept on visit.departmentid = dept.departmentid
    	inner join pat_patient as pat on visit.patientid = pat.patientid
    	inner join bil_cfg_scheme as scheme on visit.schemeid = scheme.schemeid
    	left join mst_countrysubdivision as countrysubdivision on pat.countrysubdivisionid = countrysubdivision.countrysubdivisionid
    	left join pat_map_patientschemes map on visit.patientvisitid = map.latestpatientvisitid
    		and pat.patientid = map.patientid
    	where pat.isactive = 1
    		and visit.isactive = 1
    		and (visit.visitdate)::date between (v_validdate)::date
    			and (v_now)::date
    		and lower(visit.visittype) != 'inpatient'
    		and lower(visit.billingstatus) != 'returned'
    		and (
    			 --krishna,07th,sept'22 , Logic below works as; If p_searchusinghospitalno is false then search is done through like operator but if p_searchusinghospitalno is true then search is done through exact Hospital No
    			((COALESCE(p_searchusinghospitalno,0) = 0 AND COALESCE(p_searchusingidcardno,0) = 0) AND
    				(pat.PatientCode like '%' || COALESCE(p_searchtxt,'') || '%'  
    				OR pat.ShortName like '%' || COALESCE(p_searchtxt,'') || '%'    
    				OR COALESCE(pat.PhoneNumber,'') LIKE '%' || COALESCE(p_searchtxt,'') || '%'))
    			or (coalesce(p_searchusinghospitalno,0) = 1 and pat.patientcode = coalesce(p_searchtxt,pat.patientcode)) 
    			or (coalesce(p_searchusingidcardno,0) = 1 and pat.idcardnumber = coalesce(p_searchtxt,pat.idcardnumber)))     
    		and visit.ins_hasinsurance = 0    
     order by     
       visit.patientvisitid desc limit p_rowcounts; --show recent visit at top..     
       end;
END;
$$ LANGUAGE plpgsql;