#include <windows.h>
#include <process.h> 
#include <stdio.h>

#include "luaservice.h"

/* Glboals for communication with real service implementation */
	extern void threadMain(void);

static struct ErrEntry {
	int code;
	const char* msg;
} ErrList[] = {
// http://msdn.microsoft.com/library/default.asp?url=/library/en-us/debug/base/system_error_codes.asp
	{ 0,	"No error" },
	{ 1055,	"The service database is locked." },
	{ 1056,	"An instance of the service is already running." },
	{ 1060, "The service does not exist as an installed service." },
	{ 1061,	"The service cannot accept control messages at this time." },
	{ 1062, "The service has not been started." },
	{ 1063, "The service process could not connect to the service controller." },
	{ 1064,	"An exception occurred in the service when handling the control request." },
	{ 1065,	"The database specified does not exist." },
	{ 1066,	"The service has returned a service-specific error code." },
	{ 1067,	"The process terminated unexpectedly." },
	{ 1068,	"The dependency service or group failed to start." },
	{ 1069,	"The service did not start due to a logon failure." },
	{ 1070,	"After starting, the service hung in a start-pending state." },
	{ 1071,	"The specified service database lock is invalid." },
	{ 1072, "The service marked for deletion." },
	{ 1073, "The service already exists." },
	{ 1078,	"The name is already in use as either a service name or a service display name." },
};
const int nErrList = sizeof(ErrList) / sizeof(ErrList[0]);


//// Global /////////////////////////////////////////////////////////
FILE*		pLog;							
HANDLE		terminateEvent = NULL;			// Event used to hold ServerMain from completing
											// Handle used to communicate status info with 
											// the SCM. Created by RegisterServiceCtrlHandler
HANDLE		threadHandle = 0;				// Thread for the actual work
BOOL		pauseService = FALSE;			// Flags holding current state of service
BOOL		runningService = FALSE;			//
SERVICE_STATUS_HANDLE serviceStatusHandle;	//

void	ErrorHandler(char *s, int err);
void	GetStatus(SC_HANDLE service);
void	ShowUsage();
// service config program tasks
int	InstallService();
int	UninstallService();
int	GetConfiguration();
int	ChangeConfig();
// service control program tasks
int	ServiceRun();
int	ServiceControl(char* CONTROL);

#if 0
// DWORD	WINAPI ServiceThread( LPDWORD lParam);
unsigned WINAPI ServiceThread(LPVOID lParam);
BOOL	InitService();
BOOL	SendStatusToSCM(DWORD dwCurrentState, DWORD dwWin32ExitCode, DWORD dwServiceSpecificExitCode, DWORD dwCheckPoint, DWORD dwWaitHint);
void	ResumeService();
void	PauseService();
void	StopService();
void	terminate(DWORD error);
void	ServiceCtrlHandler(DWORD controlCode);
void	ServiceMain(DWORD argc, LPTSTR *argv);
int main(int argc, char *argv[])
{
	SERVICE_TABLE_ENTRY serviceTable[] =
	{
		{ ServiceName, (LPSERVICE_MAIN_FUNCTION) ServiceMain},
		{ NULL, NULL}
	};
	BOOL success;
	
	if(argc == 2)
	{
		if (stricmp("-i", argv[1]) == 0)
			InstallService();
		else if (stricmp("-u", argv[1]) == 0)			
			UninstallService();
		else if (stricmp("-r", argv[1]) == 0)
			ServiceRun();
		else if (stricmp("-s", argv[1]) == 0)
			ServiceControl("STOP");
		else if (stricmp("-p", argv[1]) == 0)
			ServiceControl("PAUSE");
		else if (stricmp("-c", argv[1]) == 0)
			ServiceControl("RESUME");
		else if (stricmp("status", argv[1]) == 0)
		{	
			SC_HANDLE scm, service;
			//Open connection to SCM
			scm = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
			if (!scm)
				ErrorHandler("OpenSCManager", GetLastError());
			//Get service's handle
			service = OpenService(scm, ServiceName, SERVICE_ALL_ACCESS);
			if (!service)
				ErrorHandler("OpenService", GetLastError());
			cout << "STATUS: ";
			GetStatus(service);
		}
		else if (stricmp("config", argv[1]) == 0)
			GetConfiguration();
		else if (stricmp("help", argv[1]) == 0)
			ShowUsage();
		//add other custom commands here and 
		//update ShowUsage function

		else
			ShowUsage();
	}
	
	else 
	{
		//register with SCM
		success = StartServiceCtrlDispatcher(serviceTable);
		if (!success)
			ErrorHandler("StartServiceCtrlDispatcher",GetLastError());
	}
}


