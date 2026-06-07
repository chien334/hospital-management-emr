CREATE OR REPLACE FUNCTION sp_report_itemwisefromlab(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "ServiceDepartmentName" VARCHAR,
    "ItemName" VARCHAR,
    "Unit" VARCHAR,
    "TotalAmount" DECIMAL
) AS $$
BEGIN
    /*
    filename: "sp_report_itemwisefromlab" '2019-10-09','2019-10-09'
    createdby/date: dinesh/2019-09-22
    description: to get the total count and amount of individual tests along with service department name
    remarks:    
    change history
    s.no.    updatedby/date                        remarks
    1       dinesh 2019-09-22          to get the count of tests from lab daywise
    */
    
    begin
    if(p_fromdate is not null or p_todate is not null)
      then 
          RETURN QUERY SELECT x.servicedepartmentname, x.itemname,sum(quantity) AS "Unit",sum(totalamount) AS "TotalAmount" from (
    select
    case when bt.itemname like '%ECHO%' then 'ECHO'
     else bt.itemname end AS "ItemName" ,
    --else coalesce(' ',0) end 'SD',
    sd.servicedepartmentname AS "ServiceDepartmentName",
        sum(coalesce(bt.quantity, 0))  as "quantity",
        sum(coalesce(bt.totalamount, 0)) AS "TotalAmount"
      from bil_mst_servicedepartment sd 
      join bil_txn_billingtransactionitems bt on sd.servicedepartmentid= bt.servicedepartmentid
      left join bil_txn_invoicereturnitems ret on bt.billingtransactionitemid=ret.billingtransactionitemid
      where  ret.billingtransactionitemid is null and bt.billstatus!='cancel' and
      (bt.createdon)::date between (p_fromdate)::date and (p_todate)::date and sd.integrationname like 'LAB'
      group by bt.itemname,sd.integrationname,sd.servicedepartmentname
      )as x
      --where x.itemname !='Unknown'
      group by x.itemname,x.servicedepartmentname
      order by unit desc;
      end if;  
    end;
END;
$$ LANGUAGE plpgsql;