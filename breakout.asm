.data

MMIO: .word 0xffff0000
bar: .word 0x10040FB8
posicionBarra: .word 0x00000000
T: .word 0x00000000
INCREMENTO: .word 0x00000000
vidas: .word 0x00000003
bloques: .word 0x00000000

tecla: .space 2

.text

main:

# habilitamos la entrada por teclado
lw $t3,MMIO($zero)
lw $t5,0($t3)
ori $t4,$t5,0x00000010
sw $t4,0($t3)

#Realizo la invocacion de la rutina que llena el contenido
#grafico de las condiciones iniciales del juego en pantalla
jal init
#Habilito interrupciones en el coprocesador
mfc0 $t8, $12
andi $t8, 0xFFFF00FF
ori $t8, 0x00000800
ori $t8, 0X00000001
mtc0 $t8, $12
#Habilita interrupciones en el dispositivo
li $t8, 0x00000002
sw $t8, 0XFFFF0000
#Contador de vidas restantes y de bloques existentes y parametros de velocidad
li $t0, 3
la $t1, vidas
sw $t0, ($t1)
li $t0, 128
la $t1, bloques
sw $t0, ($t1)
li $t0, 10
la $t1, T
sw $t0, ($t1)
li $t0, 100
la $t1, INCREMENTO
sw $t0, ($t1)
#Inicializar Vx=$t0 y Vy=$t1 para la pelota
restart: 
li $s2, 0
addi $s2, $s2, 1
li $v0, 42
move $a0, $s2
li $a1, 5
syscall
bnez $a0, inicio1
li $t0, 0
li $t1, 2
j start
inicio1: bne $a0, 1, inicio2
li $t0, 1
li $t1, 2
j start
inicio2: bne $a0, 2, inicio3
li $t0, -1
li $t1, 2
j start
inicio3: bne $a0, 3, inicio4
li $t0, 1
li $t1, 1
j start
inicio4: 
li $t0, -1
li $t1, 1
start: 
#Inicializo $t2 con la direccion de memoria a partir
#de la cual se encuentra mapeado el monitor
#para el uso de Bitmap Display
li $t2, 0x10040000
#Me desplazo por ese sector de memoria mapeada
#para ubicar la pelota en su posicion iniciales
#y asi dar comienzo al movimiento
addi $t2, $t2, 2112
#Me posiciono en el centro de la
#pantalla (en las direcciones de memoria)
#para colocar la pelota en rojo
li $t9, 0x00FF0000
sw $t9, ($t2)
#Bandera para saber si pise bloque o no
li $t8, 0
#Etiqueta "continue" inicia bloque repetitivo de
#comandos para efectuar movimiento de pelota
#Rutina de pausa en la ejecucion para que el movimiento
#en pantalla pueda percibirse
continue: li $v0, 32 #sleep
li $a0, 250 #20ms
syscall #do the sleep
#Aplicar reglas del movimiento de la pelota
#Por si esta chocando con los costados del monitor
#el techo del mismo, un bloque o la barra
#1a Condicion: Choca con los costados de la pantalla
bnez $t8, label1
and $t3, $t2, 0x000000FF
seq $t4, $t3, 0x00
seq $t5, $t3, 0x7F
seq $t6, $t3, 0x80
seq $t7, $t3, 0xFF
or $t3, $t4, $t5
or $t3, $t3, $t6
or $t3, $t3, $t7
beqz $t3, label1
mul $t0, $t0, -1
#2a Condicion: Choca con el techo de la pantalla
label1:bgt $t2, 0x1004007F, label2
bnez $t8, label2
mul $t1, $t1, -1
j forward 
#3a Condicion: Choca con un ladrillo de frente
label2: 
bnez $t8, label3
addi $t3, $t2, -128
lw $t4, ($t3)
beqz $t4, label3
li $t4, 0
sw $t4, ($t3)
mul $t1, $t1, -1
addi $s1, $s1, 1
jal hitTheWall
j forward
#4a Condicion: Choca con la barra
label3: addi $t3, $t2, 128
lw $t4, ($t3)
beqz $t4, label4
bne $t4, 0x0000006F, x1
li $t0, 0
j y1
x1: lw $t5, -4($t3)
bne $t5, 0x0000006F, x2
li $t0, -4
j y1
x2: li $t0, 4
y1: bne $t4, 0x000000FF, y2
li $t1, -1
j forward
y2: li $t1, -2 
j forward
#5a Condicion: Choca con el muro pero no hay ladrillo en frente 
#porque desaparecio previamente pero hay ladrillo al lado
label4: beqz $t0, forward
bnez $t8, forward
#5a Condicion: El ladrillo esta justo al lado
mul $t3, $t0, 4
add $t3, $t3, $t2
lw $t4, ($t3)
beqz $t4, label4a
li $t4, 0
sw $t4, ($t3)
mul $t1, $t1, -1
jal hitTheWall
j forward
#5b Condicion: El ladrillo esta diagonal
label4a: mul $t3, $t0, 4
add $t3, $t3, $t2
add $t3, $t3, -128
lw $t4, ($t3)
beqz $t4, forward
li $t4, 0
sw $t4, ($t3)
mul $t1, $t1, -1
jal hitTheWall
#7a Condicion: No se consigue con nada en su camino y avanza
forward: li $t3, 0
sw $t3, ($t2)
#Calculo la siguiente posicion de la pelota
mul $t3, $t1, 128
add $t2, $t2, $t3 
mul $t3, $t0, 4
add $t2, $t2, $t3
#Condicion 7.1 : Choca con el muro pero posandose sobre 
#el ladrillo que debe desaparecer
lw $t3, ($t2)
beqz $t3, limpiar
li $t8, 1
mul $t1, $t1, -1
jal hitTheWall
j ahead
#No piso ladrillo
limpiar: li $t8, 0
#Avanza a la posicion calculada
ahead: li $t3, 0x00FF0000
sw $t3, ($t2)
#8a Condicion: Esta al fondo de la pantalla
#y debe desaparecer de lo contrario
#retorna a "continue" para continuar movimiento 
blt $t2, 0x10040F80, continue
#Desaparece la pelota
li $t3, 0
sw $t3, ($t2)
#Descuenta vida
lw $a0, vidas
addi $a0, $a0, -1
sw $a0, vidas
jal mostrarDerrota
#Si ha vidas restantes reanuda el juego
bnez $a0, restart
#Game Over
jal gameOver
salir: li $v0, 10
syscall

