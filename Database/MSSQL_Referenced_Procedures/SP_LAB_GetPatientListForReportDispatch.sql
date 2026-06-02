CREATE PROCEDURE [dbo].[SP_LAB_GetPatientListForReportDispatch]
  @StartDate DATE = null,
  @EndDate DATE = null,
  @CategoryList NVARCHAR(400) = ''
AS

/*
File: SP_LAB_GetPatientListForReportDispatch
Created: Anish/Sud:6Sep'21
Description: To get distinct patient list in the given date range for Lab-Dispatch Page.
NOTE: Returned  And Cancelled items are excluded from this.
Change History:
S.No.  ChangedBy/Date         Remarks
1.    Anish/Sud:6Sep'21       Needed new sp since previous was processing more data and hence taking more time
2.    Anish:10Sep'21          Correction in Verification Filter, which was missing earlier.
                              Added ProvisionalRestriction Check(parameterized) which was missing earlier.
*/
BEGIN

Declare @CategoryIdTbl Table(CategoryId int)
Insert into @CategoryIdTbl
Select value from string_split(@CategoryList, ',') where RTRIM(value) <> ''

Declare @allowProvisionalPrintStr varchar(10)
Set @allowProvisionalPrintStr = (Select ParameterValue 
                                 from CORE_CFG_Parameters 
								 where LOWER(ParameterGroupName)='lab' and ParameterName='AllowLabReportToPrintOnProvisional');
Declare @allowProvisionalPrint bit = 0;
IF(@allowProvisionalPrintStr = 'true' OR @allowProvisionalPrintStr = '1')
BEGIN 
  Set @allowProvisionalPrint=1
END


declare @isVerificationEnabled bit;
declare @verificationParam varchar(500) = (Select ParameterValue 
                                           from CORE_CFG_Parameters 
                                           where ParameterName='LabReportVerificationNeededB4Print')

set @isVerificationEnabled = (SELECT JSON_VALUE(@verificationParam, '$.EnableVerificationStep'));

--need to get distinct since there could be more than one requisition for same patient---  
Select distinct 
    pat.PatientId,
    pat.PatientCode,
    pat.ShortName as PatientName,
    pat.PhoneNumber,
    pat.Gender,
    Convert(Date,pat.DateOfBirth) 'DateOfBirth'
    
from LAB_TestRequisition req 
    INNER JOIN  PAT_Patient pat on req.PatientId = pat.PatientId
    INNER JOIN LAB_LabTests test on req.LabTestId = test.LabTestId
    INNER JOIN @CategoryIdTbl cat on test.LabTestCategoryId=cat.CategoryId
    
where req.OrderStatus = 'report-generated'  --take only report generated patients..
    and (req.IsVerified=1 OR ISNULL(req.IsVerified,0) = @isVerificationEnabled )
       --filter by request created on--
    and Convert(Date,req.CreatedOn) Between @StartDate and @EndDate
    and req.BillingStatus !='returned'  --exclude returned and cancelled requests (from billing)
    and req.BillingStatus !='cancel'
	AND (  @allowProvisionalPrint = 1
	       OR(req.VisitType='inpatient' OR req.VisitType='emergency')
		   OR (req.BillingStatus !='provisional')
		)

Order by pat.ShortName
END