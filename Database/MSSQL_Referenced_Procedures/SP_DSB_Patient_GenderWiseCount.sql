CREATE PROCEDURE [dbo].[SP_DSB_Patient_GenderWiseCount]
AS
/*
FileName: [SP_DSB_Patient_GenderWiseCount]
CreatedBy/date: sudarshan/2017-07-09
Description: to get gender wise count of all registered patients.
Remarks:  
Change History
S.No.    UpdatedBy/Date                        Remarks
1        sudarshan/2017-07-09	               created
*/
BEGIN
  Select Gender, ISNULL( Count(*),0) 'Count' from PAT_Patient
  group by Gender
END