#define regular "`1234567890-=[];'\,./~!@#$%^&*()_+{}:"|<>?qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"
#define crypt   "`1234567890-=[];'\,./~!@#$%^&*()_+{}:"|<>?qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"

** Прва промена
** branch developZorica
oXXX=NewIHRReplikator()
** Втора промена
** branch master

PROCEDURE NewIHRReplikator()
	SET PROCEDURE TO sys_aux, config ADDITIVE 
	RETURN CREATEOBJECT('EIHRREPLIKATOR')
ENDPROC 
<<<<<<< HEAD
** Трета промена
** od kompjuterot na Eleonora vo cloned repository

=======

** Трета промена од мастер
** има нов корисник дали ќе се види таму проментата
>>>>>>> d1c2f6e838a6bb3311f011f08eb6887f3d58d51b
DEFINE CLASS eIHRReplikator as ReplicatorProcess
processname = 'IHRPROC'
inipath = ''

prmconn = .f. 
prm = .f.

masterconn = .f.
scm = .f. && masterconnstr
slaveconn = .f.
scs = .f. && slaveconnstr

checkinterval = 0
bsid = ''
debugsqlon = 0
maxlogsize = 1024000
logpfx = 'logihrproc'
logfile = ''
logpath = ''
ntrs = 0 && obidi za konekcija 
debugon = 1
waittime = 15
denoviunazad=5
DOWEB_kolku_bazi = 1
pla_tip=''


