/****** Object:  Procedure [dbo].[VI_AddDestinationRoute_ExecBy_C#]    Committed by VersionSQL https://www.versionsql.com ******/

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[VI_AddDestinationRoute_ExecBy_C#]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	---------- Add Route to Destination : AddDestinationRoute ให้กับถังปลายทางที่เราได้เลือกมา ----------
	----- START - Cursor:AddDestinationRoute -----
	-- Declare Variable for Cursor
	DECLARE @SequenceID INT
	DECLARE @LineCodeName NVARCHAR(20)
	DECLARE @Destination1 INT
	DECLARE @Destination2 INT
	DECLARE @Destination3 INT
	DECLARE @Destination4 INT

	DECLARE cursor_@AddDestinationRoute CURSOR FOR
		SELECT [SequenceID], [LineCodeName], [Destination1], [Destination2], [Destination3], [Destination4]
		FROM [JobHammermill].[dbo].[JobSequenceHammerMill]
		WHERE [Destination1] <> 0 AND [LineCodeName] <> '0'

	-- Open Cursor
	OPEN cursor_@AddDestinationRoute
	FETCH NEXT FROM cursor_@AddDestinationRoute
	INTO @SequenceID, @LineCodeName, @Destination1, @Destination2, @Destination3, @Destination4
	
	-- Loop From Cursor
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
			--เลือก DestinationRoute ให้กับ Destination 1-4 ของแต่ละ Job โดยจะเลือก Route ที่ว่างให้ก่อน ถ้าไม่มี Route ที่ว่าง จะเลือก MainRoute ให้
			CREATE TABLE #ResultDestinationRoute
			(
				RowID INT IDENTITY (1, 1),
				DestinationRoute INT,
			)

			CREATE TABLE #tempDestinationBin
			(
				RowID INT IDENTITY (1, 1),
				Destination INT
			)
			INSERT INTO #tempDestinationBin (Destination) VALUES (@Destination1)
			INSERT INTO #tempDestinationBin (Destination) VALUES (@Destination2)
			INSERT INTO #tempDestinationBin (Destination) VALUES (@Destination3)
			INSERT INTO #tempDestinationBin (Destination) VALUES (@Destination4)

			DECLARE @i INT = 1 ;

			WHILE (@i <= 4 )
				BEGIN
					--ประกาศตัวแปรที่ใช้ใน While Loop
					DECLARE @DestinationBin INT = (SELECT [Destination] FROM #tempDestinationBin WHERE [RowID] = @i) ;
					DECLARE @DestinationRoute INT ;

					--ถ้าไม่มีการกำหนดถังปลายทาง จะไม่ทำการเลือก Route ให้
					IF (@DestinationBin = 0)
						BEGIN
							INSERT INTO #ResultDestinationRoute ([DestinationRoute])
							VALUES (0)
						END
					--ถ้ามีถังปลายทางเข้ามาจะทำการเลือก Route ให้โดยจะเลือก Route ที่ว่างให้ก่อน ถ้าไม่มี Route ที่ว่าง จะเลือก MainRoute ให้
					ELSE
						BEGIN
							--ตรวจสอบ Route ที่เป็นไปได้ทั้งหมด ที่ได้ทำการ Active ใช้งานไว้
							;WITH CheckAvailibleDestinationRoute AS
							(
								SELECT [DestinationRoute], [DestinationMainRoute]
								FROM [MasterSmartFeed].[dbo].[DestinationSetup]
								WHERE [LineCodeName] = @LineCodeName AND [BinIO] = @DestinationBin AND [DestinationRouteActive] = 1
							),
							--ตรวจสอบ Route ที่กำลังถูกใช้งานอยู่ ณ ขณะนั้น
							CheckActiveDestinaitonRoute AS
							(
								SELECT [DestinationRoute]
								FROM [MasterSmartFeed].[dbo].[LineActiveJob]
								WHERE [DestinationRoute] <> 0
							),
							--เลือก Route ที่ว่างให้กับถังปลายทาง
							SelecteDestinationRoute AS
							(
								SELECT [DestinationRoute], [DestinationMainRoute]
								FROM CheckAvailibleDestinationRoute
								WHERE [DestinationRoute] NOT IN (SELECT [DestinationRoute] FROM CheckActiveDestinaitonRoute)
							)
							SELECT TOP(1) [DestinationRoute] INTO #SelecteDestinationRoute FROM SelecteDestinationRoute ORDER BY [DestinationMainRoute] DESC ;

							SELECT @DestinationRoute = [DestinationRoute] FROM #SelecteDestinationRoute

							--ถ้าไม่มี Route ที่ว่างจะทำการเลือก MainRoute ไว้ให้
							IF NOT EXISTS (SELECT * FROM #SelecteDestinationRoute)
								SELECT @DestinationRoute = [DestinationRoute]
								FROM [MasterSmartFeed].[dbo].[DestinationSetup]
								WHERE [LineCodeName] = @LineCodeName AND [BinIO] = @DestinationBin AND 
										[DestinationRouteActive] = 1 AND [DestinationMainRoute] = 1 ;

							INSERT INTO #ResultDestinationRoute ([DestinationRoute])
							VALUES	(@DestinationRoute)
						END	
		
						--Set or Reset @Variable, #TempTable for Next While Loop
						SET @i = @i + 1

						DROP TABLE IF EXISTS #SelecteDestinationRoute ;
				END

			--อัพเดท SourceRoute และ DestinationRoute ในแต่ละ SequenceID
			DECLARE @DestinationRoute1 INT = (SELECT [DestinationRoute] FROM #ResultDestinationRoute WHERE [RowID] = 1)
			DECLARE @DestinationRoute2 INT = (SELECT [DestinationRoute] FROM #ResultDestinationRoute WHERE [RowID] = 2)
			DECLARE @DestinationRoute3 INT = (SELECT [DestinationRoute] FROM #ResultDestinationRoute WHERE [RowID] = 3)
			DECLARE @DestinationRoute4 INT = (SELECT [DestinationRoute] FROM #ResultDestinationRoute WHERE [RowID] = 4)

			UPDATE [JobHammermill].[dbo].[JobSequenceHammerMill]
			SET [DestinationRoute1] = COALESCE(@DestinationRoute1, 0),
				[DestinationRoute2] = COALESCE(@DestinationRoute2, 0),
				[DestinationRoute3] = COALESCE(@DestinationRoute3, 0),
				[DestinationRoute4] = COALESCE(@DestinationRoute4, 0)
			WHERE [SequenceID] = @SequenceID
			
			--Reset @Variable, #TempTable before Fetch Next
			DROP TABLE IF EXISTS #ResultDestinationRoute ;
			DROP TABLE IF EXISTS #tempDestinationBin ;

	--Fetch next Cursor
			FETCH NEXT FROM cursor_@AddDestinationRoute
			INTO @SequenceID, @LineCodeName, @Destination1, @Destination2, @Destination3, @Destination4 ;
		END

	--Close Cursor
	CLOSE cursor_@AddDestinationRoute ;
	DEALLOCATE cursor_@AddDestinationRoute ;

	----- END - Cursor:AddDestinationRoute -----
END
