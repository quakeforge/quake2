#
# Quake2 Makefile
#
# Nov '97 by Zoid <zoid@idsoftware.com>
# Dec '01 by Steven Fuller <relnev@icculus.org>
# Jan '02 by Jamie Wilkinson <jaq@spacepants.org>

# start of configurable options

# Here are your build options, no more will be added!
# (Note: not all options are available for all platforms).
# quake2 (uses OSS for sound, cdrom ioctls for cd audio) is automatically built.
# game$(ARCH).so is automatically built.
BUILD_SDLQUAKE2=YES	# sdlquake2 executable (uses SDL for cdrom and sound)
BUILD_SVGA=YES		# SVGAlib driver. Seems to work fine.
BUILD_X11=YES		# X11 software driver. Works somewhat ok.
BUILD_GLX=YES		# X11 GLX driver. Works somewhat ok.
BUILD_FXGL=NO		# FXMesa driver. Not tested. (used only for V1 and V2).
BUILD_SDL=YES		# SDL software driver. Works fine for some people.
BUILD_SDLGL=YES		# SDL OpenGL driver. Works fine for some people.
BUILD_CTFDLL=YES		# gamei386.so for ctf
# i can add support for building xatrix and rogue libs if needed

# this nice line comes from the linux kernel makefile
ARCH := $(shell uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc/ -e s/sparc64/sparc/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/alpha/axp/)

CC=gcc

RELEASE_CFLAGS=$(BASE_CFLAGS) -ffast-math -funroll-loops \
	-fomit-frame-pointer -fexpensive-optimizations

ifeq ($(ARCH),i386)
RELEASE_CFLAGS+=-O2 -malign-loops=2 -malign-jumps=2 -malign-functions=2 -g
# compiler bugs with gcc 2.96 and 3.0.1 can cause bad builds with heavy opts.
#RELEASE_CFLAGS=$(BASE_CFLAGS) -O6 -m486 -ffast-math -funroll-loops \
#	-fomit-frame-pointer -fexpensive-optimizations -malign-loops=2 \
#	-malign-jumps=2 -malign-functions=2
endif

# (hopefully) end of configurable options
VERSION=3.21

MOUNT_DIR=.

BUILD_DEBUG_DIR=debug$(ARCH)
BUILD_RELEASE_DIR=release$(ARCH)
CLIENT_DIR=$(MOUNT_DIR)/client
SERVER_DIR=$(MOUNT_DIR)/server
REF_SOFT_DIR=$(MOUNT_DIR)/ref_soft
REF_GL_DIR=$(MOUNT_DIR)/ref_gl
COMMON_DIR=$(MOUNT_DIR)/qcommon
LINUX_DIR=$(MOUNT_DIR)/linux
GAME_DIR=$(MOUNT_DIR)/game
CTF_DIR=$(MOUNT_DIR)/ctf
XATRIX_DIR=$(MOUNT_DIR)/xatrix

BASE_CFLAGS=-Dstricmp=strcasecmp -Wall -Werror -pipe

ifneq ($(ARCH),i386)
  BASE_CFLAGS+=-DC_ONLY
endif

DEBUG_CFLAGS=$(BASE_CFLAGS) -g

LDFLAGS=-lm -ldl

SVGALDFLAGS=-lvga

XCFLAGS=
XLDFLAGS=-L/usr/X11R6/lib -lX11 -lXext -lXxf86dga -lXxf86vm

SDLCFLAGS=$(shell sdl-config --cflags)
SDLLDFLAGS=$(shell sdl-config --libs)

FXGLCFLAGS=
FXGLLDFLAGS=-L/usr/local/glide/lib -L/usr/X11/lib -L/usr/local/lib \
	-L/usr/X11R6/lib -lX11 -lXext -lGL -lvga

GLXCFLAGS=
GLXLDFLAGS=-L/usr/X11R6/lib -lX11 -lXext -lXxf86dga -lXxf86vm

SDLGLCFLAGS=$(SDLCFLAGS) -DOPENGL
SDLGLLDFLAGS=$(shell sdl-config --libs)

SHLIBEXT=so

SHLIBCFLAGS=-fPIC
SHLIBLDFLAGS=-shared

# added $(ARCH) here as make would munge the quoting in BASE_CFLAGS above
DO_CC=$(CC) -DARCH=\""$(ARCH)"\" $(CFLAGS) -o $@ -c $<
DO_SHLIB_CC=$(CC) -DARCH=\""$(ARCH)"\" $(CFLAGS) $(SHLIBCFLAGS) -o $@ -c $<
DO_GL_SHLIB_CC=$(CC) -DARCH=\""$(ARCH)"\" $(CFLAGS) $(SHLIBCFLAGS) $(GLCFLAGS) -o $@ -c $<
DO_AS=$(CC) -DARCH=\""$(ARCH)"\" $(CFLAGS) -DELF -x assembler-with-cpp -o $@ -c $<
DO_SHLIB_AS=$(CC) -DARCH=\""$(ARCH)"\" $(CFLAGS) $(SHLIBCFLAGS) -DELF -x assembler-with-cpp -o $@ -c $<

#############################################################################
# SETUP AND BUILD
#############################################################################

.PHONY : targets build_debug build_release clean clean-debug clean-release clean2

TARGETS=$(BUILDDIR)/quake2 $(BUILDDIR)/game$(ARCH).$(SHLIBEXT)

ifeq ($(strip $(BUILD_CTFDLL)),YES)
 TARGETS += $(BUILDDIR)/ctf/game$(ARCH).$(SHLIBEXT)
endif

 ifeq ($(strip $(BUILD_SDLQUAKE2)),YES)
  TARGETS += $(BUILDDIR)/sdlquake2
 endif

