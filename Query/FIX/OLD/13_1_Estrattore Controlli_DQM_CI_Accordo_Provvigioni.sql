-----------------------------------------------------------------------
-------  13.1 Se codice accordo 60030 provvigione incasso = provvigione acquisto =0
-----------------------------------------------------------------------

----------------------------------------
--Configurazione ID script
----------------------------------------
Declare @IDSCRIPT as integer=92

if object_id('tempdb..#PE', 'U') is not null drop table #PE
select  pos=row_number() over ( order by n_progressivo), * into #PE from KPI.ParametrizzazioneEstrazioni with (nolock) where id_script = @IDSCRIPT


----------------------------------------
-- DEBUG
----------------------------------------
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_prodotto')                  alter table #PE     add  c_prodotto varchar(5) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_prodotto_escluso')          alter table #PE     add  c_prodotto_escluso varchar(5) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale')         alter table #PE     add c_ramo_ministeriale varchar(2) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale_escluso') alter table #PE     add c_ramo_ministeriale_escluso varchar(2) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_garanzia')					alter table #PE     add c_garanzia varchar(2) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_garanzia_esclusa')			alter table #PE     add c_garanzia_esclusa varchar(2) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_stato')                     alter table #PE     add c_stato varchar(1) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_stato_escluso')             alter table #PE     add c_stato_escluso varchar(1) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_Effetto')                   alter table #PE     add d_Effetto date null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_accordo')					alter table #PE     add c_accordo varchar(5) null


