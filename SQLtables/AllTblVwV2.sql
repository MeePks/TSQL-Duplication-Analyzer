USE []
GO

/****** Object:  View [dbo].[VW_AllTables]    Script Date: 11/3/2023 5:44:13 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




Create or alter    View [dbo].[VW_AllTables] 
AS
	WITH CTE AS(
  select distinct isnull(tt. DataSetName,'') DataSetName,isnull(tt.DatabaseName,'') as LoadDB, 
  isnull(Replace(tt.TableName,'dbo.',''),'') as LoadTbl,
  isnull(fm.SQLDB,'') as MainDB,isnull(Replace(fm.SQLTable,'dbo.',''),'') MainTbl,
  Isnull(Coalesce(fm.SQLDB,tt.DatabaseName),'') as DatabaseName,
  Isnull(Coalesce(Replace(fm.SQLTable,'dbo.',''),Replace(tt.TableName,'dbo.','')),'') as TableName,
  Case When Isnull(SQLTable,'')<>'' Then 'MainTable' Else 'LoadTable' End as TblCat
  --select distinct count(*)--select count(*)--select *
  from [DPGroupDataTracker].dbo.Vw_Tracking_Tables tt --where DataSetName='1010data'
  full outer join [DPGroupDataTracker].[dbo].[__FileManifestMaster] fm 
  on Replace(tt.TableName,'dbo.','')=Replace(fm.SQLLoadTable,'dbo.','') and tt.DatabaseName=fm.SQLLoadDB )-- select * from CTE
  
  
  ,GWP as(
   Select Column2 as DatabaseName,Replace(text,'dbo.','') as TableName
   From .dbo.__GlobalWizProcesses gp
   Where FormName='CCA_frmWizDupOutWizard'
   EXCEPT 
   select DatabaseName,TableName from CTE
  )
  ,GwpDetails as(
  Select IsNull(DatasetName,'') DataSetName,Gwp.DatabaseName,Replace(Gwp.TableName,'dbo.','') TableName,'GblWIzTbl' as TblCat
  From GWP 
  Left join [DPGroupDataTracker].dbo.Vw_Tracking_Tables tt 
  on GWP.TableName=Replace(tt.TableName,'dbo.','') and GWP.DataBaseName=tt.DatabaseName
  
  )
  select DataSetName,Replace(DatabaseName,'YYYY',YEAR(GetDate())) as DatabaseName,Replace(TableName,'YYYY',YEAR(GetDate())) as TableName,TblCat
  From CTE
  --where (DataSetName<>'' and DatabaseName<>'' and tablename<>'')
  Union 
  select * from GwpDetails

  
  
  
  
  --select distinct *
  --from CTE c





  --left join .dbo.__GlobalWizProcesses gp 
  --on coalesce(c.MainTbl,c.LoadTbl)=gp.Text
  --and coalesce(c.MainDB,c.LoadDB)=gp.column2
  --and formname='CCA_frmWizDupOutWizard'





GO


