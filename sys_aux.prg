FUNCTION ISNUMERIC(xVal)
	RETURN VARTYPE(xVal) = 'N'
ENDFUNC 

FUNCTION ISCHAR(xVal)
	RETURN VARTYPE(xVal) = 'C'
ENDFUNC 

FUNCTION ISOBJECT(xObj) 
	RETURN VARTYPE(xObj) = 'O'
ENDFUNC 

PROCEDURE Halt
	ON ERROR 
	ON SHUTDOWN
	CLEAR EVENTS 
	_SCREEN.Hide()
	QUIT
	CLEAR ALL
	RELEASE ALL 
ENDPROC

PROCEDURE PRINTERROR(oParent, xError, xMess, xMess1, xProg, xLine)
PRIVATE ALL 
	oParent.logit('**************************')
	oParent.logit(TRANSFORM(xError))
	oParent.logit(TRANSFORM(xMess))
	oParent.logit(TRANSFORM(xMess1))
	oParent.logit(TRANSFORM(xProg))
	oParent.logit(TRANSFORM(xLine))
	oParent.logit('**************************')
	IF !EMPTY(oParent.autostartonerr)
		cPcsname = oParent.processname
		RUN /n &cPcsname
	ENDIF 
	halt()
ENDPROC

DEFINE CLASS ReplicatorProcess as Custom
processname = 'RPRCSS'
inipath = ''
masterconn = .f.
slaveconn = .f.
scm = .f. && masterconnstr
scs = .f. && slaveconnstr
checkinterval = 0
bsid = ''
maxlogsize = 1024000
logpfx = 'log'
logfile = ''
logpath = ''
ntrs = 0
debugon = .f.
checkprocesscnt = 0
autostartonerr = 1

