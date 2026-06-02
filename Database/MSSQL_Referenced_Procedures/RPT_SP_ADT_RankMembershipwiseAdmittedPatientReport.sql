/*
[RPT_SP_ADT_RankMembershipwiseAdmittedPatientReport] '2023-1-12','2023-1-12', '1,2,3','SI,CON'
FileName: [RPT_SP_ADT_RankMembershipwiseAdmittedPatientReport]
CreatedBy/Date: Sanjeev/2023-1-13
Description: .
Remarks:    A
-- =============================================
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sanjeev/2023-01-11          Initial Draft
2.      Sanjeev/2023-01-12          Added Rank-Membershipwise date filter
*/
-- =============================================
CREATE PROCEDURE RPT_SP_ADT_RankMembershipwiseAdmittedPatientReport 
	@FromDate DATE = NULL,
	@ToDate DATE = NULL,
	@Memberships VARCHAR(1000) = NULL,
	@Ranks VARCHAR(1000) = NULL
AS
BEGIN
	SELECT adm.AdmissionDate,
		pat.PatientCode,
		visit.VisitCode,
		pat.Rank,
		meb.MembershipTypeName 'MembershipName',
		meb.MembershipTypeId 'MembershipId',
		pat.ShortName 'PatientName',
		bed.BedCode 'BedCode',
		bedf.BedFeatureName 'BedFeature',
		bedf.BedFeatureId,
		dept.DepartmentName,
		dept.DepartmentId,
		pat.Address,
		pat.PhoneNumber,
		pat.Age + '/' + CONVERT(CHAR(1), pat.Gender) 'Age/Sex'
	FROM ADT_PatientAdmission adm
	INNER JOIN ADT_TXN_PatientBedInfo adtPat
		ON adm.PatientId = adtPat.PatientId
	INNER JOIN PAT_PatientVisits visit
		ON adm.PatientVisitId = visit.PatientVisitId
	INNER JOIN PAT_Patient pat
		ON pat.PatientId = visit.PatientId
	INNER JOIN ADT_MST_Ward ward
		ON ward.WardID = adtPat.WardId
	INNER JOIN ADT_Bed bed
		ON bed.BedID = adtPat.BedId
	INNER JOIN ADT_MAP_BedFeaturesMap bedm
		ON bed.BedID = bedm.BedId
	INNER JOIN ADT_MST_BedFeature bedf
		ON bedm.BedFeatureId = bedf.BedFeatureId
	INNER JOIN PAT_CFG_MembershipType meb
		ON pat.MembershipTypeId = meb.MembershipTypeId
	INNER JOIN MST_Department dept
		ON dept.DepartmentId = adtPat.RequestingDeptId
	WHERE (CONVERT(DATE, adm.AdmissionDate) BETWEEN @FromDate AND @ToDate)
		AND (adm.AdmissionStatus = 'admitted')
		AND (pat.Rank IS NOT NULL)
		AND (
			meb.MembershipTypeId IN (
				SELECT VALUE
				FROM String_split(@Memberships, ',')
				)
			OR @Memberships = ''
			)
		AND (
			pat.Rank IN (
				SELECT VALUE
				FROM String_split(@Ranks, ',')
				)
			OR @Ranks = ''
			)
	ORDER BY adm.AdmissionDate DESC
END