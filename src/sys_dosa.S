/* $Id$
 *
 * x86 assembly-language DOS-dependent routines
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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif
#include "qasm.h"


	.data

	.align	4
fpenv:
	.long	0, 0, 0, 0, 0, 0, 0, 0

	.text

.globl C(MaskExceptions)
C(MaskExceptions):
	fnstenv	fpenv
	orl		$0x3F,fpenv
	fldenv	fpenv

	ret

#if 0
.globl C(unmaskexceptions)
C(unmaskexceptions):
	fnstenv	fpenv
	andl		$0xFFFFFFE0,fpenv
	fldenv	fpenv

	ret
#endif

	.data

	.align	4
.globl	ceil_cw, single_cw, full_cw, cw, pushed_cw
ceil_cw:	.long	0
single_cw:	.long	0
full_cw:	.long	0
cw:			.long	0
pushed_cw:	.long	0

	.text

.globl C(Sys_LowFPPrecision)
C(Sys_LowFPPrecision):
	fldcw	single_cw

	ret

.globl C(Sys_HighFPPrecision)
C(Sys_HighFPPrecision):
	fldcw	full_cw

	ret

.globl C(Sys_PushFPCW_SetHigh)
C(Sys_PushFPCW_SetHigh):
	fnstcw	pushed_cw
	fldcw	full_cw

	ret

.globl C(Sys_PopFPCW)
C(Sys_PopFPCW):
	fldcw	pushed_cw

	ret

.globl C(Sys_SetFPCW)
C(Sys_SetFPCW):
	fnstcw	cw
	movl	cw,%eax
/* These seem suspicious
#ifdef USE_ASM
*/
	andb	$0xF0,%ah
	orb		$0x03,%ah	// round mode, 64-bit precision
/*#endif*/
	movl	%eax,full_cw

/*#ifdef USE_ASM*/
	andb	$0xF0,%ah
	orb		$0x0C,%ah	// chop mode, single precision
/*#endif*/
	movl	%eax,single_cw

/*#ifdef USE_ASM*/
	andb	$0xF0,%ah
	orb		$0x08,%ah	// ceil mode, single precision
/*#endif*/
	movl	%eax,ceil_cw

	ret

