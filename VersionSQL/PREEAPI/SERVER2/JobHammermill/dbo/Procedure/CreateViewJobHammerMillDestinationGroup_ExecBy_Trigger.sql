/****** Object:  Procedure [dbo].[CreateViewJobHammerMillDestinationGroup_ExecBy_Trigger]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CreateViewJobHammerMillDestinationGroup_ExecBy_Trigger]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	--------------- START - Cursor: CreateViewJobHammerMillDestinationGroup ---------------

	-- Declare Variable for Cursor
	DECLARE @TableDestinationBin NVARCHAR(100) ;

	DECLARE cursor_@CreateViewJobHammerMillDestinationGroup CURSOR FOR
		SELECT [TableDestinationBin] FROM [JobHammermill].[dbo].[ConfigJobHammerMillDestinationGroup] ;
	
	-- Open Cursor
	OPEN cursor_@CreateViewJobHammerMillDestinationGroup ;
	FETCH NEXT FROM cursor_@CreateViewJobHammerMillDestinationGroup
	INTO @TableDestinationBin ;

	DECLARE @cmdSQL NVARCHAR(MAX) ;
	DECLARE @i INT = 0 ;

	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			---------- Create: SQL command to Select all SourceBin Table from ConfigJobTransferSourceGroup ----------
			IF (@i = 0)
				BEGIN
					SET @cmdSQL = 'SELECT  [BinIO]
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
								   FROM [MasterSmartFeed].[dbo].' + @TableDestinationBin ;					
				END

			ELSE IF (@i >= 1)
				BEGIN
					SET @cmdSQL = @cmdSQL + ' UNION SELECT [BinIO]
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
											  FROM [MasterSmartFeed].[dbo].' + @TableDestinationBin ;					
				END

			--Reset @Variable, #TempTable before Fetch Next
			SET @i = @i + 1 ;

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@CreateViewJobHammerMillDestinationGroup
			INTO @TableDestinationBin ;
		END

	--Close Cursor
	CLOSE cursor_@CreateViewJobHammerMillDestinationGroup ;
	DEALLOCATE cursor_@CreateViewJobHammerMillDestinationGroup ;

	--------------- END - Cursor: CreateViewJobTransferDestinationGroup ---------------

	--------------- Drop: View_JobTransferSourceGroup ของเดิมที่มีอยู่ ---------------
	DROP VIEW IF EXISTS [dbo].[View_JobHammerMillDestinationGroup]

	--------------- Create: View_JobTransferSourceGroup ของใหม่ ---------------
	DECLARE @cmdCreateView NVARCHAR(MAX) = 'CREATE VIEW View_JobHammerMillDestinationGroup AS ' + @cmdSQL 
	EXEC SP_EXECUTESQL @cmdCreateView
END
