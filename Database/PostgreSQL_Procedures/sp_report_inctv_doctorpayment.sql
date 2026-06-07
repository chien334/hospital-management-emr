CREATE OR REPLACE FUNCTION sp_report_inctv_doctorpayment(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    "PaymentDate" TIMESTAMP,
    "ReceiverName" VARCHAR,
    "PANNumber" VARCHAR,
    "ReceiverId" INT,
    "PaymentInfoId" INT,
    "TotalAmount" DECIMAL,
    "TDSAmount" DECIMAL,
    "NetPayAmount" DECIMAL,
    "AdjustedAmount" DECIMAL,
    "VoucherNumber" VARCHAR,
    "Remarks" VARCHAR,
    "CreatedBy" VARCHAR
) AS $$
BEGIN
    /*-- author: pratik/31march'20
    -- Description:	To get Incentive payment reports at doctor level for given date range
    --Change History:
    S.No.  Author/Date                   Remarks
    1.    Pratik/31March'20              initial draft
    2.	  ashish/29april'20				add two clm Voucher no. & remarks for get in report.
    3.    Pratik/13Dec'21               adding doctor pan number field in incentive report
    
    */
    
      RETURN QUERY SELECT (paymentdate)::date AS "PaymentDate",
      emp.fullname AS "ReceiverName",emp.pannumber, payinfo.receiverid,paymentinfoid,
      coalesce(payinfo.totalamount,0) AS "TotalAmount",
      coalesce(payinfo.tdsamount,0) AS "TDSAmount",
      coalesce(payinfo.netpayamount,0) AS "NetPayAmount",
      coalesce(payinfo.adjustedamount,0) AS "AdjustedAmount",
      coalesce(payinfo.vouchernumber,0) AS "VoucherNumber",
      coalesce(payinfo.remarks,0) AS "Remarks",
      (select fullname from emp_employee where employeeid=payinfo.createdby) AS "CreatedBy"
      from
      inctv_txn_paymentinfo payinfo
      join emp_employee emp
      on emp.employeeid=payinfo.receiverid
    
      where coalesce(payinfo.isactive,0)=1
    	    and (payinfo.paymentdate)::date between p_fromdate and p_todate;
END;
$$ LANGUAGE plpgsql;