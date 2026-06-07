/*
  FileName: [SP_MAT_RPT_GetMaternityPaymentDetails] 
  CreatedBy/date: Swapnil/19-11-2021
  Execute SP : exec [SP_MAT_RPT_GetMaternityPaymentDetails] '2022-01-01','2022-03-25'
  Description: To get the Details of  Maternity Payment Details Report
  Remarks:    
  Change History
  S.No.    UpdatedBy/Date                        Remarks
  1.    Swapnil/19-11-2021                   created the script
  2.    Aniket/21-11-2021                    added patientpaymentId d.PatientPaymentId and updated InAmount instead of OutAmount and vise versa 
  3.    Dev Narayan/31-03-2022               Enhancement of report
  */
CREATE OR REPLACE FUNCTION sp_mat_rpt_getmaternitypaymentdetails(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_userid INT DEFAULT 0
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    begin
      if (
        (p_fromdate is not null) 
        and (p_todate is not null)
      ) 
    then p_userid := coalesce(p_userid, 0); end if;  begin 
    open ref1 for select 
      sum(
        coalesce(d.paidamount, 0)
      ) - sum(
        coalesce(d.returnamount, 0)
      ) as "netpaidamount", 
      sum(
        coalesce(d.paidamount, 0)
      ) as "paidtopatient", 
      sum(
        coalesce(d.returnamount, 0)
      ) as "returnedfrompatient", 
      d.patientpaymentid as "patientpaymentid" 
    from 
      (
        select 
          case when mtp.transactiontype = 'MaternityAllowance' then mtp.outamount end as "paidamount", 
          case when mtp.transactiontype = 'MaternityAllowanceReturn' then mtp.inamount end as "returnamount", 
          mtp.patientpaymentid 
        from 
          mat_txn_patientpayments mtp 
        where 
          (
            (mtp.createdon)::date between (p_fromdate)::date 
            and (p_todate)::date
          ) 
          and mtp.transactiontype in (
            'MaternityAllowance', 'MaternityAllowanceReturn'
          ) 
          and (
            mtp.createdby = p_userid 
            or p_userid = 0
          )
      ) as d 
    group by 
      d.patientpaymentid;
        return next ref1; 
    open ref2 for select 
      mtp.receiptno, 
      mtp.createdon, 
      case when mtp.transactiontype = 'MaternityAllowance' then 'Maternity Allowance' else 'Maternity Allowance Return' end as "transactiontype", 
      p.shortname, 
      p.patientcode as "hospitalno", 
      p.age, 
      p.gender, 
      e.fullname, 
      mtp.patientpaymentid as "patientpaymentid", 
      case when mtp.transactiontype = 'MaternityAllowance' then mtp.outamount else 0 end as "amount", 
      case when mtp.transactiontype = 'MaternityAllowanceReturn' then mtp.inamount else 0 end as "returnamount" 
    from 
      mat_txn_patientpayments mtp 
      join emp_employee e on mtp.createdby = e.employeeid 
      join pat_patient p on mtp.patientid = p.patientid 
    where 
      (
        (mtp.createdon)::date between (p_fromdate)::date 
        and (p_todate)::date
      ) 
      and mtp.transactiontype in (
        'MaternityAllowance', 'MaternityAllowanceReturn'
      ) 
      and (
        mtp.createdby = p_userid 
        or p_userid = 0
      );
        return next ref2; 
     end; 
    end;
END;
$$ LANGUAGE plpgsql;