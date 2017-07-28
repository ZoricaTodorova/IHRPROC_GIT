PROCEDURE Config
	**** NET ****
	SET EXCLUSIVE  OFF 
	SET LOCK       OFF
	SET MULTILOCKS ON
	SET REFRESH TO   0, 5
	SET REPROCESS TO -1

	SET CENTURY    ON   
	SET DATE BRITISH
	SET DELETED    ON  
	SET TALK       OFF 
	SET SAFETY     OFF
	SET HOURS TO 24
	SET DECIMALS TO 4

	SET AUTOINCERROR OFF
	SET TABLEPROMPT OFF
	SET TABLEVALIDATE TO 2
	*SET COLLATE TO 'RUSSIAN'

	**** FLAGS ****
		
	SET ALTERNATE  OFF          
	SET ANSI       OFF          
	SET ASSERTS    OFF          
	SET BELL       ON           
	SET BLINK      ON           
	SET BRSTATUS   OFF          
	SET CARRY      OFF          
	                            
	SET CLEAR      ON           
	SET COLOR      ON           
	SET COMPATIBLE OFF          
	SET CONFIRM    OFF          
	SET CONSOLE    ON           
	SET CURSOR     ON           
	                            
	SET ECHO       OFF          
	SET EXACT      OFF          
	         
	SET FIELDS     OFF          
	SET FIXED      OFF           
	SET FULLPATH   ON           
	SET HEADING    ON     
	SET MEMOWIDTH TO 8000      
	                            
	SET HELP       ON           
	SET INTENSITY  ON           
	      
	SET LOGERRORS  ON           
	SET MOUSE      ON           
	SET NEAR       OFF          
	SET NULL       OFF          
	                            
	SET OPTIMIZE   ON           
	SET PRINT      OFF          
	SET READBORDER OFF                    
	SET SPACE      ON    
	SET CURRENCY TO ""       
	SET STATUS BAR ON
	SET SYSMENUS   ON           
	                            
	SET TEXTMERGE  OFF          
	SET UNIQUE     OFF

	RAND(-1)
ENDPROC 