/****** Object:  Procedure [dbo].[CreateViewJobHammerMillSourceGroup_ExecBy_Trigger]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[CreateViewJobHammerMillSourceGroup_ExecBy_Trigger]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- Declare Variable for Cursor
	DECLARE @TableSourceBin NVARCHAR(100) ;

	DECLARE cursor_@CreateViewJobHammerMillSourceGroup CURSOR FOR
		SELECT [TableSourceBin] FROM [JobHammermill].[dbo].[ConfigJobHammerMillSourceGroup] ;
	
	-- Open Cursor
	OPEN cursor_@CreateViewJobHammerMillSourceGroup ;
	FETCH NEXT FROM cursor_@CreateViewJobHammerMillSourceGroup
	INTO @TableSourceBin ;

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
								   FROM [MasterSmartFeed].[dbo].' + @TableSourceBin ;
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
											  FROM [MasterSmartFeed].[dbo].' + @TableSourceBin ;
				END

			--Reset @Variable, #TempTable before Fetch Next
			SET @i = @i + 1 ;

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@CreateViewJobHammerMillSourceGroup
			INTO @TableSourceBin ;
		END

	--Close Cursor
	CLOSE cursor_@CreateViewJobHammerMillSourceGroup ;
	DEALLOCATE cursor_@CreateViewJobHammerMillSourceGroup ;

	--------------- END - Cursor: CreateViewJobTransferSourceGroup ---------------

	--------------- Drop: View_JobTransferSourceGroup ของเดิมที่มีอยู่ ---------------
	DROP VIEW IF EXISTS  dbo.[View_JobHammerMillSourceGroup]

	--------------- Create: View_JobTransferSourceGroup ของใหม่ ---------------
	DECLARE @cmdCreateView NVARCHAR(MAX) = 'CREATE VIEW View_JobHammerMillSourceGroup AS ' + @cmdSQL 
	EXEC SP_EXECUTESQL @cmdCreateView
END
