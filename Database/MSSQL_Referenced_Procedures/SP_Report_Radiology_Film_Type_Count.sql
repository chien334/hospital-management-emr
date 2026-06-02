CREATE PROCEDURE [dbo].[SP_Report_Radiology_Film_Type_Count]
	@fromDate DATE= null, 
	@toDate DATE = null
AS
BEGIN
SET NOCOUNT ON
-- exec SP_Report_Radiology_Film_Type_Count '2023-10-08','2023-10-09'
/************************************************************************
FileName: [SP_Report_Radiology_Film_Type_Count ]
Change History
S.No.    UpdatedBy/Date                        Remarks
1.    Prem						SP For Film Type Count in Report| Radilogy
2.	  Bibek-8th Oct'23:			 Added Fromdate and Todate filter
*************************************************************************/

SELECT 
    film.FilmTypeDisplayName AS FilmType,
    ISNULL(SUM(req.FilmQuantity),0) AS 'QuantityUsed'
FROM  RAD_PatientImagingReport rpt
	LEFT JOIN RAD_PatientImagingRequisition req ON rpt.ImagingRequisitionId = req.ImagingRequisitionId
	LEFT JOIN RAD_MST_FilmType film ON req.FilmTypeId = film.FilmTypeId 
WHERE CONVERT(DATE, rpt.CreatedOn) BETWEEN @fromDate AND @toDate
GROUP BY film.FilmTypeDisplayName
ORDER BY FilmType ASC

END