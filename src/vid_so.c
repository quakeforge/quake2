/* $Id$
 *
 * Copyright (C) 1997-2001 Id Software, Inc.
 * Copyright (c) 2002 The Quakeforge Project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * 
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

// Main windowed and fullscreen graphics interface module. This module
// is used for both the software and OpenGL rendering versions of the
// Quake refresh engine.

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

/* merged in from irix/vid_so.c -- jaq */
#ifdef __sgi
#define SO_FILE "/etc/quake2.conf"
#endif

#include <assert.h>

#ifdef HAVE_DLOPEN
# include <dlfcn.h> // ELF dl loader
#endif

#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

/* merged in from bsd -- jaq */
#ifndef RTLD_NOW
#define RTLD_NOW RTLD_LAZY
#endif

#ifndef RTLD_GLOBAL
#define RTLD_GLOBAL 0
#endif

#ifdef __OpenBSD__
#define dlsym(X, Y) dlsym(X, "_"##Y)
#endif

#include "client.h"
#include "rw.h"

// Structure containing functions exported from refresh DLL
refexport_t	re;

/* merged from irix/vid_so.c -- jaq */
#ifdef REF_HARD_LINKED
refexport_t GetRefAPI(refimport_t rimp);
#endif

// Console variables that we need to access from this module
cvar_t		*vid_gamma;
cvar_t		*vid_ref;			// Name of Refresh DLL loaded
cvar_t		*vid_xpos;			// X coordinate of window position
cvar_t		*vid_ypos;			// Y coordinate of window position
cvar_t		*vid_fullscreen;

// Global variables used internally by this module
viddef_t	viddef;				// global video state; used by other modules
void		*reflib_library;		// Handle to refresh DLL 
qboolean	reflib_active = 0;

#define VID_NUM_MODES ( sizeof( vid_modes ) / sizeof( vid_modes[0] ) )

/** KEYBOARD **************************************************************/

void Do_Key_Event(int key, qboolean down);

void (*KBD_Update_fp)(void);
void (*KBD_Init_fp)(Key_Event_fp_t fp);
void (*KBD_Close_fp)(void);

/** MOUSE *****************************************************************/

in_state_t in_state;

void (*RW_IN_Init_fp)(in_state_t *in_state_p);
void (*RW_IN_Shutdown_fp)(void);
void (*RW_IN_Activate_fp)(qboolean active);
void (*RW_IN_Commands_fp)(void);
void (*RW_IN_Move_fp)(usercmd_t *cmd);
void (*RW_IN_Frame_fp)(void);

void Real_IN_Init (void);

/** CLIPBOARD *************************************************************/

char *(*RW_Sys_GetClipboardData_fp)(void);

/*
==========================================================================

DLL GLUE

==========================================================================
*/

#define	MAXPRINTMSG	4096
void VID_Printf (int print_level, char *fmt, ...)
{
	va_list		argptr;
	char		msg[MAXPRINTMSG];
	
	va_start (argptr,fmt);
	vsnprintf (msg,MAXPRINTMSG,fmt,argptr);
	va_end (argptr);

	if (print_level == PRINT_ALL)
		Com_Printf ("%s", msg);
	else
		Com_DPrintf ("%s", msg);
}

void __attribute__((noreturn)) VID_Error (int err_level, char *fmt, ...)
{
	va_list		argptr;
	char		msg[MAXPRINTMSG];
	
	va_start (argptr,fmt);
	vsnprintf (msg,MAXPRINTMSG,fmt,argptr);
	va_end (argptr);

	Com_Error (err_level,"%s", msg);
}

//==========================================================================

/*
============
VID_Restart_f

Console command to re-start the video mode and refresh DLL. We do this
simply by setting the modified flag for the vid_ref variable, which will
cause the entire video mode and refresh DLL to be reset on the next frame.
============
*/
void VID_Restart_f (void)
{
	vid_ref->modified = true;
}

/*
** VID_GetModeInfo
*/
typedef struct vidmode_s
{
	const char *description;
	int         width, height;
	int         mode;
} vidmode_t;

vidmode_t vid_modes[] =
{
	{ "Mode 0: 320x240",   320, 240,   0 },
	{ "Mode 1: 400x300",   400, 300,   1 },
	{ "Mode 2: 512x384",   512, 384,   2 },
	{ "Mode 3: 640x480",   640, 480,   3 },
	{ "Mode 4: 800x600",   800, 600,   4 },
	{ "Mode 5: 960x720",   960, 720,   5 },
	{ "Mode 6: 1024x768",  1024, 768,  6 },
	{ "Mode 7: 1152x864",  1152, 864,  7 },
	{ "Mode 8: 1280x1024",  1280, 1024, 8 },
	{ "Mode 9: 1600x1200", 1600, 1200, 9 },
	{ "Mode 10: 2048x1536", 2048, 1536, 10 }
};