void ServiceMain(DWORD argc, LPTSTR *argv)
{
	BOOL success;

	//immediately call registration function 
	serviceStatusHandle = RegisterServiceCtrlHandler(ServiceName, (LPHANDLER_FUNCTION)ServiceCtrlHandler);
	if (!serviceStatusHandle)
	{
		terminate(GetLastError());
		return;
	}

	//notify SCM
	success = SendStatusToSCM(SERVICE_START_PENDING, NO_ERROR, 0 , 1, 5000);
	if (!success)
	{ 
		terminate(GetLastError());
		return;
	}

	//create termination event
	terminateEvent = CreateEvent (0, TRUE, FALSE, 0);
	if (!terminateEvent)
	{
		terminate(GetLastError());
		return;
	}

	//notify SCM
	success = SendStatusToSCM(SERVICE_START_PENDING, NO_ERROR, 0 , 2, 1000);
	if (!success)
	{ 
		terminate(GetLastError());
		return;
	}

	/*
	//check for startup parameter
	if (argc == 2)
		
	else
		
	*/

	//notify SCM
	success = SendStatusToSCM(SERVICE_START_PENDING, NO_ERROR, 0 , 3, 5000);
	if (!success)
	{ 
		terminate(GetLastError());
		return;
	}

	//start service
	success = InitService();
	if (!success)
	{ 
		terminate(GetLastError());
		return;
	}

	//notify SCM service is runnning
	success = SendStatusToSCM(SERVICE_RUNNING, NO_ERROR, 0 , 0, 0);
	if (!success)
	{ 
		terminate(GetLastError());
		return;
	}

	//wait for stop signal and then terminate
	WaitForSingleObject(terminateEvent, INFINITE);

	terminate(0);
}

#ifdef NO_CRT_IN_THREAD
DWORD WINAPI ServiceThread(LPDWORD lParam)
#else
unsigned WINAPI ServiceThread(LPVOID lParam)
#endif
{
	//DO YOUR THINGS HERE
	OutputDebugStringA("Launching threadMain()");
	(void)threadMain();
	return 0;
}

//initialises the service by starting its thread
BOOL InitService()
{

	// Start the service's thread
#ifdef NO_CRT_IN_THREAD
	DWORD id;
	threadHandle = CreateThread(
	NULL,
	0,
	(LPTHREAD_START_ROUTINE) ServiceThread,
	NULL,
	0,
	&id);
#else
	unsigned int id;
	threadHandle = (HANDLE)_beginthreadex(
	NULL,
	0,
	ServiceThread,
	NULL,
	0,
	&id);
#endif
	if (threadHandle == 0)
		return FALSE;
	else
	{
		runningService = TRUE;
		return TRUE;
	}
}


//resumes paused service
void ResumeService()
{
	pauseService = FALSE;
	ResumeThread(threadHandle);
}

//pauses service
void PauseService()
{
	pauseService = TRUE;
	SuspendThread(threadHandle);
}

//stops service by allowing ServiceMain to complete
void StopService()
{
	runningService = FALSE;
	//set the event that is holding ServiceMain
	SetEvent(terminateEvent);
}

