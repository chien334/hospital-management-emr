/* ***********************************************************************
FileName: [SP_ACC_GetAllEmployee_LedgerList]  
CreatedBy/date: Anish/Apr-2020
Description: To get ledger details for Consultant ledgers from acc-mapping table 
Change History
S.No.    UpdatedBy/Date                        Remarks
1.      Sud/Nagesh:20Jun'20                    HospitalId added for Phrm-Acc Separation
************************************************************************ */

CREATE PROCEDURE [dbo].[SP_ACC_GetAllEmployee_LedgerList]  
  @HospitalId INT
AS
BEGIN
  Select led.LedgerId, consLedMap.ReferenceId 'EmployeeId',
  led.LedgerName, led.Code 'LedgerCode', ledGrp.LedgerGroupName
  from ACC_Ledger led, ACC_MST_LedgerGroup ledGrp, 
  (Select * from ACC_Ledger_Mapping where LedgerType='consultant' and HospitalId=@HospitalId) consLedMap
  Where led.LedgerGroupId=ledGrp.LedgerGroupId
    and led.LedgerId=consLedMap.LedgerId 
    and led.HospitalId = @HospitalId and ledGrp.HospitalId=@HospitalId
END