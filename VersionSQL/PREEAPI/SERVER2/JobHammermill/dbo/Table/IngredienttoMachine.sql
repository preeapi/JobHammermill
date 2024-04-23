/****** Object:  Table [dbo].[IngredienttoMachine]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE [dbo].[IngredienttoMachine](
	[IngredientCode] [nvarchar](50) NOT NULL,
	[ScreenSizeDown] [int] NOT NULL,
	[ScreenSizeUp] [int] NOT NULL,
	[LineCodeName] [nvarchar](20) NOT NULL,
	[RawMatDirectionID] [int] NOT NULL,
	[FeederHM] [decimal](5, 2) NULL,
	[RPMHM] [int] NULL,
	[OpenSlideFeeder] [bit] NULL,
	[NumberOfGrinding] [int] NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[IngredienttoMachine] ADD  CONSTRAINT [DF_IngredienttoMachine_FeederHM]  DEFAULT ((0)) FOR [FeederHM]
ALTER TABLE [dbo].[IngredienttoMachine] ADD  CONSTRAINT [DF_IngredienttoMachine_RPMHM]  DEFAULT ((0)) FOR [RPMHM]
ALTER TABLE [dbo].[IngredienttoMachine] ADD  CONSTRAINT [DF_IngredienttoMachine_OpenSlideFeeder]  DEFAULT ((0)) FOR [OpenSlideFeeder]
ALTER TABLE [dbo].[IngredienttoMachine] ADD  CONSTRAINT [DF_IngredienttoMachine_NumberOfGrinding]  DEFAULT ((0)) FOR [NumberOfGrinding]
ALTER TABLE [dbo].[IngredienttoMachine]  WITH CHECK ADD  CONSTRAINT [RawMatDirectionIDtoRawMatDirection] FOREIGN KEY([RawMatDirectionID])
REFERENCES [dbo].[RawMatDirectionMaster] ([RawMatDirectionID])
ON UPDATE CASCADE
ON DELETE CASCADE
ALTER TABLE [dbo].[IngredienttoMachine] CHECK CONSTRAINT [RawMatDirectionIDtoRawMatDirection]
ALTER TABLE [dbo].[IngredienttoMachine]  WITH CHECK ADD  CONSTRAINT [ScreenSizeIDtoScreenSizeDownMachine] FOREIGN KEY([ScreenSizeDown])
REFERENCES [dbo].[ScreenSizeMaster] ([ScreenSizeID])
ON DELETE CASCADE
ALTER TABLE [dbo].[IngredienttoMachine] CHECK CONSTRAINT [ScreenSizeIDtoScreenSizeDownMachine]
ALTER TABLE [dbo].[IngredienttoMachine]  WITH CHECK ADD  CONSTRAINT [ScreenSizeIDtoScreenSizeUpMachine] FOREIGN KEY([ScreenSizeUp])
REFERENCES [dbo].[ScreenSizeMaster] ([ScreenSizeID])
ALTER TABLE [dbo].[IngredienttoMachine] CHECK CONSTRAINT [ScreenSizeIDtoScreenSizeUpMachine]
