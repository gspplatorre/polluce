-----------------------------------------------------------------------
-- CONT 10.1 Coerenza Titolo e dettagliotitolo	Titolo e dettagliotitolo controllo di coerenza degli importi di Premio e provvigioni per tipo Titolo
-- CR RealTime / Titolo Campi
-----------------------------------------------------------------------
set nocount on

print 'INIZIO'; print convert( varchar(23), getdate(), 121); if object_id('tempdb..##RPL_DEBUG_C1001', 'U') is not null drop table ##RPL_DEBUG_C1001; select n='INIZIO___________________________', d=getdate() into ##RPL_DEBUG_C1001

	----------------------------------------
	--Configurazione ID script
	----------------------------------------
	Declare @IDSCRIPT as integer=89

	if object_id('tempdb..#PE_C1001 ', 'U') is not null drop table #PE_C1001 
	select  pos=row_number() over ( order by n_progressivo), * into #PE_C1001  from KPI.ParametrizzazioneEstrazioni with (nolock) where id_script = @IDSCRIPT
 
	----------------------------------------
	-- DEBUG
	----------------------------------------
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_prodotto')                  alter table #PE_C1001      add  c_prodotto varchar(5) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_prodotto_escluso')          alter table #PE_C1001      add  c_prodotto_escluso varchar(5) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale')         alter table #PE_C1001      add c_ramo_ministeriale varchar(2) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale_escluso') alter table #PE_C1001      add c_ramo_ministeriale_escluso varchar(2) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_garanzia')					alter table #PE_C1001      add c_garanzia varchar(2) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_garanzia_esclusa')			alter table #PE_C1001      add c_garanzia_esclusa varchar(2) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_stato')                     alter table #PE_C1001      add c_stato varchar(1) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_stato_escluso')             alter table #PE_C1001      add c_stato_escluso varchar(1) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_Effetto')                   alter table #PE_C1001      add d_Effetto date null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo')               alter table #PE_C1001      add c_tipo_titolo varchar(2) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo_escluso')       alter table #PE_C1001      add c_tipo_titolo_escluso varchar(2) null
	--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_cutoff')                    alter table #PE_C1001      add d_cutoff date null


	--if ( select count(*) from #PE_C1001  ) = 0 
	--	   insert into #PE_C1001  (n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante, id_script, c_Tipo_GestioneProdotto, c_Tipo_GestioneProdotto_escluso, c_ramo_ministeriale,  f_raggruppa_prodotto, c_prodotto,d_Effetto,c_attivita,c_prodotto_escluso, c_ramo_ministeriale_escluso,c_garanzia,c_garanzia_esclusa,d_cutoff) 
	--				   values (     1,       'Query',      'Universo', 'Pagamento', 'UNI',    1000, 'N',          @IDSCRIPT, NULL,                    NULL,                            NULL,                'N',                  NULL,      NULL,      NULL,     NULL,								NULL,						NULL,		NULL, '20021001')


	--update #PE_C1001  set c_stato = case	when len(c_stato) = 1 then '''' + c_stato + '''' 
	--								when c_stato is null then '''0''' end
									 
	update #PE_C1001  set d_cutoff = '2002-10-01' where d_cutoff is null 

	update #PE_C1001  set c_stato=''''+c_stato+'''' where len(c_stato) = 1


	--select '#PE_C1001 ', id_script, kpi, oggetto_controllo, d_cutoff, c_stato, c_stato_escluso, c_prodotto, c_attivita, '!', * from #PE_C1001 

		print 'Perimetro PE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro PE', getdate() )

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
from #PE_C1001   K where  K.id_script = @IDSCRIPT

if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 

----------------------------------------
--INIZIO Query
----------------------------------------
if object_id('tempdb..#DATA', 'U') is not null drop table #DATA
select pos, d_effetto, d_cutoff into #DATA from #PE_C1001 

		print 'Perimetro DATA'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro DATA', getdate() )


