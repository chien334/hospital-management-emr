CREATE PROCEDURE [dbo].[SP_CLN_GetIntakeOutputParameters]
AS

/*
FileName:[SP_CLN_GetIntakeOutputParameters] 
CreatedBy/date:  Santosh/2ndOct'23
Description:  Get Intake/Output parameters for Clinical Intake/Output
 Change History
 S.No.    Date/User                    Change          Remarks
 1.       Santosh/2ndOct'23          Created         Initial Draft.      
*/
BEGIN
SELECT 
tbl1.IntakeOutputId,
tbl1.ParameterType,
tbl1.ParameterValue AS 'ParameterValue',
tbl2.ParameterValue AS 'ParentParameterValue',
tbl1.IsActive,
tbl1.ParameterMainId
FROM CLN_MST_IntakeOutTakeParameter tbl1
LEFT JOIN CLN_MST_IntakeOutTakeParameter tbl2 ON tbl1.ParameterMainId = tbl2.IntakeOutputId
END