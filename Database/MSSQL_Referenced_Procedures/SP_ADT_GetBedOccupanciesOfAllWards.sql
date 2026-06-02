Create PROCEDURE [dbo].[SP_ADT_GetBedOccupanciesOfAllWards]
AS
/*
File: ADT_GetBedOccupanciesOfAllWards
Created: Sud:16Sep'21
Description: To get Occupied, Reserved and Vacant beds per Ward.
Remarks: This may give incorrect data because of IsActive-Checks in different tables.
       --Needs proper revision on this.. 

SN    User/Date              Remarks
1.    Sud/16Sep'21          Added Comments, Renamed from Last SP: ADT_BedFeature

 */
BEGIN
select x.WardName,x.WardId,x.Occupied,x.Vacant, x.Reserved, (x.Occupied + x.Vacant+ x.Reserved) AS Total  from 
(	
	select  y.WardID,y.WardName,
		 count( CASE When y.IsOccupied=1 and y.bdIA='true' and y.wIA='true' and y.bfIA='true' then 1 END) AS Occupied,
		 count( CASE When y.IsOccupied=0  and y.bdIA='true' and y.wIA='true' and y.bfIA='true' then 1 END) AS Vacant,
		 (0) AS Reserved
			
	from (
	select distinct bd.BedId,bd.BedCode, ward.WardID,bd.IsOccupied,ward.WardName,bd.IsActive as bdIA,ward.IsActive as wIA,bf.IsActive as bfIA from
	ADT_Bed bd		 
	 inner join	ADT_MAP_BedFeaturesMap Map ON Map.BedId = bd.BedID
	 inner join ADT_MST_Ward ward on ward.WardID = Map.WardId 	
	 inner join ADT_MST_BedFeature bf on map.BedFeatureId=bf.BedFeatureId
	 where ward.IsActive=1
	) as y group by WardName,WardID
	
	
	) as x	
 order by X.WardName
END