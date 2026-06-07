CREATE OR REPLACE FUNCTION sp_adt_allbedswithpatientsinfo(

)
RETURNS TABLE (
    "WardId" INT,
    "WardName" VARCHAR,
    "BedID" INT,
    "BedNumber" VARCHAR,
    "BedCode" VARCHAR,
    "BedFeatureName" VARCHAR,
    "BedPrice" DECIMAL,
    "IsOccupied" BOOLEAN,
    "IsReserved" BOOLEAN,
    "PatientId" INT,
    "PatientName" VARCHAR,
    "Gender" VARCHAR,
    "PatientDob" VARCHAR,
    "AdmissionDate" TIMESTAMP,
    "PatientVisitId" INT,
    "VisitCode" VARCHAR
) AS $$
BEGIN
    /*
    file: "sp_adt_allbedswithpatientsinfo"
    created: sud:16sep'21
    Description: To get all beds info along with the Patient's info of occupying patient.
    
    sn    user/date              remarks
    1.    sud/16sep'21          Needed new functionality containing all information of Beds.
    
     */
    
      RETURN QUERY SELECT W.WardId, W.WardName, B.BedID, B.BedNumber,B.BedCode, F.BedFeatureName,
      F.BedPrice,B.IsOccupied, B.IsReserved,
    patAdm.PatientId, patAdm.PatientName, patAdm.Gender, patAdm.DateOfBirth AS "PatientDob",
    (patAdm.AdmissionDate)::Date AS "AdmissionDate",patAdm.PatientVisitId, patAdm.VisitCode
    FROM ADT_Bed B 
       INNER JOIN
    ADT_MST_Ward W ON B.WardId = W.WardID and W.IsActive='true'
       INNER JOIN
    ADT_MAP_BedFeaturesMap Map ON Map.BedId = B.BedID
       INNER JOIN
    ADT_MST_BedFeature F ON F.BedFeatureId = Map.BedFeatureId
     LEFT JOIN 
      (
           select  adm.PatientId, pat.ShortName AS "PatientName",
    	   adm.PatientVisitId,visit.VisitCode,pat.DateOfBirth, pat.Gender,
    		 ward.WardName,  bed.BedID,  bed.BedCode, bed.BedNumber, adm.AdmissionDate
    		 from ADT_PatientAdmission adm
    		 inner join (select * from PAT_PatientVisits) visit
    			on  adm.PatientVisitId= visit.PatientVisitId
    		 inner join (Select * from ADT_TXN_PatientBedInfo 
    					where IsActive=1 and OutAction is null) bedInfo
    		   ON adm.PatientVisitId=bedInfo.PatientVisitId
    		     INNER JOIN ADT_MST_Ward ward on bedInfo.WardId=ward.WardID
    		   inner join ADT_Bed bed on bedInfo.BedId = bed.BedID
    		   INNER JOIN PAT_Patient pat on adm.PatientId=pat.PatientId
    		      Where adm.AdmissionStatus='admitted'
      )patadm
     
      on b.bedid=patadm.bedid
      where b.isactive=1
    
      order by b.bednumber;
END;
$$ LANGUAGE plpgsql;