# svgalib just doesn't work with non-i386 at the moment, so don't bother
ifeq ($(ARCH),i386)
 ifeq ($(strip $(BUILD_SVGA)),YES)
  TARGETS += $(BUILDDIR)/ref_soft.$(SHLIBEXT)
 endif
endif

 ifeq ($(strip $(BUILD_X11)),YES)
  TARGETS += $(BUILDDIR)/ref_softx.$(SHLIBEXT)
 endif

 ifeq ($(strip $(BUILD_GLX)),YES)
  TARGETS += $(BUILDDIR)/ref_glx.$(SHLIBEXT)
 endif

 ifeq ($(strip $(BUILD_FXGL)),YES)
  TARGETS += $(BUILDDIR)/ref_gl.$(SHLIBEXT)
 endif

 ifeq ($(strip $(BUILD_SDL)),YES)
  TARGETS += $(BUILDDIR)/ref_softsdl.$(SHLIBEXT)
 endif

 ifeq ($(strip $(BUILD_SDLGL)),YES)
  TARGETS += $(BUILDDIR)/ref_sdlgl.$(SHLIBEXT)
 endif

all: build_debug build_release

build_debug:
	@-mkdir -p $(BUILD_DEBUG_DIR) \
		$(BUILD_DEBUG_DIR)/client \
		$(BUILD_DEBUG_DIR)/ref_soft \
		$(BUILD_DEBUG_DIR)/ref_gl \
		$(BUILD_DEBUG_DIR)/game \
		$(BUILD_DEBUG_DIR)/ctf
	$(MAKE) targets BUILDDIR=$(BUILD_DEBUG_DIR) CFLAGS="$(DEBUG_CFLAGS)"

build_release:
	@-mkdir -p $(BUILD_RELEASE_DIR) \
		$(BUILD_RELEASE_DIR)/client \
		$(BUILD_RELEASE_DIR)/ref_soft \
		$(BUILD_RELEASE_DIR)/ref_gl \
		$(BUILD_RELEASE_DIR)/game \
		$(BUILD_RELEASE_DIR)/ctf
	$(MAKE) targets BUILDDIR=$(BUILD_RELEASE_DIR) CFLAGS="$(RELEASE_CFLAGS)"

targets: $(TARGETS)

#############################################################################
# CLIENT/SERVER
#############################################################################

QUAKE2_OBJS = \
	$(BUILDDIR)/client/cl_cin.o \
	$(BUILDDIR)/client/cl_ents.o \
	$(BUILDDIR)/client/cl_fx.o \
	$(BUILDDIR)/client/cl_input.o \
	$(BUILDDIR)/client/cl_inv.o \
	$(BUILDDIR)/client/cl_main.o \
	$(BUILDDIR)/client/cl_parse.o \
	$(BUILDDIR)/client/cl_pred.o \
	$(BUILDDIR)/client/cl_tent.o \
	$(BUILDDIR)/client/cl_scrn.o \
	$(BUILDDIR)/client/cl_view.o \
	$(BUILDDIR)/client/cl_newfx.o \
	$(BUILDDIR)/client/console.o \
	$(BUILDDIR)/client/keys.o \
	$(BUILDDIR)/client/menu.o \
	$(BUILDDIR)/client/snd_dma.o \
	$(BUILDDIR)/client/snd_mem.o \
	$(BUILDDIR)/client/snd_mix.o \
	$(BUILDDIR)/client/qmenu.o \
	$(BUILDDIR)/client/m_flash.o \
	\
	$(BUILDDIR)/client/checksum.o \
	$(BUILDDIR)/client/cmd.o \
	$(BUILDDIR)/client/cmodel.o \
	$(BUILDDIR)/client/common.o \
	$(BUILDDIR)/client/crc.o \
	$(BUILDDIR)/client/cvar.o \
	$(BUILDDIR)/client/files.o \
	$(BUILDDIR)/client/mdfour.o \
	$(BUILDDIR)/client/net_chan.o \
	\
	$(BUILDDIR)/client/sv_ccmds.o \
	$(BUILDDIR)/client/sv_ents.o \
	$(BUILDDIR)/client/sv_game.o \
	$(BUILDDIR)/client/sv_init.o \
	$(BUILDDIR)/client/sv_main.o \
	$(BUILDDIR)/client/sv_send.o \
	$(BUILDDIR)/client/sv_user.o \
	$(BUILDDIR)/client/sv_world.o \
	\
	$(BUILDDIR)/client/q_shlinux.o \
	$(BUILDDIR)/client/vid_menu.o \
	$(BUILDDIR)/client/vid_so.o \
	$(BUILDDIR)/client/sys_linux.o \
	$(BUILDDIR)/client/glob.o \
	$(BUILDDIR)/client/net_udp.o \
	\
	$(BUILDDIR)/client/q_shared.o \
	$(BUILDDIR)/client/pmove.o

QUAKE2_LNX_OBJS = \
	$(BUILDDIR)/client/cd_linux.o \
	$(BUILDDIR)/client/snd_linux.o

QUAKE2_SDL_OBJS = \
	$(BUILDDIR)/client/cd_sdl.o \
	$(BUILDDIR)/client/snd_sdl.o

# more i386 asm
ifeq ($(ARCH),i386)
QUAKE2_AS_OBJS = $(BUILDDIR)/client/snd_mixa.o
else
QUAKE2_AS_OBJS =  #blank
endif

$(BUILDDIR)/quake2 : $(QUAKE2_OBJS) $(QUAKE2_LNX_OBJS) $(QUAKE2_AS_OBJS)
	$(CC) $(CFLAGS) -o $@ $(QUAKE2_OBJS) $(QUAKE2_LNX_OBJS) $(QUAKE2_AS_OBJS) $(LDFLAGS)