//this function consolidates the activities of updating
//the service status with SetServiceStatus
BOOL SendStatusToSCM(DWORD dwCurrentState, DWORD dwWin32ExitCode, DWORD dwServiceSpecificExitCode, DWORD dwCheckPoint, DWORD dwWaitHint)
{
	BOOL success;
	SERVICE_STATUS serviceStatus;

	//fill in all of the SERVICE_STATUS fields
	serviceStatus.dwServiceType = SERVICE_WIN32_OWN_PROCESS;
	serviceStatus.dwCurrentState = dwCurrentState;

	//if in the process of something, then accept
	//no control events, else accept anything
	if (dwCurrentState == SERVICE_START_PENDING)
		serviceStatus.dwControlsAccepted = 0;
	else
		serviceStatus.dwControlsAccepted = 
			SERVICE_ACCEPT_STOP | 
			SERVICE_ACCEPT_PAUSE_CONTINUE |
			SERVICE_ACCEPT_SHUTDOWN;

	//if a specific exit code is defines, set up the win32 exit code properly
	if (dwServiceSpecificExitCode == 0)
		serviceStatus.dwWin32ExitCode = dwWin32ExitCode;
	else
		serviceStatus.dwWin32ExitCode = ERROR_SERVICE_SPECIFIC_ERROR;
	
	serviceStatus.dwServiceSpecificExitCode = dwServiceSpecificExitCode;
	serviceStatus.dwCheckPoint = dwCheckPoint;
	serviceStatus.dwWaitHint = dwWaitHint;
	
	success = SetServiceStatus (serviceStatusHandle, &serviceStatus);
	if (!success)
		StopService();

	return success;
}

void ServiceCtrlHandler(DWORD controlCode)
{
	DWORD currentState = 0;
	BOOL success;

	switch(controlCode)
	{
		// START = ServiceMain()

		// STOP
		case SERVICE_CONTROL_STOP:
			currentState = SERVICE_STOP_PENDING;
			//notify SCM
			success = SendStatusToSCM(
				SERVICE_STOP_PENDING,
				NO_ERROR,
				0,
				1,
				5000);
			//stop service
			StopService();
			return;

		// PAUSE
		case SERVICE_CONTROL_PAUSE:
			if (runningService && !pauseService)
			{
				//notify SCM
				success = SendStatusToSCM(
					SERVICE_PAUSE_PENDING,
					NO_ERROR,
					0,
					1,
					1000);
				
				PauseService();
				currentState = SERVICE_PAUSED;
			}
			break;
			
		// RESUME
		case SERVICE_CONTROL_CONTINUE:
			if (runningService && pauseService)
			{
				//notify SCM
				success = SendStatusToSCM(
					SERVICE_CONTINUE_PENDING,
					NO_ERROR,
					0,
					1,
					1000);
				
				ResumeService();
				currentState = SERVICE_RUNNING;
			}
			break;

		// UPDATE
		case SERVICE_CONTROL_INTERROGATE:
			//update status out of switch()
			break;
			
		case SERVICE_CONTROL_SHUTDOWN:
			//do nothing
			return;
		default:
			break;
	}
	//notify SCM current state
	SendStatusToSCM(currentState, NO_ERROR, 0, 0, 0);
}
	

//handle an error from ServiceMain by cleaning up and tell SCM service didn't start.
void terminate(DWORD error)
{
	//close event handle
	if (terminateEvent)
		CloseHandle(terminateEvent);

	//notify SCM service stopped
	if (serviceStatusHandle)
		SendStatusToSCM(SERVICE_STOPPED, error, 0, 0, 0);

	//close thread handle
	if (threadHandle)
		CloseHandle(threadHandle);
}
#endif

	
void ErrorHandler(char *s, int err)
{

	printf("%s failed\n"
			"Error (%d): ", s, err);
	int i;
	for (i = 0; i < nErrList; ++i) {
		if (ErrList[i].code == err) {
			puts(ErrList[i].msg);
			break;
		}
	}
	if (i == nErrList) {
		puts("unknown error");
	}
	pLog = fopen("server.log","a");
	fprintf(pLog, "%s failed, error code = %d\n",s , err); 
	fclose(pLog);

	ExitProcess(err);
}

void ShowUsage()
{
	printf("Usage:\n"
		"server -i\tInstall service\n"
		"server -u\tUninstall service"
		"server -r\tRun service\n"
		"server -s\tStop service\n"
		"server -p\tPause service\n"
		"server -c\tResume service\n"
		"server status\tCurrent status\n"
		);
}


