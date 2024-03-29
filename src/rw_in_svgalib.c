/* $Id$
*
* Copyright(C) 1997-2001 Id Software, Inc.
* Copyright(c) 2002 The Quakeforge Project.
* 
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or(at your option) any later version.
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <termios.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <stdarg.h>
#include <stdio.h>
#include <signal.h>
#include <sys/mman.h>

/* seems to work fine without
#ifdef HAVE_SYS_VT_H
# include <sys/vt.h>
#endif
*/

#include "vga.h"
#include "vgakeyboard.h"
#include "vgamouse.h"

#include "r_local.h"
#include "keys.h"
#include "rw.h"

/*****************************************************************************/
/* KEYBOARD                                                                  */
/*****************************************************************************/

static unsigned char scantokey[128];
Key_Event_fp_t Key_Event_fp;

static void keyhandler(int scancode, int state){
	int sc;
	
	sc = scancode & 0x7f;
	//ri.Con_Printf(PRINT_ALL, "scancode=%x(%d%s)\n", scancode, sc, scancode&0x80?"+128":"");
	Key_Event_fp(scantokey[sc], state == KEY_EVENTPRESS);
}

void KBD_Init(Key_Event_fp_t fp){
	int i;
	
	Key_Event_fp = fp;
	
	for(i = 0; i < 128; i++)
		scantokey[i] = ' ';
		
	scantokey[ 1] = K_ESCAPE;
	scantokey[ 2] = '1';
	scantokey[ 3] = '2';
	scantokey[ 4] = '3';
	scantokey[ 5] = '4';
	scantokey[ 6] = '5';
	scantokey[ 7] = '6';
	scantokey[ 8] = '7';
	scantokey[ 9] = '8';
	scantokey[ 10] = '9';
	scantokey[ 11] = '0';
	scantokey[ 12] = '-';
	scantokey[ 13] = '=';
	scantokey[ 14] = K_BACKSPACE;
	scantokey[ 15] = K_TAB;
	scantokey[ 16] = 'q';
	scantokey[ 17] = 'w';
	scantokey[ 18] = 'e';
	scantokey[ 19] = 'r';
	scantokey[ 20] = 't';
	scantokey[ 21] = 'y';
	scantokey[ 22] = 'u';
	scantokey[ 23] = 'i';
	scantokey[ 24] = 'o';
	scantokey[ 25] = 'p';
	scantokey[ 26] = '[';
	scantokey[ 27] = ']';
	scantokey[ 28] = K_ENTER;
	scantokey[ 29] = K_CTRL; //left
	scantokey[ 30] = 'a';
	scantokey[ 31] = 's';
	scantokey[ 32] = 'd';
	scantokey[ 33] = 'f';
	scantokey[ 34] = 'g';
	scantokey[ 35] = 'h';
	scantokey[ 36] = 'j';
	scantokey[ 37] = 'k';
	scantokey[ 38] = 'l';
	scantokey[ 39] = ';';
	scantokey[ 40] = '\'';
	scantokey[ 41] = '`';
	scantokey[ 42] = K_SHIFT; //left
	scantokey[ 43] = '\\';
	scantokey[ 44] = 'z';
	scantokey[ 45] = 'x';
	scantokey[ 46] = 'c';
	scantokey[ 47] = 'v';
	scantokey[ 48] = 'b';
	scantokey[ 49] = 'n';
	scantokey[ 50] = 'm';
	scantokey[ 51] = ',';
	scantokey[ 52] = '.';
	scantokey[ 53] = '/';
	scantokey[ 54] = K_SHIFT; //right
	scantokey[ 55] = '*'; //keypad
	scantokey[ 56] = K_ALT; //left
	scantokey[ 57] = ' ';
	// 58 caps lock
	scantokey[ 59] = K_F1;
	scantokey[ 60] = K_F2;
	scantokey[ 61] = K_F3;
	scantokey[ 62] = K_F4;
	scantokey[ 63] = K_F5;
	scantokey[ 64] = K_F6;
	scantokey[ 65] = K_F7;
	scantokey[ 66] = K_F8;
	scantokey[ 67] = K_F9;
	scantokey[ 68] = K_F10;
	// 69 numlock
	// 70 scrollock
	scantokey[ 71] = K_KP_HOME;
	scantokey[ 72] = K_KP_UPARROW;
	scantokey[ 73] = K_KP_PGUP;
	scantokey[ 74] = K_KP_MINUS;
	scantokey[ 75] = K_KP_LEFTARROW;
	scantokey[ 76] = K_KP_5;
	scantokey[ 77] = K_KP_RIGHTARROW;
	scantokey[ 79] = K_KP_END;
	scantokey[ 78] = K_KP_PLUS;
	scantokey[ 80] = K_KP_DOWNARROW;
	scantokey[ 81] = K_KP_PGDN;
	scantokey[ 82] = K_KP_INS;
	scantokey[ 83] = K_KP_DEL;
	// 84 to 86 not used
	scantokey[ 87] = K_F11;
	scantokey[ 88] = K_F12;
	// 89 to 95 not used
	scantokey[ 96] = K_KP_ENTER; //keypad enter
	scantokey[ 97] = K_CTRL; //right
	scantokey[ 98] = K_KP_SLASH;
	scantokey[ 99] = K_F12; // print screen, bind to screenshot by default
	scantokey[100] = K_ALT; // right
	
	scantokey[101] = K_PAUSE; // break
	scantokey[102] = K_HOME;
	scantokey[103] = K_UPARROW;
	scantokey[104] = K_PGUP;
	scantokey[105] = K_LEFTARROW;
	scantokey[106] = K_RIGHTARROW;
	scantokey[107] = K_END;
	scantokey[108] = K_DOWNARROW;
	scantokey[109] = K_PGDN;
	scantokey[110] = K_INS;
	scantokey[111] = K_DEL;
	
	scantokey[119] = K_PAUSE;
	
	if(keyboard_init())
		Sys_Error("keyboard_init() failed");
	keyboard_seteventhandler(keyhandler);
	keyboard_translatekeys(DONT_CATCH_CTRLC);
}

void KBD_Update(void){
	while(keyboard_update())
		;
}

void KBD_Close(void){
	keyboard_close();
}

/*****************************************************************************/
/* MOUSE                                                                     */
/*****************************************************************************/

// this is inside the renderer shared lib, so these are called from vid_so

static qboolean	UseMouse = true;

static int mouse_buttons;
static int mouse_buttonstate;
static int mouse_oldbuttonstate;
static float mouse_x, mouse_y;
static float old_mouse_x, old_mouse_y;
static int mx, my;
static int mwheel;

static cvar_t	*m_filter;
static cvar_t	*in_mouse;

static qboolean	mlooking;

// state struct passed in Init
static in_state_t	*in_state;

static cvar_t *sensitivity;
static cvar_t *lookstrafe;
static cvar_t *m_side;
static cvar_t *m_yaw;
static cvar_t *m_pitch;
static cvar_t *m_forward;
static cvar_t *freelook;

static void Force_CenterView_f(void){
	in_state->viewangles[PITCH] = 0;
}

static void RW_IN_MLookDown(void){
	mlooking = true;
}

static void RW_IN_MLookUp(void){
	mlooking = false;
	in_state->IN_CenterView_fp();
}

#if 0 /* old definition */
static void mousehandler(int buttonstate, int dx, int dy){
	mouse_buttonstate = buttonstate;
	mx += dx;
	my += dy;
}
#else /* drx is assumed to be the mouse wheel */
static void mousehandler(int buttonstate, int dx, int dy, int dz, int drx, int dry, int drz){
	mouse_buttonstate = buttonstate;
	mx += dx;
	my += dy;

	mwheel = drx;
}
#endif

