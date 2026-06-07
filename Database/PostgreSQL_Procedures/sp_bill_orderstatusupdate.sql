CREATE OR REPLACE FUNCTION sp_bill_orderstatusupdate(
    p_requisitionid_orderstatus labrequisitionid_orderstatus_table[]
)
RETURNS void AS $$
BEGIN
    /*
    author:		<anish bhattarai>
    create date: <7 aug, 2020>
    description:	<update the orderstatus of billtxnitem table>
    change history:
    s.n			changedby/date					remarks
    1.			anish/10thaug'23				Initial draft
    2.			Krishna/20thJuly'23				alter join condition for billingtransactionitem and labrequisition
    3.          devn/12thsept'23                Alter Parametertype get list of requisitionId and orderstatus from client.
    */
    
    UPDATE BIL_TXN_BillingTransactionItems SET OrderStatus = req.OrderStatus FROM 
        (SELECT requisition.RequisitionId,requisition.BillingTransactionItemId, parameter.OrderStatus FROM LAB_TestRequisition requisition 
    	INNER JOIN unnest(p_requisitionid_orderstatus) parameter ON requisition.RequisitionId = parameter.RequisitionId) as req 
    	join BIL_TXN_BillingTransactionItems as txnItem on req.BillingTransactionItemId = txnItem.BillingTransactionItemId
    	join BIL_MST_ServiceDepartment as srv on txnItem.ServiceDepartmentId = srv.ServiceDepartmentId
    	where srv.IntegrationName = 'lab' and coalesce(txnitem.returnstatus,0)= 0 and  txnitem.cancelledby is null;
END;
$$ LANGUAGE plpgsql;