qboolean VID_GetModeInfo( unsigned int *width, unsigned int *height, int mode )
{
	if ( mode < 0 || mode >= VID_NUM_MODES )
		return false;

	*width  = vid_modes[mode].width;
	*height = vid_modes[mode].height;

	return true;
}

/*
** VID_NewWindow
*/
void VID_NewWindow ( int width, int height)
{
	viddef.width  = width;
	viddef.height = height;
}

void VID_FreeReflib (void)
{
	if (reflib_library) {
		if (KBD_Close_fp)
			KBD_Close_fp();
		if (RW_IN_Shutdown_fp)
			RW_IN_Shutdown_fp();
/* merged from irix/vid_so.c -- jaq */
#ifndef REF_HARD_LINKED
		dlclose(reflib_library);
#endif
	}

	KBD_Init_fp = NULL;
	KBD_Update_fp = NULL;
	KBD_Close_fp = NULL;
	RW_IN_Init_fp = NULL;
	RW_IN_Shutdown_fp = NULL;
	RW_IN_Activate_fp = NULL;
	RW_IN_Commands_fp = NULL;
	RW_IN_Move_fp = NULL;
	RW_IN_Frame_fp = NULL;
	RW_Sys_GetClipboardData_fp = NULL;

	memset (&re, 0, sizeof(re));
	reflib_library = NULL;
	reflib_active  = false;
}

