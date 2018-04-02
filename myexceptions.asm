# SPIM S20 MIPS simulator.
# The default exception handler for spim.
#
# Copyright (c) 1990-2010, James R. Larus.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# Neither the name of the James R. Larus nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
# GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# Define the exception handling code.  This must go first!

	.kdata
__m1_:	.asciiz "  Exception "
__m2_:	.asciiz " keyboard\n"
__m3_:  .asciiz " key A\n"
__m4_:  .asciiz " key D\n"
__m5_:  .asciiz " key Space\n"
__m6_:  .asciiz " key Escape\n"
__e0_:	.asciiz "  [Interrupt] "
__e1_:	.asciiz	"  [TLB]"
__e2_:	.asciiz	"  [TLB]"
__e3_:	.asciiz	"  [TLB]"
__e4_:	.asciiz	"  [Address error in inst/data fetch] "
__e5_:	.asciiz	"  [Address error in store] "
__e6_:	.asciiz	"  [Bad instruction address] "
__e7_:	.asciiz	"  [Bad data address] "
__e8_:	.asciiz	"  [Error in syscall] "
__e9_:	.asciiz	"  [Breakpoint] "
__e10_:	.asciiz	"  [Reserved instruction] "
__e11_:	.asciiz	""
__e12_:	.asciiz	"  [Arithmetic overflow] "
__e13_:	.asciiz	"  [Trap] "
__e14_:	.asciiz	""
__e15_:	.asciiz	"  [Floating point] "
__e16_:	.asciiz	""
__e17_:	.asciiz	""
__e18_:	.asciiz	"  [Coproc 2]"
__e19_:	.asciiz	""
__e20_:	.asciiz	""
__e21_:	.asciiz	""
__e22_:	.asciiz	"  [MDMX]"
__e23_:	.asciiz	"  [Watch]"
__e24_:	.asciiz	"  [Machine check]"
__e25_:	.asciiz	""
__e26_:	.asciiz	""
__e27_:	.asciiz	""
__e28_:	.asciiz	""
__e29_:	.asciiz	""
__e30_:	.asciiz	"  [Cache]"
__e31_:	.asciiz	""
__excp:	.word __e0_, __e1_, __e2_, __e3_, __e4_, __e5_, __e6_, __e7_, __e8_, __e9_
	.word __e10_, __e11_, __e12_, __e13_, __e14_, __e15_, __e16_, __e17_, __e18_,
	.word __e19_, __e20_, __e21_, __e22_, __e23_, __e24_, __e25_, __e26_, __e27_,
	.word __e28_, __e29_, __e30_, __e31_
s1:	.word 0
s2:	.word 0

# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can server as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.

# This is the exception vector address for MIPS-1 (R2000):
#	.ktext 0x80000080
# This is the exception vector address for MIPS32:

	.ktext 0x80000180
	
# Select the appropriate one for the mode in which SPIM is compiled.

	# apagamos la entrada por teclado
	lw $a0,MMIO($zero)
	lw $a1,0($a0)
	ori $a1,$a1,0x00000010
	sw $a1,0($a0)
	
	#.set noat discomment for SPIM
	
	move $k1 $at		# Save $at
	
	#.set at discomment for SPIM
	
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f

	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m1_
	syscall

	li $v0 1		# syscall 1 (print_int)
	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	syscall

	li $v0 4		# syscall 4 (print_str)
	andi $a0 $k0 0x3c
	lw $a0 __excp($a0)
	nop
	syscall

	bne $k0 0x18 ok_pc	# Bad PC exception requires special checks
	nop

	mfc0 $a0 $14		# EPC
	andi $a0 $a0 0x3	# Is EPC word-aligned?
	beq $a0 0 ok_pc
	nop

	li $v0 10		# Exit on really bad PC
	syscall

ok_pc:
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m2_
	syscall

	srl $a0 $k0 2		# Extract ExcCode Field
	andi $a0 $a0 0x1f
	bne $a0 0 ret		# 0 means exception was an interrupt
	nop

# Interrupt-specific code goes here!
# Don't skip instruction at EPC since it has not executed.


