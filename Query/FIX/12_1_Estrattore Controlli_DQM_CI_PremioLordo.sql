-----------------------------------------------------------------------
-- CONT 12.1 premio netto+imposte = premio lordo (sul multiramo il premio netto è ottenuto cumulando le garanzie)
-- CR RealTime / Titolo Campi 
-----------------------------------------------------------------------
set nocount on
print 'INIZIO'; print convert( varchar(23), getdate(), 121); if object_id('tempdb..##RPL_DEBUG_C1201', 'U') is not null drop table ##RPL_DEBUG_C1201; select n='INIZIO___________________________', d=getdate() into ##RPL_DEBUG_C1201

----------------------------------------
--Configurazione ID script
----------------------------------------
Declare @IDSCRIPT as integer=91

if object_id('tempdb..#PE_C1201', 'U') is not null drop table #PE_C1201
select  pos=row_number() over ( order by n_progressivo), * into #PE_C1201 from KPI.ParametrizzazioneEstrazioni with (nolock) where id_script = @IDSCRIPT

 
----------------------------------------
-- DEBUG
----------------------------------------
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_prodotto')                  alter table #PE_C1201     add  c_prodotto varchar(5) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_prodotto_escluso')          alter table #PE_C1201     add  c_prodotto_escluso varchar(5) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale')         alter table #PE_C1201     add c_ramo_ministeriale varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_ramo_ministeriale_escluso') alter table #PE_C1201     add c_ramo_ministeriale_escluso varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_garanzia')					alter table #PE_C1201     add c_garanzia varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_garanzia_esclusa')			alter table #PE_C1201     add c_garanzia_esclusa varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_stato')                     alter table #PE_C1201     add c_stato varchar(1) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_stato_escluso')             alter table #PE_C1201     add c_stato_escluso varchar(1) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_Effetto')                   alter table #PE_C1201     add d_Effetto date null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo')               alter table #PE_C1201     add c_tipo_titolo varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='c_tipo_titolo_escluso')       alter table #PE_C1201     add c_tipo_titolo_escluso varchar(2) null
--if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_cutoff')                    alter table #PE_C1201     add d_cutoff date null
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='tolleranza')                  alter table #PE_C1201     add tolleranza money null

--if ( select count(*) from #PE_C1201 ) = 0 
--       insert into #PE_C1201 (n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante, id_script, c_Tipo_GestioneProdotto, c_Tipo_GestioneProdotto_escluso, c_ramo_ministeriale,  f_raggruppa_prodotto, c_prodotto,d_Effetto,c_attivita,c_prodotto_escluso, c_ramo_ministeriale_escluso,c_garanzia,c_garanzia_esclusa,d_cutoff) 
--                   values (     1,       'Query',      'Universo', 'Pagamento', 'UNI',    1000, 'N',          @IDSCRIPT, NULL,                    NULL,                            NULL,                'N',                  NULL,      NULL,      NULL,     NULL,								NULL,						NULL,		NULL,'2006-05-01') 


--update #PE_C1201 set c_stato = case	when len(c_stato) = 1 then '''' + c_stato + '''' 
--								when c_stato is null then '''0''' end 

update #PE_C1201 set d_cutoff = '2006-05-01' where d_cutoff is null 

update #PE_C1201 set c_stato=''''+c_stato+'''' where len(c_stato) = 1
update #PE_C1201 set tolleranza = 0.01 where tolleranza is null
--select '#PE_C1201', id_script, kpi, oggetto_controllo, c_stato, c_stato_escluso, c_prodotto, d_cutoff, '!', * from #PE_C1201
		
		print 'Perimetro PE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro PE', getdate() )

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
from #PE_C1201  K where  K.id_script = @IDSCRIPT

if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 

----------------------------------------
--INIZIO Query
----------------------------------------
if object_id('tempdb..#DATA', 'U') is not null drop table #DATA
select pos, d_effetto, d_cutoff into #DATA from #PE_C1201

		print 'Perimetro DATA'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro DATA', getdate() )

