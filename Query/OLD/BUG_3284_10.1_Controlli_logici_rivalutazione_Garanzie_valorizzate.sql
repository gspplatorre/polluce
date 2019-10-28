----------------------------------------------------------------------
--  10.1 Controlli logici rivalutazione:  Garanzie valorizzate
-- Garanzia popolate in tabella storicoprestazionegaranzia
-----------------------------------------------------------------------

----------------------------------------
--Configurazione ID script
----------------------------------------
Declare @IDSCRIPT as integer=1130

if object_id('tempdb..#PE', 'U') is not null drop table #PE
select  pos=row_number() over ( order by n_progressivo), * into #PE from KPI.ParametrizzazioneEstrazioni with (nolock) where id_script = @IDSCRIPT

----------------------------------------
-- DEBUG
----------------------------------------
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_liquidazione_escluso') alter table #PE     add c_tipo_liquidazione_escluso varchar(250) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale_escluso') alter table #PE     add c_ramo_ministeriale_escluso varchar(250) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_cutoff')                    alter table #PE     add d_cutoff date null


if ( select count(*) from #PE ) = 0 
       insert into #PE ( id_script, pos, n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante, d_cutoff,      c_garanzia_esclusa,                        c_prodotto_escluso ) 
                values ( @IDSCRIPT, 1,   10,           'DEBUG',      'Universo', 'Pagamento', 'UNI',    1000, 'N',          '2015-01-01', '''10'',''64'',''IS'',''PI'',''IN'',''44''', '''NUL%'''        )
    
--update #PE set c_garanzia_esclusa = '''10'',''64'',''IS'',''PI'',''IN'',''44''' where c_garanzia_esclusa is null
--update #PE set c_prodotto_escluso = '''NUL%''' where c_prodotto_escluso is null
--update #PE set d_cutoff = '2015-01-01' where d_cutoff is null

--select ''#PE', pos, id_script  from #PE

----------------------------------------
-- PARAMETRI INTERNI
----------------------------------------
Declare @ESITOOK as varchar(100)='OK'
Declare @ESITOKO as varchar(100)='KO'
Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'
Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'
Declare @AREACONTROLLO as varchar(2000); select @AREACONTROLLO = case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end+ case when c_garanzia is not null                then 'GARANZIA ' else '' end  + case when c_tipo_liquidazione is not null       then 'LIQUIDAZIONE ' else '' end from #PE  K; if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 


----------------------------------------
-- TABELLE TEMP
----------------------------------------
if object_id('tempdb..#DATA', 'U') is not null drop table #DATA
select pos, d_effetto=isnull( d_effetto, cast(getdate() as date)), d_cutoff=isnull( d_cutoff, '1900-01-01') into #DATA from #PE
/*
	select '#DATA', * from #DATA
*/
if object_id('tempdb..#STATO', 'U') is not null drop table #STATO
select K.pos, S.c_stato, stato=S.descrizione 
into #STATO
from #PE K
join Stato S with (nolock) on  ( K.c_stato             like '%'''+S.c_stato+'''%' or K.c_stato is null ) 
                           and ( K.c_stato_escluso not like '%'''+S.c_stato+'''%' or K.c_stato_escluso is null )
create nonclustered index IXT_STATO on #STATO ( pos )
/*
	select '#STATO', * from #STATO
*/

if object_id('tempdb..#TIPOLIQ', 'U') is not null drop table #TIPOLIQ
select K.pos, S.c_tipo_liquidazione, stato=S.descrizione 
into #TIPOLIQ
from #PE K
join TipoLiquidazione S with (nolock) on  ( K.c_tipo_liquidazione             like '%'''+replace(S.c_tipo_liquidazione, '_', '[_]')+'''%' or K.c_tipo_liquidazione is null ) 
                                      and ( K.c_tipo_liquidazione_escluso not like '%'''+replace(S.c_tipo_liquidazione, '_', '[_]')+'''%' or K.c_tipo_liquidazione_escluso is null ) 
create nonclustered index IXT_TIPOLIQ on #TIPOLIQ ( pos )
/*
	select '#PE', pos, c_tipo_liquidazione from #PE
	select '#TIPOLIQ', * from #TIPOLIQ
*/ 


if object_id('tempdb..#STATOPRAT', 'U') is not null drop table #STATOPRAT
select K.pos, S.c_stato_pratica, stato=S.descrizione 
into #STATOPRAT
from #PE K
join StatoPraticaLiquidazione S with (nolock) on  ( K.c_stato_pratica             like '%'''+S.c_stato_pratica+'''%' or K.c_stato_pratica is null ) 
                                              and ( K.c_stato_pratica_escluso not like '%'''+S.c_stato_pratica+'''%' or K.c_stato_pratica_escluso is null ) 
create nonclustered index IXT_STATOPRAT on #STATOPRAT ( pos )
/*
	select * from #STATOPRAT
*/

if object_id('tempdb..#PROD', 'U') is not null drop table #PROD
select K.pos, E.c_compagnia, E.c_prodotto, E.c_Tipo_GestioneProdotto, E.c_ramo_ministeriale, c_gestione = ISNULL(E.c_Tipo_GestioneProdotto,E.c_ramo_ministeriale) 
into #PROD
from #PE K
join Prodotto E with (nolock) on  ( K.c_prodotto                          like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto is null                      or ''''+E.c_prodotto+'''' like K.c_prodotto) 
                              and ( K.c_prodotto_escluso              not like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto_escluso is null              )
                              and ( K.c_Tipo_GestioneProdotto             like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_Tipo_GestioneProdotto is null         ) 
							  and ( K.c_tipo_GestioneProdotto_escluso not like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_tipo_GestioneProdotto_escluso is null )
							  and ( ''''+E.c_prodotto+''''            not like K.c_prodotto_escluso                              or K.c_prodotto_escluso is null              )
                              and ( K.c_ramo_ministeriale                 like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale is null             ) 
							  and ( K.c_ramo_ministeriale_escluso     not like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale_escluso is null     )
create nonclustered index IX_tmpPROD on #PROD ( c_compagnia, c_prodotto, pos )
create nonclustered index IXT_PROD2 on #PROD ( pos )
/*
	select '#PE', c_prodotto, c_prodotto_escluso, c_tipo_GestioneProdotto, c_tipo_GestioneProdotto_escluso, c_ramo_ministeriale, c_ramo_ministeriale_escluso from #PE
	select '#PROD', * from #PROD where c_prodotto like 'NUL%'

*/

------------------

if object_id('tempdb..#POL', 'U') is not null drop table #POL
select 	D.pos, P.c_compagnia, P.n_polizza, P.n_posizione, P.c_prodotto, P.d_effetto_polizza
into #POL
from #PROD  D
join Polizza             P with (nolock) on P.c_compagnia=D.c_compagnia and P.c_prodotto=D.c_prodotto
join StoricoPolizza      S with (nolock) on S.n_polizza=P.n_polizza and S.n_posizione=P.n_posizione and S.c_compagnia=P.c_compagnia and S.d_inizio <= getdate() and S.d_fine > getdate() 
join #STATO	             T               on T.pos=D.pos and T.c_stato=S.c_stato 
--where P.n_polizza in ( 1710100011,1210800102,1706900009,1218100001,1215700007,1709800009,1705800098,1705800093,1710100067,1705800034,1705800091,1705800022,50002929483,1709800007,1705800148,1219800003,1707500069,1709300047,1219800002,1706900046 )
/*
	select '#POL', * from #POL
*/

if object_id('tempdb..#GAR', 'U') is not null drop table #GAR
select K.pos, S.c_garanzia, garanzia=S.descrizione 
into #GAR
from #PE K
join Garanzia S with (nolock) on  ( K.c_garanzia             like '%'''+S.c_garanzia+'''%' or K.c_garanzia is null ) 
                                      and ( K.c_garanzia_esclusa not like '%'''+S.c_garanzia+'''%' or K.c_garanzia_esclusa is null ) 
create nonclustered index IXT_GAR on #GAR ( pos )
/*
	select '#PE', pos, c_garanzia from #PE
	select '#GAR', c_garanzia, garanzia from #GAR
*/ 


if object_id('tempdb..#SPG', 'U') is not null drop table #SPG
select  P.pos, G.c_compagnia, G.n_polizza, G.n_posizione, G.c_garanzia, G.d_effetto_garanzia,
		S.d_inizio, S.c_tipo_aggiornamento_garanzia, Z.garanzia
into #SPG
from #POL                            P
join GaranziaPolizza                 G with (nolock) on G.n_polizza=P.n_polizza and G.n_posizione=P.n_posizione and G.c_compagnia=P.c_compagnia 
join #DATA                           T               on T.pos=P.pos and T.d_cutoff <= G.d_effetto_garanzia
join #GAR                            Z               on Z.pos=P.pos and Z.c_garanzia=G.c_garanzia
left join StoricoPrestazioneGaranzia S with (nolock) on S.n_polizza=G.n_polizza and S.n_posizione=G.n_posizione and S.c_compagnia=G.c_compagnia and S.c_garanzia=G.c_garanzia and S.d_inizio<=getdate() and S.d_fine > getdate()
                                                     and  not exists ( select 1 from StoricoPrestazioneGaranzia SS where SS.n_polizza=S.n_polizza and SS.n_posizione=S.n_posizione and SS.c_compagnia=S.c_compagnia and SS.c_garanzia=S.c_garanzia and SS.c_tipo_aggiornamento_garanzia=2 and S.c_tipo_aggiornamento_garanzia=1 ) 

/*
	select '#SPG', * from #SPG
*/
----------------------------------------
-- ESTR
----------------------------------------
if object_id('tempdb..#ESTR', 'U') is not null drop table #ESTR
select K.pos, K.nome_kpi, K.kpi,
              c_garanzia                          = S.c_garanzia,
              c_tipo                              = S.c_tipo_aggiornamento_garanzia,
              c_gestione                          = D.c_gestione,
              d_controllo                         = cast( getdate() as date),
			  TipoEsito							  = cast( NULL as varchar(15)),
              esito                               = @EsitoOK,
              c_prodotto                          = D.c_prodotto,
              n_parametro                         = P.n_polizza,
              informazioni_aggiuntive			  = S.garanzia,
              oggetto_squadratura				  = S.c_garanzia,
			  P.c_compagnia, P.n_polizza, P.n_posizione, S.d_inizio, S.c_tipo_aggiornamento_garanzia, S.d_effetto_garanzia
into #ESTR
from #PE   K  
join #PROD D on D.pos=K.pos
join #POL  P on P.pos=K.pos and P.c_compagnia=D.c_compagnia and P.c_prodotto=D.c_prodotto
join #SPG  S on S.pos=K.pos and S.c_compagnia=P.c_compagnia and S.n_polizza=P.n_polizza and S.n_posizione=P.n_posizione



----------------------------------------
--Esito
----------------------------------------
update #ESTR set esito = @EsitoKO where d_inizio is  null

/*
	select top 20 '#ESTR', n_polizza, * from #ESTR where esito = 'KO'

	select tipoesito, esito, count(*) from #ESTR group by tipoesito, esito
	select c_prodotto, perc=sum(case when esito='KO' then 100.0 else 0 end)/count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_prodotto  order by perc, num desc

	select c_garanzia, perc=sum(case when esito='KO' then 100.0 else 0 end)/count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_garanzia  order by perc, num desc
	select year(d_effetto_garanzia), perc=sum(case when esito='KO' then 100.0 else 0 end)/count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by year(d_effetto_garanzia)  order by year(d_effetto_garanzia)
*/

----------------------------------------
-- Output
----------------------------------------
--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000) = 'TUTTO IL PORTAFOGLIO' 
if object_id('tempdb..#Output', 'U') is not null drop table #Output
select  nome_controllo          = max(E.nome_kpi), 
              id_controllo            = max(E.kpi),
              area_controllo          = @AREACONTROLLO,
              c_garanzia              = NULL,
              c_tipo                  = NULL,
              c_gestione              = NULL,
              d_controllo             = max(E.d_controllo),
              esito                   = @ESITOOK,
              livello_aggregazione    = @AGGREGAZIONE,
              c_prodotto              = NULL,
              n_parametro             = NULL,
              n_conteggio             = count(E.n_parametro),
              informazioni_aggiuntive = NULL,
              oggetto_squadratura     = NULL
into #Output from #ESTR E where E.Esito=@ESITOOK
union
Select nome_controllo          = E.nome_kpi, 
              id_controllo            = E.kpi,
              area_controllo          = @AREACONTROLLO,
              c_garanzia              = E.c_garanzia,
              c_tipo                  = E.c_tipo,
              c_gestione              = E.c_gestione,
              d_controllo             = E.d_controllo,
              esito                   = @ESITOKO,
              livello_aggregazione    = @NESSUNAAGGREGAZIONE,
              c_prodotto              = E.c_prodotto,
              n_parametro             = E.n_parametro,
              n_conteggio             = NULL,
              informazioni_aggiuntive = E.informazioni_aggiuntive,
              oggetto_squadratura     = E.oggetto_squadratura
from #ESTR E where Esito=@ESITOKO 
-----------------------------------------
--and isnull( E.f_raggruppa_prodotto, '') <>'S'
--if ( select count(*) from #PE where f_raggruppa_prodotto ='S' ) > 0
--	insert into #OutPut ( nome_controllo, id_controllo, area_controllo, c_gestione, d_controllo, esito,    livello_aggregazione, c_prodotto, n_conteggio  )
--	select                nome_kpi,       kpi,          @AREACONTROLLO, c_gestione, d_controllo, @ESITOKO, @AGGREGAZIONE,        c_prodotto, count(E.n_parametro)  
--	from #ESTR E
--	where E.Esito=@ESITOKO and E.f_raggruppa_prodotto ='S'
--	group by nome_kpi, kpi, d_controllo, c_gestione, c_prodotto
-----------------------------------------

select * from #Output Z order by Z.ESITO desc, n_parametro
