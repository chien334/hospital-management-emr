/*-- =============================================
-- Author:        <Pratik Mani Lamichhane>
-- Create date: <29 March 2021>
-- Description:    <Handover Receive Transaction Report>
-- Change History-----
S.No.   Date/Author    Remarks
1.     29March'21/Pratik                Initial Draft
2.     25Aug'21/Dev Narayan				some changes done in report
3.     29Sept'21/Sud                    Filtering By Received On rather than VoucherDate.
-- =============================================*/
CREATE OR REPLACE FUNCTION sp_handoverreceivetransactionreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "VoucherDate" TIMESTAMP,
    "BankName" VARCHAR,
    "VoucherNumber" VARCHAR,
    "HandoverAmount" DECIMAL,
    "DueAmount" DECIMAL,
    "ReceivedById" INT,
    "ReceivedBy" VARCHAR,
    "DepartmentName" VARCHAR,
    "UserName" VARCHAR,
    "ReceivedOn" TIMESTAMP,
    "ReceiveRemarks" VARCHAR
) AS $$
BEGIN
    
        RETURN QUERY SELECT handovertxn.voucherdate,
        handovertxn.bankname,handovertxn.vouchernumber,handovertxn.handoveramount,handovertxn.dueamount,
        handovertxn.receivedbyid,receiveremp.fullname AS "ReceivedBy",
        d.departmentname,handoveremp.fullname AS "UserName",
        handovertxn.receivedon,handovertxn.receiveremarks
        from bil_txn_cashhandover handovertxn
        join bil_cfg_counter counter on counter.counterid= handovertxn.counterid
        join emp_employee handoveremp on handoveremp.employeeid= handovertxn.handoverbyempid
        join emp_employee receiveremp on receiveremp.employeeid= handovertxn.receivedbyid
        left join mst_department d on receiveremp.departmentid = d.departmentid --and coalesce(0,reciveremp.departmentid)
        
        where handovertxn.isactive=1 and handovertxn.receivedbyid is not null 
    	    and (handovertxn.receivedon)::date between p_fromdate and p_todate
        order by handovertxn.receivedon desc;
END;
$$ LANGUAGE plpgsql;