# AQUI VA EL CODIGO PARA LA EJECUCION DE LA EXCEPCION DEL TECLADO
interrupTeclado:

	lw $k0, MMIO($zero)
	addi $k0,$k0, 4
	lw $k1,0($k0)
	li $k0,0x00000061 # Key A
	beq $k1,$k0,moveLeft
	li $k0,0x00000064 # Key D
	beq $k1,$k0,moveRight
	li $k0,0x0000001b # Key ESC
	beq $k1,$k0,Escape
	li $k0,0x00000020 # Key Space
	beq $k1,$k0,Space
	# Others
	j ret 

moveLeft:
	#move to the left the bar
	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m3_
	syscall
	
	#Limpiar Cero
	lw $k0, bar
	
	#Verificamos pared
	li $k1,0x10040f80
	beq $k0,$k1, passLeft
	
	#No es esquina
	li $k1, 0
	sw $k1, ($k0)
	addi $k0, $k0, 4
	sw $k1, ($k0)
	addi $k0, $k0, 4
	sw $k1, ($k0)
	addi $k0, $k0, 4
	sw $k1, ($k0)
	addi $k0, $k0, 4
	sw $k1, ($k0)

	#Colocar Nueva Barra
	lw $k0, bar
	addi $k0,$k0,-4
	li $k1, 0x000000FF
	sw $k1, ($k0)
	addi $k0, $k0, 4
	li $k1, 0x000000C0
	sw $k1, ($k0)
	addi $k0, $k0, 4
	li $k1, 0x0000006F
	sw $k1, ($k0)
	addi $k0, $k0, 4
	li $k1, 0x000000C0
	sw $k1, ($k0)
	addi $k0, $k0, 4
	li $k1, 0x000000FF
	sw $k1, ($k0)
	#Guardar Nueva Barra
	lw $k0, bar
	addi $k0,$k0,-4
	sw $k0,bar
		
passLeft:
	j ret
moveRight:
	#move to the right the bar
	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m4_
	syscall
		
	#Limpiar Cero
	lw $k0, bar
	
	#Verificamos pared
	li $k1,0x10040FFA
	beq $k0,$k1, passRight
	
	#No es  pared
	
	li $k1, 0
	sw $k1, ($k0)
	addi $k0, $k0, 4
	sw $k1, ($k0)
	addi $k0, $k0, 4
	sw $k1, ($k0)
	addi $k0, $k0, 4
	sw $k1, ($k0)
	addi $k0, $k0, 4
	sw $k1, ($k0)


	#Colocar Nueva Barra
	lw $k0, bar
	addi $k0,$k0,4
	li $k1, 0x000000FF
	sw $k1, ($k0)
	addi $k0, $k0, 4
	li $k1, 0x000000C0
	sw $k1, ($k0)
	addi $k0, $k0, 4
	li $k1, 0x0000006F
	sw $k1, ($k0)
	addi $k0, $k0, 4
	li $k1, 0x000000C0
	sw $k1, ($k0)
	addi $k0, $k0, 4
	li $k1, 0x000000FF
	sw $k1, ($k0)
	#Guardar Nueva Barra
	lw $k0, bar
	addi $k0,$k0,4
	sw $k0,bar
passRight:
	j ret
Escape:
	#Exit 
	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m6_
	syscall
	li $v0,10
	syscall
Space:
	#Pause game
	# Print information about exception.
	#
	li $v0 4		# syscall 4 (print_str)
	la $a0 __m5_
	syscall
	j ret

ret:
# Return from (non-interrupt) exception. Skip offending instruction
# at EPC to avoid infinite loop.
#
	mfc0 $k0 $14		# Bump EPC register
	addiu $k0 $k0 4		# Skip faulting instruction
				# (Need to handle delayed branch case here)
	mtc0 $k0 $14


# Restore registers and reset processor state
#
	lw $v0 s1		# Restore other registers
	lw $a0 s2

	move $at $k1		# Restore $at

	mtc0 $0 $13		# Clear Cause register

	mfc0 $k0 $12		# Set Status register
	ori  $k0 0x1		# Interrupts enabled
	mtc0 $k0 $12

# Return from exception on MIPS32:
# habilitamos la entrada por teclado

	lw $a0,MMIO($zero)
	lw $a1,0($a0)
	ori $a1,$a1,0x00000010
	sw $a1,0($a0)
	eret

# Standard startup code.  Invoke the routine "main" with arguments:
#	main(argc, argv, envp)
#
.data

.include "breakout.asm"

.text

	.globl __start
	
#AQUI COMIENZA  EL PROGRAMA
__start:
	
	nop
	
	.globl __eoth
__eoth:

