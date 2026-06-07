CREATE OR REPLACE FUNCTION sp_report_bill_patientbillhistory(
    p_fromdate TIMESTAMP DEFAULT NULL,
    p_todate TIMESTAMP DEFAULT NULL,
    p_patientcode VARCHAR DEFAULT NULL
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
BEGIN
    /*
    filename: "sp_report_bill_patientbillhistory"
    createdby/date: nagesh/2017-05-25
    description: to get the total of billed, unbilled, and returned along with the other data
    remarks:    needs lot of improvisation on this sp--sudarshan(29jul'17)
    Change History
    S.No.    UpdatedBy/Date                        Remarks
    1       nagesh/2017-05-25	                created the script
    2		ashim/2017-07-11					modified the script
    3		ashim/2017-07-28					modifications for bug fix
    											(ReceiptNo and ItemPrice,ItemName-ReturnedBill)
    4		ramavtar/2018-10-04					change parameter (replaced PatientId with PatientCode)
    5		ramavtar/2018-10-15					change in SP (corrected where clause in paid,unpaid.. change table in case of return taking from BIL_TXN_InvoiceReturn.. 
    											added require columns (remark, corrected receiptNo)
    6		Sanjeev/31st-May'23					change deposittype to transactiontype and change amount to inamount if transactiontype is 'Deposit', else change amount to outamount
    */
    begin
    
      if (p_fromdate is not null and p_todate is not null and p_patientcode is not null)
      then
    
        --paid bill history
        open ref1 for with paidbillhistory
        as (select
    		row_number() over (order by billingtransactionitemid) as srno,
    		srvdept.servicedepartmentname as "department",
    		itemname as item,
    		price as rate,
    		quantity,
    		transactionitem.subtotal as amount,
    		coalesce(transactionitem.discountamount, 0) as discount,
    		transactionitem.tax,
    		coalesce(transactionitem.totalamount, 0) as subtotal,
    		(transactionitem.paiddate)::date as "paiddate",
    		txn.invoiceno as receiptno
        from bil_txn_billingtransactionitems transactionitem
    	inner join bil_txn_billingtransaction txn on transactionitem.billingtransactionid = txn.billingtransactionid
        inner join bil_mst_servicedepartment srvdept on transactionitem.servicedepartmentid = srvdept.servicedepartmentid
        inner join pat_patient pat on transactionitem.patientid = pat.patientid
        where transactionitem.billstatus = 'paid' and pat.patientcode = p_patientcode 
    		and (transactionitem.paiddate)::date between p_fromdate and p_todate
    		and transactionitem.returnstatus is null)
        
    	select * from paidbillhistory order by (paiddate)::date desc;
        return next ref1;
    
        --unpaid bill history
        open ref2 for with unpaidbillhistory
        as (select
    		row_number() over (order by billingtransactionitemid) as srno,
    		srvdept.servicedepartmentname as "department",
    		itemname as item,
    		price as rate,
    		quantity,
    		transactionitem.subtotal as amount,
    		coalesce(transactionitem.discountamount, 0) as discount,
    		transactionitem.tax,
    		coalesce(transactionitem.totalamount, 0) as subtotal,
    		(transactionitem.requisitiondate)::date as "date",
    		txn.invoiceno as receiptno
        from bil_txn_billingtransactionitems transactionitem
    	inner join bil_txn_billingtransaction txn on transactionitem.billingtransactionid = txn.billingtransactionid
        inner join bil_mst_servicedepartment srvdept on transactionitem.servicedepartmentid = srvdept.servicedepartmentid
        inner join pat_patient pat on transactionitem.patientid = pat.patientid
        where transactionitem.billstatus = 'unpaid' and pat.patientcode = p_patientcode
    		and transactionitem.returnstatus is null
    		and (requisitiondate)::date between p_fromdate and p_todate)
        
    	select * from unpaidbillhistory order by ("date")::date desc;
        return next ref2;
    
        --returned bill history
        open ref3 for with returnedbillhistory
        as (select
    		row_number() over (order by billreturn.billreturnid) as srno,
    		srvdept.servicedepartmentname as department,
    		transactionitem.itemname as item,
    		transactionitem.price as rate,
    		transactionitem.quantity,
    		transactionitem.subtotal as amount,
    		billreturn.remarks as remarks,
    		coalesce(transactionitem.discountamount, 0) as discount,
    		transactionitem.tax,
    		coalesce(transactionitem.totalamount, 0) as returnedamount,
    		(billreturn.createdon)::date as "returndate",
    		txn.invoiceno as receiptno,
    		emp.firstname || coalesce(' ' || emp.middlename || ' ', ' ') || emp.lastname as returnedby
        from bil_txn_invoicereturn billreturn
    	inner join bil_txn_billingtransaction txn on billreturn.billingtransactionid = txn.billingtransactionid
    	inner join bil_txn_billingtransactionitems transactionitem on txn.billingtransactionid = transactionitem.billingtransactionid
        inner join bil_mst_servicedepartment srvdept on transactionitem.servicedepartmentid = srvdept.servicedepartmentid
        inner join emp_employee emp on billreturn.createdby = emp.employeeid
        inner join pat_patient pat on billreturn.patientid = pat.patientid
        where pat.patientcode = p_patientcode
    		and (billreturn.createdon)::date between p_fromdate and p_todate)
    
        select * from returnedbillhistory order by (returndate)::date desc;
        return next ref3;
    
        --deposit
        open ref4 for with deposithistory
        as (select
          row_number() over (order by depositid) as srno,
          (dep.createdon)::date as "date",
          transactiontype,
          case when transactiontype = 'Deposit' then inamount else outamount end as amount,
          remarks,
    	  receiptno
        from bil_txn_deposit dep
        inner join pat_patient pat on dep.patientid = pat.patientid
        where pat.patientcode = p_patientcode
    		and (dep.createdon)::date between p_fromdate and p_todate)
        
    	select * from deposithistory order by (date)::date desc;
        return next ref4;
    
        --cancel bill history
        open ref5 for with cancelbillhistory
        as (select
          row_number() over (order by billingtransactionitemid) as srno,
          srvdept.servicedepartmentname as "department",
          itemname as item,
          price as rate,
          quantity,
          cancelremarks as remarks,
          subtotal as amount,
          totalamount as cancelledamount,
          (cancelledon)::date as cancelleddate,
          emp.firstname || coalesce(' ' || emp.middlename || ' ', ' ') || emp.lastname as cancelledby,
          coalesce(discountamount, 0) as discount,
          tax,
          coalesce(totalamount, 0) as subtotal,
          (requisitiondate)::date as "date"
        from bil_txn_billingtransactionitems transactionitem
        inner join bil_mst_servicedepartment srvdept on transactionitem.servicedepartmentid = srvdept.servicedepartmentid
        inner join emp_employee emp on transactionitem.cancelledby = emp.employeeid
        inner join pat_patient pat on transactionitem.patientid = pat.patientid
        where billstatus = 'cancel' and pat.patientcode = p_patientcode
    		and (requisitiondate)::date between p_fromdate and p_todate)
        
    	select * from cancelbillhistory order by ("date")::date desc;
        return next ref5;
    
      
      elsif (p_fromdate is null and p_todate is null and p_patientcode is not null)
      then
    	    --paid bill history
        open ref6 for with paidbillhistory
        as (select
    		row_number() over (order by billingtransactionitemid) as srno,
    		srvdept.servicedepartmentname as "department",
    		itemname as item,
    		price as rate,
    		quantity,
    		transactionitem.subtotal as amount,
    		coalesce(transactionitem.discountamount, 0) as discount,
    		transactionitem.tax,
    		coalesce(transactionitem.totalamount, 0) as subtotal,
    		(transactionitem.paiddate)::date as "paiddate",
    		txn.invoiceno as receiptno
        from bil_txn_billingtransactionitems transactionitem
    	inner join bil_txn_billingtransaction txn on transactionitem.billingtransactionid = txn.billingtransactionid
        inner join bil_mst_servicedepartment srvdept on transactionitem.servicedepartmentid = srvdept.servicedepartmentid
        inner join pat_patient pat on transactionitem.patientid = pat.patientid
        where transactionitem.billstatus = 'paid' and pat.patientcode = p_patientcode
    		and transactionitem.returnstatus is null)
        
    	select * from paidbillhistory order by (paiddate)::date desc;
        return next ref6;
    
        --unpaid bill history
        open ref7 for with unpaidbillhistory
        as (select
    		row_number() over (order by billingtransactionitemid) as srno,
    		srvdept.servicedepartmentname as "department",
    		itemname as item,
    		price as rate,
    		quantity,
    		transactionitem.subtotal as amount,
    		coalesce(transactionitem.discountamount, 0) as discount,
    		transactionitem.tax,
    		coalesce(transactionitem.totalamount, 0) as subtotal,
    		(transactionitem.requisitiondate)::date as "date",
    		txn.invoiceno as receiptno
        from bil_txn_billingtransactionitems transactionitem
    	inner join bil_txn_billingtransaction txn on transactionitem.billingtransactionid = txn.billingtransactionid
        inner join bil_mst_servicedepartment srvdept on transactionitem.servicedepartmentid = srvdept.servicedepartmentid
        inner join pat_patient pat on transactionitem.patientid = pat.patientid
        where transactionitem.billstatus = 'unpaid' and pat.patientcode = p_patientcode
    		and transactionitem.returnstatus is null)
        
    	select * from unpaidbillhistory order by ("date")::date desc;
        return next ref7;
    
        --returned bill history
        open ref8 for with returnedbillhistory
        as (select
    		row_number() over (order by billreturn.billreturnid) as srno,
    		srvdept.servicedepartmentname as department,
    		transactionitem.itemname as item,
    		transactionitem.price as rate,
    		transactionitem.quantity,
    		transactionitem.subtotal as amount,
    		billreturn.remarks as remarks,
    		coalesce(transactionitem.discountamount, 0) as discount,
    		transactionitem.tax,
    		coalesce(transactionitem.totalamount, 0) as returnedamount,
    		(billreturn.createdon)::date as "returndate",
    		txn.invoiceno as receiptno,
    		emp.firstname || coalesce(' ' || emp.middlename || ' ', ' ') || emp.lastname as returnedby
        from bil_txn_invoicereturn billreturn
    	inner join bil_txn_billingtransaction txn on billreturn.billingtransactionid = txn.billingtransactionid
    	inner join bil_txn_billingtransactionitems transactionitem on txn.billingtransactionid = transactionitem.billingtransactionid
        inner join bil_mst_servicedepartment srvdept on transactionitem.servicedepartmentid = srvdept.servicedepartmentid
        inner join emp_employee emp on billreturn.createdby = emp.employeeid
        inner join pat_patient pat on billreturn.patientid = pat.patientid
        where pat.patientcode = p_patientcode)
    
        select * from returnedbillhistory order by (returndate)::date desc;
        return next ref8;
    
        --deposit
        open ref9 for with deposithistory
        as (select
          row_number() over (order by depositid) as srno,
          (dep.createdon)::date as "date",
          transactiontype,
          case when transactiontype = 'Deposit' then inamount else outamount end as amount,
          remarks,
    	  receiptno
        from bil_txn_deposit dep
        inner join pat_patient pat on dep.patientid = pat.patientid
        where pat.patientcode = p_patientcode)
        
    	select * from deposithistory order by (date)::date desc;
        return next ref9;
    
        --cancel bill history
        open ref10 for with cancelbillhistory
        as (select
          row_number() over (order by billingtransactionitemid) as srno,
          srvdept.servicedepartmentname as "department",
          itemname as item,
          price as rate,
          quantity,
          cancelremarks as remarks,
          subtotal as amount,
          totalamount as cancelledamount,
          (cancelledon)::date as cancelleddate,
          emp.firstname || coalesce(' ' || emp.middlename || ' ', ' ') || emp.lastname as cancelledby,
          coalesce(discountamount, 0) as discount,
          tax,
          coalesce(totalamount, 0) as subtotal,
          (requisitiondate)::date as "date"
        from bil_txn_billingtransactionitems transactionitem
        inner join bil_mst_servicedepartment srvdept on transactionitem.servicedepartmentid = srvdept.servicedepartmentid
        inner join emp_employee emp on transactionitem.cancelledby = emp.employeeid
        inner join pat_patient pat on transactionitem.patientid = pat.patientid
        where billstatus = 'cancel' and pat.patientcode = p_patientcode)
        
    	select * from cancelbillhistory order by ("date")::date desc;
        return next ref10;
    
      end if;
    end;
END;
$$ LANGUAGE plpgsql;