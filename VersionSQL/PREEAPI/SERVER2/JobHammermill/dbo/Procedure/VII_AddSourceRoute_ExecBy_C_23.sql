/****** Object:  Procedure [dbo].[VII_AddSourceRoute_ExecBy_C#]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[VII_AddSourceRoute_ExecBy_C#]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	---------- Add Route to Source : AddSourceRoute ให้กับถังต้นทางที่เราได้เลือกมา ----------
	----- START - Cursor:AddSourceRoute -----
	-- Declare Variable for Cursor
	DECLARE @SequenceID INT
	DECLARE @LineCodeName NVARCHAR(20)
	DECLARE @Source1 INT
	DECLARE @Source2 INT

	DECLARE cursor_@AddSourceRoute CURSOR FOR
		SELECT [SequenceID], [LineCodeName], [Source1], [Source2]
		FROM [JobHammermill].[dbo].[JobSequenceHammerMill]
		WHERE [Source1] <> 0 AND [LineCodeName] <> '0'

	-- Open Cursor
	OPEN cursor_@AddSourceRoute
	FETCH NEXT FROM cursor_@AddSourceRoute
	INTO @SequenceID, @LineCodeName, @Source1, @Source2
	
	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			--เลือก SourceRoute ให้กับ Source 1-2 ของแต่ละ Job โดยจะเลือก Route ที่ว่างให้ก่อน ถ้าไม่มี Route ที่ว่าง จะเลือก MainRoute ให้
			CREATE TABLE #ResultSourceRoute
			(
				RowID INT IDENTITY (1, 1),
				SourceRoute INT,
			)

			CREATE TABLE #tempSourceBin
			(
				RowID INT IDENTITY (1, 1),
				SourceBin INT
			)
			INSERT INTO #tempSourceBin (SourceBin) VALUES (@Source1)
			INSERT INTO #tempSourceBin (SourceBin) VALUES (@Source2)

			DECLARE @i INT = 1 ;

			WHILE (@i <= 2)
				BEGIN
					--ประกาศตัวแปรที่ใช้ใน While DECLARE
					DECLARE @SourceBin INT = (SELECT [SourceBin] FROM #tempSourceBin WHERE [RowID] = @i) ;
					DECLARE @SourceRoute INT ;

					--ถ้าไม่มีการกำหนดถังปลายทาง จะไม่ทำการเลือก Route ให้
					IF (@SourceBin = 0)
						BEGIN
							INSERT INTO #ResultSourceRoute ([SourceRoute])
							VALUES (0)
						END
					--ถ้ามีถังปลายทางเข้ามาจะทำการเลือก Route ให้โดยจะเลือก Route ที่ว่างให้ก่อน ถ้าไม่มี Route ที่ว่าง จะเลือก MainRoute ให้
					ELSE
						BEGIN
							--ตรวจสอบ Route ที่เป็นไปได้ทั้งหมด ที่ได้ทำการ Active ใช้งานไว้
							;WITH CheckAvailibleSourceRoute AS
							(
								SELECT [SourceRoute], [SourceMainRoute]
								FROM [MasterSmartFeed].[dbo].[SourceSetup]
								WHERE [LineCodeName] = @LineCodeName AND [BinIO] = @SourceBin AND [SourceRouteActive] = 1
							),
							--ตรวจสอบ Route ที่กำลังถูกใช้งานอยู่ ณ ขณะนั้น
							CheckActiveSoucreRoute AS
							(
								SELECT [SourceRoute]
								FROM [MasterSmartFeed].[dbo].[LineActiveJob]
								WHERE [SourceRoute] <> 0
							),
							--เลือก Route ที่ว่างให้กับถังต้นทาง
							SelecteSourceRoute AS
							(
								SELECT [SourceRoute], [SourceMainRoute]
								FROM CheckAvailibleSourceRoute
								WHERE [SourceRoute] NOT IN (SELECT [SourceRoute] FROM CheckActiveSoucreRoute)
							)
							SELECT TOP(1) [SourceRoute] INTO #SelecteSourcenRoute FROM SelecteSourceRoute ORDER BY [SourceMainRoute] DESC ;

							SELECT @SourceRoute = [SourceRoute] FROM #SelecteSourcenRoute

							--ถ้าไม่มี Route ที่ว่างจะทำการเลือก MainRoute ไว้ให้
							IF NOT EXISTS (SELECT * FROM #SelecteSourcenRoute)
								SELECT @SourceRoute = [SourceRoute]
								FROM [MasterSmartFeed].[dbo].[SourceSetup]
								WHERE [LineCodeName] = @LineCodeName AND [BinIO] = @SourceBin AND 
									  [SourceRouteActive] = 1 AND [SourceMainRoute] = 1 ;

							INSERT INTO #ResultSourceRoute ([SourceRoute])
							VALUES	(@SourceRoute)
						END
		
						--Set or Reset @Variable, #TempTable for Next While Loop
						SET @i = @i + 1

						DROP TABLE IF EXISTS #SelecteSourcenRoute ;
				END
			
			--อัพเดท SourceRoute และ DestinationRoute ในแต่ละ SequenceID
			DECLARE @SourceRoute1 INT = (SELECT [SourceRoute] FROM #ResultSourceRoute WHERE [RowID] = 1)
			DECLARE @SourceRoute2 INT = (SELECT [SourceRoute] FROM #ResultSourceRoute WHERE [RowID] = 2)

			UPDATE [JobHammermill].[dbo].[JobSequenceHammerMill]
			SET [SourceRoute1] = COALESCE(@SourceRoute1, 0),
				[SourceRoute2] = COALESCE(@SourceRoute2, 0)
			WHERE [SequenceID] = @SequenceID
			
			--Reset @Variable, #TempTable before Fetch Next
			DROP TABLE IF EXISTS #ResultSourceRoute ;
			DROP TABLE IF EXISTS #tempSourceBin ;

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@AddSourceRoute
			INTO @SequenceID, @LineCodeName, @Source1, @Source2 ;
		END

	--Close Cursor
	CLOSE cursor_@AddSourceRoute ;
	DEALLOCATE cursor_@AddSourceRoute ;

	----- END - Cursor:AddSourceRoute -----
END