if ( select count(*) from #PE ) = 0 
       insert into #PE (n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante, id_script, c_Tipo_GestioneProdotto, c_Tipo_GestioneProdotto_escluso, c_ramo_ministeriale,  f_raggruppa_prodotto, c_prodotto,d_Effetto,c_attivita,c_prodotto_escluso, c_ramo_ministeriale_escluso,c_garanzia,c_garanzia_esclusa) 
                   values (     1,       'Query',      'Universo', 'Pagamento', 'UNI',    1000, 'N',          @IDSCRIPT, NULL,                    NULL,                            NULL,                'N',                  NULL,      NULL,      NULL,     NULL,								NULL,						NULL,		NULL)

--update #PE set c_stato = case	when len(c_stato) = 1 then '''' + c_stato + '''' 
--								when c_stato is null then '''0''' end 
update #PE set c_accordo = '60030' where c_accordo is null

update #PE set c_stato=''''+c_stato+'''' where len(c_stato) = 1


--select '#PE', id_script, kpi, oggetto_controllo, c_stato, c_accordo,  c_stato_escluso, c_prodotto, d_cutoff, '!', * from #PE



----------------------------------------
-- PARAMETRI INTERNI
----------------------------------------
Declare @ESITOOK as varchar(100)='OK'
Declare @ESITOKO as varchar(100)='KO'
Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'
Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'


Declare @AREACONTROLLO as varchar(2000)
select @AREACONTROLLO = 
         case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end
       + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end
       + case when c_garanzia is not null                then 'GARANZIA ' else '' end 
from #PE  K where  K.id_script = @IDSCRIPT

if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 

----------------------------------------
--INIZIO Query
----------------------------------------
if object_id('tempdb..#STATO', 'U') is not null drop table #STATO
select K.pos, S.c_stato, stato=S.descrizione 
into #STATO
from #PE K
join Stato S with (nolock) on  ( K.c_stato             like '%'''+S.c_stato+'''%' or K.c_stato is null ) 
                           and ( K.c_stato_escluso not like '%'''+S.c_stato+'''%' or K.c_stato_escluso is null )
create nonclustered index IXT_STATO on #STATO ( pos )


if object_id('tempdb..#PROD', 'U') is not null drop table #PROD
select K.pos, K.f_raggruppa_prodotto,  E.c_compagnia, E.c_prodotto, E.c_Tipo_GestioneProdotto, E.c_ramo_ministeriale, c_gestione = ISNULL(E.c_Tipo_GestioneProdotto,E.c_ramo_ministeriale) 
into #PROD
from #PE K
join Prodotto E with (nolock) on  ( K.c_prodotto                          like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto is null                      or ''''+E.c_prodotto+'''' like K.c_prodotto) 
                              and ( K.c_prodotto_escluso              not like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto_escluso is null              )
                              and ( K.c_Tipo_GestioneProdotto             like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_Tipo_GestioneProdotto is null         ) 
							  and ( K.c_tipo_GestioneProdotto_escluso not like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_tipo_GestioneProdotto_escluso is null )
							  and ( ''''+E.c_prodotto+''''            not like K.c_prodotto_escluso                             or K.c_prodotto_escluso is null              )
                              and ( K.c_ramo_ministeriale                 like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale is null             ) 
							  and ( K.c_ramo_ministeriale_escluso     not like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale_escluso is null     )
create nonclustered index IX_tmpPROD on #PROD ( c_compagnia, c_prodotto, pos )
create nonclustered index IXT_PROD2 on #PROD ( pos )



if object_id('tempdb..#POL', 'U') is not null drop table #POL
select 
D.pos, A.c_compagnia, A.c_prodotto, A.n_polizza, A.n_posizione
into #POL
from #PROD          D
join Polizza        A with (nolock) on A.c_compagnia=D.c_compagnia and A.c_prodotto=D.c_prodotto /* TOKEN_WHERE */	
join StoricoPolizza S with (nolock) on S.c_compagnia=A.c_compagnia and S.n_polizza=A.n_polizza and S.n_posizione=A.n_posizione and S.d_inizio <= getdate() and S.d_fine > getdate() 
join #STATO         T               on T.pos=D.pos and T.c_stato=S.c_stato
--where A.n_polizza in ( 50000001006, 50000001011, 50000000237, 50000000432 , 50003139283, 50003139672, 50009524919 )

if object_id('tempdb..#ACCORDO', 'U') is not null drop table #ACCORDO
select K.pos, A.c_accordo, accdescrizione=A.descrizione
into #ACCORDO
from #PE K
join AccordoCommerciale A with (nolock) on (K.c_accordo is null or A.c_accordo = K.c_accordo )

--select * from #ACCORDO


if object_id('tempdb..#TIT', 'U') is not null drop table #TIT
select	P.pos,T.c_compagnia, T.n_polizza, T.n_posizione, 
		T.c_tipo_titolo, T.c_accordo,	T.d_effetto, T.n_progressivo_titolo, 
		T.i_provvigione_incasso, T.i_provvigione_acquisto 

into #TIT
from #POL P
join Titolo			 T with (nolock) on T.c_compagnia=P.c_compagnia and T.n_polizza=P.n_polizza and T.n_posizione=P.n_posizione 
join #ACCORDO			 TT on TT.c_accordo=T.c_accordo


--select * from #TIT

	if object_id('tempdb..#DETT', 'U') is not null drop table #DETT
	select  T.pos, T.c_compagnia, T.n_polizza, T.n_posizione, T.d_effetto,
			c_tipo_titolo = max( T.c_tipo_titolo ) ,
			n_progressivo_titolo = MAX( T.n_progressivo_titolo ),
			provvigione_incasso_titolo    =  max(isnull(T.i_provvigione_incasso, 0)),
			provvigione_acquisto_titolo    =  max(isnull(T.i_provvigione_acquisto, 0)),
			provvigione_incasso_titolo_dettaglio = sum( isnull(D.i_provvigione_incasso, 0)) ,
			provvigione_acquisto_titolo_dettaglio = sum(+isnull(D.i_provvigione_acquisto, 0))
	into #DETT
	from #TIT T
	join DettaglioTitolo D with (nolock) on D.c_compagnia=T.c_compagnia and D.n_polizza=T.n_polizza and D.n_posizione=T.n_posizione and D.d_effetto=T.d_effetto and D.n_progressivo_titolo=T.n_progressivo_titolo
	group by T.pos, T.c_compagnia, T.n_polizza, T.n_posizione, T.d_effetto,T.n_progressivo_titolo

	--select * from #DETT

	----------------------------------------
	-- ESTR 
	--



	if object_id('tempdb..#ESTR', 'U') is not null drop table #ESTR
	select K.pos, K.nome_kpi, K.kpi, K.c_Tipo_GestioneProdotto, K.f_raggruppa_prodotto, K.c_tipo_liquidazione,provvigione_incasso_titolo,provvigione_acquisto_titolo,provvigione_incasso_titolo_dettaglio,provvigione_acquisto_titolo_dettaglio,
		   c_garanzia                 = NULL,																  
		   c_tipo                     = D.c_tipo_titolo,											  
		   c_gestione                 = isnull(C.c_Tipo_GestioneProdotto,C.c_ramo_ministeriale),			  
		   d_controllo                = cast( getdate() as date),
		   esito                      = @ESITOOK,  
		   tipoesito                  = cast( NULL as varchar(22)),  
		   c_prodotto                 = C.c_prodotto,
		   n_parametro                = D.n_polizza,
		   informazioni_aggiuntive    = convert( varchar(10), D.d_effetto, 121),
		   oggetto_squadratura        = D.n_progressivo_titolo
	into #ESTR
	from #PE             K
	join #PROD		 C on K.pos = C.pos
	join #POL		 P on K.pos = P.pos and C.c_prodotto = P.c_prodotto and C.c_compagnia = P.c_compagnia
	join #DETT		 D on K.pos = D.pos and D.n_polizza = P.n_polizza and D.c_compagnia = P.c_compagnia and D.n_posizione = P.n_posizione
	----------------------------------------
	--Esito  
	--

	update #ESTR set tipoesito='TIT', esito=@EsitoKO where TipoEsito is null and provvigione_incasso_titolo<>0           or provvigione_acquisto_titolo<>0 
	update #ESTR set tipoesito='DET', esito=@EsitoKO where TipoEsito is null and provvigione_incasso_titolo_dettaglio<>0 or provvigione_acquisto_titolo_dettaglio<>0 

	---------------------------------------
	--Output

	--
	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000) = 'TUTTO IL PORTAFOGLIO'
	declare @TAB varchar(75) = 'Data_effetto'
	declare @COL varchar(75) = 'n_progressivo_titolo'
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


