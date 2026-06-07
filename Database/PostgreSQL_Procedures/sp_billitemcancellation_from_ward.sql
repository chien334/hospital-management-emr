CREATE OR REPLACE FUNCTION sp_billitemcancellation_from_ward(
    p_billingtransactionitemid INT,
    p_requisitionid INT,
    p_integrationname VARCHAR,
    p_userid INT,
    p_remarks VARCHAR
)
RETURNS TABLE (
    "v_cancelledon" TIMESTAMP
) AS $$
DECLARE
    v_cancelledon TIMESTAMP;
BEGIN
    /*
    author:		<anish bhattarai>
    create date: <12 august>
    description:	<cancellation of bill item>
    change history
    s.n.		updatedby/date				remarks
    1			anish/12august				initial script
    2			bibek/25thsept'23			update lab and imaging requisitions using billingtransactionItemId 
    */
    
    BEGIN
    	
    		
    	
    		
    		v_cancelledon := CURRENT_TIMESTAMP;
    		RETURN QUERY SELECT v_cancelledon;
    
    		Update BIL_TXN_BillingTransactionItems
    		set BillStatus='cancel', CancelledBy=p_userid,CancelledOn=v_cancelledon,CancelRemarks=p_remarks where BillingTransactionItemId=p_billingtransactionitemid;
    
    		IF(LOWER(p_integrationname)='lab')
    		THEN
    			Update LAB_TestRequisition set BillingStatus='cancel', BillCancelledBy=p_userid, BillCancelledOn=v_cancelledon where BillingTransactionItemId=p_billingtransactionitemid;
    		END IF;
    
    		IF(LOWER(p_integrationname)='radiology')
    		THEN
    			Update RAD_PatientImagingRequisition set BillingStatus='cancel', billcancelledby=p_userid, billcancelledon=v_cancelledon where billingtransactionitemid=p_billingtransactionitemid;
    		end if;	
    
    		commit;
    
    	
    
    	
    
    end;
END;
$$ LANGUAGE plpgsql;