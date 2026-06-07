CREATE OR REPLACE FUNCTION sp_wardreport_transferreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_storeid INT DEFAULT NULL,
    p_status INT DEFAULT NULL
)
RETURNS TABLE (
    "Date" TIMESTAMP,
    "ItemName" VARCHAR,
    "TransferQty" INT,
    "Remarks" VARCHAR,
    "TransferedBy" VARCHAR,
    "ReceivedBy" VARCHAR
) AS $$
BEGIN
    /*
    filename: "sp_wardreport_transferreport" '1/7/2020','1/8/2020',13
    createdby/date: rusha/03-26-2019
    description: to get the details of report of ward to ward tranfer and ward to pharmacy trannsfer of stock 
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1.		rusha/03-29-2019						shows report of ward to ward transfer and ward to pharmacy transfer
    2.		sanjit/01-09-2020						added received by field in both transfer cases.
    3.		sanjit/05-22-2020						corrected date format
    */
    
    begin
      if ((p_fromdate is not null) and (p_todate is not null)) 
    		then
    		--if (p_status = 1)
    			--select convert(date,transc.createdon) AS "Date",itemname, transc.quantity AS "TransferQty", remarks,transc.createdby AS "TransferedBy",transc.receivedby AS "ReceivedBy" from ward_transaction as transc
    			--join phrm_mst_item as itm on transc.itemid=itm.itemid
    			--where transactiontype = 'WardtoWard' and convert(date, transc.createdon) between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    			--group by itm.itemname, transc.quantity,transc.remarks, convert(date,transc.createdon),transc.createdby,transc.receivedby
    		
    		--elsif (p_status =0)
    			 RETURN QUERY SELECT (transc.createdon)::varchar AS "Date",itemname, transc.quantity AS "TransferQty",transc.remarks,transc.createdby AS "TransferedBy",transc.receivedby AS "ReceivedBy" 
    			from ward_transaction as transc
    			join phrm_mst_item as itm on transc.itemid=itm.itemid
    			where transc.storeid = p_storeid and transactiontype = 'WardToPharmacy' and (transc.createdon)::date between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    			group by itm.itemname, transc.quantity,transc.remarks,transc.createdon,transc.createdby,transc.receivedby;
    			 
    
    		--else
    			--select convert(date,transc.createdon) AS "Date",itemname, transc.quantity AS "TransferQty", remarks,transc.createdby AS "TransferedBy",transc.receivedby AS "ReceivedBy" from ward_transaction as transc
    			--join phrm_mst_item as itm on transc.itemid=itm.itemid
    			--where transactiontype in ('WardToPharmacy','WardtoWard') and convert(date, transc.createdon) between coalesce(p_fromdate,current_timestamp)  and coalesce(p_todate,current_timestamp)+1
    			--group by itm.itemname, transc.quantity,transc.remarks, convert(date,transc.createdon),transc.createdby,transc.receivedby
    		end if;	
    end;
END;
$$ LANGUAGE plpgsql;