CREATE PROCEDURE [dbo].[sp_BedInformation]

AS
BEGIN
SELECT * FROM 
	(SELECT COUNT(distinct b.BedID) Total FROM ADT_Bed b 
	 inner join	ADT_MAP_BedFeaturesMap Map ON Map.BedId = b.BedID and b.IsActive='true'
	 inner join ADT_MST_Ward ward on ward.WardID = Map.WardId and ward.IsActive='true'
	 inner join ADT_MST_BedFeature bf on map.BedFeatureId=bf.BedFeatureId and bf.IsActive='true') AS Total,
	(SELECT COUNT( distinct b.BedID) Available FROM ADT_Bed b
	 inner join	ADT_MAP_BedFeaturesMap Map ON Map.BedId = b.BedID and b.IsActive='true'
	 inner join ADT_MST_Ward ward on ward.WardID = Map.WardId and ward.IsActive='true'
	 inner join ADT_MST_BedFeature bf on map.BedFeatureId=bf.BedFeatureId and bf.IsActive='true' and b.IsOccupied = 'false') AS Available,
	(SELECT COUNT( distinct b.BedID) Occupied FROM ADT_Bed b 
	 inner join	ADT_MAP_BedFeaturesMap Map ON Map.BedId = b.BedID and b.IsActive='true'
	 inner join ADT_MST_Ward ward on ward.WardID = Map.WardId and ward.IsActive='true'
	 inner join ADT_MST_BedFeature bf on map.BedFeatureId=bf.BedFeatureId and bf.IsActive='true' and b.IsOccupied = 'true') AS Occupied

SELECT B.BedNumber,F.BedFeatureName,F.BedPrice,B.IsOccupied,W.WardName FROM ADT_Bed B 
INNER JOIN
ADT_MST_Ward W ON B.WardId = W.WardID and W.IsActive='true'
INNER JOIN
ADT_MAP_BedFeaturesMap Map ON Map.BedId = B.BedID
INNER JOIN
ADT_MST_BedFeature F ON F.BedFeatureId = Map.BedFeatureId

END