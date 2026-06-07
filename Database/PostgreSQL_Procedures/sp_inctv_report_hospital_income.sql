CREATE OR REPLACE FUNCTION sp_inctv_report_hospital_income(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL,
    p_servicedepartments VARCHAR DEFAULT NULL
)
RETURNS TABLE (
    "ServiceDepartmentId" INT,
    "ServiceDepartmentName" VARCHAR,
    "NetSales" VARCHAR,
    "ReferralCommission" TIMESTAMP,
    "GrossIncome" VARCHAR,
    "OtherIncentive" VARCHAR,
    "HospitalNetIncome" VARCHAR
) AS $$
BEGIN
    
       RETURN QUERY SELECT
          itms.servicedepartmentid,
          itms.servicedepartmentname,
          sum(coalesce(itms.netsales, 0)) AS "NetSales",
          sum(coalesce(inctv.referralcommission, 0)) AS "ReferralCommission",
          (
             sum(coalesce(itms.netsales, 0)) - sum(coalesce(inctv.referralcommission, 0))
          )
          AS "GrossIncome",
          sum(coalesce(inctv.otherincentive, 0)) AS "OtherIncentive",
          (
    		(sum(coalesce(itms.netsales, 0)) - sum(coalesce(inctv.referralcommission, 0))) - sum(coalesce(inctv.otherincentive, 0))
          )
          AS "HospitalNetIncome" 
       from
          (
             select
                itm.billingtransactionitemid,
                servicedepartmentid,
                sum(coalesce(itm.totalamount, 0) - coalesce(retitm.retamount, 0)) AS "NetSales",
                --deduct returnamount to get netsales
                servicedepartmentname,
                (txn.createdon)::date as "invoicedate" 
             from
                bil_txn_billingtransaction txn 
                inner join
                   bil_txn_billingtransactionitems itm 
                   on itm.billingtransactionid = txn.billingtransactionid 
                left join
                   (
                      select
                         billingtransactionid,
                         billingtransactionitemid,
                         sum(rettotalamount) as "retamount" 
                      from
                         bil_txn_invoicereturnitems 
                      group by
                         billingtransactionid,
                         billingtransactionitemid
                   )
                   retitm 
                   on itm.billingtransactionitemid = retitm.billingtransactionitemid 
             where
                (txn.createdon)::date between p_fromdate and p_todate 
             group by
                itm.billingtransactionitemid,
                itm.servicedepartmentid,
                itm.servicedepartmentname,
                (txn.createdon)::date 				---end: get netsales at each billingtransacitonitem level---
          )
          itms 
          left join
             (
                --we need 2 level select query here.
                --1st level to seggregate referral and other commission at billingtxnitem + incentivetype level
                --2nd level to sum up that amount again at billingtxnitem level.
                select
                   billingtransactionitemid,
                   sum(coalesce(referralcommission, 0)) AS "ReferralCommission",
                   sum(coalesce(otherincentive, 0)) AS "OtherIncentive" 
                from
                   (
                      select
                         billingtransactionitemid,
                         incentivetype,
                         case
                            when
                               incentivetype = 'referral' 
                            then
                               sum(coalesce(incentiveamount, 0)) 
                         end
                         AS "ReferralCommission", 
                         case
                            when
                               (
                                  incentivetype = 'performer' 
                                  or incentivetype = 'prescriber'
                               )
                            then
                               sum(coalesce(incentiveamount, 0)) 
                         end
                         AS "OtherIncentive" 
                      from
                         inctv_txn_incentivefractionitem 
                      where
                         coalesce(isactive, 0) = 1 
                         and (transactiondate)::date between p_fromdate and p_todate 
                      group by
                         billingtransactionitemid, incentivetype 							---end :1st level query gives billingtxnitemid, incentivetype and their respective amounts---
                   )
                   a 					--end of 2nd level query for outer grouping
                group by
                   billingtransactionitemid 
             )
             inctv 
             on itms.billingtransactionitemid = inctv.billingtransactionitemid 
          inner join
             (
                select
                   value AS "ServiceDepartmentId" 
                from
                   string_split(p_servicedepartments, ',')
             )
             serv 
             on itms.servicedepartmentid = serv.servicedepartmentid 
       where
          (itms.invoicedate)::date between p_fromdate and p_todate 
       group by
          itms.servicedepartmentname,
          itms.servicedepartmentid 
       order by
          itms.servicedepartmentname;
END;
$$ LANGUAGE plpgsql;