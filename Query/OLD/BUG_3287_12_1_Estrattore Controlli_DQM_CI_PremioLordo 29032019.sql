-----------------------------------------------------------------------
-------  12.1 premio netto+imposte = premio lordo (sul multiramo il premio netto è ottenuto cumulando le garanzie)
-----------------------------------------------------------------------

----------------------------------------
--Configurazione ID script
----------------------------------------
Declare @IDSCRIPT as integer=37

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
if not exists (select 1 from sys.syscolumns where object_name(id)='ParametrizzazioneEstrazioni' and name='d_cutoff')                    alter table #PE     add d_cutoff date null



if ( select count(*) from #PE ) = 0 
begin
       insert into #PE (n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante, id_script, c_Tipo_GestioneProdotto, c_Tipo_GestioneProdotto_escluso, c_ramo_ministeriale,  f_raggruppa_prodotto, c_prodotto,d_Effetto,c_attivita,c_prodotto_escluso, c_ramo_ministeriale_escluso,c_garanzia,c_garanzia_esclusa,d_cutoff) 
                   values (     1,       'Query',      'Universo', 'Pagamento', 'UNI',    1000, 'N',          @IDSCRIPT, NULL,                    NULL,                            NULL,                'N',                  NULL,      NULL,      NULL,     NULL,								NULL,						NULL,		NULL,'2006-05-01')
    
      

end


update #PE set c_stato = case	when len(c_stato) = 1 then '''' + c_stato + '''' 
								when c_stato is null then '''0''' end 

update #PE set d_cutoff = '2006-05-01' where d_cutoff is null 

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
if object_id('tempdb..#DATA', 'U') is not null drop table #DATA
select pos, d_effetto, d_cutoff into #DATA from #PE

if object_id('tempdb..#STATO', 'U') is not null drop table #STATO
select K.pos, S.c_stato, stato=S.descrizione 
into #STATO
from #PE K
join Stato S with (nolock) on  ( K.c_stato             like '%'''+S.c_stato+'''%' or K.c_stato is null ) 
                           and ( K.c_stato_escluso not like '%'''+S.c_stato+'''%' or K.c_stato_escluso is null )
create nonclustered index IXT_STATO on #STATO ( pos )


if object_id('tempdb..#PROD', 'U') is not null drop table #PROD
select K.pos, E.c_compagnia, E.c_prodotto, E.c_Tipo_GestioneProdotto, E.c_ramo_ministeriale, c_gestione = ISNULL(E.c_Tipo_GestioneProdotto,E.c_ramo_ministeriale) 
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
select D.pos, P.c_compagnia, P.c_prodotto, P.n_polizza, P.n_posizione
into #POL
from #PROD          D
join Polizza        P with (nolock) on P.c_compagnia=D.c_compagnia and P.c_prodotto=D.c_prodotto
join StoricoPolizza S with (nolock) on S.c_compagnia=P.c_compagnia and S.n_polizza=P.n_polizza and S.n_posizione=P.n_posizione and S.d_inizio <= getdate() and S.d_fine > getdate() 
join #STATO         T               on T.pos=D.pos and T.c_stato=S.c_stato



if object_id('tempdb..#TIPOT', 'U') is not null drop table #TIPOT
select K.pos, T.c_tipo_titolo, tipoTitolo=T.descrizione
into #TIPOT
from #PE K
join TipoTitolo T with (nolock) on (K.c_tipo_titolo is null or K.c_tipo_titolo like '%'''+T.c_tipo_titolo+'''%' )



if object_id('tempdb..#TIT', 'U') is not null drop table #TIT
select	P.pos,T.c_compagnia, T.n_polizza, T.n_posizione,
		T.c_tipo_titolo,T.d_effetto, T.n_progressivo_titolo, T.i_premio_lordo
	

into #TIT
from #POL P
join #DATA           E               on E.pos=P.pos
join Titolo			 T with (nolock) on T.c_compagnia=P.c_compagnia and T.n_polizza=P.n_polizza and T.n_posizione=P.n_posizione and T.d_effetto >= E.d_cutoff
join #TIPOT			 TT on TT.c_tipo_titolo=T.c_tipo_titolo



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


--Declare @ESITOOK as varchar(100)='OK'; Declare @ESITOKO as varchar(100)='KO'; Declare @AGGREGAZIONE as varchar(100)='AGGREGAZIONE'; Declare @NESSUNAAGGREGAZIONE as varchar(100)='NESSUNA AGGREGAZIONE'; Declare @AREACONTROLLO as varchar(2000); select @AREACONTROLLO = case when c_Tipo_GestioneProdotto is not null or c_Tipo_GestioneProdotto_escluso is not null     then 'GESTIONE ' else '' end + case when c_ramo_ministeriale is not null       then 'RAMO ' else '' end + case when c_garanzia is not null                then 'GARANZIA ' else '' end from #PE  K if @AREACONTROLLO ='' set @AREACONTROLLO = 'TUTTO IL PORTAFOGLIO' 

if object_id('tempdb..#ESTR', 'U') is not null drop table #ESTR
select K.pos, K.nome_kpi, K.kpi, K.c_Tipo_GestioneProdotto, K.f_raggruppa_prodotto, K.c_tipo_liquidazione,D.Importolordo_titolo,D.Imposta_titolo,D.Importonetto_dettaglio,Netto_Imposte = D.Imposta_titolo + D.Importonetto_dettaglio,
       c_garanzia                 = NULL,																																  
       c_tipo                     = D.d_effetto,
       c_gestione                 = isnull(C.c_Tipo_GestioneProdotto,C.c_ramo_ministeriale),
	   d_controllo                = cast( getdate() as date),
       esito                      = @ESITOOK,  
       tipoesito                  = cast( NULL as varchar(22)),  
       c_prodotto                 = C.c_prodotto,
       n_parametro                = D.n_polizza,
	   informazioni_aggiuntive    = D.n_progressivo_titolo ,
       oggetto_squadratura        = D.c_tipo_titolo
into #ESTR
from #PE             K
join #PROD		 C on K.pos = C.pos
join #POL		 P on K.pos = P.pos and C.c_prodotto = P.c_prodotto and C.c_compagnia = P.c_compagnia
join #DETT		 D on K.pos = D.pos and D.n_polizza = P.n_polizza and D.c_compagnia = P.c_compagnia and D.n_posizione = P.n_posizione



update #ESTR set esito =  @ESITOKO,tipoesito = 'KO' where Importolordo_titolo <> Netto_Imposte 


/*
	select perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR order by perc, num desc
	--2721316

	--STORNO
	select c_motivo_storno, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_motivo_storno  order by perc, num desc
	
	--garanzia
	select c_garanzia, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_garanzia  order by perc, num desc

	--MOD
	select c_modalita_pagamento, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_modalita_pagamento  order by perc, num desc

	--TIPO
	select oggetto_squadratura, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by oggetto_squadratura  order by perc, num desc

	--ANNO
	select year(c_tipo), month(c_tipo), perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by year(c_tipo), month(c_tipo)   order by year(c_tipo), month(c_tipo)

	--PRODOTTO
	select c_prodotto, c_gestione, perc=sum( case when esito='KO' then 100.0 else 0 end) / count(*), KO=sum( case when esito='KO' then 1 else 0 end), NUM=count(*) from #ESTR group by c_prodotto, c_gestione  order by perc, num desc
	
	select 'KO', * from #ESTR where esito = 'KO' and c_prodotto like 'PUG35' order by d_effetto desc

	
*/


----------------------------------------
--Output
----------------------------------------
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

select * from #Output O order by O.ESITO desc



