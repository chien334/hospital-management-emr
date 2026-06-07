CREATE OR REPLACE FUNCTION sp_report_bill_patientcensus(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_performerid INT DEFAULT NULL,
    p_departmentid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
BEGIN
    /*  
    change history  
    s.no.    updatedby/date     remarks  
    1  ramavtar/03aug'18   created the script  
    2  Ramavtar/9Aug'18  getting summary of deposit, and deposit-return (as table 3),  
            excluding entry where billstatus == cancel and for return items we are not including its amount in totalcollection  
    3.      sud  --     updated after creating common function.   
    4.      dinesh /14thsep'18      grouped and  merged the labcharges and miscellaneous to the respective single view header   
    5.  ramavtar/05Oct'18  getting provider name from employee table instead of txn table  
    6.  ramavtar/03dec'18  revamp of SP -> as per new requirement  
    7.  ramavtar/05Dec'18  filter more case of paid/credit bills  
    8.  ramavtar/13dec'18  taking quantity  
    9.      Dinesh/05th_Feb'19      doctor department department included in report to segregate doctors according to department  
    10.     dev/24th_jan'22         Change NoDoctor to Unassgined in case no doctor is selected
    11.		Krishna/9thJun'22		changed providerid to performerid and providername to performername
    */  
      
     open ref1 for select   
      tbl.performer,  
      tbl.servicedepartmentname,  
      tbl.totc1,  
      tbl.retc1,  
      tbl.tota1,  
      tbl.reta1,  
      tbl.totc2,  
      tbl.tota2,  
      tbl.totc3,  
      tbl.retc3,  
      tbl.tota3,  
      tbl.reta3,  
      (tbl.totc1 - tbl.retc1) + (tbl.totc3 - tbl.retc3) as "tottc",  
      (tbl.tota1 - tbl.reta1) + (tbl.tota3 - tbl.reta3) as "totta"   
     from (  
     select   
      coalesce(fn.performername,'Unassigned') as "performer",  
      fn.servicedepartmentname,  
      sum(case  
        when fn.billstatus = 'paid' and vm.provisionaldate is null and (fn.paymentmode != 'credit' or fn.creditdate is not null) then fn.quantity  
        when fn.billstatus = 'credit' and vm.provisionaldate is null then fn.quantity  
        when fn.billstatus = 'return' and vm.provisionaldate is null and ((fn.paymentmode = 'credit' and fn.creditdate is not null) or (fn.paymentmode != 'credit' and fn.paiddate is not null)) then fn.quantity  
        else 0  
       end) as "totc1",  
      sum(case  
        when fn.billstatus = 'return' and vm.provisionaldate is null then fn.quantity else 0  
       end) as "retc1",  
      sum(case   
        when vm.provisionaldate is null and fn.billstatus = 'paid' and (fn.paymentmode != 'credit' or fn.creditdate is not null) then fn.paidamount  
        when vm.provisionaldate is null and fn.billstatus = 'credit' then fn.creditamount  
        when vm.provisionaldate is null and fn.billstatus = 'return' and ((fn.paymentmode = 'credit' and fn.creditdate is not null) or (fn.paymentmode != 'credit' and fn.paiddate is not null)) then fn.returnamount  
        else 0  
       end) as "tota1",  
      sum(case  
        when fn.billstatus = 'return' and vm.provisionaldate is null then fn.returnamount  
        else 0  
       end) as "reta1",  
      sum(case  
        when fn.billstatus = 'provisional' then fn.quantity  
        else 0  
       end) as "totc2",  
      sum(case   
        when fn.billstatus = 'provisional' then fn.provisionalamount   
        else 0   
       end) as "tota2",  
      sum(case   
        when fn.billstatus = 'credit' and vm.provisionaldate is not null then fn.quantity  
        when fn.billstatus = 'paid' and vm.provisionaldate is not null and (fn.paymentmode != 'credit' or fn.creditdate is not null) then fn.quantity  
        when fn.billstatus = 'return' and vm.provisionaldate is not null and ((fn.paymentmode = 'credit' and fn.creditdate is not null) or (fn.paymentmode != 'credit' and fn.paiddate is not null))  then fn.quantity  
        else 0  
       end) as "totc3",  
      sum(case  
        when fn.billstatus = 'return' and vm.provisionaldate is not null  
        then fn.quantity else 0   
       end) as "retc3",  
      sum(case  
        when fn.billstatus = 'paid' and vm.provisionaldate is not null and (fn.paymentmode != 'credit' or fn.creditdate is not null) then fn.paidamount  
        when fn.billstatus = 'credit' and vm.provisionaldate is not null then fn.creditamount  
        when fn.billstatus = 'return' and vm.provisionaldate is not null and ((fn.paymentmode = 'credit' and fn.creditdate is not null) or (fn.paymentmode != 'credit' and fn.paiddate is not null)) then fn.returnamount  
        else 0  
       end) as "tota3",  
      sum(case  
        when fn.billstatus = 'return' and vm.provisionaldate is not null then fn.returnamount  
        else 0  
       end) as "reta3"  
      --,  
      --sum(case  
      --  when fn.billstatus = 'paid' or fn.billstatus = 'credit' then 1 else 0   
      -- end) as "tottc",  
      --sum(case   
      --  when fn.billstatus = 'paid' then fn.paidamount  
      --  when fn.billstatus = 'credit' then fn.creditamount  
      --  else 0  
      -- end) as "totta"  
     from fn_bil_gettxnitemsinfowithdateseparation_patientcensus(p_fromdate,p_todate) fn  
     join vw_bil_txnitemsinfowithdateseparation vm on fn.billingtransactionitemid = vm.billingtransactionitemid  
     where coalesce(p_performerid,coalesce(fn.performerid,0)) = coalesce(fn.performerid,0)  
     and coalesce(p_departmentid,coalesce(fn.departmentid,0))= coalesce(fn.departmentid,0)  
     group by fn.performername,fn.servicedepartmentname,fn.departmentid  
     --order by 1,2  
     ) tbl  
     order by tbl.performer,tbl.servicedepartmentname;
        return next ref1;  
      
    open ref2 for select distinct dep.advancereceived,dep.advancesettled,prov.provisional,prov.unpaid   
    from   
    (  
     select  
      sum(coalesce(advancereceived, 0)) as "advancereceived",  
      sum(coalesce(advancesettled, 0)) as "advancesettled"  
     from "fn_bil_getdepositnprovisionalbetndaterange" (p_fromdate, p_todate)  
    ) dep,  
    (  
       select sum(provisionalamount-cancelledamount) as "provisional",  
           sum(creditamount) as "unpaid"  
        from  "fn_bil_gettxnitemsinfowithdateseparation_patientcensus"(p_fromdate, p_todate)  
    )prov;
        return next ref2;
END;
$$ LANGUAGE plpgsql;