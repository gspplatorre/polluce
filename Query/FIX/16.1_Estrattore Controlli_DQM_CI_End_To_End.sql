-----------------------------------------------------------------------
-- 16.1 Controllo Coerenza rif end to end 
-- CR RealTime / Titolo Campi 
-----------------------------------------------------------------------
set nocount on

----------------------------------------
--Configurazione ID script
----------------------------------------
Declare @IDSCRIPT as integer=120

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
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_modalita_pagamento_esclusa') alter table #PE     add c_modalita_pagamento_esclusa varchar(10) null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_modalita_pagamento') alter table #PE     add c_modalita_pagamento varchar(10) null




if ( select count(*) from #PE ) = 0 
       insert into #PE ( id_script, pos, n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante, d_cutoff ) 
                values ( @IDSCRIPT,  1,   10,           'DEBUG',      'Universo', 'Pagamento', 'UNI',    1000, 'N',         '2016-07-01'          )
    

--update #PE set c_stato = case	when len(c_stato) = 1 then '''' + c_stato + '''' 
--								when c_stato is null then '''0''' end 
update #PE set c_tipo_titolo = '''18'',''04'',''03''' --where c_tipo_titolo is null --''05'',''06'',''07'','''01'',''02'',''80'',''90'''
--update #PE set c_tipo_titolo = null
update #PE set d_cutoff = '2016-07-01' where d_cutoff is null 
update #PE set c_modalita_pagamento = '''01''' where c_modalita_pagamento is null 

update #PE set c_stato=''''+c_stato+'''' where len(c_stato) = 1
--select '#PE', id_script, kpi, oggetto_controllo, c_stato, c_stato_escluso, c_prodotto, d_cutoff,c_modalita_pagamento, '!', * from #PE

--select distinct c_endtoend from #ESTR_C161 where esito = 'OK'

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

if object_id('tempdb..#MODPAG', 'U') is not null drop table #MODPAG
select pos, S.c_modalita_pagamento into #MODPAG from #PE K
join ModalitaPagamento S with (nolock) on	( K.c_modalita_pagamento             like '%'''+S.c_modalita_pagamento+'''%' or K.c_modalita_pagamento is null ) 
										and ( K.c_modalita_pagamento_esclusa not like '%'''+S.c_modalita_pagamento+'''%' or K.c_modalita_pagamento_esclusa is null )

/*
	select '#DATA', * from #MODPAG
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
--and P.n_polizza in ( 50012398928 )
--where S.n_polizza = 50011510111

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
		T.c_tipo_titolo, T.c_esito,	T.c_motivo_storno, T.c_modalita_pagamento, T.C_ENDTOEND
into #TIT
from #POL            P
join #DATA           E               on E.pos=P.pos
join Titolo			 T with (nolock) on T.c_compagnia=P.c_compagnia and T.n_polizza=P.n_polizza and T.n_posizione=P.n_posizione and T.d_effetto >= E.d_cutoff and c_motivo_storno is null
join #TIPOT			 TT              on TT.pos=P.pos and TT.c_tipo_titolo=T.c_tipo_titolo
join #MODPAG		 MP				 on T.c_modalita_pagamento = MP.c_modalita_pagamento

	----------------------------------------
	-- ESTR 
	--


	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000); select @AREACONTROLLO = case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end + case when c_garanzia is not null                then 'GARANZIA ' else '' end from #PE  K if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 
	if object_id('tempdb..#ESTR_C161', 'U') is not null drop table #ESTR_C161
	select K.pos, K.nome_kpi, K.kpi, K.f_raggruppa_prodotto,
		   c_garanzia                 = NULL,
		   c_tipo                     = C.c_tipo_titolo,
		   c_gestione                 = D.c_gestione,
		   d_controllo                = cast( getdate() as date),
		   esito                      = @ESITOKO,  
		   tipoesito                  = cast( NULL as varchar(22)),  
		   c_prodotto                 = C.c_prodotto,
		   n_parametro                = C.n_polizza,
		   informazioni_aggiuntive    = c.n_progressivo_titolo,
		   oggetto_squadratura        = C.c_tipo_titolo,
		   C.c_compagnia, C.n_polizza, C.n_posizione, 
		   C.d_effetto, C.c_tipo_titolo, C.c_esito,	C.c_motivo_storno, C.c_modalita_pagamento, C.C_ENDTOEND
	into #ESTR_C161
	from #PE    K
	join #PROD  D on D.pos=K.pos
	join #TIT	C on C.pos=K.pos and C.c_compagnia=D.c_compagnia and C.c_prodotto=D.c_prodotto
		
	----------------------------------------
	--Esito  
	--

	--update #ESTR_C161 set esito = Case
	--							when C_ENDTOSAPSFCD is null then @ESITOKO 
	--							else @ESITOOK end 

	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; 
	update #ESTR_C161 set tipoesito='VAL', esito=@ESITOOK where C_ENDTOEND is not null and C_ENDTOEND <> ' '

	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; 
	--update #ESTR_C161 set tipoesito='STO', esito=@ESITOOK where tipoesito is null and c_motivo_storno is not null

	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; 
	--update #ESTR_C161 set tipoesito='MOD99', esito=@ESITOOK where tipoesito is null and c_modalita_pagamento = '99'


	/*
	select * from #ESTR_C161
	select * from #TIPOT
	select C_ENDTOEND, count(*) from Titolo group by C_ENDTOEND

		select perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C161 order by perc, num desc
		--2721316

		--STORNO
		select c_motivo_storno, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C161 group by c_motivo_storno  order by perc, num desc

		--MOD
		select c_modalita_pagamento, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C161 group by c_modalita_pagamento  order by perc, num desc

		--TIPO
		select c_tipo_titolo, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C161 group by c_tipo_titolo  order by perc, num desc

		--ANNO
		select year(d_effetto), month(d_effetto), perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C161 group by year(d_effetto), month(d_effetto)   order by year(d_effetto), month(d_effetto)

		--PRODOTTO
		select c_prodotto, c_gestione, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C161 group by c_prodotto, c_gestione  order by perc, num desc
	
		select 'KO', * from #ESTR_C161 where esito = 'KO' and c_prodotto like 'PUG35' order by d_effetto desc

	
	*/
	
	---------------------------------------
	--Output

	--
	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000) = 'TUTTO IL PORTAFOGLIO'
	--declare @TAB varchar(75) = 'Titolo'
	--declare @COL varchar(75) = 'c_tipo_titolo'
	--select @tab=NULL, @col=NULL from #PE where isnull( f_raggruppa_prodotto, '') ='S'

	--declare @IA_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR_C161%' and C.name = 'informazioni_aggiuntive'   )
	--declare @OS_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR_C161%' and C.name = 'oggetto_squadratura'   )

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
			informazioni_aggiuntive = 'Titolo', --@TAB,
			oggetto_squadratura     = 'c_tipo_titolo' --@COL
	into #Output from #ESTR_C161 E where E.Esito=@ESITOOK
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
			informazioni_aggiuntive = cast( E.informazioni_aggiuntive as varchar),--case when @IA_type in ('money','numeric') then replace( replace( cast( E.informazioni_aggiuntive as varchar), ',', ''), '.',',') when @IA_type like '%date%' then convert(varchar(10), E.informazioni_aggiuntive, 121) else cast( E.informazioni_aggiuntive as varchar) end,
			oggetto_squadratura     = cast( E.oggetto_squadratura     as varchar)--case when @OS_type in ('money','numeric') then replace( replace( cast( E.oggetto_squadratura     as varchar), ',', ''), '.',',') when @OS_type like '%date%' then convert(varchar(10), E.oggetto_squadratura, 121)     else cast( E.oggetto_squadratura     as varchar) end
	from #ESTR_C161 E where Esito=@ESITOKO 
	-----------------------------------------
	and isnull( E.f_raggruppa_prodotto, '') <>'S'
	if ( select count(*) from #PE where f_raggruppa_prodotto ='S' ) > 0
		insert into #OutPut ( nome_controllo, id_controllo, area_controllo, c_gestione, d_controllo, esito,    livello_aggregazione, c_prodotto, n_conteggio  )
		select                nome_kpi,       kpi,          @AREACONTROLLO, c_gestione, d_controllo, @ESITOKO, @AGGREGAZIONE,        c_prodotto, count(E.n_parametro)  
		from #ESTR_C161 E
		where E.Esito=@ESITOKO and E.f_raggruppa_prodotto ='S'
		group by nome_kpi, kpi, d_controllo, c_gestione, c_prodotto
	-----------------------------------------

	select * from #Output Z order by Z.ESITO desc, n_parametro 



-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

-- @TAB E @col

/*

select c_EndToEnd, n_polizza,n_posizione, c_tipo_titolo /*, n_progressivo_titolo*/   from #ESTR_C161 where n_polizza in (
'50010219167','50011071089','50011083504','50011087224','50011378888','50011386748','50011441680','50011441718',
'50011441721','50011441895','50011441953','50011441958','50011441965','50011442000','50011442051','50011442054',
'50011442126','50011442133','50011442150','50011442184','50011442226','50011442248','50011442251','50011442262',
'50011442267','50011442287','50011442366','50011442421') and c_EndToEnd is not null

*/

--select a.c_EndToEnd, 
--a.n_polizza,
--a.n_posizione, 
--a.c_tipo_titolo , 
--a.n_progressivo_titolo
--from TITOLO a 
--where a.n_polizza in (select n_parametro from #Output)
--and a.n_progressivo_titolo = (select max(b.n_progressivo_titolo) from TITOLO b where b.n_polizza = a.n_polizza)

--select C_ENDTOEND,* from Titolo where n_polizza = 50011510111