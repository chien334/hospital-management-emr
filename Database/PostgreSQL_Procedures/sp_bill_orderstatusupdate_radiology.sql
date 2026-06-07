/*
Author:		<Anish Bhattarai>
Create date: <10 Aug, 2020>
Description:	<Update OrderStatus on BillTxnItems table on Radiology Actions>

Change History:
S.N			ChangedBy/Date					Remarks
1.			Anish/10thAug'23				Initial draft
2.			Krishna/20thJuly'23				Alter Join condition for BillingTransactionItem and ImagingRequisition
*/
CREATE OR REPLACE FUNCTION sp_bill_orderstatusupdate_radiology(
    p_reqid INT,
    p_status VARCHAR
)
RETURNS void AS $$
BEGIN
    
    	update bil_txn_billingtransactionitems set orderstatus=p_status where billingtransactionitemid in (
    	(select txnitem.billingtransactionitemid from (select * from rad_patientimagingrequisition 
    	where imagingrequisitionid = p_reqid) as req 
    	join bil_txn_billingtransactionitems as txnitem on req.billingtransactionitemid = txnitem.billingtransactionitemid
    	join bil_mst_servicedepartment as srv on txnitem.servicedepartmentid = srv.servicedepartmentid
    	where lower(srv.integrationname) = 'radiology' and coalesce(txnitem.returnstatus,0)= 0 and  txnitem.cancelledby is null)
    	);
END;
$$ LANGUAGE plpgsql;