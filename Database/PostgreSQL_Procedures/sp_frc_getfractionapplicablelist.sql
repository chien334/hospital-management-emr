CREATE OR REPLACE FUNCTION sp_frc_getfractionapplicablelist(

)
RETURNS TABLE (
    "PercentSettingId" INT,
    "BillTransactionItemId" INT,
    "TransactionDate" TIMESTAMP,
    "ItemName" VARCHAR,
    "BillItemPriceId" INT,
    "TotalAmount" DECIMAL,
    "BillingType" VARCHAR,
    "FullName" VARCHAR,
    "ServiceDepartmentName" VARCHAR,
    "BillTxnItemId" INT
) AS $$
BEGIN
    /*
     altered by sud on 20nov'19 for Transaction Date
    */
    
    RETURN QUERY SELECT 
      per.PercentSettingId,txnItm.BillingTransactionItemId AS "BillTransactionItemId",
      txnItm.CreatedOn AS "TransactionDate",
      itmPrice.ItemName, 
      itmPrice.BillItemPriceId, txnItm.TotalAmount, txnItm.BillingType, (pat.FirstName || ' ' || pat.lastname) AS "FullName",
      txnitm.servicedepartmentname,  c.billtxnitemid 
      from bil_txn_billingtransactionitems txnitm
      join bil_cfg_billitemprice itmprice on txnitm.itemid = itmprice.itemid 
        join pat_patient pat on txnitm.patientid = pat.patientid
      left join frc_fractioncalculation c on txnitm.billingtransactionitemid = c.billtxnitemid
      left join frc_percentsetting per on per.billitempriceid = itmprice.billitempriceid
    where txnitm.servicedepartmentid = itmprice.servicedepartmentid 
        and itmprice.isfractionapplicable = 1 
    	and per.percentsettingid is not null
    
    group by txnitm.billingtransactionitemid,txnitm.createdon, itmprice.itemid, 
      c.billtxnitemid, itmprice.itemid ,  itmprice.billitempriceid, per.percentsettingid,
      c.billtxnitemid, itmprice.itemname ,
      txnitm.servicedepartmentname, txnitm.totalamount ,
      txnitm.billingtype, firstname, lastname
    order by txnitm.billingtransactionitemid desc;
END;
$$ LANGUAGE plpgsql;