-----------------------------------------------------------------------
-- CONT 15.1 Controllo coerenza  Provvigioni
-- CR RealTime / Titolo Campi
-- Versione 2.0
-- Data 13/05/2019
-----------------------------------------------------------------------

----------------------------------------
--Configurazione ID script
----------------------------------------
Declare @IDSCRIPT as integer=119

if object_id('tempdb..#PE', 'U') is not null drop table #PE
select  pos=row_number() over ( order by n_progressivo), * into #PE from KPI.ParametrizzazioneEstrazioni with (nolock) where id_script = @IDSCRIPT

 
----------------------------------------
-- DEBUG
----------------------------------------
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo')               alter table #PE     add c_tipo_titolo varchar(50) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_effetto')                   alter table #PE     add d_Effetto date null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_cutoff')                    alter table #PE     add d_cutoff date null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo_escluso')       alter table #PE     add c_tipo_titolo_escluso varchar(2) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_liquidazione_escluso')       alter table #PE     add c_tipo_liquidazione_escluso varchar(2) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale_escluso') alter table #PE     add c_ramo_ministeriale_escluso varchar(2) null

--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_prodotto')                  alter table #PE     add  c_prodotto varchar(5) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_prodotto_escluso')          alter table #PE     add  c_prodotto_escluso varchar(5) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale')         alter table #PE     add c_ramo_ministeriale varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_garanzia')					alter table #PE     add c_garanzia varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_garanzia_esclusa')			alter table #PE     add c_garanzia_esclusa varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_stato')                     alter table #PE     add c_stato varchar(1) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_stato_escluso')             alter table #PE     add c_stato_escluso varchar(1) null


