/*  
  FileName: [SP_NEPH_GetDialisysPatientListWithBillingItem]   
  Created: 29-Dec-22/Nirmala 
  Description: To Get the Nephrology Patient Detail 
   
  Remarks:     
  History  
  S.No.    Date/User              Change          Remarks  
  1.       29-Dec'22/Nirmala                      Create SP_NEPH_GetDialisysPatientListWithBillingItem for Nursing Nephrology   
 */
CREATE OR REPLACE FUNCTION sp_neph_getdialisyspatientlistwithbillingitem(

)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "DialysisCode" VARCHAR,
    "Gender" VARCHAR,
    "ItemName" VARCHAR,
    "RequisitionDate" TIMESTAMP,
    "Age" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Address" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "PerformerName" VARCHAR,
    "LastName" VARCHAR
) AS $$
BEGIN
    
    RETURN QUERY SELECT pat.patientid
    	,pat.patientcode
    	,pat.dialysiscode
    	,pat.gender
    	,bti.itemname
    	,bti.requisitiondate
    	,pat.age
    	,pat.dateofbirth
    	,pat.address
    	,pat.phonenumber
    	,bti.performername
    	,shortname = pat.firstname || ' ' || coalesce(pat.middlename, ' ') || pat.lastname
    from pat_patient pat
    inner join bil_txn_billingtransactionitems bti on pat.patientid = bti.patientid
    inner join bil_mst_servicedepartment msd on bti.servicedepartmentid = msd.servicedepartmentid
    where msd.integrationname = 'Nephrology'
    	and pat.dialysiscode is not null
    order by pat.patientid desc;
END;
$$ LANGUAGE plpgsql;