-----------------------------------------------------------------------
-- 17.1 
-- CR RealTime / Titolo Campi 
-----------------------------------------------------------------------
set nocount on


----------------------------------------
--Configurazione ID script
----------------------------------------
Declare @IDSCRIPT as integer=94

if object_id('tempdb..#PE', 'U') is not null drop table #PE
select  pos=row_number() over ( order by n_progressivo), * into #PE from KPI.ParametrizzazioneEstrazioni with (nolock) where id_script = @IDSCRIPT
if object_id('tempdb..#ESTR', 'U') is not null drop table #ESTR
 
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
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo')               alter table #PE     add c_tipo_titolo varchar(2) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo_escluso')       alter table #PE     add c_tipo_titolo_escluso varchar(2) null


if ( select count(*) from #PE ) = 0 
	insert into #PE (n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante, id_script, c_Tipo_GestioneProdotto, c_Tipo_GestioneProdotto_escluso, c_ramo_ministeriale,  f_raggruppa_prodotto, c_prodotto,d_Effetto,c_attivita,c_prodotto_escluso, c_ramo_ministeriale_escluso,c_garanzia,c_garanzia_esclusa) 
		     values (     1,       'Query',      'Universo', 'Pagamento', 'UNI',    1000, 'N',          @IDSCRIPT, NULL,                    NULL,                            NULL,                'N',                  NULL,      NULL,      NULL,     NULL,								NULL,						NULL,		NULL)
    
update #PE set c_stato=''''+c_stato+'''' where len(c_stato) = 1
--select '#PE', id_script, kpi, oggetto_controllo, c_stato, c_stato_escluso, c_prodotto, d_cutoff, '!', * from #PE



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


if object_id('tempdb..#PROD', 'U') is not null drop table #PROD
select	K.pos, K.d_effetto, K.c_stato_pratica, K.c_stato, K.c_tipo_titolo, K.f_raggruppa_prodotto, 
		E.c_compagnia, E.c_prodotto, E.c_Tipo_GestioneProdotto, E.c_ramo_ministeriale, 
c_gestione = ISNULL(E.c_Tipo_GestioneProdotto,E.c_ramo_ministeriale)
into #PROD
from #PE K
join Prodotto E with (nolock) on 
    ( K.c_Tipo_GestioneProdotto is null or K.c_Tipo_GestioneProdotto =  E.c_Tipo_GestioneProdotto )
and ( K.c_ramo_ministeriale is null     or K.c_ramo_ministeriale = E.c_ramo_ministeriale )
and ( K.c_prodotto is null              or K.c_prodotto = E.c_prodotto )
and not exists ( select 1 from #PE KK where KK.c_Tipo_GestioneProdotto_escluso = E.c_Tipo_GestioneProdotto  and KK.c_Tipo_GestioneProdotto_escluso is not null )
and not exists ( select 1 from #PE KK where KK.c_ramo_ministeriale_escluso     = E.c_ramo_ministeriale      and KK.c_ramo_ministeriale_escluso is not null          )
and not exists ( select 1 from #PE KK where KK.c_prodotto_escluso              = E.c_prodotto               and KK.c_prodotto_escluso is not null                   )



if object_id('tempdb..#TIPOT', 'U') is not null drop table #TIPOT
select K.pos, T.c_tipo_titolo, tipoTitolo=T.descrizione
into #TIPOT
from #PE K
join TipoTitolo T with (nolock) on (K.c_tipo_titolo is null or T.c_tipo_titolo = K.c_tipo_titolo )

if object_id('tempdb..#ARR', 'U') is not null drop table #ARR
select c_compagnia, n_polizza, n_posizione, d_effetto, incassato = sum( case c_esito when 'A' then -1 when 'S' then 1 when 'I' then 1 end ),A.c_tipo_titolo
into #ARR
from Arretrato A with (nolock) 
join #TIPOT T on A.c_tipo_titolo = T.c_tipo_titolo
group by c_compagnia, n_polizza, n_posizione, d_effetto,A.c_tipo_titolo


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

if object_id('tempdb..#POL', 'U') is not null drop table #POL
select D.pos, D.c_Tipo_GestioneProdotto, D.c_ramo_ministeriale, AR.c_tipo_titolo, AR.incassato,AR.d_effetto,A.d_effetto_polizza,
		A.c_compagnia, A.c_prodotto, A.n_polizza, A.n_posizione, n_prog = row_number() over (partition by A.c_prodotto order by A.d_effetto_polizza desc )
into #POL
from #PROD D
join Polizza A with (nolock) on A.c_compagnia=D.c_compagnia and A.c_prodotto=D.c_prodotto /* TOKEN_WHERE */	
join #ARR AR with (nolock) on AR.c_compagnia=A.c_compagnia and AR.n_polizza=A.n_polizza and AR.n_posizione=A.n_posizione
join StoricoPolizza S with (nolock) on S.c_compagnia=A.c_compagnia and S.n_polizza=A.n_polizza and S.n_posizione=A.n_posizione 
									and S.d_inizio <= getdate() and S.d_fine > getdate() 
join #STATO T on T.pos=D.pos and T.c_stato=S.c_stato
--join #PE K on (S.c_stato = K.c_stato or K.c_stato is null)


	----------------------------------------
	-- ESTR 
	--
	if object_id('tempdb..#ESTR', 'U') is not null drop table #ESTR
	select K.pos, K.nome_kpi, K.kpi, K.c_Tipo_GestioneProdotto, K.f_raggruppa_prodotto, K.c_tipo_liquidazione,C.incassato,
		   c_garanzia                 = NULL,
		   c_tipo                     = null,--C.c_tipo_titolo,
		   c_gestione                 = isnull(C.c_Tipo_GestioneProdotto,C.c_ramo_ministeriale),
		   d_controllo                = cast( getdate() as date),
		   esito                      = @ESITOOK,  
		   tipoesito                  = cast( NULL as varchar(22)),  
		   c_prodotto                 = C.c_prodotto,
		   n_parametro                = C.n_polizza,
		   informazioni_aggiuntive    = C.d_effetto_polizza,--C.n_progressivo_titolo,
		   oggetto_squadratura        = C.c_tipo_titolo

	into #ESTR
	from #PE             K
	join #POL		 C on K.pos = C.pos

	----------------------------------------
	--Esito  
	--

	update #ESTR set esito = case when incassato < -1 then @ESITOKO else @ESITOOK end

	
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