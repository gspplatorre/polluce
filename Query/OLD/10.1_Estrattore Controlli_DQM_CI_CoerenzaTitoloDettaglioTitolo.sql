-----------------------------------------------------------------------
-------  10.1 Coerenza Titolo e dettagliotitolo	Titolo e dettagliotitolo controllo di coerenza degli importi di Premio e provvigioni per tipo Titolo
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


if ( select count(*) from #PE ) = 0 
begin
       insert into #PE (n_progressivo, area_logica, tipo_kpi,   interfaccia, nome_kpi, kpi,   f_bloccante, id_script, c_Tipo_GestioneProdotto, c_Tipo_GestioneProdotto_escluso, c_ramo_ministeriale,  f_raggruppa_prodotto, c_prodotto,d_Effetto,c_attivita,c_prodotto_escluso, c_ramo_ministeriale_escluso,c_garanzia,c_garanzia_esclusa) 
                   values (     1,       'Query',      'Universo', 'Pagamento', 'UNI',    1000, 'N',          @IDSCRIPT, NULL,                    NULL,                            NULL,                'N',                  NULL,      NULL,      NULL,     NULL,								NULL,						NULL,		NULL)
    

end


update #PE set c_stato = '0' where c_stato is null
update #PE set c_tipo_titolo = '02' where c_tipo_titolo is null



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
select	K.pos, K.d_effetto, K.c_stato_pratica, K.c_stato, K.c_tipo_titolo, 
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


if object_id('tempdb..#POL', 'U') is not null drop table #POL
select	D.pos, D.c_Tipo_GestioneProdotto, D.c_ramo_ministeriale, D.c_tipo_titolo, 
		P.c_compagnia, P.c_prodotto, P.n_polizza, P.n_posizione, n_prog = row_number() over (partition by P.c_prodotto order by P.d_effetto_polizza desc )
into #POL
from #PROD D
join Polizza P with (nolock) on P.c_compagnia=D.c_compagnia and P.c_prodotto=D.c_prodotto
join StoricoPolizza S with (nolock) on S.c_compagnia=P.c_compagnia and S.n_polizza=P.n_polizza and S.n_posizione=P.n_posizione 
									and S.c_stato=D.c_stato
									and S.d_inizio <= getdate() and S.d_fine > getdate() 



if object_id('tempdb..#TIPOT', 'U') is not null drop table #TIPOT
select K.pos, T.c_tipo_titolo, tipoTitolo=T.descrizione
into #TIPOT
from #PE K
join TipoTitolo T with (nolock) on (K.c_tipo_titolo is null or T.c_tipo_titolo = K.c_tipo_titolo )



if object_id('tempdb..#TIT', 'U') is not null drop table #TIT
select	P.pos, P.c_Tipo_GestioneProdotto, P.c_ramo_ministeriale,
		T.c_compagnia, T.n_polizza, T.n_posizione, P.c_prodotto,
		T.c_tipo_titolo, T.c_esito,	T.d_effetto, T.n_progressivo_titolo, T.c_motivo_storno, T.i_premio_lordo, T.i_imposta,
		T.i_provvigione_incasso, T.i_provvigione_acquisto, 
		T.i_commissione_recesso, T.i_commissione_variabile, T.i_commissione_fissa
into #TIT
from #POL P
join Titolo			 T with (nolock) on T.c_compagnia=P.c_compagnia and T.n_polizza=P.n_polizza and T.n_posizione=P.n_posizione
join #TIPOT			 TT on TT.c_tipo_titolo=T.c_tipo_titolo



if object_id('tempdb..#DETT', 'U') is not null drop table #DETT
select  T.pos, T.c_Tipo_GestioneProdotto, T.c_ramo_ministeriale,
		T.c_compagnia, T.n_polizza, T.n_posizione, T.c_prodotto, T.d_effetto, T.n_progressivo_titolo, T.c_tipo_titolo,
		netto_titolo	= max( isnull(T.i_premio_lordo,0) ) - max( isnull(T.i_imposta,0) ),
		netto_dettaglio	= sum( isnull(D.i_premio_netto,0) ),
		provv_titolo    = max( isnull(T.i_provvigione_incasso, 0)+isnull(T.i_provvigione_acquisto, 0)) ,
		provv_dettaglio = sum( isnull(D.i_provvigione_incasso, 0)+isnull(D.i_provvigione_acquisto, 0))
into #DETT
from #TIT T
join DettaglioTitolo D with (nolock) on D.c_compagnia=T.c_compagnia and D.n_polizza=T.n_polizza and D.n_posizione=T.n_posizione and D.d_effetto=T.d_effetto and D.n_progressivo_titolo=T.n_progressivo_titolo
group by T.pos, T.c_Tipo_GestioneProdotto, T.c_ramo_ministeriale, T.c_compagnia, T.n_polizza, T.n_posizione, T.c_prodotto, T.d_effetto, T.n_progressivo_titolo, T.c_tipo_titolo



if object_id('tempdb..#ESTR', 'U') is not null drop table #ESTR
select K.pos, K.nome_kpi, K.kpi, K.c_Tipo_GestioneProdotto, K.f_raggruppa_prodotto, K.c_tipo_liquidazione,C.netto_titolo,C.netto_dettaglio,C.provv_titolo,C.provv_dettaglio,--K.tolleranza,
       c_garanzia                 = NULL,
       c_tipo                     = C.c_tipo_titolo,
       c_gestione                 = isnull(C.c_Tipo_GestioneProdotto,C.c_ramo_ministeriale),
	   d_controllo                = cast( getdate() as date),
       esito                      = @EsitoKo,  
       tipoesito                  = cast( NULL as varchar(22)),  
       c_prodotto                 = C.c_prodotto,
       n_parametro                = C.n_polizza,
	   informazioni_aggiuntive    = cast(round(C.netto_titolo,2) as money) + ' ' + cast(round(C.provv_titolo,2) as money),
       oggetto_squadratura        = cast(round(C.netto_dettaglio,2) as money) + ' ' + cast(round(C.provv_dettaglio,2) as money)
into #ESTR
from #PE             K
join #DETT		 C on K.pos = C.pos


update #ESTR set tipoesito = CASE WHEN netto_titolo = netto_dettaglio and provv_titolo <> provv_dettaglio THEN 'PROVVIGIONI'
									WHEN netto_titolo <> netto_dettaglio and provv_titolo = provv_dettaglio THEN 'PREMI'
									WHEN netto_titolo <> netto_dettaglio and provv_titolo <> provv_dettaglio THEN 'PROVVIGIONI + PREMI' END 

update #ESTR set esito =  @ESITOOK,tipoesito = 'ESATTO' where netto_titolo = netto_dettaglio AND provv_titolo = provv_dettaglio


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