void RW_IN_Init(in_state_t *in_state_p){
	in_state = in_state_p;
	
	// mouse variables
	m_filter = ri.Cvar_Get("m_filter", "0", 0);
	in_mouse = ri.Cvar_Get("in_mouse", "1", CVAR_ARCHIVE);
	freelook = ri.Cvar_Get( "freelook", "0", 0);
	lookstrafe = ri.Cvar_Get("lookstrafe", "0", 0);
	sensitivity = ri.Cvar_Get("sensitivity", "3", 0);
	m_pitch = ri.Cvar_Get("m_pitch", "0.022", 0);
	m_yaw = ri.Cvar_Get("m_yaw", "0.022", 0);
	m_forward = ri.Cvar_Get("m_forward", "1", 0);
	m_side = ri.Cvar_Get("m_side", "0.8", 0);
	
	ri.Cmd_AddCommand("+mlook", RW_IN_MLookDown);
	ri.Cmd_AddCommand("-mlook", RW_IN_MLookUp);
	
	ri.Cmd_AddCommand("force_centerview", Force_CenterView_f);
	
	mouse_buttons = 3;
	
	if(vga_getmousetype() == MOUSE_NONE){
		ri.Con_Printf(PRINT_ALL, "No mouse found\n");
		UseMouse = false;
	} else {
		vga_setmousesupport(1);
		mouse_seteventhandler((__mouse_handler) mousehandler);
	}
}

void RW_IN_Shutdown(void){}

/*
===========
IN_Commands
===========
*/
void RW_IN_Commands(void){
	if(!UseMouse)
		return;
		
	// poll mouse values
	mouse_update();
	
	// perform button actions
	if((mouse_buttonstate & MOUSE_LEFTBUTTON) &&
			!(mouse_oldbuttonstate & MOUSE_LEFTBUTTON))
		in_state->Key_Event_fp(K_MOUSE1, true);
	else if(!(mouse_buttonstate & MOUSE_LEFTBUTTON) &&
			(mouse_oldbuttonstate & MOUSE_LEFTBUTTON))
		in_state->Key_Event_fp(K_MOUSE1, false);
		
	if((mouse_buttonstate & MOUSE_RIGHTBUTTON) &&
			!(mouse_oldbuttonstate & MOUSE_RIGHTBUTTON))
		in_state->Key_Event_fp(K_MOUSE2, true);
	else if(!(mouse_buttonstate & MOUSE_RIGHTBUTTON) &&
			(mouse_oldbuttonstate & MOUSE_RIGHTBUTTON))
		in_state->Key_Event_fp(K_MOUSE2, false);
		
	if((mouse_buttonstate & MOUSE_MIDDLEBUTTON) &&
			!(mouse_oldbuttonstate & MOUSE_MIDDLEBUTTON))
		in_state->Key_Event_fp(K_MOUSE3, true);
	else if(!(mouse_buttonstate & MOUSE_MIDDLEBUTTON) &&
			(mouse_oldbuttonstate & MOUSE_MIDDLEBUTTON))
		in_state->Key_Event_fp(K_MOUSE3, false);
		
	mouse_oldbuttonstate = mouse_buttonstate;
	
	if(mwheel < 0){
		in_state->Key_Event_fp(K_MWHEELUP, true);
		in_state->Key_Event_fp(K_MWHEELUP, false);
	}
	if(mwheel > 0){
		in_state->Key_Event_fp(K_MWHEELDOWN, true);
		in_state->Key_Event_fp(K_MWHEELDOWN, false);
	}
	mwheel = 0;
}

/*
===========
IN_Move
===========
*/
void RW_IN_Move(usercmd_t *cmd){
	if(!UseMouse)
		return;
		
	// poll mouse values
	mouse_update();
	
	if(m_filter->value){
		mouse_x =(mx + old_mouse_x) * 0.5;
		mouse_y =(my + old_mouse_y) * 0.5;
	} else {
		mouse_x = mx;
		mouse_y = my;
	}
	old_mouse_x = mx;
	old_mouse_y = my;
	
	if(!mx && !my)
		return;
		
	mx = my = 0; // clear for next update
	
	mouse_x *= sensitivity->value;
	mouse_y *= sensitivity->value;
	
	// add mouse X/Y movement to cmd
	if((*in_state->in_strafe_state & 1) ||
			(lookstrafe->value && mlooking))
		cmd->sidemove += m_side->value * mouse_x;
	else
		in_state->viewangles[YAW] -= m_yaw->value * mouse_x;
		
	if((mlooking || freelook->value) &&
			!(*in_state->in_strafe_state & 1)){
		in_state->viewangles[PITCH] += m_pitch->value * mouse_y;
	} else {
		cmd->forwardmove -= m_forward->value * mouse_y;
	}
}

void RW_IN_Frame(void){}

void RW_IN_Activate(void){}



