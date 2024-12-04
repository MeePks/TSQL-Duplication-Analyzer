USE [RiteAidDPGroupTracker]
GO

/****** Object:  View [dbo].[Vw_Tracking_Tables]    Script Date: 9/28/2023 7:21:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE View [dbo].[Vw_Tracking_Tables]
As
select td.Schedule,td.DataSetName,td.DatasetFolder,td.MethodReceipt,td.LoadedFromSplit,td.AdvTracking,
tdd.DatasetID,tdd.DatasetDetailName,tdd.FilePatterns,tdd.FileExt,
tm.*
				FROM   [RiteAidDPGroupTracker].[DBO].[tracking_datasets] TD
				       INNER JOIN [RiteAidDPGroupTracker].dbo.[tracking_datasetdetail] TDD
				               ON TD.datasetid = TDD.datasetid
				       INNER JOIN [RiteAidDPGroupTracker].[DBO].[tracking_maps] TM
				               ON TM.detailid = TDD.detailid 
							  where  tm.ActiveMapBit=1
GO