if object_id('tempdb..#PROD', 'U') is not null drop table #PROD
select K.pos, K.f_raggruppa_prodotto, E.c_compagnia, E.c_prodotto, E.c_Tipo_GestioneProdotto, E.c_ramo_ministeriale, c_gestione = ISNULL(E.c_Tipo_GestioneProdotto,E.c_ramo_ministeriale) 
into #PROD
from #PE_C1001  K
join Prodotto E with (nolock) on  ( K.c_prodotto                          like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto is null                      or ''''+E.c_prodotto+'''' like K.c_prodotto) 
                              and ( K.c_prodotto_escluso              not like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto_escluso is null              )
                              and ( K.c_Tipo_GestioneProdotto             like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_Tipo_GestioneProdotto is null         ) 
							  and ( K.c_tipo_GestioneProdotto_escluso not like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_tipo_GestioneProdotto_escluso is null )
							  and ( ''''+E.c_prodotto+''''            not like K.c_prodotto_escluso                             or K.c_prodotto_escluso is null              )
                              and ( K.c_ramo_ministeriale                 like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale is null             ) 
							  and ( K.c_ramo_ministeriale_escluso     not like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale_escluso is null     )
create nonclustered index IX_tmpPROD on #PROD ( c_compagnia, c_prodotto, pos )
create nonclustered index IXT_PROD2 on #PROD ( pos )

		print 'Perimetro PRODOTTO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro PRODOTTO', getdate() )

if object_id('tempdb..#STATO', 'U') is not null drop table #STATO
select K.pos, S.c_stato, stato=S.descrizione 
into #STATO
from #PE_C1001  K
join Stato S with (nolock) on  ( K.c_stato             like '%'''+S.c_stato+'''%' or K.c_stato is null ) 
                           and ( K.c_stato_escluso not like '%'''+S.c_stato+'''%' or K.c_stato_escluso is null )
create nonclustered index IXT_STATO on #STATO ( pos )

		print 'Perimetro STATO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro STATO', getdate() )


if object_id('tempdb..#POL', 'U') is not null drop table #POL
select	D.pos, A.c_compagnia, A.c_prodotto, A.n_polizza, A.n_posizione, S.c_stato
into #POL
from #PROD D
join Polizza A with (nolock)		on A.c_compagnia=D.c_compagnia and A.c_prodotto=D.c_prodotto /* TOKEN_WHERE */	
join StoricoPolizza S with (nolock) on S.c_compagnia=A.c_compagnia and S.n_polizza=A.n_polizza and S.n_posizione=A.n_posizione 
									and S.d_inizio <= getdate() and S.d_fine > getdate() 
join #STATO	ST with (nolock)		on S.c_stato = ST.c_stato		

create nonclustered index IX_tmpPOL on #POL ( n_polizza, c_compagnia, n_posizione, pos )
--create nonclustered index IXT_POL2 on #POL ( pos )

		print 'Perimetro POLIZZE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro POLIZZE', getdate() )


if object_id('tempdb..#TIPOT', 'U') is not null drop table #TIPOT
select K.pos, T.c_tipo_titolo, tipoTitolo=T.descrizione
into #TIPOT
from #PE_C1001  K
join TipoTitolo T with (nolock) on (K.c_tipo_titolo is null or K.c_tipo_titolo like '%'''+T.c_tipo_titolo+'''%' )

		print 'Perimetro TIPOTIT'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro TIPOTIT', getdate() )


if object_id('tempdb..#TIT', 'U') is not null drop table #TIT
select	P.pos,T.c_compagnia, T.n_polizza, T.n_posizione, 
		/*T.c_tipo_titolo, T.c_esito,*/	T.d_effetto, T.n_progressivo_titolo/*, T.c_motivo_storno, 
		T.i_provvigione_incasso, T.i_provvigione_acquisto,T.i_premio_lordo,T.i_imposta*/,
		c_tipo_titolo	= max(T.c_tipo_titolo),
		netto_titolo	= max( isnull(T.i_premio_lordo,0) ) - max( isnull(T.i_imposta,0) ),
		netto_dettaglio	= sum( isnull(D.i_premio_netto,0) ),
		provv_titolo    = max( isnull(T.i_provvigione_incasso, 0)+isnull(T.i_provvigione_acquisto, 0)) ,
		provv_dettaglio = sum( isnull(D.i_provvigione_incasso, 0)+isnull(D.i_provvigione_acquisto, 0))
into #TIT
from #POL P
join #DATA           E               on E.pos=P.pos
join Titolo			 T with (nolock)	on T.c_compagnia=P.c_compagnia and T.n_polizza=P.n_polizza and T.n_posizione=P.n_posizione and T.d_effetto >= E.d_cutoff
join #TIPOT			 TT with (nolock)	on (TT.c_tipo_titolo=T.c_tipo_titolo)
join DettaglioTitolo D with (nolock) on D.c_compagnia=T.c_compagnia and D.n_polizza=T.n_polizza and D.n_posizione=T.n_posizione and D.d_effetto=T.d_effetto and D.n_progressivo_titolo=T.n_progressivo_titolo
group by P.pos, T.c_compagnia, T.n_polizza, T.n_posizione, T.d_effetto, T.n_progressivo_titolo

		print 'Perimetro TITOLO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro TITOLO', getdate() )

	----------------------------------------
	-- ESTR 
	--
	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000); select @AREACONTROLLO = case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end + case when c_garanzia is not null                then 'GARANZIA ' else '' end from #PE_C1001   K if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 
	if object_id('tempdb..#ESTR_C1001', 'U') is not null drop table #ESTR_C1001
	select K.pos, K.nome_kpi, K.kpi, K.c_Tipo_GestioneProdotto, K.f_raggruppa_prodotto, K.c_tipo_liquidazione,D.netto_titolo,D.netto_dettaglio,D.provv_titolo,D.provv_dettaglio,--K.tolleranza,
		   c_garanzia                 = NULL,
		   c_tipo                     = D.c_tipo_titolo,
		   c_gestione                 = isnull(C.c_Tipo_GestioneProdotto,C.c_ramo_ministeriale),
		   d_controllo                = cast( getdate() as date),
		   esito                      = @ESITOOK,  
		   tipoesito                  = cast( NULL as varchar(22)),  
		   c_prodotto                 = C.c_prodotto,
		   n_parametro                = D.n_polizza,
		   informazioni_aggiuntive    = D.n_progressivo_titolo,
		   oggetto_squadratura        = case when netto_titolo - netto_dettaglio <> 0 then abs(netto_titolo - netto_dettaglio) when provv_titolo - provv_dettaglio <> 0 then ABS(provv_titolo - provv_dettaglio) end--D.c_tipo_titolo
	into #ESTR_C1001
	from #PE_C1001              K
	join #PROD		 C on K.pos = C.pos
	join #POL		 P on K.pos = P.pos and C.c_prodotto = P.c_prodotto and C.c_compagnia = P.c_compagnia
	join #TIT		 D on K.pos = D.pos and D.n_polizza = P.n_polizza and D.c_compagnia = P.c_compagnia and D.n_posizione = P.n_posizione


		print 'Perimetro #ESTR_C1001'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro #ESTR_C1001', getdate() )

	----------------------------------------
	--Esito  
	--

	update #ESTR_C1001 set esito =  @ESITOKO where netto_titolo <> netto_dettaglio or provv_titolo <> provv_dettaglio


		print 'Perimetro UPDATE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro UPDATE', getdate() )


	/*
		select perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1001 order by perc, num desc


		--STORNO
		select c_motivo_storno, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1001 group by c_motivo_storno  order by perc, num desc

		--MOD
		select c_modalita_pagamento, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1001 group by c_modalita_pagamento  order by perc, num desc

		--TIPO
		select c_tipo_titolo, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1001 group by c_tipo_titolo  order by perc, num desc

		--ANNO
		select year(c_tipo), month(c_tipo), perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1001 group by year(c_tipo), month(c_tipo)   order by year(c_tipo), month(c_tipo)

		--PRODOTTO
		select c_prodotto, c_gestione, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1001 group by c_prodotto, c_gestione  order by perc, num desc
	
		select 'KO', * from #ESTR_C1001 where esito = 'KO' and c_prodotto like 'PUG35' order by d_effetto desc

	
	*/
	
	---------------------------------------
	--Output

	--
	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000) = 'TUTTO IL PORTAFOGLIO'
	--declare @TAB varchar(75) = 'n_progressivo_titolo'
	--declare @COL varchar(75) = 'c_tipo_titolo'
	--select @tab=NULL, @col=NULL from #PE_C1001  where isnull( f_raggruppa_prodotto, '') ='S'

	--declare @IA_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR_C1001%' and C.name = 'informazioni_aggiuntive'   )
	--declare @OS_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR_C1001%' and C.name = 'oggetto_squadratura'   )

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
			informazioni_aggiuntive = 'n_progressivo_titolo',
			oggetto_squadratura     = 'c_tipo_titolo'
	into #Output from #ESTR_C1001 E where E.Esito=@ESITOOK
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
	from #ESTR_C1001 E where Esito=@ESITOKO 
	-----------------------------------------
	--and isnull( E.f_raggruppa_prodotto, '') <>'S'
	--if ( select count(*) from #PE_C1001  where f_raggruppa_prodotto ='S' ) > 0
	--	insert into #OutPut ( nome_controllo, id_controllo, area_controllo, c_gestione, d_controllo, esito,    livello_aggregazione, c_prodotto, n_conteggio  )
	--	select                nome_kpi,       kpi,          @AREACONTROLLO, c_gestione, d_controllo, @ESITOKO, @AGGREGAZIONE,        c_prodotto, count(E.n_parametro)  
	--	from #ESTR_C1001 E
	--	where E.Esito=@ESITOKO and E.f_raggruppa_prodotto ='S'
	--	group by nome_kpi, kpi, d_controllo, c_gestione, c_prodotto
	-----------------------------------------

		print 'Perimetro OUTPUT'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro OUTPUT', getdate() )


	select * from #Output Z order by Z.ESITO desc, n_parametro 

		print 'Perimetro FINE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro FINE', getdate() )


-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- select  'if object_id(''tempdb..'+name+''', ''U'') is not null drop table '+name from ( select name=replace(replace(replace(left(name,50),'#ESTR_P0202_P0702_P0701_P0801_P0802_P0901_P0403_','$$'),'_',''),'$$','#ESTR_P0202_P0702_P0701_P0801_P0802_P0901_P0403_')  from tempdb..sysobjects O with (nolock) where name not like '##%' ) O where name not in ('#PE_P1403', '#OUTPUT', '#STATO', '#TIPOLIQ', '#STATOPRAT', '#PROD' )

		print 'Perimetro CANC_TEMP'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1001(n, d) values ('Perimetro CAMC_TEMP', getdate() )





