CREATE OR REPLACE FUNCTION sp_report_handoverdetailreport(
    p_fromdate DATE,
    p_todate DATE,
    p_employeeid INT
)
RETURNS TABLE (
    "BankName" VARCHAR,
    "VoucherNumber" VARCHAR,
    "HandoverAmount" DECIMAL,
    "DueAmount" DECIMAL,
    "DepartmentName" VARCHAR,
    "HandoverDate" TIMESTAMP,
    "HandoverByEmpId" INT,
    "UserName" VARCHAR,
    "ReceivedById" INT,
    "ReceivedBy" VARCHAR,
    "ReceivedOn" TIMESTAMP,
    "ReceiveRemarks" VARCHAR,
    "CounterName" INT
) AS $$
BEGIN
    -- =============================================
    -- author:		<pratik mani lamichhane>
    -- create date: <10 aug 2021>
    -- description:	<handover detail report>
    -- =============================================
    
    RETURN QUERY SELECT handovertxn.bankname,handovertxn.vouchernumber,
    	handovertxn.handoveramount, handovertxn.dueamount, 
    	d.departmentname,handovertxn.createdon AS "HandoverDate",
    	handovertxn.handoverbyempid, handoveremp.fullname AS "UserName",
    	handovertxn.receivedbyid,receiveremp.fullname AS "ReceivedBy",
    	handovertxn.receivedon,handovertxn.receiveremarks,
    	counter.countername
    	from bil_txn_cashhandover handovertxn
    
    	join bil_cfg_counter counter on counter.counterid= handovertxn.counterid
    	join emp_employee handoveremp on handoveremp.employeeid= handovertxn.handoverbyempid
    	join emp_employee receiveremp on receiveremp.employeeid= handovertxn.receivedbyid
    	left join mst_department d on receiveremp.departmentid = d.departmentid 
    	
    	where handovertxn.isactive=1 
    	and (handovertxn.createdon)::date between p_fromdate and p_todate
    	and	handovertxn.handoverbyempid = p_employeeid;
END;
$$ LANGUAGE plpgsql;