if object_id('tempdb..#STATO', 'U') is not null drop table #STATO
select K.pos, S.c_stato, stato=S.descrizione 
into #STATO
from #PE_C1201 K
join Stato S with (nolock) on  ( K.c_stato             like '%'''+S.c_stato+'''%' or K.c_stato is null ) 
                           and ( K.c_stato_escluso not like '%'''+S.c_stato+'''%' or K.c_stato_escluso is null )
create nonclustered index IXT_STATO on #STATO ( pos )

		print 'Perimetro STATO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro STATO', getdate() )


if object_id('tempdb..#PROD', 'U') is not null drop table #PROD
select K.pos, K.f_raggruppa_prodotto, E.c_compagnia, E.c_prodotto, E.c_Tipo_GestioneProdotto, E.c_ramo_ministeriale, c_gestione = ISNULL(E.c_Tipo_GestioneProdotto,E.c_ramo_ministeriale) 
into #PROD
from #PE_C1201 K
join Prodotto E with (nolock) on  ( K.c_prodotto                          like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto is null                      or ''''+E.c_prodotto+'''' like K.c_prodotto) 
                              and ( K.c_prodotto_escluso              not like '%'''+RTRIM(E.c_prodotto)+'''%'                  or K.c_prodotto_escluso is null              )
                              and ( K.c_Tipo_GestioneProdotto             like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_Tipo_GestioneProdotto is null         ) 
							  and ( K.c_tipo_GestioneProdotto_escluso not like '%'''+isnull(E.c_Tipo_GestioneProdotto,'')+'''%' or K.c_tipo_GestioneProdotto_escluso is null )
							  and ( ''''+E.c_prodotto+''''            not like K.c_prodotto_escluso                             or K.c_prodotto_escluso is null              )
                              and ( K.c_ramo_ministeriale                 like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale is null             ) 
							  and ( K.c_ramo_ministeriale_escluso     not like '%'''+E.c_ramo_ministeriale+'''%'                or K.c_ramo_ministeriale_escluso is null     )
create nonclustered index IX_tmpPROD on #PROD ( c_compagnia, c_prodotto, pos )
create nonclustered index IXT_PROD2 on #PROD ( pos )

		print 'Perimetro PRODOTTO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro PRODOTTO', getdate() )


if object_id('tempdb..#POL', 'U') is not null drop table #POL
select D.pos, A.c_compagnia, A.c_prodotto, A.n_polizza, A.n_posizione
into #POL
from #PROD          D
join Polizza        A with (nolock) on A.c_compagnia=D.c_compagnia and A.c_prodotto=D.c_prodotto /* TOKEN_WHERE */
join StoricoPolizza S with (nolock) on S.c_compagnia=A.c_compagnia and S.n_polizza=A.n_polizza and S.n_posizione=A.n_posizione and S.d_inizio <= getdate() and S.d_fine > getdate() 
join #STATO         T               on T.pos=D.pos and T.c_stato=S.c_stato
--where P.n_polizza in ( 50000000451 ) 

		print 'Perimetro POLIZZA'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro POLIZZA', getdate() )
		

if object_id('tempdb..#TIPOT', 'U') is not null drop table #TIPOT
select K.pos, T.c_tipo_titolo, tipoTitolo=T.descrizione
into #TIPOT
from #PE_C1201 K
join TipoTitolo T with (nolock) on (K.c_tipo_titolo is null or K.c_tipo_titolo like '%'''+T.c_tipo_titolo+'''%' )

		print 'Perimetro TIPOT'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro TIPOT', getdate() )


if object_id('tempdb..#TIT', 'U') is not null drop table #TIT
select	P.pos,T.c_compagnia, T.n_polizza, T.n_posizione,
		T.c_tipo_titolo,T.d_effetto, T.n_progressivo_titolo, T.i_premio_lordo
	

into #TIT
from #POL P
join #DATA           E               on E.pos=P.pos
join Titolo			 T with (nolock) on T.c_compagnia=P.c_compagnia and T.n_polizza=P.n_polizza and T.n_posizione=P.n_posizione and T.d_effetto >= E.d_cutoff
join #TIPOT			 TT on TT.c_tipo_titolo=T.c_tipo_titolo

		print 'Perimetro TITOLO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro TITOLO', getdate() )



if object_id('tempdb..#DETT', 'U') is not null drop table #DETT
select  T.pos, T.c_compagnia, T.n_polizza, T.n_posizione, T.d_effetto,T.n_progressivo_titolo,
		c_tipo_titolo			= max(T.c_tipo_titolo),
		Importolordo_titolo		= max( isnull(T.i_premio_lordo,0) ) ,
		Imposta_titolo			= sum( isnull(D.i_imposta,0) ),
		Importonetto_dettaglio	= sum( isnull(D.i_premio_netto,0) )
into #DETT
from #TIT T
join DettaglioTitolo D with (nolock) on D.c_compagnia=T.c_compagnia and D.n_polizza=T.n_polizza and D.n_posizione=T.n_posizione and D.d_effetto=T.d_effetto and D.n_progressivo_titolo=T.n_progressivo_titolo
group by T.pos, T.c_compagnia, T.n_polizza, T.n_posizione, T.d_effetto,T.n_progressivo_titolo

		print 'Perimetro DETTAGLIOTITOLO'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro DETTAGLIOTITOLO', getdate() )

	----------------------------------------
	-- ESTR 
	--


	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000); select @AREACONTROLLO = case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end + case when c_garanzia is not null                then 'GARANZIA ' else '' end from #PE_C1201  K if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 
	if object_id('tempdb..#ESTR_C1201', 'U') is not null drop table #ESTR_C1201
	select K.pos, K.nome_kpi, K.kpi, K.c_Tipo_GestioneProdotto, K.f_raggruppa_prodotto, K.c_tipo_liquidazione,D.Importolordo_titolo,D.Imposta_titolo,D.Importonetto_dettaglio,
			Netto_Imposte = D.Imposta_titolo + D.Importonetto_dettaglio,K.tolleranza,
		   c_garanzia                 = NULL,																																  
		   c_tipo                     = D.c_tipo_titolo,
		   c_gestione                 = isnull(C.c_Tipo_GestioneProdotto,C.c_ramo_ministeriale),
		   d_controllo                = cast( getdate() as date),
		   esito                      = @ESITOOK,  
		   tipoesito                  = cast( NULL as varchar(22)),  
		   c_prodotto                 = C.c_prodotto,
		   n_parametro                = D.n_polizza,
		   informazioni_aggiuntive    = D.n_progressivo_titolo ,
		   oggetto_squadratura        = D.c_tipo_titolo
	into #ESTR_C1201
	from #PE_C1201             K
	join #PROD		 C on K.pos = C.pos
	join #POL		 P on K.pos = P.pos and C.c_prodotto = P.c_prodotto and C.c_compagnia = P.c_compagnia
	join #DETT		 D on K.pos = D.pos and D.n_polizza = P.n_polizza and D.c_compagnia = P.c_compagnia and D.n_posizione = P.n_posizione

			print 'Perimetro #ESTR_C1201'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro #ESTR_C1201', getdate() )

	----------------------------------------
	--Esito  
	--
	update #ESTR_C1201 set esito =  @ESITOKO,tipoesito = 'KO' where abs(Importolordo_titolo) - abs(Netto_Imposte) > tolleranza 

			print 'Perimetro UPDATE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro UPDATE', getdate() )

/*
	select perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1201 order by perc, num desc
	--2721316

	--STORNO
	select c_motivo_storno, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1201 group by c_motivo_storno  order by perc, num desc
	
	--garanzia
	select c_garanzia, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1201 group by c_garanzia  order by perc, num desc

	--MOD
	select c_modalita_pagamento, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1201 group by c_modalita_pagamento  order by perc, num desc

	--TIPO
	select oggetto_squadratura, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1201 group by oggetto_squadratura  order by perc, num desc

	--ANNO
	select year(c_tipo), month(c_tipo), perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1201 group by year(c_tipo), month(c_tipo)   order by year(c_tipo), month(c_tipo)

	--PRODOTTO
	select c_prodotto, c_gestione, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR_C1201 group by c_prodotto, c_gestione  order by perc, num desc
	
	select 'KO', * from #ESTR_C1201 where esito = 'KO' and c_prodotto like 'PUG35' order by d_effetto desc


--oggetto_squadratura e informazioni aggiuntive continuano con valori errati, 
inoltre effettuando un test sulla polizza 50000000451 il rapporto tra (lordo+imposte) - (netto) = 0 per n_progressivo = 1 
non  dovrebbe risultare nei KO.

i valori che abbiamo preso in considerazione sono  
titolo.i_premio_lordo = 100


dettagliotitolo.i_prestazione_base+dettagliotitolo.i_commissione_variabile+i_commissione_fissa = 87,75 + 10,00 + 2,25

select '#ESTR_C1201', n_parametro, informazioni_aggiuntive, oggetto_squadratura, esito, ImportoLordo_titolo, Imposta_titolo, netto_imposte, Importonetto_dettaglio from #ESTR_C1201 where n_parametro = 50000000451 and informazioni_aggiuntive = 1
select '#TIT', * from #TIT  where n_polizza = 50000000451 and n_progressivo_titolo = 1
select '#DETT', * from #DETT where n_polizza = 50000000451 and n_progressivo_titolo = 1
select 'Titolo', n_polizza, n_progressivo_titolo, c_esito, c_tipo_titolo, i_premio_lordo, i_imposta from Titolo where n_polizza = 50000000451 and n_progressivo_titolo = 1 and c_tipo_titolo ='01'
select 'Dettaglio', n_polizza, n_progressivo_titolo, c_garanzia, i_premio_netto from dettagliotitolo where n_polizza = 50000000451 and n_progressivo_titolo=1

select 'Dettaglio', n_polizza, n_progressivo_titolo, c_garanzia, i_prestazione_base, i_commissione_variabile, i_commissione_fissa, * from dettagliotitolo where n_polizza = 50000000451 and n_progressivo_titolo=1

*/


	---------------------------------------
	--Output

	--
	--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000) = 'TUTTO IL PORTAFOGLIO'
	--declare @TAB varchar(75) = 'Titolo'
	--declare @COL varchar(75) = 'c_tipo_titolo'
	--select @tab=NULL, @col=NULL from #PE_C1201 where isnull( f_raggruppa_prodotto, '') ='S'

	--declare @IA_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR_C1201%' and C.name = 'informazioni_aggiuntive'   )
	--declare @OS_type varchar(50) = ( select T.name from tempdb..sysobjects O with (nolock) join tempdb..syscolumns C with (nolock) on C.id=O.id	join tempdb..systypes   T with (nolock) on T.xusertype=C.xusertype	where O.name like '#ESTR_C1201%' and C.name = 'oggetto_squadratura'   )

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
	into #Output from #ESTR_C1201 E where E.Esito=@ESITOOK
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
	from #ESTR_C1201 E where Esito=@ESITOKO 
	-----------------------------------------
	--and isnull( E.f_raggruppa_prodotto, '') <>'S'
	--if ( select count(*) from #PE_C1201 where f_raggruppa_prodotto ='S' ) > 0
	--	insert into #OutPut ( nome_controllo, id_controllo, area_controllo, c_gestione, d_controllo, esito,    livello_aggregazione, c_prodotto, n_conteggio  )
	--	select                nome_kpi,       kpi,          @AREACONTROLLO, c_gestione, d_controllo, @ESITOKO, @AGGREGAZIONE,        c_prodotto, count(E.n_parametro)  
	--	from #ESTR_C1201 E
	--	where E.Esito=@ESITOKO and E.f_raggruppa_prodotto ='S'
	--	group by nome_kpi, kpi, d_controllo, c_gestione, c_prodotto
	-----------------------------------------
				print 'Perimetro OUTPUT'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro OUTPUT', getdate() )


	select * from #Output Z order by Z.ESITO desc, n_parametro 

				print 'Perimetro FINE'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro FINE', getdate() )


-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- select  'if object_id(''tempdb..'+name+''', ''U'') is not null drop table '+name from ( select name=replace(replace(replace(left(name,50),'#ESTR_P0202_P0702_P0701_P0801_P0802_P0901_P0403_','$$'),'_',''),'$$','#ESTR_P0202_P0702_P0701_P0801_P0802_P0901_P0403_')  from tempdb..sysobjects O with (nolock) where name not like '##%' ) O where name not in ('#PE_P1403', '#OUTPUT', '#STATO', '#TIPOLIQ', '#STATOPRAT', '#PROD' )
if object_id('tempdb..#POL', 'U') is not null drop table #POL
if object_id('tempdb..#TIPOT', 'U') is not null drop table #TIPOT
if object_id('tempdb..#TIT', 'U') is not null drop table #TIT
if object_id('tempdb..#DETT', 'U') is not null drop table #DETT
if object_id('tempdb..#ESTRC1201', 'U') is not null drop table #ESTR_C1201
if object_id('tempdb..#PEC1201', 'U') is not null drop table #PE_C1201
if object_id('tempdb..#DATA', 'U') is not null drop table #DATA

			print 'Perimetro CANC_TEMP'; print convert( varchar(23), getdate(), 121); insert into ##RPL_DEBUG_C1201(n, d) values ('Perimetro CANC_TEMP', getdate() )