ADD OBJECT oTimer as Timer

	PROCEDURE Init
	PRIVATE ALL 
		config()
		_screen.Visible = .f.
		ADDPROPERTY(application, 'context', this)
		
		ON ERROR PRINTERROR(application.context, ERROR(), MESSAGE(), MESSAGE(1), PROGRAM(), LINENO())
		ON SHUTDOWN DO HALT
		
		this.inipath = FULLPATH(CURDIR())
		this.readsettings()
				
		this.logpfx = 'log'+this.processname		
		this.logpath = this.inipath +'log\'
		this.logfile = this.logpath + this.logpfx + SYS(2015)
		
	ENDPROC 
	
	PROCEDURE ProcessRunning
	PRIVATE ALL 
		IF EMPTY(this.checkprocesscnt)
			RETURN .f.
		ENDIF 
		nCnt = this.GetProcessCountRunning(this.processname+'.exe')
		RETURN !EMPTY(nCnt-1)
	ENDPROC 
	
	FUNCTION GetProcessCountRunning(tcName)
	PRIVATE ALL 
		LOCAL loLocator, loWMI, loProcesses, loProcess, llIsRunning
		loLocator 	= CREATEOBJECT('WBEMScripting.SWBEMLocator')
		loWMI		= loLocator.ConnectServer() 
		loWMI.Security_.ImpersonationLevel = 3  		&& Impersonate 
		loProcesses	= loWMI.ExecQuery([SELECT * FROM Win32_Process WHERE Name = ']+tcName+['])
		RETURN loProcesses.Count
	ENDFUNC 
	
	PROCEDURE StartProcess()
		this.Starttimer()				
		READ EVENTS
	ENDPROC
	
	PROCEDURE Starttimer
	PRIVATE ALL 
		IF EMPTY(this.checkinterval)
			this.logit('NODEF CHECKINTERVAL')
			RETURN 
		ENDIF 
		this.logit('STARTTIMER')
		this.oTimer.interval = this.checkinterval * 1000
	ENDPROC 
	
	PROCEDURE Stoptimer
		this.logit('STOPTIMER')
		this.oTimer.interval = 0
	ENDPROC 

	PROCEDURE ReadSettings
	PRIVATE ALL 
		IF EMPTY(this.inipath)
			RETURN .f.
		ENDIF 
		
		IF !FILE(this.inipath+this.processname+'.cnf')
			this.logit('NOF '+UPPER(this.processname)+'.CNF')
			RETURN .f.
		ENDIF 
		
		cSettings = FILETOSTR(this.inipath+this.processname+'.cnf')
		nLines = ALINES(aSet, cSettings)
		FOR i = 1 TO nLines
			cSet = ALLTRIM(UPPER(SUBSTR(aSet[i], 1, ATC('=', aSet[i])-1)))
			cVal = ALLTRIM(SUBSTR(aSet[i], ATC('=', aSet[i])+1))
			IF !EMPTY(PEMSTATUS(this, cSet, 5))
				this.&cSet. = &cVal.
			ELSE 
				ADDPROPERTY(this, cSet, &cVal)
			ENDIF 
		ENDFOR 		
		RETURN .t.		
	ENDPROC
	
	PROCEDURE oTimer.timer
	PRIVATE ALL 
	ENDPROC 
		
	PROCEDURE Encrypt(cDecryptedString)
	PRIVATE ALL 
				
		cDecryptedString = ALLTRIM(cDecryptedString)
		cEncryptedString= ""
		
		IF !EMPTY(cDecryptedString)
			FOR i = 1 TO LEN(cDecryptedString)
				cEncryptedString = cEncryptedString + CHR(ASC(SUBSTR(cDecryptedString, i, 1)) - 7)
			ENDFOR 
		ENDIF 
		
		RETURN cEncryptedString
	ENDPROC 
	
	PROCEDURE Decrypt(cEncryptedString)
	PRIVATE ALL 
		cEncryptedString = ALLTRIM(cEncryptedString)
		cDecryptedString = ""
		
		IF !EMPTY(cEncryptedString)
			FOR i = 1 TO LEN(cEncryptedString)
				cDecryptedString = cDecryptedString + CHR(ASC(SUBSTR(cEncryptedString, i, 1)) + 7)
			ENDFOR 
		ENDIF 
		
		RETURN cDecryptedString
	ENDPROC 
	
	PROCEDURE Logit(cMess)
		IF EMPTY(this.logfile)
			IF !EMPTY(this.debugon)
				? 'EMPTY(this.logfile)'
			ENDIF 
			RETURN 
		ENDIF 
		
		IF EMPTY(DIRECTORY(this.logpath, 1))
			MD (this.logpath)
		ENDIF 
		
		nFiles = ADIR(aLogs, this.logfile)
		IF nFiles > 0
			IF aLogs(2) > this.maxlogsize
				this.logfile = this.logpath + this.logpfx + SYS(2015)
			ENDIF 
		ENDIF 
		STRTOFILE(TTOC(DATETIME()) + ': ' + cMess + CHR(13), this.logfile, 1)
		IF !EMPTY(this.debugon)
			? TTOC(DATETIME()) + ': ' + cMess
		ENDIF
	ENDPROC 
	
	PROCEDURE LogSqlerror()
	PRIVATE ALL 
		nErr = AERROR(sqlError)
		IF nErr > 0
			this.logit('******************************')
			this.logit(TRANSFORM(sqlError(1,1)))
			this.logit(TRANSFORM(sqlError(1,2)))
			this.logit(TRANSFORM(sqlError(1,3)))
			this.logit(TRANSFORM(sqlError(1,4)))
			this.logit(TRANSFORM(sqlError(1,5)))
			this.logit(TRANSFORM(sqlError(1,6)))
			this.logit(TRANSFORM(sqlError(1,7)))
			this.logit('******************************')
		ENDIF 
	ENDPROC 
	
	PROCEDURE OpenTransaction(xHandle)
	PRIVATE ALL 
		isOk = SQLEXEC(xHandle, 'START TRANSACTION')
		IF isOk < 1
			this.logsqlerror()
			RETURN .f.
		ENDIF 
		RETURN .t.
	ENDPROC
	
	PROCEDURE Commit(xHandle)
	PRIVATE ALL 
		isOk = SQLEXEC(xHandle, 'COMMIT')
		IF isOk < 1
			this.logsqlerror()
			RETURN .f.
		ENDIF 
		RETURN .t.
	ENDPROC 
	
	PROCEDURE Rollback(xHandle)
	PRIVATE ALL 
		this.logit('ROLLBACK')
		isOk = SQLEXEC(xHandle, 'ROLLBACK')
		IF isOk < 1
			this.logsqlerror()
			RETURN .f.
		ENDIF 
		RETURN .t.
	ENDPROC 
	
ENDDEFINE 


PROCEDURE NEWCONNECT(xConn, oSys)
	RETURN CREATEOBJECT('ConnectionManager', xConn, oSys)
ENDPROC 

