CREATE OR REPLACE FUNCTION sp_report_bill_dailymisreport(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    ref3 refcursor := 'cursor3';
    ref4 refcursor := 'cursor4';
    ref5 refcursor := 'cursor5';
    ref6 refcursor := 'cursor6';
    ref7 refcursor := 'cursor7';
    ref8 refcursor := 'cursor8';
    ref9 refcursor := 'cursor9';
    ref10 refcursor := 'cursor10';
    ref11 refcursor := 'cursor11';
BEGIN
    /*  
    filename: sp_report_bill_dailymisreport  
    change history  
    s.no.    updatedby/date  remarks  
    1       ramavtar/2018-08-30     created the script  
    2       sud/2018-08-30          revised for provisional and billstatus  
    3  ajay/2018-12-12   getting data for summaryview  
    4  ajay/2018-12-14   getting data from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"  
    5  ram/ajay 17dec2018  corrected calculation 
    6  krishna/9thjun'22	changed ProviderId to PerformerId and ProviderName to PerformerName
    */  
    BEGIN  
    
      OPEN ref1 FOR WITH BilTxnItemsCTE  
      AS (SELECT  
        bil.BillingTransactionItemId,  
        pat.PatientCode AS HospitalNo,  
        pat.FirstName || ' ' || COALESCE(pat.MiddleName || ' ', '') || pat.LastName AS PatientName,  
        bil.PerformerName,  
        dept.DepartmentName,  
        bil.ServiceDepartmentName,  
        (p_fromdate)::VARCHAR || '-to-' || (p_todate)::VARCHAR AS "billDate",  
        --COALESCE(bil.PaidDate,bil.CreatedDate) AS billDate,  
        bil.ItemName AS "description",  
        bil.Price,  
        bil.Quantity AS qty,  
        bil.SubTotal AS subTotal,  
        bil.DiscountAmount AS discount,  
        COALESCE(bil.ReturnAmount, 0) AS ReturnAmount,  
        bil.TotalAmount AS total,  
        bil.BillStatus, --sud:30Aug'18  
        bil.provisionalamount as "provisionalamount",--sud:30aug'18 (We'll need this as well)  
        coalesce(bil.billingtype, 'OutPatient')  
        as billingtype  
      from (select  
        *  
      from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate)) bil  
      join pat_patient pat  
        on bil.patientid = pat.patientid  
      join bil_mst_servicedepartment sdept  
        on sdept.servicedepartmentid = bil.servicedepartmentid  
      join mst_department dept  
        on dept.departmentid = sdept.departmentid  
      --where bil.createddate between p_fromdate and p_todate  
      )  
      select  
        case  
          when "departmentname" = 'ADMINISTRATION' and  
            servicedepartmentname != 'CONSUMEABLES' then 'ADMINISTRATIVE'  
          when servicedepartmentname = 'CONSUMEABLES' then 'CONSUMEABLES'  
          when "departmentname" = 'OT' and  
            "departmentname" != '' then 'OT'  
          when "description" = 'BED CHARGES' then 'BED'  
          when "description" = 'INDOOR-DOCTOR''S VISIT FEE (PER DAY)' then 'DOCTOR AND NURSING CARE'  
          when "departmentname" = 'MEDICINE' then 'MEDICINE'  
          when "departmentname" = 'SURGERY' then 'SURGERY'  
          else departmentname  
        end as departmentname,  
        hospitalno as "hospitalno",  
        patientname as "patientname",  
        performername as "performername",  
        billingtype,  
        description as "itemname",  
        price as "price",  
        qty as "quantity",  
        subtotal as "subtotal",  
        discount as "discount",  
        returnamount as "return",  
        coalesce(total, 0) - coalesce(returnamount, 0) as "nettotal",  
        billstatus as "billstatus",  
        provisionalamount as "provisional"  
      from biltxnitemscte  
      order by departmentname asc, billingtype desc, patientname asc;
        return next ref1;  
      
     open ref2 for select  
      coalesce(fn.performerid, 0) as "performerid",--performerid  
      coalesce(fn.performername, 'NoDoctor') as "performername",--performername  
      count(  
       case  
        when fn.billstatus = 'return' and fn.paiddate is not null then fn.patientid  
        when fn.billstatus != 'return' then fn.patientid  
       end) - count(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.patientid end) as "count",  
      sum(  
       case  
        when fn.billstatus = 'return' and fn.paiddate is not null then fn.paidamount  
        when fn.billstatus != 'return' then fn.paidamount  
        else 0  
       end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.returnamount else 0 end) as "totalamount"  
     from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
     join "vw_bil_txnitemsinfowithdateseparation_mis_report" vw on fn.billingtransactionitemid = vw.billingtransactionitemid  
     where fn.itemname = 'Consultation Charge'  
      and fn.billstatus != 'provisional'  
      and fn.billstatus != 'cancelled'  
      and fn.billstatus != 'credit'  
      --and (fn.paymentmode != 'credit' or fn.creditdate is not null)  
     group by fn.performerid,  
      fn.performername  
     order by 2;
        return next ref2;  
      
     open ref3 for select  
      fn.itemname as "itemname",  
      sum(  
       case  
        when fn.billstatus = 'return' and fn.paiddate is not null then fn.qty_temp  
        when fn.billstatus != 'return' then fn.qty_temp  
        else 0  
       end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.qty_temp else 0 end) as "count",  
      sum(  
       case  
        when fn.billstatus = 'return' and fn.paiddate is not null then fn.paidamount  
        when fn.billstatus != 'return' then fn.paidamount  
        else 0  
       end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.returnamount else 0 end) as "totalamount"  
     from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
     join "vw_bil_txnitemsinfowithdateseparation_mis_report" vw on fn.billingtransactionitemid = vw.billingtransactionitemid  
     where fn.itemname like '%Health Card%'  
      and fn.billstatus != 'provisional'  
      and fn.billstatus != 'cancelled'  
      and fn.billstatus != 'credit'  
      --and (fn.paymentmode != 'credit' or fn.creditdate is not null)  
     group by fn.itemname;
        return next ref3;  
      
     open ref4 for select  
      visittype,  
      ai.servicedepartmentname,  
      sum("count") as "count",  
      sum("totalamount") as "totalamount"  
     from (  
      select  
       case  
        when fn.visittype = 'inpatient' then 'IPD'  
        when fn.visittype = 'outpatient' then 'OPD'  
        else fn.visittype  
       end as visittype,  
       fn.servicedepartmentname,  
       sum(case  
        when fn.billstatus = 'return' and fn.paiddate is not null then fn.qty_temp  
        when fn.billstatus != 'return' then fn.qty_temp  
        else 0  
       end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.qty_temp else 0 end) as "count",  
       sum(case  
        when fn.billstatus = 'return' and fn.paiddate is not null then fn.paidamount  
        when fn.billstatus != 'return' then fn.paidamount  
        else 0  
       end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.returnamount else 0 end) as "totalamount"  
      from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
       inner join bil_mst_servicedepartment sd on fn.servicedepartmentid = sd.servicedepartmentid  
       join "vw_bil_txnitemsinfowithdateseparation_mis_report" vw on fn.billingtransactionitemid = vw.billingtransactionitemid  
      where sd.integrationname = 'LAB'  
       and fn.billstatus != 'cancelled'  
       and fn.billstatus != 'provisional'  
       and fn.billstatus != 'credit'  
       --and (fn.paymentmode != 'credit' or fn.creditdate is not null)  
      group by fn.visittype,  
               fn.servicedepartmentname  
     ) ai  
     group by ai.servicedepartmentname,  
               visittype  
      union all  
      select  
        ' ',  
        'Total',  
        sum(  
      case  
       when fn.billstatus = 'return' and fn.paiddate is not null then fn.qty_temp  
       when fn.billstatus != 'return' then fn.qty_temp  
       else 0  
       end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.qty_temp else 0 end) as "total count",  
     sum(  
      case  
       when fn.billstatus = 'return' and fn.paiddate is not null then fn.paidamount  
       when fn.billstatus != 'return' then fn.paidamount  
       else 0  
      end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.returnamount else 0 end) as "totalamount"  
      from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
     inner join bil_mst_servicedepartment sd on fn.servicedepartmentid = sd.servicedepartmentid  
     join "vw_bil_txnitemsinfowithdateseparation_mis_report" vw on fn.billingtransactionitemid = vw.billingtransactionitemid  
      where sd.integrationname = 'LAB'  
     and fn.billstatus != 'cancelled'  
     and fn.billstatus != 'provisional'  
     and fn.billstatus != 'credit'  
     --and (fn.paymentmode != 'credit' or fn.creditdate is not null)  
      order by visittype;
        return next ref4;  
      
     open ref5 for select  
      case  
       when bt.visittype = 'inpatient' then 'IPD'  
       when bt.visittype = 'outpatient' then 'OPD'  
       else bt.visittype  
      end as visittype,  
      bt.servicedepartmentname,  
      sum(case  
       when fn.billstatus = 'return' and fn.paiddate is not null then fn.qty_temp  
       when fn.billstatus != 'return' then fn.qty_temp  
       else 0  
      end) - sum(case when fn.billstatus = 'return' and bt.paiddate is not null then fn.qty_temp else 0 end) as "count",  
      sum(case  
       when fn.billstatus = 'return' and fn.paiddate is not null then fn.paidamount  
       when fn.billstatus != 'return' then fn.paidamount  
       else 0  
      end) - sum(case when fn.billstatus = 'return' and bt.paiddate is not null then fn.returnamount else 0 end) as "totalamount"  
     from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
      inner join bil_txn_billingtransactionitems bt on fn.billingtransactionitemid = bt.billingtransactionitemid  
      inner join bil_mst_servicedepartment sd on bt.servicedepartmentid = sd.servicedepartmentid  
     where sd.integrationname = 'Radiology'  
      and fn.billstatus != 'cancelled'  
      and fn.billstatus != 'provisional'  
      and fn.billstatus != 'credit'  
      --and (fn.paymentmode != 'credit' or fn.creditdate is not null)  
     group by bt.visittype,  
      bt.servicedepartmentname  
      union all  
     select  
      ' ',  
      'Total',  
      sum(case  
       when fn.billstatus = 'return' and fn.paiddate is not null then fn.qty_temp  
       when fn.billstatus != 'return' then fn.qty_temp  
       else 0  
      end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.qty_temp else 0 end) as "total count",  
      sum(case  
       when fn.billstatus = 'return' and fn.paiddate is not null then fn.paidamount  
       when fn.billstatus != 'return' then fn.paidamount  
       else 0  
      end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.returnamount else 0 end) as "totalamount"  
     from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
      inner join bil_mst_servicedepartment sd on fn.servicedepartmentid = sd.servicedepartmentid  
      join "vw_bil_txnitemsinfowithdateseparation_mis_report" vw on fn.billingtransactionitemid = vw.billingtransactionitemid  
     where sd.integrationname = 'Radiology'  
      and fn.billstatus != 'cancelled'  
      and fn.billstatus != 'provisional'  
      and fn.billstatus != 'credit'  
      --and (fn.paymentmode != 'credit' or fn.creditdate is not null)  
     order by visittype;
        return next ref5;  
      
     open ref6 for select  
      x.itemname,  
      sum(quantity) as "unit",  
      sum(totalamount) as "totalamount"  
     from (  
      select  
       case  
         when fn.itemname like '%ECHO%' then 'ECHO'  
         when fn.itemname like '%TMT%' then 'TMT'  
         when fn.itemname like '%ECG%' then 'ECG'  
         when fn.itemname like '%Holter%' then 'Holter'  
         else 'Unknown'  
       end as itemname,  
       sum(case  
         when fn.billstatus = 'return' and fn.paiddate is not null then fn.qty_temp  
         when fn.billstatus != 'return' then fn.qty_temp  
         else 0  
       end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.qty_temp else 0 end) as "quantity",  
       sum(case  
         when fn.billstatus = 'return' and fn.paiddate is not null then fn.paidamount  
         when fn.billstatus != 'return' then fn.paidamount  
         else 0  
       end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.returnamount else 0 end) as "totalamount"  
      from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
      join "vw_bil_txnitemsinfowithdateseparation_mis_report" vw on fn.billingtransactionitemid = vw.billingtransactionitemid  
      where fn.billstatus != 'cancelled'  
       and fn.billstatus != 'provisional'  
       and fn.billstatus != 'credit'  
       --and (fn.paymentmode != 'credit' or fn.creditdate is not null)  
      group by fn.itemname  
     ) as x  
     where x.itemname != 'Unknown'  
     group by x.itemname;
        return next ref6;  
      
     open ref7 for select  
      fn.performerid,  
      fn.performername,  
      dept.departmentname,  
      fn.itemname,  
      sum(  
       case   
        when fn.billstatus = 'return' and  ((fn.paymentmode = 'credit' and fn.creditdate is not null) or (fn.paymentmode != 'credit' and fn.paiddate is not null)) then fn.quantity  
        when fn.billstatus != 'return' then fn.qty_temp  
        else 0  
       end) - sum(case when fn.billstatus = 'return' then fn.qty_temp else 0 end) as "quantity",  
      sum(case when fn.billstatus = 'provisional' then fn.provisionalamount else 0 end) as "prov_amount",  
      sum(case when fn.billstatus = 'credit' then fn.creditamount else 0 end) as "credit_amount",  
      sum(  
       case  
        when fn.billstatus = 'return' and ((fn.paymentmode = 'credit' and fn.creditdate is not null) or (fn.paymentmode != 'credit' and fn.paiddate is not null)) then fn.total_temp  
        when fn.billstatus != 'return' then fn.total_temp  
        else 0   
       end) - sum(case when fn.billstatus = 'return' then fn.returnamount else 0 end) as "totalamount"  
     from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
      inner join emp_employee emp on fn.performerid = emp.employeeid  
      inner join mst_department dept on emp.departmentid = dept.departmentid  
     where fn.itemname like '%operation%'  
      and fn.billstatus != 'cancelled'  
      and (fn.paymentmode != 'credit' or fn.creditdate is not null or fn.billstatus = 'provisional')  
     group by fn.performerid,  
      fn.performername,  
      dept.departmentname,  
      fn.itemname,  
      fn.servicedepartmentname;
        return next ref7;  
      
      open ref8 for select  
       x.itemname,  
       sum(quantity) as "unit",  
       sum(totalamount) as "totalamount"  
      from (  
       select  
        case  
         when fn.itemname like '%labor%' then 'LABOR Normal'  
         when fn.itemname like '%LSCS%' then 'LABOR LSCS'  
         else 'Unknown'  
        end as itemname,  
        sum(  
         case  
          when fn.billstatus = 'return' and fn.paiddate is not null then fn.qty_temp  
          when fn.billstatus != 'return' then fn.qty_temp  
          else 0  
         end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.qty_temp else 0 end) as "quantity",  
        sum(  
         case  
          when fn.billstatus = 'return' and fn.paiddate is not null then fn.paidamount  
          when fn.billstatus != 'return' then fn.paidamount else 0  
         end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.returnamount else 0 end) as "totalamount"  
       from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
       join "vw_bil_txnitemsinfowithdateseparation_mis_report" vw on fn.billingtransactionitemid = vw.billingtransactionitemid  
       where fn.billstatus != 'cancelled'  
        and fn.billstatus != 'provisional'  
        and fn.billstatus != 'credit'  
        --and (fn.paymentmode != 'credit' or fn.creditdate is not null)  
       group by fn.itemname  
      ) as x  
      where x.itemname != 'Unknown'  
      group by x.itemname;
        return next ref8;  
      
     open ref9 for select  
         'No. of Admssions' as "patienttype",  
      count(patientadmissionid) as "count"  
     from adt_patientadmission  
     where (admissiondate)::date between p_fromdate and p_todate  
        
     union all  
     select  
      'No. of Discharges',  
      count(patientadmissionid)  
     from adt_patientadmission  
     where (dischargedate)::date between p_fromdate and p_todate  
      and dischargedate is not null  
      
     union all  
     select  
         'Total No. of Admitted Patient' as "patienttype",  
      count(patientadmissionid) as "count"  
     from adt_patientadmission  
     where  (dischargedate)::date is null and admissionstatus = 'admitted';
        return next ref9;  
      
     open ref10 for select  
      x.itemname,  
      sum(quantity) as "unit",  
      sum(totalamount) as "totalamount"  
     from (  
      select  
       case  
        when fn.itemname like '%ECHO%' then 'ECHO'  
        when fn.itemname like '%TMT%' then 'TMT'  
        when fn.itemname like '%ECG%' then 'ECG'  
        when fn.itemname like '%Holter%' then 'Holter'  
        when fn.itemname like '%CONSULTATION%' then 'OPD'  
        when fn.itemname like '%Health Card%' then 'Health Card'  
        when sd.integrationname like 'LAB' then 'LABS'  
        when sd.integrationname like 'RADIOLOGY' then 'RADIOLOGY'  
        when fn.itemname like '%Operation%' then 'OPERATION CHARGES'  
        else 'Hospital Other Charges'  
       end as itemname,  
       sum(  
        case  
         when fn.billstatus = 'return' and  fn.paiddate is not null then fn.qty_temp  
         when fn.billstatus != 'return' then fn.qty_temp  
         else 0  
        end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.qty_temp else 0 end) as "quantity",  
       sum(  
        case  
         when fn.billstatus = 'return' and fn.paiddate is not null then fn.paidamount  
         when fn.billstatus != 'return' then fn.paidamount  
         else 0  
        end) - sum(case when fn.billstatus = 'return' and vw.paiddate is not null then fn.returnamount else 0 end) as "totalamount"  
      from "fn_bil_gettxnitemsinfowithdateseparation_mis_report"(p_fromdate, p_todate) fn  
      inner join bil_mst_servicedepartment sd on sd.servicedepartmentid = fn.servicedepartmentid  
      join "vw_bil_txnitemsinfowithdateseparation_mis_report" vw on fn.billingtransactionitemid = vw.billingtransactionitemid  
      where fn.billstatus != 'cancelled'  
       and fn.billstatus != 'provisional'  
       and fn.billstatus != 'credit'  
       --and (fn.paymentmode != 'credit' or fn.creditdate is not null)  
      group by fn.itemname,  
       sd.integrationname  
     ) as x  
     group by x.itemname  
     union all  
     select  
      'Earlier Return Amount' as "item name",  
      ' ' as " ",  
      -sum(sum.totalamount) as "total amount"  
     from (select  
      distinct  
      (ret.billreturnid),  
      ret.totalamount  
      from (select  
      br.createdon as "ret date",  
      bt.itemname,  
      bt.quantity as "unit",  
      bt.paiddate as "paiddate",  
      br.billreturnid as "billreturnid",  
      br.totalamount as "totalamount"  
     from bil_txn_invoicereturn br  
     inner join bil_txn_billingtransactionitems bt on br.billingtransactionid = bt.billingtransactionid  
     where (br.createdon)::date between p_fromdate and p_todate  
      and 1 = 2   
      and (bt.createdon)::date != (br.createdon)::date) ret) sum  
     union all  
     select  
      'Advance Received' as "itemname",  
      ' ',  
      coalesce(sum(amount), 0) as "total amount"  
     from bil_txn_deposit  
     where (createdon)::date between p_fromdate and p_todate  
      and deposittype = 'Deposit'  
     union all  
     select  
         'Advance Settled' as "itemname",  
      ' ',  
      coalesce(-sum(amount), 0)  
     from bil_txn_deposit  
     where (createdon)::date between p_fromdate and p_todate  
      and deposittype = 'depositdeduct'  
     union all  
     select  
      'Advance Returned' as "itemname",  
      ' ',  
      -coalesce(sum(amount), 0)  
     from bil_txn_deposit  
     where (createdon)::date between p_fromdate and p_todate  
      and deposittype = 'ReturnDeposit';
        return next ref10;  
      
     open ref11 for select   'Total' as type,sum(quantity) as quantity,  sum(totalamount-returnamount) as "totalamount"  
     from (   
              select  sum(inv.paidamount)as totalamount, sum(inv.totalquantity) as quantity ,0 as returnamount, sum(inv.discountamount) as discountamount  
                from "phrm_txn_invoice" inv         
                  where  (inv.createon)::date   between p_fromdate and p_todate   
      
         union all  
          
         select  0 as totalamount,sum(invret.quantity) as retquantity,sum(invret.totalamount ) as returnamount,  sum(-(invret.discountpercentage/100)*invret.subtotal ) as discountpercentage  
         from"phrm_txn_invoicereturnitems" invret  
           
         where (invret.createdon)::date  between p_fromdate and p_todate and invret.invoiceid is not null  
           
         )tabletotal;
        return next ref11;  
    end;
END;
$$ LANGUAGE plpgsql;