////////////////////////////////////////////////////////////////////////////////
// Purpose	:Install service into SCM.
// Parameter:N/A
// Returns	:N/A
////////////////////////////////////////////////////////////////////////////////
int InstallService()
{
	SC_HANDLE newService;
	SC_HANDLE scm; 
    char szPath[MAX_PATH+3];

	//get file path
    szPath[0] = '\"';
	GetModuleFileName(GetModuleHandle(NULL), szPath+1, MAX_PATH);
    strcat(szPath, "\"");

	//open connection to SCM
	scm = OpenSCManager(NULL, NULL, SC_MANAGER_CREATE_SERVICE);
	if (!scm)
		ErrorHandler("OpenSCManager", GetLastError());

	//install service
	newService = CreateService(
		scm,						//scm database
		ServiceName,				//service name
		ServiceName,				//display name
		SERVICE_ALL_ACCESS,			//access rights to the service
		SERVICE_WIN32_OWN_PROCESS,	//service type
		SERVICE_AUTO_START,			//service start type
		SERVICE_ERROR_NORMAL,		//error control type
		szPath,						//service path
		NULL,						//no load ordering group 
		NULL,						//no tag identifier
		NULL,						//no dependencies	
		NULL,						//LocalSystem account
		NULL);						//no password
	if(!newService)
	{
		ErrorHandler("CreateService", GetLastError());
		return FALSE;
	}
	else
	{
		puts("Service Installed");
		ServiceRun();
	}

	//clean up
	CloseServiceHandle(newService);
	CloseServiceHandle(scm);
	return TRUE;
}

////////////////////////////////////////////////////////////////////////////////
// Purpose	:Uninstall service from SCM.
// Parameter:N/A
// Returns	:N/A
////////////////////////////////////////////////////////////////////////////////
int UninstallService()
{
	SC_HANDLE service;
	SC_HANDLE scm;
	int SUCCESS;
	SERVICE_STATUS status;

	//Open connection to SCM
	scm = OpenSCManager(NULL, NULL, SC_MANAGER_CREATE_SERVICE);
	if (!scm)
		ErrorHandler("OpenSCManager", GetLastError());

	//Get service's handle
	service = OpenService(scm, ServiceName, SERVICE_ALL_ACCESS | DELETE);
	if (!service)
		ErrorHandler("OpenService", GetLastError());

	//Get service status
	SUCCESS	= QueryServiceStatus(service, &status);
	if (!SUCCESS)
		ErrorHandler("QueryServiceStatus", GetLastError());
	
	//Stop service if necessary		
	if (status.dwCurrentState != SERVICE_STOPPED)
	{
		puts("Stopping service...");
		SUCCESS = ControlService(service, SERVICE_CONTROL_STOP, &status);
		if (!SUCCESS)
			ErrorHandler("ControlService", GetLastError());
		Sleep(500);
	}

	//Delete service
	SUCCESS = DeleteService(service);
	if (SUCCESS)
		puts("Service Uninstalled");
	else
		ErrorHandler("DeleteService", GetLastError());

	//Clean up
	CloseServiceHandle(service);
	CloseServiceHandle(scm);

	return TRUE;
}


