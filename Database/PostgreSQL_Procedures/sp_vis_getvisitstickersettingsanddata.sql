CREATE OR REPLACE FUNCTION sp_vis_getvisitstickersettingsanddata(
    p_patientvisitid INT DEFAULT NULL
)
RETURNS SETOF refcursor AS $$
DECLARE
    ref1 refcursor := 'cursor1';
    ref2 refcursor := 'cursor2';
    v_currentschemeid INT;
    v_visittype VARCHAR;
    v_stickergroupcode VARCHAR;
    v_stickername VARCHAR;
BEGIN
    /*  
    filename: sp_vis_getvisitstickersettingsanddata  
    createdby/date: sud:26mar'23
    Description: All fields values required for Sticker Print of OP/ER/IPD from CurrentVisit. 
               : Returns 2 tables.   1> StickerSettings for CurrentVisit/Scheme , 2> StickerData for CurrentVisit
    Logic Used:
         --To get Sticker Settings----
           > Get SchemeId and VisitType from Visit Table
    	   > Get StickerGroupCode from SchemeTable
    	   > Get StickerName and SettingsData from StickerSettings table
    	   > Remarks: Use Default if StickerGroupCode not found in Scheme Table
        --To Get StickerData--
    	  > Join Visit, Patient, AdmissionBedInfo, Scheme, Department etc tables to get necessary data
    	  > Remarks: For inpatient, get the 1st Bed where patient was admitted
    
    USAGE: EXEC SP_VIS_GetVisitStickerSettingsAndData 79818
    
    Change History  
    S.No.    UpdatedBy/Date                        Remarks  
    1.      Sud:26Mar'23                        initialdraft - rewrite after newstructure in visit/billing
    2.		krishna, 6thapril'23				Format PatientAddress
    3.		Devendra, 11thJuly'23				adding queueno setting
    4.		krishna, 15thjuly'23				Format PatientAddress to show Municipaliy and wardNumber
    */  
    BEGIN  
     
     
    
    
    SELECT vis.SchemeId, VisitType, sch.RegStickerGroupCode INTO v_currentschemeid, v_visittype, v_stickergroupcode FROM PAT_PatientVisits vis INNER JOIN BIL_CFG_Scheme sch on vis.SchemeId=sch.SchemeId
    where PatientVisitId=p_patientvisitid;
    
    IF(v_stickergroupcode IS NOT NULL)
    THEN
        v_stickername := (Select  StickerName from CFG_RegistrationStickerSettings 
                           Where COALESCE(VisitType,'outpatient')= v_visittype
    					          AND StickerGroupCode=v_stickergroupcode LIMIT 1);
    
    ELSE
    
     v_stickername := (Select  StickerName from CFG_RegistrationStickerSettings 
                           Where COALESCE(VisitType,'outpatient') = v_visittype
    					          AND IsDefaultForCurrentVisitType=1 LIMIT 1);
    END IF;
    
    
    
    --Return Table-1: StickerSettings----
    OPEN ref1 FOR Select 
         RegistrationStickerSettingsId,StickerName,StickerGroupCode,VisitType,IsDefaultForCurrentVisitType
    	,VisitDateLabel,ShowSchemeCode,ShowMemberNo,MemberNoLabel,ShowClaimCode,ShowIpdNumber,ShowWardBedNo
    	,ShowRegistrationCharge,ShowPatContactNo,ShowPatientDesignation,PatientDesignationLabel,ShowQueueNo,QueueNoLabel
    from CFG_RegistrationStickerSettings
    Where StickerName=v_stickername;
        RETURN NEXT ref1;
    
    
    --Return Table-2: StickerData----
    OPEN ref2 FOR Select 
    	vis.PatientId,
    	vis.PatientVisitId,
    	pat.PatientCode AS "HospitalNumber",
    	pat.ShortName AS "PatientName",
    	pat.Gender,
    	pat.DateOfBirth,
    	COALESCE(dist.CountrySubDivisionName,'') || COALESCE(', '||mun.MunicipalityName,'') || COALESCE('-'|| (pat.WardNumber)::VARCHAR,'') AS "PatientAddress",
    	pat.PhoneNumber AS "PatientPhoneNumber",
    	pat.Rank AS "PatientDesignation",
    
    	vis.VisitCode,
    	((vis.VisitDate)::Date)::TIMESTAMP + (vis.VisitTime)::TIMESTAMP AS "VisitDateTime",
    	Case WHEN vis.VisitType='outpatient' THEN 'opd'
    		 WHEN vis.VisitType='inpatient' THEN 'ipd'
    		 WHEN vis.VisitType='emergency' THEN 'er'
    		 ELSE '' end as "visittypeformatted",
    	vis.appointmenttype,
    	dep.departmentname,
    	vis.performername as "performername",
    	vis.ticketcharge,
    	wardbed.wardname,
    	wardbed.bednumber,
    	usr.username,
    	vis.claimcode,
    	sch.schemecode,
    	patsch.policyno as "memberno",
    	vis.queueno
    from pat_patientvisits vis
    inner join pat_patient pat on vis.patientid=pat.patientid
    inner join mst_department dep on vis.departmentid=dep.departmentid
    inner join bil_cfg_scheme sch on vis.schemeid=sch.schemeid
    inner join rbac_user usr on vis.createdby=usr.employeeid 
    left join mst_countrysubdivision dist on pat.countrysubdivisionid = dist.countrysubdivisionid
    left join mst_municipality mun on pat.municipalityid = mun.municipalityid
    left join ( select * from
    			(
    				select bedinfo.patientvisitid, w.wardname, b.bednumber,
    				row_number() over (partition by patientvisitid order by bedinfo.patientbedinfoid) as rownum
    				from adt_txn_patientbedinfo bedinfo
    				inner join adt_mst_ward w on bedinfo.wardid=w.wardid
    				inner join adt_bed b on bedinfo.bedid=b.bedid
    			)bedinfo1 where rownum=1) wardbed on vis.patientvisitid=wardbed.patientvisitid
    
    left join pat_map_patientschemes patsch on vis.schemeid=patsch.schemeid and vis.patientid=patsch.patientid
    
    where vis.patientvisitid=p_patientvisitid;
        return next ref2;
    
    end;
END;
$$ LANGUAGE plpgsql;