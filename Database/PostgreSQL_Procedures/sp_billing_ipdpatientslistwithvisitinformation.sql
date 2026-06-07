CREATE OR REPLACE FUNCTION sp_billing_ipdpatientslistwithvisitinformation(
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
    "MembershipTypeName" VARCHAR,
    "MembershipDiscountPercent" INT,
    "PANNumber" VARCHAR,
    "BloodGroup" VARCHAR,
    "DialysisCode" VARCHAR,
    "VisitType" VARCHAR,
    "IsAdmitted" BOOLEAN,
    "WardName" VARCHAR,
    "BedCode" VARCHAR,
    "BedNumber" VARCHAR,
    "VisitCode" VARCHAR,
    "PatientVisitId" INT,
    "Insurance" VARCHAR,
    "SchemeId" INT,
    "PriceCategoryId" INT,
    "SchemeName" VARCHAR
) AS $$
BEGIN
    /*
     filename:  "sp_billing_ipdpatientslistwithvisitinformation" ''
     created: 20feb'21/Sud
     Description: To Search for IPD Patients with PatientName or VisitCode.
     Remarks: We need to reuse this stored procedure also for other pages.. right now used only for billing.
     Change History
     S.No.    Date/User              Change          Remarks
     1.	     20Feb'21/sud		                   inital draft
     2.		 27april'21/Anjana					IPD Search using patientcode 
    											of discharged cancelled patient
     3.		 5 May,'21/anjana					fixed issue of showing all patient in search
     4.		20july21, sanjit/sud				show outdoor patient in billing as well since it is seen in adt search patient --snch 20july21
     5.     sud:9sep'21                         Handle Search by PatientCode (Hospital Number as well)
                                               needed since IPD-Patient many times give the cards with hospital number only, 
    										   so its necessary to search by HospNumber as well.
     6.		Krishna/24thNov'22				   add phone number search for ipd search
     7.		krishna/22ndmay'23				   Add SchemeId and PriceCategoryId in Select Query
     8.     Bibek/18thJune'23                  add visit type in select query 
     9.	    krishna/19thjune'23				   Read SchemeName for Patient Information
    */
    BEGIN	   
    
    RETURN QUERY SELECT 
    	pat.PatientId,
    	pat.PatientCode,
    	pat.ShortName,
    	pat.FirstName,
    	pat.LastName,
    	pat.MiddleName,
    	pat.Age,
    	cntry.CountryName,
    	pat.Gender,
    	pat.PhoneNumber,
    	pat.DateOfBirth,
    	pat.Address,
    	pat.IsOutdoorPat,
    	pat.CreatedOn,
    	pat.CountryId,
    	pat.CountrySubDivisionId,
    	sub.CountrySubDivisionName,
    	COALESCE(pat.MembershipTypeId,4) AS "MembershipTypeId",
    	COALESCE(scheme.SchemeName, 'general') AS "MembershipTypeName", -- fix it later
    	COALESCE(scheme.DiscountPercent,0) AS "MembershipDiscountPercent",
    	pat.PANNumber,
    	pat.BloodGroup,
    	pat.DialysisCode,
    	adm.VisitType,
    	case when adm.PatientId is not null then 1
    		 else 0 END AS "IsAdmitted",
        adm.WardName, adm.BedCode, adm.BedNumber,adm.VisitCode,adm.PatientVisitId,
    	case when ins.PatientId is not null then ins.CurrentBalance
    			else 0 END AS "Insurance",
    	adm.SchemeId,
    	adm.PriceCategoryId,
    	scheme.SchemeName
    
    from 
        (
    		 select adm.PatientId, adm.PatientVisitId,visit.VisitCode,visit.VisitType,
    		   ward.WardName, bed.BedCode, bed.BedNumber, bedInfo.StartedOn, visit.SchemeId, visit.PriceCategoryId
    		 from ADT_PatientAdmission adm
    		 inner join (select * from PAT_PatientVisits) visit
    			on  adm.PatientVisitId= visit.PatientVisitId
    		 inner join (Select * from ADT_TXN_PatientBedInfo 
    					where IsActive=1 and OutAction is null) bedInfo
    		   ON adm.PatientVisitId=bedInfo.PatientVisitId
    		     INNER JOIN ADT_MST_Ward ward on bedInfo.WardId=ward.WardID
    		   inner join ADT_Bed bed on bedInfo.BedId = bed.BedID
    		      Where adm.AdmissionStatus='admitted'
    	)adm
    
    	INNER JOIN 
    
      PAT_Patient pat   on pat.PatientId=adm.PatientId
     INNER JOIN  MST_Country cntry on pat.CountryId=cntry.CountryId
     inner join MST_CountrySubDivision sub
        on pat.CountrySubDivisionId=sub.CountrySubDivisionId
    
      left join BIL_CFG_Scheme scheme on adm.SchemeId=scheme.SchemeId
    
      Left join (
        Select patIns.PatientId, patins.CurrentBalance
    	 from PAT_PatientInsuranceInfo patIns INNER JOIN INS_CFG_InsuranceProviders insProv
    	on patIns.InsuranceProviderId = insProv.InsuranceProviderId
    	Where insProv.InsuranceProviderName='government insurance'
    
       ) ins on pat.PatientId = ins.PatientId
    
     WHERE --COALESCE(pat.IsOutdoorPat,0) = 0 and    --Sanjit/Sud Show outdoor patient in billing as well since it is seen in ADT Search Patient --SNCH 20July21
     pat.IsActive=1 and 
     (pat.ShortName like '%' || COALESCE(p_searchtxt,'') ||'%' 
        or adm.VisitCode like '%' || COALESCE(p_searchtxt,'') || '%'
    	or pat.PatientCode like '%' || COALESCE(p_searchtxt,'') || '%'
    	or pat.phonenumber = p_searchtxt);
     
    end;
END;
$$ LANGUAGE plpgsql;