/*
==============
VID_LoadRefresh
==============
*/
qboolean VID_LoadRefresh( char *name )
{
	refimport_t	ri;
/* from irix/vid_so.c -- jaq */
#ifndef REF_HARD_LINKED
	GetRefAPI_t	GetRefAPI;
#endif
	char	fn[MAX_OSPATH];
	char	*path;
	struct stat st;
	extern uid_t saved_euid;
	
	if ( reflib_active )
	{
		if (KBD_Close_fp)
			KBD_Close_fp();
		if (RW_IN_Shutdown_fp)
			RW_IN_Shutdown_fp();
		KBD_Close_fp = NULL;
		RW_IN_Shutdown_fp = NULL;
		re.Shutdown();
		VID_FreeReflib ();
	}

/* from irix/vid_so.c -- jaq */
#ifndef REF_HARD_LINKED

	Com_Printf( "------- Loading %s -------\n", name );

	//regain root
	seteuid(saved_euid);

	path = Cvar_Get ("basedir", ".", CVAR_NOSET)->string;

	snprintf (fn, MAX_OSPATH, "%s/%s", path, name );
	
	if (stat(fn, &st) == -1) {
		Com_Printf( "LoadLibrary(\"%s\") failed: %s\n", name, strerror(errno));
		return false;
	}
	
	// permission checking
	if (strstr(fn, "softx") == NULL &&
	    strstr(fn, "glx") == NULL &&
	    strstr(fn, "softsdl") == NULL &&
	    strstr(fn, "sdlgl") == NULL &&
		strstr(fn, "fxgl") == NULL) { // softx doesn't require root	
#if 0
		if (st.st_uid != 0) {
			Com_Printf( "LoadLibrary(\"%s\") failed: ref is not owned by root\n", name);
			return false;
		}
		if ((st.st_mode & 0777) & ~0700) {
			Com_Printf( "LoadLibrary(\"%s\") failed: invalid permissions, must be 700 for security considerations\n", name);
			return false;
		}
#endif
	} else {
		// softx requires we give up root now
		setreuid(getuid(), getuid());
		setegid(getgid());
	}

	if ( ( reflib_library = dlopen( fn, RTLD_LAZY | RTLD_GLOBAL ) ) == 0 )
	{
		Com_Printf( "LoadLibrary(\"%s\") failed: %s\n", name , dlerror());
		return false;
	}

	Com_Printf( "LoadLibrary(\"%s\")\n", fn );
#endif /* REF_HARD_LINKED */

	ri.Cmd_AddCommand = Cmd_AddCommand;
	ri.Cmd_RemoveCommand = Cmd_RemoveCommand;
	ri.Cmd_Argc = Cmd_Argc;
	ri.Cmd_Argv = Cmd_Argv;
	ri.Cmd_ExecuteText = Cbuf_ExecuteText;
	ri.Con_Printf = VID_Printf;
	ri.Sys_Error = VID_Error;
	ri.FS_LoadFile = FS_LoadFile;
	ri.FS_FreeFile = FS_FreeFile;
	ri.FS_Gamedir = FS_Gamedir;
	ri.Cvar_Get = Cvar_Get;
	ri.Cvar_Set = Cvar_Set;
	ri.Cvar_SetValue = Cvar_SetValue;
	ri.Vid_GetModeInfo = VID_GetModeInfo;
	ri.Vid_MenuInit = VID_MenuInit;
	ri.Vid_NewWindow = VID_NewWindow;

#ifndef REF_HARD_LINKED
	if ( ( GetRefAPI = (GetRefAPI_t) dlsym( reflib_library, "GetRefAPI" ) ) == 0 )
		Com_Error( ERR_FATAL, "dlsym failed on %s", name );
#endif

	re = GetRefAPI( ri );

	if (re.api_version != API_VERSION)
	{
		VID_FreeReflib ();
		Com_Error (ERR_FATAL, "%s has incompatible api_version", name);
	}

	/* Init IN (Mouse) */
	in_state.IN_CenterView_fp = IN_CenterView;
	in_state.Key_Event_fp = Do_Key_Event;
	in_state.viewangles = cl.viewangles;
	in_state.in_strafe_state = &in_strafe.state;

#ifndef REF_HARD_LINKED
	if ((RW_IN_Init_fp = (void (*)(in_state_t *)) dlsym(reflib_library, "RW_IN_Init")) == NULL ||
		(RW_IN_Shutdown_fp = (void(*)(void)) dlsym(reflib_library, "RW_IN_Shutdown")) == NULL ||
		(RW_IN_Activate_fp = (void(*)(qboolean)) dlsym(reflib_library, "RW_IN_Activate")) == NULL ||
		(RW_IN_Commands_fp = (void(*)(void)) dlsym(reflib_library, "RW_IN_Commands")) == NULL ||
		(RW_IN_Move_fp = (void(*)(usercmd_t *)) dlsym(reflib_library, "RW_IN_Move")) == NULL ||
		(RW_IN_Frame_fp = (void(*)(void)) dlsym(reflib_library, "RW_IN_Frame")) == NULL)
		Sys_Error("No RW_IN functions in REF.\n");

	/* this one is optional */
	RW_Sys_GetClipboardData_fp = (char*(*)(void)) dlsym(reflib_library, "RW_Sys_GetClipboardData");

	Real_IN_Init();
#else /* ref-hard-linked */
	{
		void RW_IN_Init(in_state_t *in_state_p);
		void RW_IN_Shutdown(void);
		void RW_IN_Commands (void);
		void RW_IN_Move (usercmd_t *cmd);
		void RW_IN_Frame (void);
		void RW_IN_Activate(void);
		
		RW_IN_Init_fp = RW_IN_Init;
		RW_IN_Shutdown_fp = RW_IN_Shutdown;
		RW_IN_Activate_fp = RW_IN_Activate;
		RW_IN_Commands_fp = RW_IN_Commands;
		RW_IN_Move_fp = RW_IN_Move;
		RW_IN_Frame_fp = RW_IN_Frame;
	}
#endif

	if ( re.Init( 0, 0 ) == -1 )
	{
		re.Shutdown();
		VID_FreeReflib ();
		return false;
	}

/* merged in from irix/vid_so.c */
#ifdef __sgi
	/* give up root now */
	setreuid(getuid(), getuid());
	setegid(getgid());
#endif

	/* Init KBD */
#ifndef REF_HARD_LINKED
	if ((KBD_Init_fp = (void(*)(Key_Event_fp_t)) dlsym(reflib_library, "KBD_Init")) == NULL ||
		(KBD_Update_fp = (void(*)(void)) dlsym(reflib_library, "KBD_Update")) == NULL ||
		(KBD_Close_fp = (void(*)(void)) dlsym(reflib_library, "KBD_Close")) == NULL)
		Sys_Error("No KBD functions in REF.\n");
#else
	{
		void KBD_Init(void);
		void KBD_Update(void);
		void KBD_Close(void);

		KBD_Init_fp = KBD_Init;
		KBD_Update_fp = KBD_Update;
		KBD_Close_fp = KBD_Close;
	}
#endif
	KBD_Init_fp(Do_Key_Event);

	/* for some reason irix has this swapped with elsewhere, kinda dodgy, needs
	 * cleaning */
#ifndef __sgi
	Key_ClearStates();
	
	// give up root now
	setreuid(getuid(), getuid());
	setegid(getgid());
#else
	Real_IN_Init();
#endif

	Com_Printf( "------------------------------------\n");
	reflib_active = true;
	return true;
}