////////////////////////////////////////////////////////////////////////////////
// Purpose	:Run service
// Parameter:N/A
// Returns	:N/A
////////////////////////////////////////////////////////////////////////////////
int ServiceRun() 
{ 
    SC_HANDLE scm, Service;
	SERVICE_STATUS ssStatus; 
    DWORD dwOldCheckPoint; 
    DWORD dwStartTickCount;
    DWORD dwWaitTime;
    DWORD dwStatus;
 	
	//open connection to SCM
	scm = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
	if (!scm)
		ErrorHandler("OpenSCManager", GetLastError());

	//open service
	Service = OpenService(scm, ServiceName, SERVICE_ALL_ACCESS);
	if(!Service)
	{
		ErrorHandler("OpenService", GetLastError());
		return FALSE;
	}
	else
	{
		//start service
		StartService(Service, 0, NULL);
		GetStatus(Service);

		// Check the status until the service is no longer start pending. 
		if (!QueryServiceStatus( Service, &ssStatus) )
			ErrorHandler("QueryServiceStatus", GetLastError());
		// Save the tick count and initial checkpoint.
		dwStartTickCount = GetTickCount();
		dwOldCheckPoint = ssStatus.dwCheckPoint;

		while (ssStatus.dwCurrentState == SERVICE_START_PENDING) 
		{ 
			// Do not wait longer than the wait hint. A good interval is 
			// one tenth the wait hint, but no less than 1 second and no 
			// more than 10 seconds. 
			dwWaitTime = ssStatus.dwWaitHint / 10;

			if( dwWaitTime < 1000 )
				dwWaitTime = 1000;
			else if ( dwWaitTime > 10000 )
				dwWaitTime = 10000;

			Sleep( dwWaitTime );

			// Check the status again. 
			if (!QueryServiceStatus(Service, &ssStatus) )
				break; 

			if ( ssStatus.dwCheckPoint > dwOldCheckPoint )
			{
				// The service is making progress.
				dwStartTickCount = GetTickCount();
				dwOldCheckPoint = ssStatus.dwCheckPoint;
			}
			else
			{
				if(GetTickCount()-dwStartTickCount > ssStatus.dwWaitHint)
				{
					// No progress made within the wait hint
					break;
				}
			}
		}
		
		if (ssStatus.dwCurrentState == SERVICE_RUNNING) 
		{
			GetStatus(Service);
			dwStatus = NO_ERROR;
		}
		else 
		{ 

			puts("\nService not started.");
			printf("  Current State: %ld\n", ssStatus.dwCurrentState); 
			printf("  Exit Code: %ld\n", ssStatus.dwWin32ExitCode); 
			printf("  Service Specific Exit Code: %ld\n", ssStatus.dwServiceSpecificExitCode); 
			printf("  Check Point: %ld\n", ssStatus.dwCheckPoint); 
			printf("  Wait Hint: %ld\n", ssStatus.dwWaitHint);
			dwStatus = GetLastError();
		} 	
	}

	CloseServiceHandle(scm);
    CloseServiceHandle(Service); 
    return TRUE;
}


////////////////////////////////////////////////////////////////////////////////
// Purpose	:Control service (STOP, PAUSE, CONTINUE).
// Parameter:N/A
// Returns	:N/A
////////////////////////////////////////////////////////////////////////////////
int ServiceControl(char* CONTROL)
{
	SC_HANDLE service;
	SC_HANDLE scm;
	BOOL SUCCESS = FALSE;
	SERVICE_STATUS status;

	//Open connection to SCM
	scm = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
	if (!scm)
		ErrorHandler("OpenSCManager", GetLastError());

	//Get service's handle
	service = OpenService(scm, ServiceName, SERVICE_ALL_ACCESS);
	if (!service)
		ErrorHandler("OpenService", GetLastError());
	
	//stop the service
	if (stricmp(CONTROL, "STOP") == 0)
	{
		puts("Service is stopping...");
		SUCCESS = ControlService(service, SERVICE_CONTROL_STOP, &status);
	}
	//pause the service
	else if (stricmp(CONTROL, "PAUSE") == 0)
	{
		puts("Service is pausing...");
		SUCCESS = ControlService(service, SERVICE_CONTROL_PAUSE, &status);
	}
	//continue the service
	else if (stricmp(CONTROL, "RESUME") == 0)
	{
		puts("Service is resuming...");
		SUCCESS = ControlService(service, SERVICE_CONTROL_CONTINUE, &status);
	}
	if (!SUCCESS)
		ErrorHandler("ControlService", GetLastError());
	else
		GetStatus(service);

	//Clean up
	CloseServiceHandle(service);
	CloseServiceHandle(scm);

	return TRUE;
}


