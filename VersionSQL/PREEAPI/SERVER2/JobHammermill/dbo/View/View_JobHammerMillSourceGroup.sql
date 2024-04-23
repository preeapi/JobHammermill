/****** Object:  View [dbo].[View_JobHammerMillSourceGroup]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE VIEW [View_JobHammerMillSourceGroup] AS SELECT  [BinIO]
										  ,[BinType]
										  ,[IngredientCode]
										  ,[Density]
										  ,[Volume]
										  ,[Weight]
										  ,[ActiveFilling]
										  ,[ActiveDischarge]
										  ,[BinUse]
										  ,[HighBin]
										  ,[BinPriority]
										  ,[FillingTime]
										  ,[LastTimeDischarge]
										  ,[LastFillingLot]
								   FROM [MasterSmartFeed].[dbo].BinIdentPreGrinding