/*
============
VID_CheckChanges

This function gets called once just before drawing each frame, and it's sole purpose in life
is to check to see if any of the video mode parameters have changed, and if they have to 
update the rendering DLL and/or video mode to match.
============
*/
void VID_CheckChanges (void)
{
	char name[100];
	cvar_t *sw_mode;

	if ( vid_ref->modified )
	{
		S_StopAllSounds();
	}

	while (vid_ref->modified)
	{
		/*
		** refresh has changed
		*/
		vid_ref->modified = false;
		vid_fullscreen->modified = true;
		cl.refresh_prepped = false;
		cls.disable_screen = true;

		sprintf( name, "ref_%s.so", vid_ref->string );
		if ( !VID_LoadRefresh( name ) )
		{
			if ( strcmp (vid_ref->string, "soft") == 0 || 
					strcmp (vid_ref->string, "softx") == 0 ) {
				Com_Printf("Refresh failed\n");
				sw_mode = Cvar_Get( "sw_mode", "0", 0 );
				if (sw_mode->value != 0) {
					Com_Printf("Trying mode 0\n");
					Cvar_SetValue("sw_mode", 0);
					if ( !VID_LoadRefresh( name ) )
						Com_Error (ERR_FATAL, "Couldn't fall back to software refresh!");
				} else
					Com_Error (ERR_FATAL, "Couldn't fall back to software refresh!");
			}

			/* prefer to fall back on X if active */
			if (getenv("DISPLAY"))
				Cvar_Set( "vid_ref", "softx" );
			else
				Cvar_Set( "vid_ref", "soft" );

			/*
			** drop the console if we fail to load a refresh
			*/
			if ( cls.key_dest != key_console )
			{
				Con_ToggleConsole_f();
			}
		}
		cls.disable_screen = false;
	}

}

/*
============
VID_Init
============
*/
void VID_Init (void)
{
	/* Create the video variables so we know how to start the graphics drivers */
	// if DISPLAY is defined, try X
	if (getenv("DISPLAY"))
		vid_ref = Cvar_Get ("vid_ref", "softx", CVAR_ARCHIVE);
	else
		vid_ref = Cvar_Get ("vid_ref", "soft", CVAR_ARCHIVE);
	vid_xpos = Cvar_Get ("vid_xpos", "3", CVAR_ARCHIVE);
	vid_ypos = Cvar_Get ("vid_ypos", "22", CVAR_ARCHIVE);
	vid_fullscreen = Cvar_Get ("vid_fullscreen", "0", CVAR_ARCHIVE);
	vid_gamma = Cvar_Get( "vid_gamma", "1", CVAR_ARCHIVE );

	/* Add some console commands that we want to handle */
	Cmd_AddCommand ("vid_restart", VID_Restart_f);

	/* Disable the 3Dfx splash screen */
	putenv("FX_GLIDE_NO_SPLASH=0");
		
	/* Start the graphics mode and load refresh DLL */
	VID_CheckChanges();
}

/*
============
VID_Shutdown
============
*/
void VID_Shutdown (void)
{
	if ( reflib_active )
	{
		if (KBD_Close_fp)
			KBD_Close_fp();
		if (RW_IN_Shutdown_fp)
			RW_IN_Shutdown_fp();
		KBD_Close_fp = NULL;
		RW_IN_Shutdown_fp = NULL;
		re.Shutdown ();
		VID_FreeReflib ();
	}
}


/*****************************************************************************/
/* INPUT                                                                     */
/*****************************************************************************/

cvar_t	*in_joystick;

// This is fake, it's acutally done by the Refresh load
void IN_Init (void)
{
	in_joystick	= Cvar_Get ("in_joystick", "0", CVAR_ARCHIVE);
}

void Real_IN_Init (void)
{
	if (RW_IN_Init_fp)
		RW_IN_Init_fp(&in_state);
}

void IN_Shutdown (void)
{
	if (RW_IN_Shutdown_fp)
		RW_IN_Shutdown_fp();
}

void IN_Commands (void)
{
	if (RW_IN_Commands_fp)
		RW_IN_Commands_fp();
}

void IN_Move (usercmd_t *cmd)
{
	if (RW_IN_Move_fp)
		RW_IN_Move_fp(cmd);
}

void IN_Frame (void)
{
/* merged from irix/vid_so.c */
#ifndef __sgi
	if (RW_IN_Activate_fp) 
	{
		if ( !cl.refresh_prepped || cls.key_dest == key_console || cls.key_dest == key_menu)
			RW_IN_Activate_fp(false);
		else
			RW_IN_Activate_fp(true);
	}
#endif

	if (RW_IN_Frame_fp)
		RW_IN_Frame_fp();
}

void IN_Activate (qboolean active) {
/* merged in from irix/vid_so.c -- jaq */
#ifdef __sgi
	if (RW_IN_Activate_fp)
		RW_IN_Activate_fp(active);
#endif
}

void Do_Key_Event(int key, qboolean down)
{
	Key_Event(key, down, Sys_Milliseconds());
}

char *Sys_GetClipboardData(void)
{
	if (RW_Sys_GetClipboardData_fp)
		return RW_Sys_GetClipboardData_fp();
    else
		return NULL;
}
