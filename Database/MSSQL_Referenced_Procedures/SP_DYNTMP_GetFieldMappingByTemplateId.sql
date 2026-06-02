CREATE PROCEDURE [dbo].[SP_DYNTMP_GetFieldMappingByTemplateId]
   @TemplateId INT 
AS
/*
FileName: EXEC SP_DYNTMP_GetFieldMappingByTemplateId <TemplateId> 
CreatedBy/date: Bikesh:22Aug2023  
Usage Eg: SP_DYNTMP_GetFieldMappingByTemplateId
Description: 
   To get the Field Mappings of the current template.
Remarks:    
   > Mapping logic is dependent on the IsCompulsoryField (column) of the FieldMaster Table.
   > All Fields on the current template type should be shown regardless of whether they are present in mapping or not (managed by using Left join)
Change History
S.No.    UpdatedBy/Date								Remarks
1        Bikesh:22Aug2023							Initial Draft
2		 Bikesh/Krishna, 24thSept'23				Convert numeric 1 & 0 into bit(boolean) value
*/
BEGIN
    SELECT 
        fm.FieldMasterId,
        fm.FieldName,
        temp.TemplateId,
        temp.TemplateName,
        IsCompulsoryField = fm.IsCompulsoryField,
        CASE 
            WHEN fm.IsCompulsoryField = 1 THEN CONVERT(BIT,1)
            ELSE CASE WHEN tfm.IsMandatory IS NOT NULL THEN tfm.IsMandatory ELSE CONVERT(BIT,0) END
        END AS 'IsMandatory',
        CASE 
            WHEN fm.IsCompulsoryField = 1 THEN CONVERT(BIT,1)
            ELSE CASE WHEN tfm.IsActive IS NOT NULL THEN tfm.IsActive ELSE CONVERT(BIT,0) END
        END AS 'IsActive',
        EnterSequence = tfm.EnterSequence,
        DisplayLabel = tfm.DisplayLabel
    FROM DYNTEMP_CFG_Template AS temp
    JOIN DYNTMP_MST_FieldMaster AS fm ON temp.TemplateTypeId = fm.TemplateTypeId
    LEFT JOIN DYNTMP_MAP_TemplateFieldMapping AS tfm
        ON temp.TemplateId = tfm.TemplateId AND fm.FieldMasterId = tfm.FieldMasterId
    WHERE temp.TemplateId = @TemplateId AND fm.IsActive = 1;
END;