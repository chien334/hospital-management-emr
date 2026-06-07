CREATE OR REPLACE FUNCTION sp_dyntmp_getfieldmappingbytemplateid(
    p_templateid INT
)
RETURNS TABLE (
    "FieldMasterId" INT,
    "FieldName" VARCHAR,
    "TemplateId" INT,
    "TemplateName" VARCHAR,
    "IsCompulsoryField" BOOLEAN,
    "IsMandatory" BOOLEAN,
    "IsActive" BOOLEAN,
    "EnterSequence" VARCHAR,
    "DisplayLabel" VARCHAR
) AS $$
BEGIN
    /*
    filename: exec sp_dyntmp_getfieldmappingbytemplateid <templateid> 
    createdby/date: bikesh:22aug2023  
    usage eg: sp_dyntmp_getfieldmappingbytemplateid
    description: 
       to get the field mappings of the current template.
    remarks:    
       > mapping logic is dependent on the iscompulsoryfield (column) of the fieldmaster table.
       > all fields on the current template type should be shown regardless of whether they are present in mapping or not (managed by using left join)
    change history
    s.no.    updatedby/date								remarks
    1        bikesh:22aug2023							initial draft
    2		 bikesh/krishna, 24thsept'23				convert numeric 1 & 0 into boolean(boolean) value
    */
    begin
        RETURN QUERY SELECT 
            fm.fieldmasterid,
            fm.fieldname,
            temp.templateid,
            temp.templatename,
            iscompulsoryfield = fm.iscompulsoryfield,
            case 
                when fm.iscompulsoryfield = 1 then (1)::boolean
                else case when tfm.ismandatory is not null then tfm.ismandatory else (0)::boolean end
            end AS "IsMandatory",
            case 
                when fm.iscompulsoryfield = 1 then (1)::boolean
                else case when tfm.isactive is not null then tfm.isactive else (0)::boolean end
            end AS "IsActive",
            entersequence = tfm.entersequence,
            displaylabel = tfm.displaylabel
        from dyntemp_cfg_template as temp
        join dyntmp_mst_fieldmaster as fm on temp.templatetypeid = fm.templatetypeid
        left join dyntmp_map_templatefieldmapping as tfm
            on temp.templateid = tfm.templateid and fm.fieldmasterid = tfm.fieldmasterid
        where temp.templateid = p_templateid and fm.isactive = 1;
    end;
END;
$$ LANGUAGE plpgsql;