init:
sw $fp, ($sp)			
move $fp, $sp			
addi $sp, $sp, -4
#Me posiciono al inicio del espacio
#de memoria mapeado y voy llenando cada 3 pixeles
#(cada 12 posiciones de memoria) con el mismo tono
#de verde (para los ladrillos del muro)
li $s0, 0x10040000
li $s1, 128
li $s2, 1
loop: bne $s2, 1, next1
li $s3, 0x0000FF00
li $s2, 2
j cargarPixel
next1: bne $s2, 2, next2
li $s3, 0x0000CF00
li $s2, 3
j cargarPixel
next2: li $s3, 0X00009F00
li $s2, 1
cargarPixel: sw $s3, ($s0)
addi $s0, $s0, 4
addi $s1, $s1, -1
bnez $s1, loop
#Me posiciono en el centro al final de la
#pantalla (en las direcciones de memoria)
#para colocar los tonos de azul de la barra
addi $s0, $s0, 3512
sw $s0, posicionBarra
li $s3, 0x000000FF
sw $s3, ($s0)
addi $s0, $s0, 4
li $s3, 0x000000C0
sw $s3, ($s0)
addi $s0, $s0, 4
li $s3, 0x0000006F
sw $s3, ($s0)
addi $s0, $s0, 4
li $s3, 0x000000C0
sw $s3, ($s0)
addi $s0, $s0, 4
li $s3, 0x000000FF
sw $s3, ($s0)
move $sp, $fp			 
lw $fp, ($sp)			
jr $ra

hitTheWall:
sw $fp, ($sp)			 
move $fp, $sp			
addi $sp, $sp, -4
#Aumenta el valor de INCREMENTO en la velocidad
#de la pelota
lw $a0, T
addi $a0, $a0, 1
sw $a0, T
#Descuenta el bloque desaparecido
lw $a0, bloques
addi $a0, $a0, -1
sw $a0, bloques
#Si hay bloques restantes continua adelante
bnez $a0, return 
#Falta Mostrar mensaje de victoria
return: move $sp, $fp		
lw $fp, ($sp)			
jr $ra

mostrarDerrota:
sw $fp, ($sp)
sw $a0, -4($sp)		 
move $fp, $sp			
addi $sp, $sp, -8
la $a0, 0X100405E0
li $v0, 0X00FFFF00
sw $v0, ($a0)
addi $a0, $a0, 64
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 64
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 16
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 64
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 136
sw $v0, ($a0)
li $v0, 32 #sleep
li $a0, 3000 #20ms
syscall #do the sleep
la $a0, 0X100405E0
li $v0, 0X00000000
sw $v0, ($a0)
addi $a0, $a0, 64
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 64
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 16
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 64
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 136
sw $v0, ($a0)
move $sp, $fp		
lw $fp, ($sp)	
lw $a0, -4($sp)		
jr $ra

mostrarVictoria:
sw $fp, ($sp)			 
move $fp, $sp			
addi $sp, $sp, -4
la $a0, 0X10040628
li $v0, 0X00FF8000
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 80
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 84
sw $v0, ($a0)
addi $a0, $a0, 12
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 12
sw $v0, ($a0)
addi $a0, $a0, 96
sw $v0, ($a0)
addi $a0, $a0, 12
sw $v0, ($a0)
addi $a0, $a0, 8
sw $v0, ($a0)
addi $a0, $a0, 12
sw $v0, ($a0)
addi $a0, $a0, 12
sw $v0, ($a0)
li $v0, 10
syscall
move $sp, $fp		
lw $fp, ($sp)			
jr $ra

gameOver:
sw $fp, ($sp)			 
move $fp, $sp			
addi $sp, $sp, -4
la $a0, 0X10040528
li $v0, 0X00990099
sw $v0, ($a0)
addi $a0, $a0, 12
sw $v0, ($a0)
addi $a0, $a0, 16
sw $v0, ($a0)
addi $a0, $a0, 12
sw $v0, ($a0)
addi $a0, $a0, 92
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 24
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 96
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 24
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 92
sw $v0, ($a0)
addi $a0, $a0, 12
sw $v0, ($a0)
addi $a0, $a0, 16
sw $v0, ($a0)
addi $a0, $a0, 12
sw $v0, ($a0)
addi $a0, $a0, 472
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 112
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 116
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
addi $a0, $a0, 4
sw $v0, ($a0)
move $sp, $fp		
lw $fp, ($sp)			
jr $ra
