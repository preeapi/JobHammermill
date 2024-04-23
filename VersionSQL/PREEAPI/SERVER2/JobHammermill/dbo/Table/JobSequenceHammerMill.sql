/****** Object:  Table [dbo].[JobSequenceHammerMill]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE [dbo].[JobSequenceHammerMill](
	[SequenceID] [int] NULL,
	[IngredientCodeSource] [nvarchar](50) NULL,
	[IngredientNameSource] [nvarchar](50) NULL,
	[IngredientCodeDestination] [nvarchar](50) NULL,
	[IngredientNameDestination] [nvarchar](50) NULL,
	[LineCodeName] [nvarchar](20) NULL,
	[Source1] [int] NULL,
	[Source2] [int] NULL,
	[SourceRoute1] [int] NULL,
	[SourceRoute2] [int] NULL,
	[Destination1] [int] NULL,
	[Destination2] [int] NULL,
	[Destination3] [int] NULL,
	[Destination4] [int] NULL,
	[DestinationRoute1] [int] NULL,
	[DestinationRoute2] [int] NULL,
	[DestinationRoute3] [int] NULL,
	[DestinationRoute4] [int] NULL,
	[RawMatDirectionID] [int] NULL,
	[FeederHM] [decimal](5, 2) NULL,
	[RPMHM] [int] NULL,
	[JobPriority] [int] NULL,
	[JobMain] [bit] NULL,
	[TargetWeight] [decimal](8, 2) NULL,
	[NeedCheckLot] [bit] NULL,
	[LastFillingLot] [nvarchar](50) NULL
) ON [PRIMARY]

ALTER TABLE [dbo].[JobSequenceHammerMill] ADD  CONSTRAINT [DF_JobSequenceHammerMill_FeederHM]  DEFAULT ((0)) FOR [FeederHM]
