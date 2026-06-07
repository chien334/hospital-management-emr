/* ***********************************************************************
  FileName: [SP_UserWiseHandoverReport]
  exec [SP_TransferHandoverReport] '2022-11-13','2022-12-13','all','all'
  S.No.    UpdatedBy/Date                        Remarks
  1.      Dev Narayan 30'Nov'22               SP Script created for Transfer Handover Report
  ************************************************************************ */
CREATE OR REPLACE FUNCTION sp_transferhandoverreport(
    p_fromdate TIMESTAMP,
    p_todate TIMESTAMP,
    p_status VARCHAR,
    p_handovertype VARCHAR
)
RETURNS TABLE (
    "HandoverDate" TIMESTAMP,
    "HandoverBy" VARCHAR,
    "Amount" DECIMAL,
    "ReceivedBy" VARCHAR,
    "Status" VARCHAR,
    "ReceivedDate" TIMESTAMP,
    "HandoverRemark" VARCHAR,
    "ReceiveRemark" VARCHAR,
    "HandoverType" VARCHAR
) AS $$
BEGIN
    
    	RETURN QUERY SELECT handover.createdon AS "HandoverDate"
    		,transferer.fullname AS "HandoverBy"
    		,handover.handoveramount AS "Amount"
    		,receiver.fullname AS "ReceivedBy"
    		,handover.handoverstatus AS "Status"
    		,handover.receivedon AS "ReceivedDate"
    		,handover.handoverremarks AS "HandoverRemark"
    		,handover.receiveremarks AS "ReceiveRemark"
    		,handover.handovertype
    	from bil_txn_cashhandover handover
    	join emp_employee transferer on handover.handoverbyempid = transferer.employeeid
    	left join emp_employee receiver on handover.receivedbyid = receiver.employeeid
    	where (handover.createdon)::date between (p_fromdate)::date
    			and (p_todate)::date
    		and (
    			p_status = 'all'
    			or handover.handoverstatus = p_status
    			)
    		and (
    			p_handovertype = 'all'
    			or handover.handovertype = p_handovertype
    			);
END;
$$ LANGUAGE plpgsql;