DEFINE CLASS ConnectionManager as Session
ConnectStr = ''
oContext = ''
Handle = 0

	PROCEDURE Init(xConn, oContext)
	PRIVATE ALL 
		this.oContext = IIF(ISOBJECT(oContext), oContext, '')
		isOk = this.DownloadFromSys()
	
		DO CASE 
			CASE EMPTY(xConn)
				IF this.isSysLinked()					
					this.Connect()
				ENDIF 
				
			CASE ISCHAR(xConn)
				this.ConnectStr = xConn
				this.Handle = SQLSTRINGCONNECT(xConn)
				
			CASE ISNUMERIC(xConn)
				IF this.TestConnection(xConn)
					this.handle = xConn
				ENDIF 
				
			OTHERWISE
		ENDCASE		
		
		isUpok = this.Uploadtosys()
	ENDPROC 	
	
	PROCEDURE Connect(cStr, toReconnect)
	PRIVATE ALL 	
		DO CASE				
			CASE EMPTY(cStr) AND !EMPTY(this.ConnectStr)
				IF !this.TestConnection()
					this.handle = SQLSTRINGCONNECT(this.ConnectStr)
				ELSE 
					IF  !EMPTY(toReconnect)
						this.Reconnect()
					ENDIF 
				ENDIF 
			
			CASE ISCHAR(cStr)
				this.Disconnect()
				this.ConnectStr = cStr
				this.handle = SQLSTRINGCONNECT(cStr)									
		ENDCASE
		
		IF this.isSysLinked()			
			this.uploadToSys()
		ENDIF 
		
		RETURN this.handle
	ENDPROC 
	
	PROCEDURE SetConnstr(cStr)
	PRIVATE ALL 
		IF EMPTY(cStr)
			RETURN .f.
		ENDIF 
		IF !ISCHAR(cStr)
			RETURN .f.
		ENDIF 
		this.connectstr = ALLTRIM(cStr)
		RETURN .t.
	ENDPROC 
	
	PROCEDURE Reconnect()
		this.disconnect()
		this.handle = SQLSTRINGCONNECT(this.ConnectStr)
		RETURN this.handle
	ENDPROC 
	
	
	PROCEDURE Disconnect(xConn, isForce)
	PRIVATE ALL 	
		IF this.TestConnection(xConn)
		
			IF this.isSysLinked()
				IF !EMPTY(isForce)
					SQLDISCONNECT(this.handle)
					this.handle = 0
					this.Uploadtosys()
				ENDIF 
			ELSE 
				IF EMPTY(xConn)
					xConn = this.Handle
					this.Handle = 0
				ENDIF 
				SQLDISCONNECT(xConn)
			ENDIF
			 			
		ELSE 
			this.Handle = 0	
		ENDIF				
		RETURN .t.
	ENDPROC 
	
	
	PROCEDURE TestConnection(xConn)
	PRIVATE ALL 	
		isConnected = .t.
		nCount = ASQLHANDLES(aConns)
		DO CASE
			CASE EMPTY(nCount)
				isConnected = .f.
				
			CASE EMPTY(xConn)
				*isConnected = !EMPTY(ASCAN(aConns, this.handle))
				IF this.handle > 0
					nOk = SQLEXEC(this.handle, "select 1", "TC0013621")				
					isConnected = !EMPTY(nOk > 0)
				ELSE 
					isConnected = .f.
				ENDIF 
				
				
			CASE !EMPTY(xConn) AND ISNUMERIC(xConn)
				*isConnected = !EMPTY(ASCAN(aConns, xConn))
				nOk = SQLEXEC(xConn, "select 1", "TC0013621")				
				isConnected = !EMPTY(nOk > 0)
								
			CASE !EMPTY(xConn) AND ISCHAR(xConn)
				****??????
				nC = SQLSTRINGCONNECT(xConn)
				IF nC > 0				
					SQLDISCONNECT(nC)
				ELSE 
					isConnected = .f.
				ENDIF 
			
			OTHERWISE 
				isConnected = .f.								
		ENDCASE
		IF USED("TC0013621")
			USE IN "TC0013621"
		ENDIF 
		RETURN isConnected
	ENDPROC 
	
	PROCEDURE UploadTosys(oSys)
	PRIVATE ALL 
		isOk = .t.
		
		IF ISOBJECT(oSys)
			TRY 
				oSys.DefaultConnStr = this.ConnectStr
				oSys.SysConn = this.handle
			CATCH 
				isOk = .f.
			ENDTRY 
			RETURN isOk
		ENDIF 
		
		IF this.isSysLinked()
			TRY 
				this.oContext.DefaultConnStr = this.ConnectStr
				this.oContext.SysConn = this.handle
			CATCH 
				isOk = .f.
			ENDTRY 	
			RETURN isOk		
		ENDIF 

	ENDPROC 
	
	PROCEDURE DownloadFromSys(oSys)
	PRIVATE ALL 
		isOk = .t.
		***this.ConnectStr = IIF(PEMSTATUS(oContext, 'DefaultConnStr', 5), oContext.DefaultConnStr, '')
		IF ISOBJECT(oSys)
			TRY 
				this.ConnectStr = oSys.DefaultConnStr
				this.handle = oSys.SysConn
			CATCH 
				isOk = .f.
			ENDTRY 
			RETURN isOk
		ENDIF 
		
		IF this.isSysLinked()
			TRY 
				this.ConnectStr = this.oContext.DefaultConnStr
				this.handle = this.oContext.SysConn
			CATCH 
				isOk = .f.
			ENDTRY 	
			RETURN isOk		
		ENDIF 
		
	ENDPROC 
	
	PROCEDURE isSysLinked()
		RETURN VARTYPE(this.oContext) == 'O'
	ENDPROC
	
	PROCEDURE GetConnectStr()
	PRIVATE ALL 
		RETURN this.ConnectStr
	ENDPROC 
	
	PROCEDURE GetConn()
		IF !this.TestConnection()
			this.handle = 0
		ENDIF 
		RETURN this.handle
	ENDPROC 
	
	PROCEDURE Close(isForce)
		this.Disconnect(EMPTY(isForce))
		RELEASE this
	ENDPROC 
	
	PROCEDURE Destroy
		DODEFAULT()
		this.Disconnect()
	ENDPROC
	
ENDDEFINE 