////////////////////////////////////////////////////////////////////////////////
// Purpose	:Get the current status of the service
// Parameter:service handle.
// Returns	:N/A
////////////////////////////////////////////////////////////////////////////////
void GetStatus(SC_HANDLE service)
{
	BOOL SUCCESS;
	SERVICE_STATUS status;	
	DWORD CurrentState = 0;

	SUCCESS = QueryServiceStatus(service, &status);
	
	switch(status.dwCurrentState)
	{
		case SERVICE_RUNNING:
			CurrentState = SERVICE_RUNNING;
			puts("Service RUNNING.");
			break;
		case SERVICE_STOPPED:
			CurrentState = SERVICE_STOPPED;
			puts("Service STOPPED.");
			break;
		case SERVICE_PAUSED:
			CurrentState = SERVICE_PAUSED;
			puts("Service PAUSED.");
			break;
		case SERVICE_CONTINUE_PENDING:
			CurrentState = SERVICE_CONTINUE_PENDING;
			puts("Service is resuming...");
			break;
		case SERVICE_PAUSE_PENDING:
			CurrentState = SERVICE_PAUSE_PENDING;
			puts("Service is pausing...");
			break;
		case SERVICE_START_PENDING:
			CurrentState = SERVICE_START_PENDING;
			puts("Service is starting...");
			break;
		case SERVICE_STOP_PENDING:
			CurrentState = SERVICE_STOP_PENDING;
			puts("Service is stopping...");
			break;
		default:
			break;
	}
	// rkb -- why is this here?
	// The current function is only called from the context of a user to control
	// the service, but SendStatusToSCM() seems like it should only be called 
	// from a thread under the control of the SCM.
	//SendStatusToSCM(CurrentState, NO_ERROR, 0, 0, 0);
}

////////////////////////////////////////////////////////////////////////////////
// Purpose	:Get configuration of service
// Parameter:N/A
// Returns	:N/A
////////////////////////////////////////////////////////////////////////////////
int GetConfiguration()
{
	SC_HANDLE service;
	SC_HANDLE scm;
	BOOL success;
	LPQUERY_SERVICE_CONFIG buffer;
	DWORD sizeNeeded;

	//open connection to SCM
	scm = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS);
	if (!scm)
		ErrorHandler("OpenSCManager", GetLastError());

	//get service's handle
	service = OpenService(scm, ServiceName, SERVICE_QUERY_CONFIG);
	if (!service)
		ErrorHandler("OpenService", GetLastError());

 	//allocate space for buffer
	buffer = (LPQUERY_SERVICE_CONFIG)LocalAlloc(LPTR, 4096);
    // Get the configuration information. 
	success = QueryServiceConfig(service, buffer, 4096, &sizeNeeded);
	if (!success)
		ErrorHandler("QueryServiceConfig", GetLastError());

	//display the info
	printf("Service name\t: %s\n", buffer->lpDisplayName);
	printf("Service type\t: %ld\n", buffer->dwServiceType);
	printf("Start type\t: %ld\n", buffer->dwStartType);
	printf("Start name\t: %s\n", buffer->lpServiceStartName);
	printf("Path\t\t: %s\n", buffer->lpBinaryPathName);

	LocalFree(buffer);

	CloseServiceHandle(service);
	CloseServiceHandle(scm);
	return TRUE;
}


int ChangeConfig()
{
	SC_HANDLE service;
	SC_HANDLE scm;
	BOOL success;
	SC_LOCK lock;

	//open connection to SCM
	scm = OpenSCManager(NULL, NULL, SC_MANAGER_ALL_ACCESS | GENERIC_WRITE);
	if (!scm)
		ErrorHandler("OpenSCManager", GetLastError());

	//lock the database to guarantee exclusive access
	lock = LockServiceDatabase(scm);
	if (lock == 0)
		ErrorHandler("LockServiceDatabase", GetLastError());
		
	//get service's handle
	service = OpenService(scm, ServiceName, SERVICE_ALL_ACCESS);
	if (!service)
		ErrorHandler("OpenService", GetLastError());
	
//	serviceType = SERVICE_NO_CHANGE;
//	serviceStart = SERVICE_NO_CHANGE;
//	serviceError = SERVICE_NO_CHANGE;
//	path = 0;

	//change service config
	success = ChangeServiceConfig(
		service,
		SERVICE_NO_CHANGE,
		SERVICE_NO_CHANGE,
		SERVICE_NO_CHANGE,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL,
		NULL);
	if (!success)
	{
		UnlockServiceDatabase(lock);
		ErrorHandler("ChangeServiceConfig", GetLastError());
	}

	//unlock database
	success = UnlockServiceDatabase(lock);
	if (!success)
		ErrorHandler("UnlockServiceDatabase", GetLastError());
	
	//clean up
	CloseServiceHandle(service);
	CloseServiceHandle(scm);
	return TRUE;
}

