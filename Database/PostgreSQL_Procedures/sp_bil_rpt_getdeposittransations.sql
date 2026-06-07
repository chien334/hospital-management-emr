CREATE OR REPLACE FUNCTION sp_bil_rpt_getdeposittransations(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_patsearchtext VARCHAR DEFAULT NULL,
    p_employeeid INT DEFAULT NULL
)
RETURNS TABLE (
    "DepositDate" TIMESTAMP,
    "ReceiptNo" VARCHAR,
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "DepositReceived" VARCHAR,
    "DepositDeducted" VARCHAR,
    "DepositReturned" VARCHAR,
    "UserName" VARCHAR,
    "CounterName" INT,
    "Remarks" VARCHAR
) AS $$
BEGIN
    /*
     file: sp_bil_rpt_getdeposittransations
     createdby: sud/10sep'21
     Description: To get the details of deposit in a given date range for given patient(optional), for given user(optional)
     Remarks: 
       If Single patient's data is required then pass the patientid, else pass null or zero
       if single user's data is required then pass the UserId (EmployeeId) else pas NULL/Zero.
    
     Example: SP_BIL_RPT_GetDepositTransations '2021-06-15','2021-09-10','ram',NULL
    
    Change History:
    SN   User/Date                                Remarks
    1.   Sud/10Sep'21                              created
    */
    
      RETURN QUERY SELECT 
    	    depositdate, receiptno, 
    	  patientid, patientcode, patientname, dateofbirth, gender, phonenumber, 
    	  depositreceived,  depositdeducted,  depositreturned, 
    	  username, countername, remarks 
      from fn_rpt_bil_getdeposittransationsindatrange (p_fromdate,p_todate,p_patsearchtext,p_employeeid)
      order by depositid;
END;
$$ LANGUAGE plpgsql;