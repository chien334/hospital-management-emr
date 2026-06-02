--END:Ramesh-28 Jun'21: PaymentStatus added in GoodsReceipt table---

--Start: Anjana: 28 June, 2021: Order Sample collected list in FIFO order-----

CREATE PROCEDURE [dbo].[SP_LAB_GetSamplesCollectedInfo]  --- SP_LAB_GetSamplesCollectedInfo
    @FromDate Datetime=null ,
	@ToDate DateTime=null,
	@SelectedLab varchar(100)
AS
/*
FileName: SP_APPT_GetPatientVisitStickerInfo
CreatedBy/date: Anjana/Feb/22/2021
Description: Get list of lab items whose sample collection is completed.  

Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Anjana/Feb/22/2021                   Initial Draft
2.      Anjana/March/9/2021					Added SampleCollectedOnDAteTime on select
*/
BEGIN

select 
	pat.PatientId,
	pat.ShortName as PatientName,
	pat.Age,
	pat.Gender,
	pat.DateOfBirth,
	pat.PatientCode,
	pat.PhoneNumber,
	cat.TestCategoryName,
	test.LabTestName,
	req.BarCodeNumber,
	req.SampleCodeFormatted,
	req.SampleCreatedOn,
	req.LabTestSpecimen,
	req.SampleCollectedOnDateTime

  from LAB_TestRequisition req join PAT_Patient pat on pat.PatientId=req.PatientId
			join LAB_LabTests test on test.LabTestId = req.LabTestId 
			join LAB_TestCategory cat on cat.TestCategoryId = test.LabTestCategoryId 
            where req.OrderStatus != Lower('active')
			and Convert(Date, req.CreatedOn) between ISNULL(@FromDate, Convert(Date, GETDATE())) and ISNULL(@ToDate, Convert(Date, GETDATE())) 
			and req.BillingStatus != 'cancel' and req.BillingStatus != 'returned'			
			and req.LabTypeName = Lower(@SelectedLab)
			Order by req.BarCodeNumber ASC
END