** да се стави варијабла од cnf дали да се извршува F2Bihr
** да се провери дали e потребна трансакција и дали валидно се менаџира истата

	PROCEDURE Init
	PRIVATE ALL 
		this.processname = JUSTSTEM(SYS(16,0))
		ADDPROPERTY(application, this.processname, this)			
		DODEFAULT()
		
		IF !EMPTY(this.debugon)
			_screen.Visible = .t.
		ENDIF 
		
		**** конекциja со wra за прм
		this.prmconn = newconnect()
		this.prm = this.decrypt(this.prm)
		this.prmconn.setconnstr(this.prm)
		******  
		
		****** ако се конектира со wra се зема цела табела
		this.logit('OK INIT PRM: ENTER')
		IF !isnumeric(this.ntrs) OR  EMPTY(this.ntrs)
			this.logit('NODEF NTRS')
			RETURN 
		ENDIF		
		
		FOR i = 1 TO this.ntrs
			nPrmHnd = this.prmconn.connect()
			IF nPrmHnd > 0
				
				cCmdsel = "select * from prm "
				
				nOk = SQLEXEC(nPrmHnd , cCmdsel, 'PRM')
				IF nOk > 0
					this.logit('OK INIT: PRM tabela')
					EXIT 
				ELSE					
					this.logit('ERR INIT: PRM tabela-'+TRANSFORM(i))
					this.logsqlerror()
				ENDIF 
								
			ELSE				
				this.logit('ERR INIT: NO CONN PRM '+TRANSFORM(i)+'/'+TRANSFORM(this.ntrs))
				this.logsqlerror()
			ENDIF 
		ENDFOR
		
		IF nPrmHnd < 1
			this.logit('ERR INIT: PRM CONN NOK')
			RETURN 
		ENDIF 
		
		IF nOk < 1
			this.logit('ERR INIT: PRM NOK')
			this.prmconn.Disconnect()
			RETURN 
		ENDIF 
		
		**** конекции за scm i scs
		SELECT prm
		GO TOP 
		LOCATE FOR cod = 'scm'
		IF FOUND('prm')
			this.scm = ALLTRIM(prm.valc)
			this.masterconn = newconnect()
			this.scm = this.decrypt(this.scm)
			this.masterconn.setconnstr(this.scm)
			this.logit('INIT: PRM scm conn')
		ELSE
			this.logit('ERR INIT: PRM scm')
			this.prmconn.Disconnect()
			RETURN 
		ENDIF 
				
		SELECT prm
		GO TOP 
		LOCATE FOR cod = 'scs'
		IF FOUND('prm')
			this.scs = ALLTRIM(prm.valc)
			this.slaveconn = newconnect()
			this.scs = this.decrypt(this.scs)
			this.slaveconn.setconnstr(this.scs)
			this.logit('INIT: PRM scs conn')
		ELSE
			this.logit('ERR INIT: PRM scs')
			this.prmconn.Disconnect()
			RETURN 
		ENDIF 
		
		*** колки денови наназад да пресметува
		SELECT prm
		GO TOP 
		LOCATE FOR cod = 'denoviunazad'
		IF FOUND('prm')
			this.denoviunazad = prm.valn
			this.logit('INIT: PRM denoviunaza')
		ELSE
			this.logit('ERR INIT: PRM denoviunazad')
			this.prmconn.Disconnect()
			RETURN 
		ENDIF 
		
		*** кои pla_tip да ги зема
		SELECT prm
		GO TOP 
		LOCATE FOR cod = 'pla_tip'
		IF FOUND('prm')
			this.pla_tip = ALLTRIM(prm.valc)
			this.logit('INIT: PRM pla_tip')
		ELSE
			this.logit('ERR INIT: PRM pla_tip')
			this.prmconn.Disconnect()
			RETURN 
		ENDIF 
		
		**** колку бази и конекции за нив
		SELECT prm
		GO TOP 
		LOCATE FOR cod = 'DOWEB_kolku_bazi'
		IF FOUND('prm')
			kolku_bazi = prm.valn
			this.logit('INIT: PRM DOWEB_kolku_bazi')
		ELSE
			this.logit('ERR INIT: PRM DOWEB_kolku_bazi')
			this.prmconn.Disconnect()
			RETURN 
		ENDIF 

		FOR i=1 TO kolku_bazi
			xscm = 'scm'+ALLTRIM(STR(i))
			xscs = 'scs'+ALLTRIM(STR(i))
			ADDPROPERTY(this,xscm,'')
			ADDPROPERTY(this,xscs,'')
			
			xmasterconn = 'masterconn'+ALLTRIM(STR(i))
			xslaveconn = 'slaveconn'+ALLTRIM(STR(i))
			
			ADDPROPERTY(this,xmasterconn,'')
			ADDPROPERTY(this,xslaveconn,'')
			
			*** master na sekoja baza
			SELECT prm 
			GO TOP 
			LOCATE FOR cod = xscm
			IF FOUND('prm')
				this.&xscm = ALLTRIM(prm.valc)
				this.&xmasterconn = newconnect()
				this.&xscm = this.decrypt(this.&xscm)
				this.&xmasterconn..setconnstr(this.&xscm)
				this.logit('INIT: OK PRM scm'+STR(i))
			ELSE
				this.logit('ERR INIT: PRM scm'+STR(i))
				this.prmconn.Disconnect()
				RETURN 
			ENDIF 

			*** slave na sekoja baza
			SELECT prm
			GO TOP  
			LOCATE FOR cod = xscs
			IF FOUND('prm')
				this.&xscs = ALLTRIM(prm.valc)
				this.&xslaveconn  = newconnect()
				this.&xscs = this.decrypt(this.&xscs)
				this.&xslaveconn..setconnstr(this.&xscs)
			ELSE
				this.logit('ERR INIT: PRM scs'+STR(i))
				this.prmconn.Disconnect()
				RETURN 
			ENDIF 

		ENDFOR 
		
		
		WAIT TIMEOUT this.waittime
		IF this.ProcessRunning()
			RETURN 
		ENDIF 
		
		this.startprocess()
	ENDPROC 	
	
	PROCEDURE oTimer.timer
	PRIVATE ALL 
		this.parent.Stoptimer()	
		*** за табела промет
		isOK = this.parent.webreports_promet()
		** за табела орг_пла
		isOk = this.parent.webreports_orgpla()
		** за табела iskoristenost
		isOk = this.parent.web_iskoristenost()
		
		this.parent.Starttimer()
	ENDPROC 
	
	PROCEDURE webreports_promet
	PRIVATE ALL
		
		FOR i = 1 TO this.DOWEB_kolku_bazi  
			** за секоја база посебна конекција, посебен селект и инсерт 
			
			xmasterconn = 'masterconn'+ALLTRIM(STR(i))
			xslaveconn = 'slaveconn'+ALLTRIM(STR(i))
			
			nMasterHnd = this.&xmasterconn..connect()
			nSlaveHnd = this.&xslaveconn..connect()
			
			ndays = TRANSFORM(this.denoviunazad)
			npla_tip = this.pla_tip
			
			cInsertCmd = " INSERT INTO promet (datum, grupa_e, org_e, mdl, iznos) "+; 
					" VALUES (?xdatum, ?xgrupa_e, ?xorg_e, ?xmdl, ?xiznos) "
						
			
			cSelectCmd = " SELECT datum, hed11 as grupa_e, hed21 as org_e, hed31 as mdl, SUM(cen) as iznos " + ;
						"FROM " + ;
						"(SELECT grpsee.cod as hed11 , ifnull(grpsee.dsc,'') as hed12 , fsmgen.see_cod as hed21 , "+;
						"IFNULL(see.dsc,'') as hed22 , fsmgen.mdl_cod as hed31 , ifnull(mdl.dsc,'') as hed32 ,  " + ;
						"SUM(FSMITM.CEN) AS CEN, SUM(FSMITM.DDVI) AS DDVI ,fsmgen.rod_odat as datum  " + ;
						"FROM FSMGEN  " + ;
						"INNER JOIN FSMITM  " + ;
						"ON FSMGEN.SM = FSMITM.SM AND FSMGEN.BR=FSMITM.BR AND FSMGEN.PLA_COD=FSMITM.PLA_COD " + ;
						"AND FSMGEN.PLA_RBR=FSMITM.PLA_RBR AND FSMGEN.MDL_COD = FSMITM.MDL_COD  " + ;
						"LEFT JOIN MDL ON FSMGEN.MDL_COD = MDL.COD  " + ;
						"LEFT JOIN SEE ON FSMGEN.SEE_COD = SEE.COD  " + ;
						"LEFT JOIN GRPSEE ON SEE.GRUPA_EE = GRPSEE.COD   " + ;
						"WHERE FSMGEN.PLA_COD not in " + npla_tip + ;
						"AND rod_odat > date_sub(curdate(),INTERVAL ?ndays day) " + ;
						"GROUP BY fsmgen.rod_odat, grpsee.cod, fsmgen.see_cod, fsmgen.mdl_cod ) as a " + ;
						"LEFT JOIN mdl ON a.hed31=mdl.cod " + ;
						"GROUP BY datum,hed11,hed12,hed22,hed31 "

		
			nOk = SQLEXEC(nMasterHnd, cSelectCmd , 'web')
			IF nOk < 1				
					this.logit('ERR webreports_promet: cSelectCmd '+TRANSFORM(this.DOWEB_kolku_bazi))
					this.logsqlerror()
			ENDIF 
			
			vrti = PADL(ALLTRIM(str(this.DOWEB_kolku_bazi)),2,'0')
			** во промет ги бришеме само тие што се од интервалот 
			cCMDdel ="DELETE FROM promet WHERE grupa_e = ?vrti  AND "+;
					"((mdl in (SELECT cod FROM wra.mdl WHERE dsc_lg='1')) OR "+;
					"( not mdl in (SELECT cod FROM wra.mdl WHERE dsc_lg='1') "+;
					" AND org_e in (select cod from see where grupa_ee = ?vrti ))) "+;
					 " AND datum > date_sub(curdate(),INTERVAL ?ndays day)"
					 
			dOK = SQLEXEC(nSlaveHnd,cCMDdel)
			IF dOk < 1				
					this.logit('ERR webreports_promet: cCMDdel -'+vrti)
					this.logsqlerror()
			ENDIF 
			
			SELECT web
			GO TOP 
			SCAN ALL
				
				xdatum = web->datum
				xgrupa_e = web->grupa_e
				xorg_e = web->org_e
				xmdl = web->mdl
				xiznos = web->iznos
				
				&&this.Opentransaction(nSlaveHnd)
				nSok = SQLEXEC(nSlaveHnd, cInsertCmd)
				
				IF nSok < 1				
					this.logit('ERR webreports_promet: INS SLAVE - '+vrti)
					this.logsqlerror()
					LOOP
				ENDIF 			
							
			ENDSCAN
			
			this.logit('OK webreports_promet: DONE - '+vrti)
			this.&xslaveconn..Disconnect()
			this.&xmasterconn..Disconnect()
			
			IF USED('web')
				SELECT web
				USE
			ENDIF 
		ENDFOR 

		IF USED('web')
			SELECT web
			USE
		ENDIF 
		
	ENDPROC 
	
	
	PROCEDURE webreports_orgpla
	PRIVATE ALL
	
		FOR i = 1 TO this.DOWEB_kolku_bazi  
			** за секоја база посебна конекција, посебен селект и инсерт 
			
			xmasterconn = 'masterconn'+ALLTRIM(STR(i))
			xslaveconn = 'slaveconn'+ALLTRIM(STR(i))
			
			nMasterHnd = this.&xmasterconn..connect()
			nSlaveHnd = this.&xslaveconn..connect()
			
			ndays = TRANSFORM(this.denoviunazad)
			
			cInsertCmd = "INSERT INTO org_pla (org_e, tip_pla, datum, iznos) "+;
				" VALUES(?xorg_e, ?xtip_pla, ?xdatum,?xiznos) "
						
			
			cSelectCmd="SELECT fsmgen.see_cod as org_e,fsmgen.pla_cod as tip_pla, rod_odat as datum, SUM(izn_pla) as iznos " + ;
	 			" FROM fsmgen  "+;
				" WHERE fsmgen.pla_cod <> '' and rod_odat > date_sub(curdate(),INTERVAL ?ndays day)  " + ;
	 			" GROUP BY fsmgen.see_cod, fsmgen.pla_cod, rod_odat "+;
	 			" ORDER BY datum  "
		
			nOk = SQLEXEC(nMasterHnd, cSelectCmd , 'orgpla')
			IF nOk < 1				
					this.logit('ERR webreports_orgpla: cSelectCmd '+TRANSFORM(this.DOWEB_kolku_bazi))
					this.logsqlerror()
			ENDIF 
			
			vrti = PADL(ALLTRIM(str(this.DOWEB_kolku_bazi)),2,'0')
			** во org_pla ги бришеме само тие што се од интервалот 
			cCMDdel ="DELETE FROM org_pla WHERE org_e in (select cod from see where grupa_ee = ?vrti)  "+;
				" AND datum > date_sub(curdate(),INTERVAL ?ndays day)"
					 
			dOK = SQLEXEC(nSlaveHnd,cCMDdel)
			IF dOk < 1				
					this.logit('ERR webreports_orgpla: cCMDdel -'+vrti)
					this.logsqlerror()
			ENDIF 
			
			SELECT orgpla
			GO TOP 
			SCAN ALL
		
				xorg_e = orgpla->org_e
				xtip_pla = orgpla->tip_pla
				xdatum = orgpla->datum
				xiznos = orgpla->iznos
			
				nSok = SQLEXEC(nSlaveHnd, cInsertCmd)
			
				IF nSok < 1				
					this.logit('ERR webreports_orgpla: INS SLAVE')
					this.logsqlerror()
					LOOP
				ENDIF 			
			ENDSCAN
			
			this.logit('OK webreports_orgpla: DONE - '+vrti)
			this.&xslaveconn..Disconnect()
			this.&xmasterconn..Disconnect()
			
			IF USED('orgpla')
				SELECT orgpla
				USE
			ENDIF 
		ENDFOR 

		IF USED('orgpla')
			SELECT orgpla
			USE
		ENDIF 
	ENDPROC 
	
	PROCEDURE web_iskoristenost
	PRIVATE ALL
	
		FOR i = 1 TO this.DOWEB_kolku_bazi  
			** за секоја база посебна конекција, посебен селект и инсерт 
			
			xmasterconn = 'masterconn'+ALLTRIM(STR(i))
			xslaveconn = 'slaveconn'+ALLTRIM(STR(i))
			
			nMasterHnd = this.&xmasterconn..connect()
			nSlaveHnd = this.&xslaveconn..connect()
			
			ndays = TRANSFORM(this.denoviunazad)
			vrti = PADL(ALLTRIM(str(this.DOWEB_kolku_bazi)),2,'0')
				
			cInsertCmd = "INSERT INTO iskoristenost(grupa_e, datum, vk_sobi, isk_sobi) "+;
					" VALUES(?xgrupa_e, ?xdatum, ?xvk_sobi, ?xisk_sobi) "
				
			cCMDdel = "DELETE FROM iskoristenost where grupa_e=?vrti and datum >= date_sub(curdate(),INTERVAL ?ndays day)"					

			Dok = SQLEXEC(nSlaveHnd, cCMDdel)					
			IF Dok < 1				
				this.logit('ERR web_iskoristenost: cCMDdel- '+vrti)
				this.logsqlerror()
			ENDIF 			
				
			today=DATE()
			do_datum=DATE()- this.denoviunazad
				
			DO WHILE do_datum<=today
				
				cDatum = do_datum
				cDatumNext=cDatum + 1

				cSelectCMD = "SELECT tabela1.datum, vk_sobi,isk_sobi "+;
					" FROM ((SELECT ?cDatum as datum, COUNT(cod) as vk_sobi FROM resgen WHERE restip_cod IN (SELECT cod FROM restip WHERE issoba)) as tabela1 " + ;
					" LEFT JOIN (SELECT ?cDatum as datum, COUNT(distinct res_cod1) as isk_sobi FROM recitm " + ;
					" WHERE ((dat_od<=?cDatum AND dat_do>=?cDatumNext AND dat_od<>dat_do) OR " + ;
					" (dat_do=?cDatumNext AND dat_od<>dat_do)) AND usl_cod='700') as Tabela2 "+;
					" ON Tabela1.datum=Tabela2.datum)"
							
				nOk = SQLEXEC(nMasterHnd, cSelectCMD, 'web')					
				IF nOk < 1				
					this.logit('ERR web_iskoristenost: cSelectCMD -'+vrti)
					this.logsqlerror()
				ENDIF
						
				cCMDgrp = "SELECT cod FROM grpsee WHERE cod= ?vrti "
				sOK = SQLEXEC(nSlaveHnd, cCMDgrp , 'grp_e') 
				IF sOK < 1				
					this.logit('ERR web_iskoristenost: cCMDgrp -'+vrti)
					this.logsqlerror()
				ENDIF
						
						
				SELECT web
				GO TOP 
				SCAN ALL
						
					xgrupa_e = grp_e->cod
					xdatum = web->datum
					xvk_sobi = web->vk_sobi
					xisk_sobi = web->isk_sobi
							
					nSok = SQLEXEC(nSlaveHnd, cInsertCmd)
							
					IF nSok < 1				
						this.logit('ERR web_iskoristenost: INS SLAVE')
						this.logsqlerror()
						LOOP
					ENDIF 			
										
				ENDSCAN
						
				do_datum=do_datum+1
				IF USED('web')
					SELECT web
					USE
				ENDIF 
				
			ENDDO
				
			this.logit('OK web_iskoristenost: DONE - '+vrti)
			this.&xmasterconn..disconnect()
			this.&xslaveconn..disconnect()
			IF USED('web')
				SELECT web
				USE
			ENDIF 
		ENDFOR 
	
	ENDPROC 

ENDDEFINE 