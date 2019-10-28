-----------------------------------------------------------------------
-- CONT 14.1 Controllo coerenza  Provvigioni
-- CR RealTime / Titolo Campi 
-----------------------------------------------------------------------
set nocount off

print 'INIZIO'; print convert( varchar(23), getdate(), 121); if object_id('tempdb..##RPL_DEBUG_C1401', 'U') is not null drop table ##RPL_DEBUG_C1401; select n='INIZIO___________________________', d=getdate() into ##RPL_DEBUG_C1401

----------------------------------------
--Configurazione ID script
----------------------------------------
Declare @IDSCRIPT as integer=93

if object_id('tempdb..#PE_C1401', 'U') is not null drop table #PE_C1401
select  pos=row_number() over ( order by n_progressivo), * into #PE_C1401 from KPI.ParametrizzazioneEstrazioni with (nolock) where id_script = @IDSCRIPT

----------------------------------------
-- DEBUG
----------------------------------------
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_effetto')                   alter table #PE_C1401     add d_Effetto date null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_cutoff')                    alter table #PE_C1401     add d_cutoff date null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo')               alter table #PE_C1401     add c_tipo_titolo varchar(50) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo_escluso')       alter table #PE_C1401     add c_tipo_titolo_escluso varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_liquidazione_escluso')       alter table #PE_C1401     add c_tipo_liquidazione_escluso varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale_escluso') alter table #PE_C1401     add c_ramo_ministeriale_escluso varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_accordo')               alter table #PE_C1401     add c_accordo varchar(5) null

--if ( select count(*) from #PE_C1401 ) = 0 
--       insert into #PE_C1401 ( id_script, pos, n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante ) 
--               values  ( @IDSCRIPT, 1,   10,           'DEBUG',      'Universo', 'Pagamento', 'UNI',    1000, 'N')

update #PE_C1401 set c_stato = ''''+c_stato+'''' where len(c_stato)=1
update #PE_C1401 set c_stato = '''0''' where c_stato is null
update #PE_C1401 set c_accordo = '''60030''' where c_accordo is null

--update #PE_C1401 set c_Tipo_GestioneProdotto_escluso = NULL where c_Tipo_GestioneProdotto_escluso is null


--select '#PE_C1401', id_script, kpi, oggetto_controllo, c_stato, c_stato_escluso, c_prodotto, d_cutoff,c_accordo, '!', * from #PE_C1401
		print 'Perimetro PE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro PE', getdate() )


----------------------------------------
-- PARAMETRI INTERNI
----------------------------------------
Declare @ESITOOK as varchar(100)='OK'
Declare @ESITOKO as varchar(100)='KO'
Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'
Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'
Declare @AREACONTROLLO as varchar(2000); select @AREACONTROLLO =          case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end  + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end + case when c_garanzia is not null                then 'GARANZIA ' else '' end from #PE_C1401  K; if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 

----------------------------------------
--INIZIO Query
----------------------------------------

----------------------------------------
-- TABELLE TEMP
----------------------------------------
if object_id('tempdb..#DATA', 'U') is not null drop table #DATA
select pos, d_effetto, d_cutoff into #DATA from #PE_C1401
/*
	select '#DATA', * from #DATA
*/

		print 'Perimetro DATA'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro DATA', getdate() )

