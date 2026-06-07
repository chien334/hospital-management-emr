CREATE OR REPLACE FUNCTION sp_report_deposit_balance(

)
RETURNS TABLE (
    "PatientId" INT,
    "PatientCode" VARCHAR,
    "PatientName" VARCHAR,
    "DateOfBirth" TIMESTAMP,
    "Gender" VARCHAR,
    "PhoneNumber" TIMESTAMP,
    "TotalDeposit" DECIMAL,
    "TotalDeducted" DECIMAL,
    "TotalRefunded" DECIMAL,
    "Balance" DECIMAL
) AS $$
DECLARE
    v_fromdate DATE := '2015-01-01'; -- Need to get from the beginning of the Software..

    v_todate DATE := (CURRENT_TIMESTAMP)::Date;
BEGIN
    /*
    filename: "sp_report_deposit_balance"
    createdby/date: dinesh/2017-07-19
    description: to get the deposit balance of the patient
    change history
    s.no.    updatedby/date                        remarks
    1       umed/2017-05-25                     created the script
    2       umed/2018-04-23                  apply round off on deposit balance because during export it dont require
    3.     ramavtar/2018-06-05              change the whole sp.. bring deposit amount of patients
    4.     narayan/2019-09-16               added  depositid column.
    5.     arpan/shankar/2020-03-24         deduct both depositdeduct and returndeposit from deposit
    6.     sud/5-oct-2020                   adding phonenumber to deposit balance report
    7.     sud/pratik: 12sep'21             showing deposits of only patient having some deposits remaining.
    */
    
     --need to check upto-today.
    
      RETURN QUERY SELECT * from 
      (
        select patientid, patientcode, patientname, dateofbirth,
          gender, phonenumber, sum(coalesce(depositreceived,0)) AS "TotalDeposit",
        sum(coalesce(depositdeducted,0)) AS "TotalDeducted",
        sum(coalesce(depositreturned,0)) AS "TotalRefunded",
        sum(coalesce(depositreceived,0))- sum((coalesce(depositdeducted,0)+coalesce(depositreturned,0))) AS "Balance"
        from fn_rpt_bil_getdeposittransationsindatrange (v_fromdate,v_todate,null,null)
        group by patientid, patientcode, patientname, dateofbirth, gender, phonenumber
      ) a
      where balance !=0;
END;
$$ LANGUAGE plpgsql;