$(BUILDDIR)/sdlquake2 : $(QUAKE2_OBJS) $(QUAKE2_SDL_OBJS) $(QUAKE2_AS_OBJS)
	$(CC) $(CFLAGS) -o $@ $(QUAKE2_OBJS) $(QUAKE2_SDL_OBJS) $(QUAKE2_AS_OBJS) $(LDFLAGS) $(SDLLDFLAGS)

$(BUILDDIR)/client/cl_cin.o :     $(CLIENT_DIR)/cl_cin.c
	$(DO_CC)

$(BUILDDIR)/client/cl_ents.o :    $(CLIENT_DIR)/cl_ents.c
	$(DO_CC)

$(BUILDDIR)/client/cl_fx.o :      $(CLIENT_DIR)/cl_fx.c
	$(DO_CC)

$(BUILDDIR)/client/cl_input.o :   $(CLIENT_DIR)/cl_input.c
	$(DO_CC)

$(BUILDDIR)/client/cl_inv.o :     $(CLIENT_DIR)/cl_inv.c
	$(DO_CC)

$(BUILDDIR)/client/cl_main.o :    $(CLIENT_DIR)/cl_main.c
	$(DO_CC)

$(BUILDDIR)/client/cl_parse.o :   $(CLIENT_DIR)/cl_parse.c
	$(DO_CC)

$(BUILDDIR)/client/cl_pred.o :    $(CLIENT_DIR)/cl_pred.c
	$(DO_CC)

$(BUILDDIR)/client/cl_tent.o :    $(CLIENT_DIR)/cl_tent.c
	$(DO_CC)

$(BUILDDIR)/client/cl_scrn.o :    $(CLIENT_DIR)/cl_scrn.c
	$(DO_CC)

$(BUILDDIR)/client/cl_view.o :    $(CLIENT_DIR)/cl_view.c
	$(DO_CC)

$(BUILDDIR)/client/cl_newfx.o :	  $(CLIENT_DIR)/cl_newfx.c
	$(DO_CC)

$(BUILDDIR)/client/console.o :    $(CLIENT_DIR)/console.c
	$(DO_CC)

$(BUILDDIR)/client/keys.o :       $(CLIENT_DIR)/keys.c
	$(DO_CC)

$(BUILDDIR)/client/menu.o :       $(CLIENT_DIR)/menu.c
	$(DO_CC)

$(BUILDDIR)/client/snd_dma.o :    $(CLIENT_DIR)/snd_dma.c
	$(DO_CC)

$(BUILDDIR)/client/snd_mem.o :    $(CLIENT_DIR)/snd_mem.c
	$(DO_CC)

$(BUILDDIR)/client/snd_mix.o :    $(CLIENT_DIR)/snd_mix.c
	$(DO_CC)

$(BUILDDIR)/client/qmenu.o :      $(CLIENT_DIR)/qmenu.c
	$(DO_CC)

$(BUILDDIR)/client/m_flash.o :    $(GAME_DIR)/m_flash.c
	$(DO_CC)

$(BUILDDIR)/client/checksum.o :   $(COMMON_DIR)/checksum.c
	$(DO_CC)

$(BUILDDIR)/client/cmd.o :        $(COMMON_DIR)/cmd.c
	$(DO_CC)

$(BUILDDIR)/client/cmodel.o :     $(COMMON_DIR)/cmodel.c
	$(DO_CC)

$(BUILDDIR)/client/common.o :     $(COMMON_DIR)/common.c
	$(DO_CC)

$(BUILDDIR)/client/crc.o :        $(COMMON_DIR)/crc.c
	$(DO_CC)

$(BUILDDIR)/client/cvar.o :       $(COMMON_DIR)/cvar.c
	$(DO_CC)

$(BUILDDIR)/client/files.o :      $(COMMON_DIR)/files.c
	$(DO_CC)

$(BUILDDIR)/client/mdfour.o :        $(COMMON_DIR)/mdfour.c
	$(DO_CC)

$(BUILDDIR)/client/net_chan.o :   $(COMMON_DIR)/net_chan.c
	$(DO_CC)

$(BUILDDIR)/client/q_shared.o :   $(GAME_DIR)/q_shared.c
	$(DO_CC)

$(BUILDDIR)/client/pmove.o :      $(COMMON_DIR)/pmove.c
	$(DO_CC)

$(BUILDDIR)/client/sv_ccmds.o :   $(SERVER_DIR)/sv_ccmds.c
	$(DO_CC)

$(BUILDDIR)/client/sv_ents.o :    $(SERVER_DIR)/sv_ents.c
	$(DO_CC)

$(BUILDDIR)/client/sv_game.o :    $(SERVER_DIR)/sv_game.c
	$(DO_CC)

$(BUILDDIR)/client/sv_init.o :    $(SERVER_DIR)/sv_init.c
	$(DO_CC)

$(BUILDDIR)/client/sv_main.o :    $(SERVER_DIR)/sv_main.c
	$(DO_CC)

$(BUILDDIR)/client/sv_send.o :    $(SERVER_DIR)/sv_send.c
	$(DO_CC)

$(BUILDDIR)/client/sv_user.o :    $(SERVER_DIR)/sv_user.c
	$(DO_CC)

$(BUILDDIR)/client/sv_world.o :   $(SERVER_DIR)/sv_world.c
	$(DO_CC)

$(BUILDDIR)/client/q_shlinux.o :  $(LINUX_DIR)/q_shlinux.c
	$(DO_CC)

$(BUILDDIR)/client/vid_menu.o :   $(LINUX_DIR)/vid_menu.c
	$(DO_CC)

$(BUILDDIR)/client/vid_so.o :     $(LINUX_DIR)/vid_so.c
	$(DO_CC)

