/*! 
 * \file LuaService.c
 * \brief Windows Service framework and startup.
 * 
 * \author Ross Berteig
 * \author Cheshire Engineering Corp.
 * 
 * Copyright © 2007, Ross Berteig, Cheshire Engineering Corp.
 */

#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

#include "luaservice.h"
extern void SvcDebugOut(LPSTR fmt, DWORD Status);
extern void WINAPI LuaServiceMain(DWORD argc, LPTSTR *argv);
extern DWORD LuaServiceInitialization(DWORD   argc, LPTSTR  *argv, 
	    DWORD *specificError);
extern void WINAPI LuaServiceCtrlHandler (DWORD Opcode);

/** Process entry point.
 * 
 * Invoked when the process starts either by a user at a command prompt 
 * to setup or control the service, or by the Service Control Manager to
 * start the service.
 * 
 * To Distinguish between the three kinds of service-related programs 
 * (the service program, the service control program, and the service 
 * configuration program) that we can call StartServiceCtrlDispatcher() 
 * early on and use its success or failure to connect to the SCM as an 
 * indication of the calling context. If it succeeds, then the process 
 * was started by the SCM and is the service program. If it fails with
 * the specific error code ERROR_FAILED_SERVICE_CONTROLLER_CONNECT, then
 * it is not the service program, and it can depend on its command line
 * to distinguish control from configuration. If any other error is 
 * returned, then it might have been a service program, but something
 * is so horribly wrong that the service cannot start.
 * 
 * \todo Implement a service that does something useful.
 *
 * \context 
 * Service, Configuration, Control
 *  
 * \param argc The count of arguments.
 * \param argv The list of arguments.
 * \returns The ANSI C process exit status.
 */
int main(int argc, char *argv[]) 
{
	static SERVICE_TABLE_ENTRY DispatchTable[] = {
			{ "LuaService", LuaServiceMain }, 
			{ NULL, NULL} 
	};
	
	if (!StartServiceCtrlDispatcher(DispatchTable)) {
		DWORD err = GetLastError();
		if (err == ERROR_FAILED_SERVICE_CONTROLLER_CONNECT) {
		/// \todo Implement service configuration and control here.
			printf("Not a service, no controls implemented.\n");
		} else {
			SvcDebugOut("[LuaService] StartServiceCtrlDispatcher (%d)\n", err);
			return EXIT_FAILURE;
		}
	} 
	return EXIT_SUCCESS;
} 

/** Output a debug string.
 * 
 * \context 
 * Service, Configuration, Control
 *  
 * \bug This function has a buffer overrun risk if misused internally.
 * 
 * \param fmt A printf()-like format string with an optional reference to
 * 				a single DWORD value.
 * \param status A DWORD value to substitute in the message.
 */
void SvcDebugOut(LPSTR fmt, DWORD status) 
{ 
   char Buffer[1024]; 
   if (strlen(fmt) < sizeof(Buffer) - 20) { 
      sprintf(Buffer, fmt, status); 
      OutputDebugStringA(Buffer); 
   } 
}


SERVICE_STATUS          LuaServiceStatus; 
SERVICE_STATUS_HANDLE   LuaServiceStatusHandle; 

/** Service Main function.
 * 
 * \context
 * Service
 * 
 * \param argc The count of arguments.
 * \param argv The list of arguments.
 */
void WINAPI LuaServiceMain(DWORD argc, LPTSTR *argv) 
{ 
	DWORD status; 
    DWORD specificError; 
 
    LuaServiceStatus.dwServiceType        = SERVICE_WIN32_OWN_PROCESS; // SERVICE_WIN32; 
    LuaServiceStatus.dwCurrentState       = SERVICE_START_PENDING; 
    LuaServiceStatus.dwControlsAccepted   = (0
    		| SERVICE_ACCEPT_STOP 
    		//| SERVICE_ACCEPT_SHUTDOWN
    		//| SERVICE_ACCEPT_PAUSE_CONTINUE
    		); 
    LuaServiceStatus.dwWin32ExitCode      = 0; 
    LuaServiceStatus.dwServiceSpecificExitCode = 0; 
    LuaServiceStatus.dwCheckPoint         = 0; 
    LuaServiceStatus.dwWaitHint           = 0; 
 
    LuaServiceStatusHandle = RegisterServiceCtrlHandler( 
    		"LuaService", 
    		LuaServiceCtrlHandler); 
 
    if (LuaServiceStatusHandle == (SERVICE_STATUS_HANDLE)0) {
    	SvcDebugOut("[LuaService] RegisterServiceCtrlHandler failed %d\n", GetLastError());
        return; 
    }
 
    // Initialization code goes here. 
    status = LuaServiceInitialization(argc,argv, &specificError); 
 
    // Handle error condition 
    if (status != NO_ERROR) 
    { 
        LuaServiceStatus.dwCurrentState       = SERVICE_STOPPED; 
        LuaServiceStatus.dwCheckPoint         = 0; 
        LuaServiceStatus.dwWaitHint           = 0; 
        LuaServiceStatus.dwWin32ExitCode      = status; 
        LuaServiceStatus.dwServiceSpecificExitCode = specificError; 
 
        SetServiceStatus (LuaServiceStatusHandle, &LuaServiceStatus); 
        return; 
    } 
 
    // Initialization complete - report running status. 
    LuaServiceStatus.dwCurrentState       = SERVICE_RUNNING; 
    LuaServiceStatus.dwCheckPoint         = 0; 
    LuaServiceStatus.dwWaitHint           = 0; 
 
    if (!SetServiceStatus (LuaServiceStatusHandle, &LuaServiceStatus)) 
    { 
        status = GetLastError(); 
        SvcDebugOut("[LuaService] SetServiceStatus error %ld\n",status); 
    } 
 
    /// \todo Do some work in this thread, say by running a Lua file.
    
    // This is where the service does its work. This sample simply falls 
    // out without accomplishing anything.
    SvcDebugOut("[LuaService] Returning the Main Thread \n",0); 
    return; 
}
 
// Stub initialization function. 
DWORD LuaServiceInitialization(DWORD   argc, LPTSTR  *argv, 
    DWORD *specificError) 
{ 
    argv; 
    argc; 
    specificError; 
    return(0); 
}

/** Service Control Handler.
 * 
 * \context
 * Service
 * 
 * \param Opcode The control operation to handle.
 */
void WINAPI LuaServiceCtrlHandler (DWORD Opcode) 
{ 
   DWORD status; 
 
   switch(Opcode) 
   { 
#if 0
      case SERVICE_CONTROL_PAUSE: 
      /// \todo Do whatever it takes to pause here. 
         LuaServiceStatus.dwCurrentState = SERVICE_PAUSED; 
         break; 
 
      case SERVICE_CONTROL_CONTINUE: 
      /// \todo Do whatever it takes to continue here. 
         LuaServiceStatus.dwCurrentState = SERVICE_RUNNING; 
         break; 
#endif
      case SERVICE_CONTROL_STOP: 
      /// \todo Do whatever it takes to stop here. 
         LuaServiceStatus.dwWin32ExitCode = 0; 
         LuaServiceStatus.dwCurrentState  = SERVICE_STOPPED; 
         LuaServiceStatus.dwCheckPoint    = 0; 
         LuaServiceStatus.dwWaitHint      = 0; 

         if (!SetServiceStatus (LuaServiceStatusHandle, 
           &LuaServiceStatus))
         { 
            status = GetLastError(); 
            SvcDebugOut(" [Lua_SERVICE] SetServiceStatus error %ld\n", 
               status); 
         } 
 
         SvcDebugOut(" [Lua_SERVICE] Leaving LuaService \n",0); 
         return; 
 
      case SERVICE_CONTROL_INTERROGATE: 
      // Fall through to send current status. 
         break; 
 
      default: 
         SvcDebugOut(" [Lua_SERVICE] Unrecognized opcode %ld\n", 
             Opcode); 
   } 
 
   // Send current status. 
   if (!SetServiceStatus (LuaServiceStatusHandle,  &LuaServiceStatus)) 
   { 
      status = GetLastError(); 
      SvcDebugOut(" [Lua_SERVICE] SetServiceStatus error %ld\n", 
         status); 
   } 
   return; 
}


