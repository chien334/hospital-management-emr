--Altering SP_REPORT_LAB_TotalDailyCovidTestDetails SP
 --changed RequestedBy to PrescriberId
  CREATE PROCEDURE [dbo].[SP_REPORT_LAB_TotalDailyCovidTestDetails] @FromDate Date = null,   
  @ToDate Date = null,   
  @TestName varchar(200) = NULL,   
  @ResultType varchar(50) = null,   
  @CountrySubDivisionId int = null,   
  @CaseType varchar(50) = null,   
  @Gender varchar(50) = null AS   
  /*  
   File: SP_REPORT_LAB_TotalDailyCovidTestDetails   
   Description: Get All details of COVID tests as per ResultDate.  
   Created: Anish  
   Modified: Sud: 9-Oct'21-- Filter condition changed to ResultDate (earler it was Billing Date)..   
   Modified: Dev:29-Nov'21--Alter procedure to show Ngene, Egene value when positive is selected....  
   ModifiedL Krishna,9thJun'22--changed RequestedBy to PrescriberId
   */  
  BEGIN declare @isVerificationEnabled bit;  
declare @verificationParam varchar(500) = (  
  Select   
    ParameterValue   
  from   
    CORE_CFG_Parameters   
  where   
    ParameterName = 'LabReportVerificationNeededB4Print'  
)   
set   
  @isVerificationEnabled = (  
    SELECT   
      JSON_VALUE(  
        @verificationParam, '$.EnableVerificationStep'  
      )  
  );  
IF(@CountrySubDivisionId = 0) BEGIN   
SET   
  @CountrySubDivisionId = null END   
SET   
  @ResultType = LOWER(  
    ISNULL(@ResultType, 'all')  
  );  
SET   
  @CaseType = REPLACE(  
    LOWER(  
      ISNULL(@CaseType, 'all')  
    ),   
    '-',   
    ''  
  );  
--SET @Gender = LOWER(ISNULL(@Gender,'all'));  
Declare @LabTestId INT   
SET   
  @LabTestId =(  
    Select   
      TOp(1) LabTestId   
    from   
      LAB_LabTests   
    where   
      LabTestName = @TestName  
  )   
Select   
  *   
from   
  (  
    SELECT   
      req.SampleCodeFormatted as SampleId,   
      req.SampleCollectedOnDateTime as CollectionDate,   
      ISNULL(emp.FullName, 'NEW') as PatientType,   
      req.ResultAddedOn as TestDate,   
      pat.ShortName 'PatientName',   
      pat.Gender as 'Gender',   
      req.VerifiedOn,   
      max(  
        case when val.ComponentName = 'E gene Ct level' then val.[Value] end  
      ) EGene,   
      max(  
        case when val.ComponentName = 'ORF1ab gene Ct level' then val.[Value] end  
      ) ORFGene,   
      max(  
        case when val.ComponentName = 'N gene Ct Level' then val.[Value] end  
      ) NGene,   
      max(  
        case when val.ComponentName = 'Test of COVID-19' then val.[Value] end  
      ) Report,   
      pat.Age,   
      --max(pat.Gender),  
      pat.PhoneNumber,   
      pat.[Address],   
      mun.MunicipalityName,   
      subDiv.CountrySubDivisionName   
    from   
      LAB_TestRequisition req   
      join PAT_Patient pat on req.PatientId = pat.PatientId --join LAB_LabTests test on req.LabTestId = test.LabTestId  
      left join (  
        Select   
          RequisitionId,   
          [Value],   
          ComponentName   
        from   
          LAB_TXN_TestComponentResult result   
        where   
          LabTestId = @LabTestId   
          and result.IsActive = 1  
      ) val on req.RequisitionId = val.RequisitionId   
      left join MST_CountrySubDivision subDiv on pat.CountrySubDivisionId = subDiv.CountrySubDivisionId   
      left join MST_Municipality mun on pat.MunicipalityId = mun.MunicipalityId   
      left join EMP_Employee emp on req.PrescriberId = emp.EmployeeId   
    WHERE   
      req.LabTestId = @LabTestId   
      and req.IsActive = 1   
      AND (  
        req.IsVerified = 1   
        OR ISNULL(req.IsVerified, 0)= @isVerificationEnabled  
      )   
      AND ISNULL(  
        @CountrySubDivisionId, pat.CountrySubDivisionId  
      )= pat.CountrySubDivisionId --AND Convert(date,req.CreatedOn) BETWEEN (CONVERT(date, @FromDate)) AND CONVERT(date, @ToDate)  
      --sud: Taking from ResultAddedOn date   
      AND Convert(date, req.ResultAddedOn) BETWEEN (  
        CONVERT(date, @FromDate)  
      )   
      AND CONVERT(date, @ToDate)        
      AND (  
        ISNULL(  
          REPLACE(emp.[FullName], '-', ''),   
          'New'  
        ) = @CaseType   
        OR @CaseType = 'all'  
      )   
    GROUP BY   
      req.SampleCodeFormatted,   
      req.SampleCollectedOnDateTime,   
      req.VerifiedOn,   
      req.ResultAddedOn,   
      pat.Gender,   
      pat.ShortName,   
      pat.Age,   
      pat.PhoneNumber,   
      pat.[Address],   
      mun.MunicipalityName,   
      subDiv.CountrySubDivisionName,   
      emp.FullName  
  ) allData   
  where allData.Report = @ResultType OR @ResultType = 'all'  
  END