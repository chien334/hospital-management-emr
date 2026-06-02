Create PROCEDURE [dbo].[SP_ADT_AllBedsWithPatientsInfo]
AS
/*
File: [SP_ADT_AllBedsWithPatientsInfo]
Created: Sud:16Sep'21
Description: To get all beds info along with the Patient's Info of occupying patient.

SN    User/Date              Remarks
1.    Sud/16Sep'21          Needed new functionality containing all information of Beds.

 */
BEGIN
  SELECT W.WardId, W.WardName, B.BedID, B.BedNumber,B.BedCode, F.BedFeatureName,
  F.BedPrice,B.IsOccupied, B.IsReserved,
patAdm.PatientId, patAdm.PatientName, patAdm.Gender, patAdm.DateOfBirth 'PatientDob',
Convert(Date,patAdm.AdmissionDate) 'AdmissionDate',patAdm.PatientVisitId, patAdm.VisitCode
FROM ADT_Bed B 
   INNER JOIN
ADT_MST_Ward W ON B.WardId = W.WardID and W.IsActive='true'
   INNER JOIN
ADT_MAP_BedFeaturesMap Map ON Map.BedId = B.BedID
   INNER JOIN
ADT_MST_BedFeature F ON F.BedFeatureId = Map.BedFeatureId
 LEFT JOIN 
  (
       select  adm.PatientId, pat.ShortName 'PatientName',
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
  )patAdm
 
  on B.BedID=patAdm.BedID
  Where B.IsActive=1

  order by B.BedNumber
END