$(BUILDDIR)/client/snd_mixa.o :   $(LINUX_DIR)/snd_mixa.S
	$(DO_AS)

$(BUILDDIR)/client/sys_linux.o :  $(LINUX_DIR)/sys_linux.c
	$(DO_CC)

$(BUILDDIR)/client/glob.o :       $(LINUX_DIR)/glob.c
	$(DO_CC)

$(BUILDDIR)/client/net_udp.o :    $(LINUX_DIR)/net_udp.c
	$(DO_CC)

$(BUILDDIR)/client/cd_linux.o :   $(LINUX_DIR)/cd_linux.c
	$(DO_CC)

$(BUILDDIR)/client/snd_linux.o :  $(LINUX_DIR)/snd_linux.c
	$(DO_CC)

$(BUILDDIR)/client/cd_sdl.o :     $(LINUX_DIR)/cd_sdl.c
	$(DO_CC) $(SDLCFLAGS)

$(BUILDDIR)/client/snd_sdl.o :     $(LINUX_DIR)/snd_sdl.c
	$(DO_CC) $(SDLCFLAGS)

#############################################################################
# GAME
#############################################################################

GAME_OBJS = \
	$(BUILDDIR)/game/g_ai.o \
	$(BUILDDIR)/game/p_client.o \
	$(BUILDDIR)/game/g_chase.o \
	$(BUILDDIR)/game/g_cmds.o \
	$(BUILDDIR)/game/g_svcmds.o \
	$(BUILDDIR)/game/g_combat.o \
	$(BUILDDIR)/game/g_func.o \
	$(BUILDDIR)/game/g_items.o \
	$(BUILDDIR)/game/g_main.o \
	$(BUILDDIR)/game/g_misc.o \
	$(BUILDDIR)/game/g_monster.o \
	$(BUILDDIR)/game/g_phys.o \
	$(BUILDDIR)/game/g_save.o \
	$(BUILDDIR)/game/g_spawn.o \
	$(BUILDDIR)/game/g_target.o \
	$(BUILDDIR)/game/g_trigger.o \
	$(BUILDDIR)/game/g_turret.o \
	$(BUILDDIR)/game/g_utils.o \
	$(BUILDDIR)/game/g_weapon.o \
	$(BUILDDIR)/game/m_actor.o \
	$(BUILDDIR)/game/m_berserk.o \
	$(BUILDDIR)/game/m_boss2.o \
	$(BUILDDIR)/game/m_boss3.o \
	$(BUILDDIR)/game/m_boss31.o \
	$(BUILDDIR)/game/m_boss32.o \
	$(BUILDDIR)/game/m_brain.o \
	$(BUILDDIR)/game/m_chick.o \
	$(BUILDDIR)/game/m_flipper.o \
	$(BUILDDIR)/game/m_float.o \
	$(BUILDDIR)/game/m_flyer.o \
	$(BUILDDIR)/game/m_gladiator.o \
	$(BUILDDIR)/game/m_gunner.o \
	$(BUILDDIR)/game/m_hover.o \
	$(BUILDDIR)/game/m_infantry.o \
	$(BUILDDIR)/game/m_insane.o \
	$(BUILDDIR)/game/m_medic.o \
	$(BUILDDIR)/game/m_move.o \
	$(BUILDDIR)/game/m_mutant.o \
	$(BUILDDIR)/game/m_parasite.o \
	$(BUILDDIR)/game/m_soldier.o \
	$(BUILDDIR)/game/m_supertank.o \
	$(BUILDDIR)/game/m_tank.o \
	$(BUILDDIR)/game/p_hud.o \
	$(BUILDDIR)/game/p_trail.o \
	$(BUILDDIR)/game/p_view.o \
	$(BUILDDIR)/game/p_weapon.o \
	$(BUILDDIR)/game/q_shared.o \
	$(BUILDDIR)/game/m_flash.o

