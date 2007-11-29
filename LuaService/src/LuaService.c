/*! 
 * \file LuaService.c
 * \brief Windows Service framework and startup.
 * 
 * Author: Ross Berteig
 * 
 * Copyright © 2007, Ross Berteig.
 */

#include <stdio.h>
#include <stdlib.h>

/*! Process entry point.
 * 
 * Invoked when the process starts either by a user at a command prompt 
 * to setup or control the service, or by the Service Control Manager to
 * start the service.
 * 
 * \todo Distinguish between service setup/control use and service startup,
 * remembering that both uses can have command-line arguments.
 * 
 * \todo Implement a service at all.
 * 
 * \param argc The count of arguments.
 * \param argv The list of arguments.
 * \returns The ANSI process exit status.
 */
int main(int argc, char *argv[]) {
	puts("Placeholder for a real service framework to get CVS started.");
	return EXIT_SUCCESS;
}
