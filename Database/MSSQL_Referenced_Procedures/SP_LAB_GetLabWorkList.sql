CREATE PROCEDURE [dbo].[SP_LAB_GetLabWorkList] 
          @FromDate DATE=NULL,
    @ToDate DATE=NULL,
    @LabTypeName varchar(100)='op-lab',
    @CategoryIdCsv VARCHAR(200) = NULL
AS
/*
FileName: [SP_LAB_GetLabWorkList]
CreatedBy/date: Sud/DevN/09Jan'23
Description: To get lab work list based on given filters. 
             We've moved the logic from C# controller to this SP since it's way too complex in LINQ query. 
Remarks    :  Data are filtered based on RequestCreatedOn (i.e: Billing Date), 
              Which may vary from hospital to hospital, we need to discuss if other hospital has any issues.
Change History
S.No.    UpdatedBy/Date                        Remarks
1       Sud/DevN/09Jan'23      Created
2.      DevN/15Jan'23                        DateRange filter changeed from CreatedOn to
            SampleCollectedOnDate
3.      DevN/9Feb'23                         Get TestNames as semicolon (;) separated string rather than CSV.
4.      DevN/12Sept'23                       Get BarCodeNumber and exclude tests send to external lab.
*/
BEGIN

 declare @isVerificationEnabled bit;
 declare @verificationParam varchar(500) = (Select ParameterValue 
              from CORE_CFG_Parameters 
              where ParameterName='LabReportVerificationNeededB4Print')
 SET @isVerificationEnabled = (SELECT JSON_VALUE(@verificationParam, '$.EnableVerificationStep'));


 select req.SampleCreatedOn SampleCollectedOn, req.BarCodeNumber, 
 req.SampleCodeFormatted,pat.ShortName 'PatientName', pat.PatientCode 'PatientCode',
 convert(Date,pat.DateOfBirth) 'DateOfBirth', 
 pat.Gender, STRING_AGG(req.LabTestName,';') 'LabTestNameCsv' ,
 req.BarCodeNumber as 'Barcode'

 From LAB_TestRequisition req
 INNER JOIN LAB_LabTests tst on req.LabTestId=tst.LabTestId
 INNER JOIN 
 (Select CONVERT(int,value) as 'CategoryId' from string_split(@CategoryIdCsv, ',') where RTRIM(value) <> '') selCat 
    on selCat.CategoryId= tst.LabTestCategoryId

   INNER JOIN PAT_Patient pat on req.PatientId=pat.PatientId
   INNER JOIN Lab_MST_LabVendors vendor ON req.ResultingVendorId = vendor.LabVendorId
 where convert(Date,req.SampleCollectedOnDateTime) Between @FromDate and @ToDate
   and ISNULL(req.LabTypeName,'op-lab')= ISNULL(@LabTypeName,'op-lab') -- this is our default
   and req.BillingStatus NOT IN ('cancel','returned')
   AND vendor.IsExternal = 0
   AND
    ( 
    --when verification disabled then take only requests having orderstatus: pending.
    (
    @isVerificationEnabled=1 
   and req.OrderStatus IN ('pending','result-added','report-generated')
   and ISNULL(req.IsVerified,0) = 0 
     )
   OR 
     (
    @isVerificationEnabled=0 and req.OrderStatus IN ('pending')
     )
    )
 group by req.SampleCreatedOn, req.BarCodeNumber, req.SampleCodeFormatted, pat.ShortName , pat.PatientCode, 
    convert(Date,pat.DateOfBirth), pat.Gender
 Order by req.SampleCreatedOn, req.BarCodeNumber, req.SampleCodeFormatted
END