if object_id('tempdb..#STATO', 'U') is not null drop table #STATO
select K.pos, S.c_stato, stato=S.descrizione 
into #STATO
from #PE_C1401 K
join Stato S with (nolock) on  ( K.c_stato             like '%'''+S.c_stato+'''%' or K.c_stato is null ) 
                           and ( K.c_stato_escluso not like '%'''+S.c_stato+'''%' or K.c_stato_escluso is null )
create nonclustered index IXT_STATO on #STATO ( pos )
/*
	select '#STATO', * from #STATO
*/

		print 'Perimetro STATO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro STATO', getdate() )

if object_id('tempdb..#TIPOLIQ', 'U') is not null drop table #TIPOLIQ
select K.pos, S.c_tipo_liquidazione, stato=S.descrizione 
into #TIPOLIQ
from #PE_C1401 K
join TipoLiquidazione S with (nolock) on  ( K.c_tipo_liquidazione             like '%'''+replace(S.c_tipo_liquidazione, '_', '[_]')+'''%' or K.c_tipo_liquidazione is null ) 
                                      and ( K.c_tipo_liquidazione_escluso not like '%'''+replace(S.c_tipo_liquidazione, '_', '[_]')+'''%' or K.c_tipo_liquidazione_escluso is null ) 
create nonclustered index IXT_TIPOLIQ on #TIPOLIQ ( pos )
/*
	select '#PE_C1401', pos, c_tipo_liquidazione from #PE_C1401
	select '#TIPOLIQ', * from #TIPOLIQ
*/ 
		print 'Perimetro TIPOLIQ'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro TIPOLIQ', getdate() )


if object_id('tempdb..#STATOPRAT', 'U') is not null drop table #STATOPRAT
select K.pos, S.c_stato_pratica, stato=S.descrizione 
into #STATOPRAT
from #PE_C1401 K
join StatoPraticaLiquidazione S with (nolock) on  ( K.c_stato_pratica             like '%'''+S.c_stato_pratica+'''%' or K.c_stato_pratica is null ) 
                                              and ( K.c_stato_pratica_escluso not like '%'''+S.c_stato_pratica+'''%' or K.c_stato_pratica_escluso is null ) 
create nonclustered index IXT_STATOPRAT on #STATOPRAT ( pos )
/*
	select * from #STATOPRAT
*/

		print 'Perimetro STATOPRAT'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro STATOPRAT', getdate() )


if object_id('tempdb..#PROD', 'U') is not null drop table #PROD
select K.pos, K.f_raggruppa_prodotto,  E.c_compagnia, E.c_prodotto, E.c_Tipo_GestioneProdotto, E.c_ramo_ministeriale, c_gestione = ISNULL(E.c_Tipo_GestioneProdotto,E.c_ramo_ministeriale) 
into #PROD
from #PE_C1401 K
join Prodotto E with (nolock) on  ( K.c_prodotto                          like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto is null                      or ''''+E.c_prodotto+'''' like K.c_prodotto) 
                              and ( K.c_prodotto_escluso              not like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto_escluso is null              )
                              and ( K.c_Tipo_GestioneProdotto             like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_Tipo_GestioneProdotto is null         ) 
							  and ( K.c_tipo_GestioneProdotto_escluso not like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_tipo_GestioneProdotto_escluso is null )
							  and ( ''''+E.c_prodotto+''''            not like K.c_prodotto_escluso                              or K.c_prodotto_escluso is null             )
                              and ( K.c_ramo_ministeriale                 like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale is null             ) 
							  and ( K.c_ramo_ministeriale_escluso     not like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale_escluso is null     )
create nonclustered index IX_tmpPROD on #PROD ( c_compagnia, c_prodotto, pos )
create nonclustered index IXT_PROD2 on #PROD ( pos )
/*
	select '#PE_C1401', c_prodotto, c_prodotto_escluso, c_tipo_GestioneProdotto, c_tipo_GestioneProdotto_escluso, c_ramo_ministeriale, c_ramo_ministeriale_escluso from #PE_C1401
	select '#PROD', * from #PROD

	select distinct '#PROD', c_tipo_GestioneProdotto from #PROD

*/

		print 'Perimetro PRODOTTO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro PRODOTTO', getdate() )


if object_id('tempdb..#POL', 'U') is not null drop table #POL
select D.pos, D.c_Tipo_GestioneProdotto, D.c_ramo_ministeriale, 
		A.c_compagnia, A.c_prodotto, A.n_polizza, A.n_posizione, n_prog = row_number() over (partition by A.c_prodotto order by A.d_effetto_polizza desc )
into #POL
from #PROD          D
join Polizza        A with (nolock) on                 A.c_compagnia=D.c_compagnia and A.c_prodotto=D.c_prodotto /* TOKEN_WHERE */	
join StoricoPolizza S with (nolock) on                 S.c_compagnia=A.c_compagnia and S.n_polizza=A.n_polizza and S.n_posizione=A.n_posizione and S.d_inizio <= getdate() and S.d_fine > getdate() 
join #STATO         T               on T.pos=D.pos and T.c_stato=S.c_stato
									
if object_id('tempdb..#TIPOT', 'U') is not null drop table #TIPOT
select K.pos, T.c_tipo_titolo, tipoTitolo=T.descrizione
into #TIPOT
from #PE_C1401 K
join TipoTitolo T with (nolock) on (K.c_tipo_titolo is null or T.c_tipo_titolo = K.c_tipo_titolo )

/*
	select * from #TIPOT
*/
		print 'Perimetro POLIZZA'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro POLIZZA', getdate() )



if object_id('tempdb..#ACCORDO', 'U') is not null drop table #ACCORDO
select K.pos, A.c_accordo, accdescrizione=A.descrizione
into #ACCORDO
from #PE_C1401 K
join AccordoCommerciale A with (nolock) on (K.c_accordo is null or K.c_accordo like '%'''+RTRIM(A.c_accordo)+'''%' )
/*
	select * from AccordoCommerciale where c_accordo = '60030'
	select * from #ACCORDO
*/

		print 'Perimetro ACCORDO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro ACCORDO', getdate() )


if object_id('tempdb..#TIT', 'U') is not null drop table #TIT
select P.pos, T.c_compagnia, T.n_polizza, T.n_posizione, T.d_effetto, T.n_progressivo_titolo, T.c_tipo_titolo, 
		i_provvigione_incasso   = isnull(T.i_provvigione_incasso, 0), 
		i_provvigione_acquisto  = isnull( T.i_provvigione_acquisto, 0)
into #TIT
from #POL     P
join Titolo   T with (nolock) on                 T.c_compagnia=P.c_compagnia and T.n_polizza=P.n_polizza and T.n_posizione=P.n_posizione
join #TIPOT   Z               on Z.pos=P.pos and Z.c_tipo_titolo=T.c_tipo_titolo
join #ACCORDO A               on A.pos=P.pos and A.c_accordo=T.c_accordo
/*
	select * from #TIT
*/

		print 'Perimetro TITOLO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro TITOLO', getdate() )


if object_id('tempdb..#DETT', 'U') is not null drop table #DETT
select  T.pos, T.c_compagnia, T.n_polizza, T.n_posizione, T.d_effetto, T.n_progressivo_titolo, 
		c_tipo_titolo						  = max( T.c_tipo_titolo ), 
		provvigione_incasso_titolo            = max( T.i_provvigione_incasso  ),
		provvigione_acquisto_titolo           = max( T.i_provvigione_acquisto ),
		provvigione_incasso_titolo_dettaglio  = sum( isnull(D.i_provvigione_incasso, 0) ) ,
		provvigione_acquisto_titolo_dettaglio = sum( isnull(D.i_provvigione_acquisto, 0) )			 
into #DETT
from #TIT T
join DettaglioTitolo D with (nolock) on D.c_compagnia=T.c_compagnia and D.n_polizza=T.n_polizza and D.n_posizione=T.n_posizione and D.d_effetto=T.d_effetto and D.n_progressivo_titolo=T.n_progressivo_titolo
group by T.pos, T.c_compagnia, T.n_polizza, T.n_posizione, T.d_effetto, T.n_progressivo_titolo

		print 'Perimetro DETTITOLO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro DETTITOLO', getdate() )

	----------------------------------------
	-- ESTR 
	--


	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000); select @AREACONTROLLO =          case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end  + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end + case when c_garanzia is not null                then 'GARANZIA ' else '' end from #PE_C1401  K; if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 
	if object_id('tempdb..#ESTR_C1401', 'U') is not null drop table #ESTR_C1401
	select K.pos, K.nome_kpi, K.kpi, K.f_raggruppa_prodotto, 
		   c_garanzia                 = NULL,
		   c_tipo                     = C.c_tipo_titolo,
		   c_gestione                 = D.c_gestione,
		   d_controllo                = cast( getdate() as date),
		   TipoEsito				  = cast( NULL as varchar(15)), 
		   esito                      = @EsitoOK,  
		   c_prodotto                 = D.c_prodotto,
		   n_parametro                = C.n_polizza,
		   informazioni_aggiuntive    = convert( varchar(10), C.d_effetto, 121),
		   oggetto_squadratura        = C.c_tipo_titolo, 
			C.c_compagnia, C.n_polizza, C.n_posizione, C.d_effetto, C.n_progressivo_titolo, 
			C.provvigione_incasso_titolo,	C.provvigione_acquisto_titolo, C.provvigione_incasso_titolo_dettaglio, C.provvigione_acquisto_titolo_dettaglio
	into #ESTR_C1401
	from #PE_C1401    K
	join #PROD  D on D.pos=K.pos
	join #POL   P on P.pos=K.pos and P.c_compagnia=D.c_compagnia and P.c_prodotto=D.c_prodotto
	join #DETT	C on C.pos=K.pos and C.c_compagnia=P.c_compagnia and C.n_polizza=P.n_polizza and C.n_posizione=P.n_posizione

		print 'Perimetro #ESTR_C1401'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro #ESTR_C1401', getdate() )

	----------------------------------------
	--Esito  
	--

	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO';
	update #ESTR_C1401 set tipoesito='TIT', esito=@EsitoKO where TipoEsito is null and provvigione_incasso_titolo<>0           and provvigione_acquisto_titolo<>0 
	update #ESTR_C1401 set tipoesito='DET', esito=@EsitoKO where TipoEsito is null and provvigione_incasso_titolo_dettaglio<>0 and provvigione_acquisto_titolo_dettaglio<>0 

	/*
		select * from #ESTR_C1401 where esito = 'KO'
	*/
		print 'Perimetro UPDATE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro UPDATE', getdate() )

	---------------------------------------
	--Output

	--
	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000) = 'TUTTO IL PORTAFOGLIO'
	--declare @TAB varchar(75) = 'Titolo'
	--declare @COL varchar(75) = 'c_tipo_titolo'
	--select @tab=NULL, @col=NULL from #PE_C1401 where isnull( f_raggruppa_prodotto, '') ='S'

	--declare @IA_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR_C1401%' and C.name = 'informazioni_aggiuntive'   )
	--declare @OS_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR_C1401%' and C.name = 'oggetto_squadratura'   )

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
			informazioni_aggiuntive = 'Titolo',
			oggetto_squadratura     = 'c_tipo_titolo'
	into #Output from #ESTR_C1401 E where E.Esito=@ESITOOK
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
			informazioni_aggiuntive = cast( E.informazioni_aggiuntive as varchar) ,
			oggetto_squadratura     = cast( E.oggetto_squadratura     as varchar) 
	from #ESTR_C1401 E where Esito=@ESITOKO 
	-----------------------------------------
	--and isnull( E.f_raggruppa_prodotto, '') <>'S'
	--if ( select count(*) from #PE_C1401 where f_raggruppa_prodotto ='S' ) > 0
	--	insert into #OutPut ( nome_controllo, id_controllo, area_controllo, c_gestione, d_controllo, esito,    livello_aggregazione, c_prodotto, n_conteggio  )
	--	select                nome_kpi,       kpi,          @AREACONTROLLO, c_gestione, d_controllo, @ESITOKO, @AGGREGAZIONE,        c_prodotto, count(E.n_parametro)  
	--	from #ESTR_C1401 E
	--	where E.Esito=@ESITOKO and E.f_raggruppa_prodotto ='S'
	--	group by nome_kpi, kpi, d_controllo, c_gestione, c_prodotto
	-----------------------------------------
		print 'Perimetro OUTPUT'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro OUTPUT', getdate() )

	select * from #Output Z order by Z.ESITO desc, n_parametro 

		print 'Perimetro FINE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro FINE', getdate() )



-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- select  'if object_id(''tempdb..'+name+''', ''U'') is not null drop table '+name from ( select name=replace(replace(replace(left(name,50),'#ESTR_P0202_P0702_P0701_P0801_P0802_P0901_P0403_','$$'),'_',''),'$$','#ESTR_P0202_P0702_P0701_P0801_P0802_P0901_P0403_')  from tempdb..sysobjects O with (nolock) where name not like '##%' ) O where name not in ('#PE_P1403', '#OUTPUT', '#STATO', '#TIPOLIQ', '#STATOPRAT', '#PROD' )
if object_id('tempdb..#DETT', 'U') is not null drop table #DETT
if object_id('tempdb..#PE_C1401', 'U') is not null drop table #PE_C1401
if object_id('tempdb..#DATA', 'U') is not null drop table #DATA
if object_id('tempdb..#POL', 'U') is not null drop table #POL
if object_id('tempdb..#ESTR_C1401', 'U') is not null drop table #ESTR_C1401
if object_id('tempdb..#TIPOT', 'U') is not null drop table #TIPOT
if object_id('tempdb..#ACCORDO', 'U') is not null drop table #ACCORDO
if object_id('tempdb..#TIT', 'U') is not null drop table #TIT


		print 'Perimetro CANC_TEMP'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1401(n, d) values ('Perimetro CANC_TEMP', getdate() )