if ( select count(*) from #PE ) = 0 
       insert into #PE ( id_script, pos, n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante, d_cutoff ) 
                values ( @IDSCRIPT,  1,   10,           'DEBUG',      'Universo', 'Pagamento', 'UNI',    1000, 'N',         '2017-01-01'          )
    

update #PE set c_stato = '''0''' where c_stato is null
update #PE set c_tipo_titolo = '''01'',''02'',''05'',''06'',''07'',''80'',''90''' where c_tipo_titolo is null

update #PE set c_stato=''''+c_stato+'''' where len(c_stato) = 1
--update #PE set c_prodotto_escluso = '''APE%'''
--select '#PE', id_script, kpi, oggetto_controllo, c_stato, c_stato_escluso, c_prodotto, d_cutoff,c_prodotto_escluso, '!', * from #PE


--select * from #PE

----------------------------------------
-- PARAMETRI INTERNI
----------------------------------------
Declare @ESITOOK as varchar(100)='OK'
Declare @ESITOKO as varchar(100)='KO'
Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'
Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'
Declare @AREACONTROLLO as varchar(2000); select @AREACONTROLLO = case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end + case when c_garanzia is not null                then 'GARANZIA ' else '' end from #PE  K where  K.id_script = @IDSCRIPT; if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 


----------------------------------------
-- TABELLE TEMP
----------------------------------------
if object_id('tempdb..#DATA', 'U') is not null drop table #DATA
select pos, d_effetto, d_cutoff into #DATA from #PE
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
select K.pos, K.d_effetto, K.c_stato_pratica, K.c_stato, K.c_tipo_titolo, K.f_raggruppa_prodotto, E.c_compagnia, E.c_prodotto, E.c_Tipo_GestioneProdotto, E.c_ramo_ministeriale, c_gestione = ISNULL(E.c_Tipo_GestioneProdotto,E.c_ramo_ministeriale) 
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
	select '#PROD', * from #PROD
*/

---------------------

if object_id('tempdb..#POL', 'U') is not null drop table #POL
select 	D.pos, D.c_Tipo_GestioneProdotto, D.c_ramo_ministeriale, D.c_tipo_titolo, 
		A.c_compagnia, A.n_polizza, A.n_posizione, A.c_prodotto, A.d_effetto_polizza,
		n_prog = row_number() over (partition by A.c_prodotto order by A.d_effetto_polizza desc )
into #POL
from #PROD  D
join Polizza             A with (nolock) on A.c_compagnia=D.c_compagnia and A.c_prodotto=D.c_prodotto /* TOKEN_WHERE */	
join StoricoPolizza      S with (nolock) on S.n_polizza=A.n_polizza and S.n_posizione=A.n_posizione and S.c_compagnia=A.c_compagnia and S.d_inizio <= getdate() and S.d_fine > getdate() 
join #STATO	             T               on T.pos=D.pos and T.c_stato=S.c_stato 
--and P.n_polizza in ( 50008854021,50007366747,50010505750,50006444751,50008812793,50009670811,50010982812,50008243229,50009778966 )
/*
	select '#POL', * from #POL
*/

-------------



if object_id('tempdb..#TIPOT', 'U') is not null drop table #TIPOT
select K.pos, T.c_tipo_titolo, tipoTitolo=T.descrizione
into #TIPOT
from #PE K
join TipoTitolo T with (nolock) on (K.c_tipo_titolo is null or K.c_tipo_titolo like '%'''+T.c_tipo_titolo+'''%')

--select * from #TIPOT

if object_id('tempdb..#TIT', 'U') is not null drop table #TIT
select P.pos, T.c_compagnia, T.n_polizza, T.n_posizione, P.c_prodotto, T.d_effetto, T.n_progressivo_titolo,
		T.c_tipo_titolo, T.c_esito,	T.c_motivo_storno, T.c_modalita_pagamento, T.C_ENDTOSAPSFCD
into #TIT
from #POL            P
join #DATA           E               on E.pos=P.pos
join Titolo			 T with (nolock) on T.c_compagnia=P.c_compagnia and T.n_polizza=P.n_polizza and T.n_posizione=P.n_posizione and T.d_effetto >= E.d_cutoff and c_motivo_storno is null and T.d_carico < CONVERT(DATE,GETDATE())
join #TIPOT			 TT              on TT.pos=P.pos and TT.c_tipo_titolo=T.c_tipo_titolo


delete from #TIT where c_tipo_titolo = '02' and c_prodotto like 'APE%'

--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000); select @AREACONTROLLO = case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end + case when c_garanzia is not null                then 'GARANZIA ' else '' end from #PE  K if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 
if object_id('tempdb..#ESTR', 'U') is not null drop table #ESTR
select K.pos, K.nome_kpi, K.kpi, K.f_raggruppa_prodotto,
       c_garanzia                 = NULL,
       c_tipo                     = C.c_tipo_titolo,
       c_gestione                 = D.c_gestione,
	   d_controllo                = cast( getdate() as date),
       esito                      = @ESITOKO,  
       tipoesito                  = cast( NULL as varchar(22)),  
       c_prodotto                 = C.c_prodotto,
       n_parametro                = C.n_polizza,
	   informazioni_aggiuntive    = C.n_progressivo_titolo,
       oggetto_squadratura        = C.c_tipo_titolo,
	   C.c_compagnia, C.n_polizza, C.n_posizione, 
	   C.d_effetto, C.c_tipo_titolo, C.c_esito,	C.c_motivo_storno, C.c_modalita_pagamento, C.C_ENDTOSAPSFCD,C.n_progressivo_titolo
into #ESTR
from #PE    K
join #PROD  D on D.pos=K.pos
join #TIT	C on C.pos=K.pos and C.c_compagnia=D.c_compagnia and C.c_prodotto=D.c_prodotto


--update #ESTR set esito = Case
--							when C_ENDTOSAPSFCD is null then @ESITOKO 
--							else @ESITOOK end 

--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; 
update #ESTR set tipoesito='VAL', esito=@ESITOOK where C_ENDTOSAPSFCD is not null 

--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; 
--update #ESTR set tipoesito='STO', esito=@ESITOOK where tipoesito is null and c_motivo_storno is not null

--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; 
--update #ESTR set tipoesito='MOD99', esito=@ESITOOK where tipoesito is null and c_modalita_pagamento = '99'


/*
	select perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR order by perc, num desc
	--2721316

	--STORNO
	select c_motivo_storno, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_motivo_storno  order by perc, num desc

	--MOD
	select c_modalita_pagamento, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_modalita_pagamento  order by perc, num desc

	--TIPO
	select c_tipo_titolo, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_tipo_titolo  order by perc, num desc

	--ANNO
	select year(d_effetto), month(d_effetto), perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by year(d_effetto), month(d_effetto)   order by year(d_effetto), month(d_effetto)

	--PRODOTTO
	select c_prodotto, c_gestione, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_prodotto, c_gestione  order by perc, num desc
	
	select 'KO', * from #ESTR where esito = 'KO' and c_prodotto like 'PUG35' order by d_effetto desc

	
*/

	---------------------------------------
	--Output

	--
	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000) = 'TUTTO IL PORTAFOGLIO'
	declare @TAB varchar(75) = 'Titolo'
	declare @COL varchar(75) = 'c_tipo_titolo'
	select @tab=NULL, @col=NULL from #PE where isnull( f_raggruppa_prodotto, '') ='S'

	declare @IA_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR%' and C.name = 'informazioni_aggiuntive'   )
	declare @OS_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR%' and C.name = 'oggetto_squadratura'   )

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
			informazioni_aggiuntive = @TAB,
			oggetto_squadratura     = @COL
	into #Output from #ESTR E where E.Esito=@ESITOOK
	union
	Select	nome_controllo          = E.nome_kpi, 
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
			informazioni_aggiuntive = case when @IA_type in ('money','numeric') then replace( replace( cast( E.informazioni_aggiuntive as varchar), ',', ''), '.',',') when @IA_type like '%date%' then convert(varchar(10), E.informazioni_aggiuntive, 121) else cast( E.informazioni_aggiuntive as varchar) end,
			oggetto_squadratura     = case when @OS_type in ('money','numeric') then replace( replace( cast( E.oggetto_squadratura     as varchar), ',', ''), '.',',') when @OS_type like '%date%' then convert(varchar(10), E.oggetto_squadratura, 121)     else cast( E.oggetto_squadratura     as varchar) end
	from #ESTR E where Esito=@ESITOKO 
	-----------------------------------------
	and isnull( E.f_raggruppa_prodotto, '') <>'S'
	if ( select count(*) from #PE where f_raggruppa_prodotto ='S' ) > 0
		insert into #OutPut ( nome_controllo, id_controllo, area_controllo, c_gestione, d_controllo, esito,    livello_aggregazione, c_prodotto, n_conteggio  )
		select                nome_kpi,       kpi,          @AREACONTROLLO, c_gestione, d_controllo, @ESITOKO, @AGGREGAZIONE,        c_prodotto, count(E.n_parametro)  
		from #ESTR E
		where E.Esito=@ESITOKO and E.f_raggruppa_prodotto ='S'
		group by nome_kpi, kpi, d_controllo, c_gestione, c_prodotto
	-----------------------------------------

	select * from #Output Z order by Z.ESITO desc, n_parametro 



-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

-- @TAB E @col

