/****** Object:  Table [dbo].[JobActiveHammerMill]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE [dbo].[JobActiveHammerMill](
	[IngredientCodeSource] [nvarchar](50) NULL,
	[IngredientNameSource] [nvarchar](250) NULL,
	[IngredientCodeDestination] [nvarchar](50) NULL,
	[IngredientNameDestination] [nvarchar](250) NULL,
	[LineCodeName] [nvarchar](20) NOT NULL,
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
	[ActiveAutoRun] [bit] NOT NULL,
	[UnderDemandPeak] [bit] NOT NULL,
	[LastFillingLot] [nvarchar](50) NULL,
 CONSTRAINT [PK_JobActiveHammerMill] PRIMARY KEY CLUSTERED 
(
	[LineCodeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
