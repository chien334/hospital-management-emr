CREATE OR REPLACE FUNCTION sp_lab_testcount_governmentreport(
    p_fromdate DATE DEFAULT NULL,
    p_todate DATE DEFAULT NULL
)
RETURNS TABLE (
    "SerialNumber" VARCHAR,
    "GroupName" VARCHAR,
    "TestName" VARCHAR,
    "DisplayName" VARCHAR,
    "HasInnerItems" BOOLEAN,
    "InnerTestGroupName" VARCHAR,
    "Total" DECIMAL
) AS $$
BEGIN
    /*
    -- =============================================
    -- author:    	<anish bhattarai>
    -- create date: <27 august 2020>
    -- description:	<get the count of each test of government lab report>
    -- =============================================
    change log:
    s.n.		name/date							remarks
    1.			anish/27aug,20						initial draft		
    2.			krishna/rusha / 08dec,22			add isactive true to get data 
    */
    
    
       RETURN QUERY SELECT
        masterdata.serialnumber,
        masterdata.groupname,
        masterdata.testname,
        masterdata.displayname,
        masterdata.hasinneritems,
        masterdata.innertestgroupname,
        count(*) AS "Total"
      from (select
        labitemid,
        iscomponentbased,
        positiveindicator,
        isresultcount,
        serialnumber,
        testname,
        groupname,
        displayname,
        hasinneritems,
        innertestgroupname
      from lab_gov_report_mapping map
      join lab_mst_gov_report_items item
        on map.reportitemid = item.reportitemid
      where map.iscomponentbased = 0
      and item.isactive = 1 and map.isactive = 1) masterdata
      join lab_testrequisition req
        on req.labtestid = masterdata.labitemid
      where req.isactive = 1
      and (req.orderdatetime)::date between (p_fromdate)::date and (p_todate)::date
      and (req.billingstatus not in ('returned', 'cancel'))
      group by masterdata.serialnumber,
               masterdata.testname,
    		   masterdata.labitemid,
               masterdata.groupname,
               masterdata.displayname,
               masterdata.hasinneritems,
               masterdata.innertestgroupname
       
      union
      (select
        masterdata.serialnumber,
        masterdata.groupname,
        masterdata.testname,
        masterdata.displayname,
        masterdata.hasinneritems,
        masterdata.innertestgroupname,
        count(*) AS "Total"
      from (select
        labitemid,
        iscomponentbased,
        positiveindicator,
        isresultcount,
        serialnumber,
        testname,
        groupname,
        displayname,
        hasinneritems,
        innertestgroupname,
        componentid,
        reportmapid,
        map.reportitemid
      from lab_gov_report_mapping map
      join lab_mst_gov_report_items item
        on map.reportitemid = item.reportitemid
      where map.iscomponentbased = 1
      and item.isactive = 1 and map.isactive = 1
      and map.isresultcount = 1) masterdata
      join (select
        res.requisitionid,
        res.componentname,
        res."value",
        res.labtestid,
    	res.componentid
      from lab_txn_testcomponentresult res
      join lab_testrequisition req
        on res.requisitionid = req.requisitionid
      where res.isactive = 1 and req.isactive = 1
      and (req.orderdatetime)::date between (p_fromdate)::date and (p_todate)::date
      and req.billingstatus not in ('returned', 'cancel')) labdata
        on (labdata.componentid = masterdata.componentid and labdata.labtestid = masterdata.labitemid)
    	and ltrim(rtrim((lower(labdata."value")))) = ltrim(rtrim((lower(masterdata.positiveindicator))))
      group by masterdata.serialnumber,
               masterdata.testname,
    		   masterdata.labitemid,
               masterdata.groupname,
               masterdata.displayname,
               masterdata.hasinneritems,
               masterdata.innertestgroupname
      )
      union
      (select
        masterdata.serialnumber,
        masterdata.groupname,
        masterdata.testname,
        masterdata.displayname,
        masterdata.hasinneritems,
        masterdata.innertestgroupname,
        count(*) AS "Total"
      from (select
        labitemid,
        iscomponentbased,
        positiveindicator,
        isresultcount,
        serialnumber,
        testname,
        groupname,
        displayname,
        hasinneritems,
        innertestgroupname,
        componentid
      from lab_gov_report_mapping map
      join lab_mst_gov_report_items item
        on map.reportitemid = item.reportitemid
      where map.iscomponentbased = 1
      and item.isactive = 1 and map.isactive = 1
      and map.isresultcount = 0) masterdata
      join (select
        res.requisitionid,
        res.componentname,
        res.value,
        res.labtestid,
    	res.componentid
      from lab_txn_testcomponentresult res
      join lab_testrequisition req
        on res.requisitionid = req.requisitionid
      where res.isactive = 1
      and (req.orderdatetime)::date between (p_fromdate)::date and (p_todate)::date
      and req.billingstatus not in ('returned', 'cancel')) labdata
        on labdata.componentid = masterdata.componentid
      group by masterdata.serialnumber,
               masterdata.testname,
    		   masterdata.labitemid,
               masterdata.groupname,
               masterdata.displayname,
               masterdata.hasinneritems,
               masterdata.innertestgroupname
      );
END;
$$ LANGUAGE plpgsql;