$(BUILDDIR)/game$(ARCH).$(SHLIBEXT) : $(GAME_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(GAME_OBJS)

$(BUILDDIR)/game/g_ai.o :        $(GAME_DIR)/g_ai.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_chase.o :     $(GAME_DIR)/g_chase.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_client.o :    $(GAME_DIR)/p_client.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_cmds.o :      $(GAME_DIR)/g_cmds.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_svcmds.o :    $(GAME_DIR)/g_svcmds.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_combat.o :    $(GAME_DIR)/g_combat.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_func.o :      $(GAME_DIR)/g_func.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_items.o :     $(GAME_DIR)/g_items.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_main.o :      $(GAME_DIR)/g_main.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_misc.o :      $(GAME_DIR)/g_misc.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_monster.o :   $(GAME_DIR)/g_monster.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_phys.o :      $(GAME_DIR)/g_phys.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_save.o :      $(GAME_DIR)/g_save.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_spawn.o :     $(GAME_DIR)/g_spawn.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_target.o :    $(GAME_DIR)/g_target.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_trigger.o :   $(GAME_DIR)/g_trigger.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_turret.o :    $(GAME_DIR)/g_turret.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_utils.o :     $(GAME_DIR)/g_utils.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/g_weapon.o :    $(GAME_DIR)/g_weapon.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_actor.o :     $(GAME_DIR)/m_actor.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_berserk.o :   $(GAME_DIR)/m_berserk.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_boss2.o :     $(GAME_DIR)/m_boss2.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_boss3.o :     $(GAME_DIR)/m_boss3.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_boss31.o :     $(GAME_DIR)/m_boss31.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_boss32.o :     $(GAME_DIR)/m_boss32.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_brain.o :     $(GAME_DIR)/m_brain.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_chick.o :     $(GAME_DIR)/m_chick.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_flipper.o :   $(GAME_DIR)/m_flipper.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_float.o :     $(GAME_DIR)/m_float.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_flyer.o :     $(GAME_DIR)/m_flyer.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_gladiator.o : $(GAME_DIR)/m_gladiator.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_gunner.o :    $(GAME_DIR)/m_gunner.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_hover.o :     $(GAME_DIR)/m_hover.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_infantry.o :  $(GAME_DIR)/m_infantry.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_insane.o :    $(GAME_DIR)/m_insane.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_medic.o :     $(GAME_DIR)/m_medic.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_move.o :      $(GAME_DIR)/m_move.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_mutant.o :    $(GAME_DIR)/m_mutant.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_parasite.o :  $(GAME_DIR)/m_parasite.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_soldier.o :   $(GAME_DIR)/m_soldier.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_supertank.o : $(GAME_DIR)/m_supertank.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_tank.o :      $(GAME_DIR)/m_tank.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_hud.o :       $(GAME_DIR)/p_hud.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_trail.o :     $(GAME_DIR)/p_trail.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_view.o :      $(GAME_DIR)/p_view.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/p_weapon.o :    $(GAME_DIR)/p_weapon.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/q_shared.o :    $(GAME_DIR)/q_shared.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/game/m_flash.o :     $(GAME_DIR)/m_flash.c
	$(DO_SHLIB_CC)

#############################################################################
# CTF
#############################################################################

CTF_OBJS = \
	$(BUILDDIR)/ctf/g_ai.o \
	$(BUILDDIR)/ctf/g_chase.o \
	$(BUILDDIR)/ctf/g_cmds.o \
	$(BUILDDIR)/ctf/g_combat.o \
	$(BUILDDIR)/ctf/g_ctf.o \
	$(BUILDDIR)/ctf/g_func.o \
	$(BUILDDIR)/ctf/g_items.o \
	$(BUILDDIR)/ctf/g_main.o \
	$(BUILDDIR)/ctf/g_misc.o \
	$(BUILDDIR)/ctf/g_monster.o \
	$(BUILDDIR)/ctf/g_phys.o \
	$(BUILDDIR)/ctf/g_save.o \
	$(BUILDDIR)/ctf/g_spawn.o \
	$(BUILDDIR)/ctf/g_svcmds.o \
	$(BUILDDIR)/ctf/g_target.o \
	$(BUILDDIR)/ctf/g_trigger.o \
	$(BUILDDIR)/ctf/g_utils.o \
	$(BUILDDIR)/ctf/g_weapon.o \
	$(BUILDDIR)/ctf/m_move.o \
	$(BUILDDIR)/ctf/p_client.o \
	$(BUILDDIR)/ctf/p_hud.o \
	$(BUILDDIR)/ctf/p_menu.o \
	$(BUILDDIR)/ctf/p_trail.o \
	$(BUILDDIR)/ctf/p_view.o \
	$(BUILDDIR)/ctf/p_weapon.o \
	$(BUILDDIR)/ctf/q_shared.o

$(BUILDDIR)/ctf/game$(ARCH).$(SHLIBEXT) : $(CTF_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(CTF_OBJS)

$(BUILDDIR)/ctf/g_ai.o :       $(CTF_DIR)/g_ai.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_chase.o :    $(CTF_DIR)/g_chase.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_cmds.o :     $(CTF_DIR)/g_cmds.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_combat.o :   $(CTF_DIR)/g_combat.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_ctf.o :      $(CTF_DIR)/g_ctf.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_func.o :     $(CTF_DIR)/g_func.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_items.o :    $(CTF_DIR)/g_items.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_main.o :     $(CTF_DIR)/g_main.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_misc.o :     $(CTF_DIR)/g_misc.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_monster.o :  $(CTF_DIR)/g_monster.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_phys.o :     $(CTF_DIR)/g_phys.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_save.o :     $(CTF_DIR)/g_save.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_spawn.o :    $(CTF_DIR)/g_spawn.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_svcmds.o :   $(CTF_DIR)/g_svcmds.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_target.o :   $(CTF_DIR)/g_target.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_trigger.o :  $(CTF_DIR)/g_trigger.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_utils.o :    $(CTF_DIR)/g_utils.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/g_weapon.o :   $(CTF_DIR)/g_weapon.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/m_move.o :     $(CTF_DIR)/m_move.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/p_client.o :   $(CTF_DIR)/p_client.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/p_hud.o :      $(CTF_DIR)/p_hud.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/p_menu.o :     $(CTF_DIR)/p_menu.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/p_trail.o :    $(CTF_DIR)/p_trail.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/p_view.o :     $(CTF_DIR)/p_view.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/p_weapon.o :   $(CTF_DIR)/p_weapon.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ctf/q_shared.o :   $(CTF_DIR)/q_shared.c
	$(DO_SHLIB_CC)

#############################################################################
# XATRIX
#############################################################################

XATRIX_OBJS = \
	$(BUILDDIR)/xatrix/g_ai.o \
	$(BUILDDIR)/xatrix/g_cmds.o \
	$(BUILDDIR)/xatrix/g_combat.o \
	$(BUILDDIR)/xatrix/g_func.o \
	$(BUILDDIR)/xatrix/g_items.o \
	$(BUILDDIR)/xatrix/g_main.o \
	$(BUILDDIR)/xatrix/g_misc.o \
	$(BUILDDIR)/xatrix/g_monster.o \
	$(BUILDDIR)/xatrix/g_phys.o \
	$(BUILDDIR)/xatrix/g_save.o \
	$(BUILDDIR)/xatrix/g_spawn.o \
	$(BUILDDIR)/xatrix/g_svcmds.o \
	$(BUILDDIR)/xatrix/g_target.o \
	$(BUILDDIR)/xatrix/g_trigger.o \
	$(BUILDDIR)/xatrix/g_turret.o \
	$(BUILDDIR)/xatrix/g_utils.o \
	$(BUILDDIR)/xatrix/g_weapon.o \
	$(BUILDDIR)/xatrix/m_actor.o \
	$(BUILDDIR)/xatrix/m_berserk.o \
	$(BUILDDIR)/xatrix/m_boss2.o \
	$(BUILDDIR)/xatrix/m_boss3.o \
	$(BUILDDIR)/xatrix/m_boss31.o \
	$(BUILDDIR)/xatrix/m_boss32.o \
	$(BUILDDIR)/xatrix/m_boss5.o \
	$(BUILDDIR)/xatrix/m_brain.o \
	$(BUILDDIR)/xatrix/m_chick.o \
	$(BUILDDIR)/xatrix/m_fixbot.o \
	$(BUILDDIR)/xatrix/m_flash.o \
	$(BUILDDIR)/xatrix/m_flipper.o \
	$(BUILDDIR)/xatrix/m_float.o \
	$(BUILDDIR)/xatrix/m_flyer.o \
	$(BUILDDIR)/xatrix/m_gekk.o \
	$(BUILDDIR)/xatrix/m_gladb.o \
	$(BUILDDIR)/xatrix/m_gladiator.o \
	$(BUILDDIR)/xatrix/m_gunner.o \
	$(BUILDDIR)/xatrix/m_hover.o \
	$(BUILDDIR)/xatrix/m_infantry.o \
	$(BUILDDIR)/xatrix/m_insane.o \
	$(BUILDDIR)/xatrix/m_medic.o \
	$(BUILDDIR)/xatrix/m_move.o \
	$(BUILDDIR)/xatrix/m_mutant.o \
	$(BUILDDIR)/xatrix/m_parasite.o \
	$(BUILDDIR)/xatrix/m_soldier.o \
	$(BUILDDIR)/xatrix/m_supertank.o \
	$(BUILDDIR)/xatrix/m_tank.o \
	$(BUILDDIR)/xatrix/p_client.o \
	$(BUILDDIR)/xatrix/p_hud.o \
	$(BUILDDIR)/xatrix/p_trail.o \
	$(BUILDDIR)/xatrix/p_view.o \
	$(BUILDDIR)/xatrix/p_weapon.o \
	$(BUILDDIR)/xatrix/q_shared.o

$(BUILDDIR)/xatrix/game$(ARCH).$(SHLIBEXT) : $(XATRIX_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(XATRIX_OBJS)

$(BUILDDIR)/xatrix/g_ai.o :        $(XATRIX_DIR)/g_ai.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_cmds.o :      $(XATRIX_DIR)/g_cmds.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_combat.o :    $(XATRIX_DIR)/g_combat.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_func.o :      $(XATRIX_DIR)/g_func.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_items.o :     $(XATRIX_DIR)/g_items.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_main.o :      $(XATRIX_DIR)/g_main.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_misc.o :      $(XATRIX_DIR)/g_misc.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_monster.o :   $(XATRIX_DIR)/g_monster.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_phys.o :      $(XATRIX_DIR)/g_phys.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_save.o :      $(XATRIX_DIR)/g_save.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_spawn.o :     $(XATRIX_DIR)/g_spawn.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_svcmds.o :    $(XATRIX_DIR)/g_svcmds.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_target.o :    $(XATRIX_DIR)/g_target.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_trigger.o :   $(XATRIX_DIR)/g_trigger.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_turret.o :    $(XATRIX_DIR)/g_turret.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_utils.o :     $(XATRIX_DIR)/g_utils.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/g_weapon.o :    $(XATRIX_DIR)/g_weapon.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_actor.o :     $(XATRIX_DIR)/m_actor.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_berserk.o :   $(XATRIX_DIR)/m_berserk.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_boss2.o :     $(XATRIX_DIR)/m_boss2.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_boss3.o :     $(XATRIX_DIR)/m_boss3.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_boss31.o :    $(XATRIX_DIR)/m_boss31.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_boss32.o :    $(XATRIX_DIR)/m_boss32.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_boss5.o :     $(XATRIX_DIR)/m_boss5.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_brain.o :     $(XATRIX_DIR)/m_brain.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_chick.o :     $(XATRIX_DIR)/m_chick.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_fixbot.o :    $(XATRIX_DIR)/m_fixbot.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_flash.o :     $(XATRIX_DIR)/m_flash.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_flipper.o :   $(XATRIX_DIR)/m_flipper.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_float.o :     $(XATRIX_DIR)/m_float.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_flyer.o :     $(XATRIX_DIR)/m_flyer.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_gekk.o :      $(XATRIX_DIR)/m_gekk.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_gladb.o :     $(XATRIX_DIR)/m_gladb.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_gladiator.o : $(XATRIX_DIR)/m_gladiator.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_gunner.o :    $(XATRIX_DIR)/m_gunner.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_hover.o :     $(XATRIX_DIR)/m_hover.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_infantry.o :  $(XATRIX_DIR)/m_infantry.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_insane.o :    $(XATRIX_DIR)/m_insane.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_medic.o :     $(XATRIX_DIR)/m_medic.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_move.o :      $(XATRIX_DIR)/m_move.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_mutant.o :    $(XATRIX_DIR)/m_mutant.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_parasite.o :  $(XATRIX_DIR)/m_parasite.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_soldier.o :   $(XATRIX_DIR)/m_soldier.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_supertank.o : $(XATRIX_DIR)/m_supertank.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/m_tank.o :      $(XATRIX_DIR)/m_tank.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/p_client.o :    $(XATRIX_DIR)/p_client.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/p_hud.o :       $(XATRIX_DIR)/p_hud.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/p_trail.o :     $(XATRIX_DIR)/p_trail.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/p_view.o :      $(XATRIX_DIR)/p_view.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/p_weapon.o :    $(XATRIX_DIR)/p_weapon.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/xatrix/q_shared.o :    $(XATRIX_DIR)/q_shared.c
	$(DO_SHLIB_CC)


#############################################################################
# REF_SOFT
#############################################################################

REF_SOFT_OBJS = \
	$(BUILDDIR)/ref_soft/r_aclip.o \
	$(BUILDDIR)/ref_soft/r_alias.o \
	$(BUILDDIR)/ref_soft/r_bsp.o \
	$(BUILDDIR)/ref_soft/r_draw.o \
	$(BUILDDIR)/ref_soft/r_edge.o \
	$(BUILDDIR)/ref_soft/r_image.o \
	$(BUILDDIR)/ref_soft/r_light.o \
	$(BUILDDIR)/ref_soft/r_main.o \
	$(BUILDDIR)/ref_soft/r_misc.o \
	$(BUILDDIR)/ref_soft/r_model.o \
	$(BUILDDIR)/ref_soft/r_part.o \
	$(BUILDDIR)/ref_soft/r_poly.o \
	$(BUILDDIR)/ref_soft/r_polyse.o \
	$(BUILDDIR)/ref_soft/r_rast.o \
	$(BUILDDIR)/ref_soft/r_scan.o \
	$(BUILDDIR)/ref_soft/r_sprite.o \
	$(BUILDDIR)/ref_soft/r_surf.o \
	$(BUILDDIR)/ref_soft/q_shared.o \
	$(BUILDDIR)/ref_soft/q_shlinux.o \
	$(BUILDDIR)/ref_soft/glob.o

ifeq ($(ARCH),i386)
REF_SOFT_OBJS += \
	$(BUILDDIR)/ref_soft/r_aclipa.o \
	$(BUILDDIR)/ref_soft/r_draw16.o \
	$(BUILDDIR)/ref_soft/r_drawa.o \
	$(BUILDDIR)/ref_soft/r_edgea.o \
	$(BUILDDIR)/ref_soft/r_scana.o \
	$(BUILDDIR)/ref_soft/r_spr8.o \
	$(BUILDDIR)/ref_soft/r_surf8.o \
	$(BUILDDIR)/ref_soft/math.o \
	$(BUILDDIR)/ref_soft/d_polysa.o \
	$(BUILDDIR)/ref_soft/r_varsa.o \
	$(BUILDDIR)/ref_soft/sys_dosa.o
endif

REF_SOFT_SVGA_OBJS = \
	$(BUILDDIR)/ref_soft/rw_svgalib.o \
	$(BUILDDIR)/ref_soft/d_copy.o \
	$(BUILDDIR)/ref_soft/rw_in_svgalib.o

REF_SOFT_X11_OBJS = \
	$(BUILDDIR)/ref_soft/rw_x11.o

REF_SOFT_SDL_OBJS = \
	$(BUILDDIR)/ref_soft/rw_sdl.o

$(BUILDDIR)/ref_soft.$(SHLIBEXT) : $(REF_SOFT_OBJS) $(REF_SOFT_SVGA_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(REF_SOFT_OBJS) \
		$(REF_SOFT_SVGA_OBJS) $(SVGALDFLAGS)

$(BUILDDIR)/ref_softx.$(SHLIBEXT) : $(REF_SOFT_OBJS) $(REF_SOFT_X11_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(REF_SOFT_OBJS) \
		$(REF_SOFT_X11_OBJS) $(XLDFLAGS)

$(BUILDDIR)/ref_softsdl.$(SHLIBEXT) : $(REF_SOFT_OBJS) $(REF_SOFT_SDL_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(REF_SOFT_OBJS) \
		$(REF_SOFT_SDL_OBJS) $(SDLLDFLAGS)

$(BUILDDIR)/ref_soft/r_aclip.o :      $(REF_SOFT_DIR)/r_aclip.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_alias.o :      $(REF_SOFT_DIR)/r_alias.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_bsp.o :        $(REF_SOFT_DIR)/r_bsp.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_draw.o :       $(REF_SOFT_DIR)/r_draw.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_edge.o :       $(REF_SOFT_DIR)/r_edge.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_image.o :      $(REF_SOFT_DIR)/r_image.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_light.o :      $(REF_SOFT_DIR)/r_light.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_main.o :       $(REF_SOFT_DIR)/r_main.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_misc.o :       $(REF_SOFT_DIR)/r_misc.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_model.o :      $(REF_SOFT_DIR)/r_model.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_part.o :       $(REF_SOFT_DIR)/r_part.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_poly.o :       $(REF_SOFT_DIR)/r_poly.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_polyse.o :     $(REF_SOFT_DIR)/r_polyse.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_rast.o :       $(REF_SOFT_DIR)/r_rast.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_scan.o :       $(REF_SOFT_DIR)/r_scan.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_sprite.o :     $(REF_SOFT_DIR)/r_sprite.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_surf.o :       $(REF_SOFT_DIR)/r_surf.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/r_aclipa.o :     $(LINUX_DIR)/r_aclipa.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/r_draw16.o :     $(LINUX_DIR)/r_draw16.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/r_drawa.o :      $(LINUX_DIR)/r_drawa.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/r_edgea.o :      $(LINUX_DIR)/r_edgea.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/r_scana.o :      $(LINUX_DIR)/r_scana.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/r_spr8.o :       $(LINUX_DIR)/r_spr8.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/r_surf8.o :      $(LINUX_DIR)/r_surf8.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/math.o :         $(LINUX_DIR)/math.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/d_polysa.o :     $(LINUX_DIR)/d_polysa.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/r_varsa.o :      $(LINUX_DIR)/r_varsa.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/sys_dosa.o :     $(LINUX_DIR)/sys_dosa.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/q_shared.o :     $(GAME_DIR)/q_shared.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/q_shlinux.o :    $(LINUX_DIR)/q_shlinux.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/glob.o :         $(LINUX_DIR)/glob.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/d_copy.o :       $(LINUX_DIR)/d_copy.S
	$(DO_SHLIB_AS)

$(BUILDDIR)/ref_soft/rw_svgalib.o :   $(LINUX_DIR)/rw_svgalib.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/rw_in_svgalib.o : $(LINUX_DIR)/rw_in_svgalib.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/rw_x11.o :       $(LINUX_DIR)/rw_x11.c
	$(DO_SHLIB_CC)

$(BUILDDIR)/ref_soft/rw_sdl.o :       $(LINUX_DIR)/rw_sdl.c
	$(DO_SHLIB_CC) $(SDLCFLAGS)

#############################################################################
# REF_GL
#############################################################################

REF_GL_OBJS = \
	$(BUILDDIR)/ref_gl/gl_draw.o \
	$(BUILDDIR)/ref_gl/gl_image.o \
	$(BUILDDIR)/ref_gl/gl_light.o \
	$(BUILDDIR)/ref_gl/gl_mesh.o \
	$(BUILDDIR)/ref_gl/gl_model.o \
	$(BUILDDIR)/ref_gl/gl_rmain.o \
	$(BUILDDIR)/ref_gl/gl_rmisc.o \
	$(BUILDDIR)/ref_gl/gl_rsurf.o \
	$(BUILDDIR)/ref_gl/gl_warp.o \
	\
	$(BUILDDIR)/ref_gl/qgl_linux.o \
	$(BUILDDIR)/ref_gl/q_shared.o \
	$(BUILDDIR)/ref_gl/q_shlinux.o \
	$(BUILDDIR)/ref_gl/glob.o

REF_GLX_OBJS = \
	$(BUILDDIR)/ref_gl/gl_glx.o

REF_FXGL_OBJS = \
	$(BUILDDIR)/ref_gl/rw_in_svgalib.o \
	$(BUILDDIR)/ref_gl/gl_fxmesa.o

REF_SDLGL_OBJS = \
	$(BUILDDIR)/ref_gl/rw_sdl.o

$(BUILDDIR)/ref_glx.$(SHLIBEXT) : $(REF_GL_OBJS) $(REF_GLX_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(REF_GL_OBJS) $(REF_GLX_OBJS) $(GLXLDFLAGS)

$(BUILDDIR)/ref_gl.$(SHLIBEXT) : $(REF_GL_OBJS) $(REF_FXGL_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(REF_GL_OBJS) $(REF_FXGL_OBJS) $(FXGLLDFLAGS)

$(BUILDDIR)/ref_sdlgl.$(SHLIBEXT) : $(REF_GL_OBJS) $(REF_SDLGL_OBJS)
	$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(REF_GL_OBJS) $(REF_SDLGL_OBJS) $(SDLGLLDFLAGS)

$(BUILDDIR)/ref_gl/gl_draw.o :        $(REF_GL_DIR)/gl_draw.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/gl_image.o :       $(REF_GL_DIR)/gl_image.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/gl_light.o :       $(REF_GL_DIR)/gl_light.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/gl_mesh.o :        $(REF_GL_DIR)/gl_mesh.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/gl_model.o :       $(REF_GL_DIR)/gl_model.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/gl_rmain.o :       $(REF_GL_DIR)/gl_rmain.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/gl_rmisc.o :       $(REF_GL_DIR)/gl_rmisc.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/gl_rsurf.o :       $(REF_GL_DIR)/gl_rsurf.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/gl_warp.o :        $(REF_GL_DIR)/gl_warp.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/qgl_linux.o :      $(LINUX_DIR)/qgl_linux.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/q_shared.o :       $(GAME_DIR)/q_shared.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/q_shlinux.o :      $(LINUX_DIR)/q_shlinux.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/glob.o :           $(LINUX_DIR)/glob.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/gl_glx.o :         $(LINUX_DIR)/gl_glx.c
	$(DO_GL_SHLIB_CC) $(GLXCFLAGS)

$(BUILDDIR)/ref_gl/gl_fxmesa.o :      $(LINUX_DIR)/gl_fxmesa.c
	$(DO_GL_SHLIB_CC) $(FXGLCFLAGS)

$(BUILDDIR)/ref_gl/rw_in_svgalib.o :  $(LINUX_DIR)/rw_in_svgalib.c
	$(DO_GL_SHLIB_CC)

$(BUILDDIR)/ref_gl/rw_sdl.o :         $(LINUX_DIR)/rw_sdl.c
	$(DO_GL_SHLIB_CC) $(SDLGLCFLAGS)

#############################################################################
# MISC
#############################################################################

clean: clean-debug clean-release

clean-debug:
	$(MAKE) clean2 BUILDDIR=$(BUILD_DEBUG_DIR) CFLAGS="$(DEBUG_CFLAGS)"

clean-release:
	$(MAKE) clean2 BUILDDIR=$(BUILD_RELEASE_DIR) CFLAGS="$(DEBUG_CFLAGS)"

clean2:
	rm -f \
	$(QUAKE2_OBJS) \
	$(QUAKE2_AS_OBJS) \
	$(GAME_OBJS) \
	$(CTF_OBJS) \
	$(XATRIX_OBJS) \
	$(REF_SOFT_OBJS) \
	$(REF_SOFT_SVGA_OBJS) \
	$(REF_SOFT_X11_OBJS) \
	$(REF_GL_OBJS)

distclean:
	-rm -rf $(BUILD_DEBUG_DIR) $(BUILD_RELEASE_DIR)
	-rm -f `find . \( -not -type d \) -and \( -name '*~' \) -type f -print`
