CREATE Procedure SP_BIL_RPT_GetDepositTransations
	@FromDate Date=NULL, 
	@ToDate Date=NULL, 
	@PatSearchText varchar(100)=null,
	@employeeId INT=null
AS
/*
 File: SP_BIL_RPT_GetDepositTransations
 CreatedBy: Sud/10Sep'21
 Description: To get the details of deposit in a given date range for given patient(optional), for given user(optional)
 Remarks: 
   If Single patient's data is required then Pass the patientid, else pass NULL or ZERO
   if single User's data is required then pass the UserId (EmployeeId) else pas NULL/Zero.

 Example: SP_BIL_RPT_GetDepositTransations '2021-06-15','2021-09-10','ram',NULL

Change History:
SN   User/Date                                Remarks
1.   Sud/10Sep'21                              Created
*/
BEGIN
  Select 
	    DepositDate, ReceiptNo, 
	  PatientId, PatientCode, PatientName, DateOfBirth, Gender, PhoneNumber, 
	  DepositReceived,  DepositDeducted,  DepositReturned, 
	  UserName, CounterName, Remarks 
  from FN_RPT_BIL_GetDepositTransationsInDatRange (@FromDate,@ToDate,@PatSearchText,@employeeId)
  order by DepositId
END