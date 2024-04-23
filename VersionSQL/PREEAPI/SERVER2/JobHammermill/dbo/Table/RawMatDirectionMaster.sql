/****** Object:  Table [dbo].[RawMatDirectionMaster]    Committed by VersionSQL https://www.versionsql.com ******/

CREATE TABLE [dbo].[RawMatDirectionMaster](
	[RawMatDirectionID] [int] NOT NULL,
	[RawMatDirectionName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_RawMatDirectionMaster] PRIMARY KEY CLUSTERED 
(
	[RawMatDirectionID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
