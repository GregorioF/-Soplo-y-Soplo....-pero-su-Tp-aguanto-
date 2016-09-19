; void colorizar_asm (
; 	unsigned char *src,
; 	unsigned char *dst,
; 	int cols,
; 	int filas,
; 	int src_row_size,
; 	int dst_row_size,
;   float alpha
; );

; Parámetros:
; 	rdi = src
; 	rsi = dst
; 	rdx = cols
; 	rcx = filas
; 	r8 = src_row_size
; 	r9 = dst_row_size
;   xmm0 = alpha


global colorizar_asm

section .data
MenosUnosEnDobleW: db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
mascaraPrueba: db 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00
mascaraMaximos: db 0x00, 0x00, 0x00, 0x00, 0x04, 0x04, 0x04, 0x04, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f
mascaraUnos: db 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00
mascaraUltraAux: db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00

section .text

colorizar_asm:
	push r12
	sub rsp, 8

	movups xmm6, xmm0
	movdqu xmm5, [mascaraMaximos]
	
	xor r9, r9  ; mi current sobre filas
	add r9, 1 ; para no contemplar la primer fila
	xor r10, r10 ; mi current sobre columnas
	sub rcx, 2 ; para no contemplar las dos filas que no proceso
	sub rdx, 2 ; misma situacion
	.ciclo1:
		
		xor r10, r10
		cmp r9, rcx ; si son iguales termine de recorrer
		je .fin
		
		.ciclo2:
			;==== cuenta auxliar para direccionamiento correcto
			lea r11, [r10*4] ; mi current en columnas
			add r11, r8
			add r11, r8		; sumo dos veces para obtener la ultima fila dela q me interesa sacar datos
			;====
			movups xmm1, [rdi + r11]	; xmm1 == p3|p2|p1|p0     
			
			;=== cuenta auxiliar para direccionamiento correcto
			lea r11, [r10*4]
			add r11, r8
			;===			
			
			movups xmm7, [rdi + r11]	; xmm2 == p7|p6|p5|p4    			
			movups xmm2, xmm7			; salvo estos en xmm2
			movups xmm13, xmm7
			
			;===
			movups xmm3, [rdi+r10*4]	; xmm3 == p11|p10|p9|p8      
			;=== listo levante tdoso los datos q qria
			
			
			pmaxub xmm1, xmm2 ; guardo el maximo de cada byte en xmm1 
			pmaxub xmm1, xmm3 ; guardo el max en xmm1 ==  pMax {3,7,11} | pmax{2,6,10}| pmax {1,5,9}| pmax {0,4,8}

			movups xmm3, xmm1 ; copio
			movups xmm2, xmm1

			psrldq xmm3, 8 ;   xmm3 == 0 | 0 | pmax1 {3,7,11} | pmax 2 {2,6,10}
			psrldq xmm1, 4 ;   xmm1 == 0 | fruta | pmax 2 {2,6,10} | pmax3 {1,5,9}

			pmaxub xmm3, xmm1 ; xmm3 == 0 | fruit | pmax {3,7,11,2,6,10} | pmax {2,6,10,1,5,9}

			pmaxub xmm2, xmm1 ; xmm2 == fruit | fruit | pmax {1,5,9,2,6,10} | pmax {0,4,8,1,5,9}

			pmaxub xmm2, xmm3 ; xmm2 == fruit | fruit | MaxP2 | MaxP1

			
			movups xmm1, xmm2 ; xmm1 == fruta | furta | maxP2 | MaxP1


			;========== seccion para calcular el maximo de los maximos en xmm1
			
			psrldq xmm1, 1 ; shifteo 1 byte, me queda 0|a|max(r)|max(g)|max(b)|a|max(r)|max(g)

			pmaxsb xmm1,xmm2 ; me quedan a|max(a,r)|max(r,g)|max(g,b)|max(b,a)|max(a,r)|max(r,g)|max(g,b)

			psrldq xmm1,1 ;  shifteo 1 byte, me queda 0|a|max(a,r)|max(r,g)|max(g,b)|max(b,a)|max(a,r)|max(r,g)

			pmaxsb xmm1, xmm2 ; xmm1 =  0 | 0 | (fruta*3, maxP2 (g,b,r)) | (fruta*3, maxP1 (g,b,r))  

			pshufb xmm1, xmm5 ; en xmm1 fruta | fruta | [maxP2(g,b,r) * 4] | [maxP1(g,b,r) * 4] 

			pcmpeqb xmm1, xmm2 ; comparo el mayor de todos con los  maximos de cada canal en pixel 1 y 2
			
			;====== termino secccion en xmm1 me qda -1 en el byte de posicion igual al canal q tiene al maximo
			;====== xmm1== fruta | fruta | InfoCopada2 | InfoCopada1
			

			punpcklbw xmm1, xmm1  ; xmm1 == InfoCopada2High| I.C.2.L | I.C.1.H | I.C.1.L|
				
			movups xmm2, xmm1	

			punpcklwd xmm2, xmm1 ;  en cada dw me qda info copada sobre cada canala respectivamente del Pixel 1

			punpckhwd xmm1, xmm1 ; en cada dw me qda info copada sobre cada canal respectivamente del Pixel 2

			movups xmm0, xmm1
			
			cvtdq2ps xmm0, xmm0
			
			call pasarDeMenosUnoAUnoYDeCeroAMenosUno

			movups xmm1, xmm0	; lo mismo q antes tengo en xmm1 pero ahora en float y bueno lo q hizo la op....
						
			movups xmm0, xmm2
			
			cvtdq2ps xmm0, xmm0

			call pasarDeMenosUnoAUnoYDeCeroAMenosUno ; hace lo q hace dice pero me devuelve xmm0 en enteros
			
			cvtdq2ps xmm1, xmm1
			cvtdq2ps xmm0, xmm0
			
			movups xmm5, xmm6	 	; le pongo en xmm5 el registro con los alphas

			mulps xmm6, xmm1 		; le multiplico al alfa  por uno si esta en la posicion de pixel maximo
									; o un -1 en caso contrario ACA QUEDAN LOS ALFAS DLEP IXEL 2
									
			mulps xmm5, xmm0		; ACA QUEDAN LOS ALFAS DEL PIXEL 1

			movdqu xmm10, [mascaraUnos]
			cvtdq2ps xmm10, xmm10
			
			addps xmm5, xmm10
			addps xmm6, xmm10 ; aca me qda po lo que tengo q multiplicar a los pixeles iniciales para el resultado final
			
			
			
			pxor xmm0, xmm0
			
			movups xmm9, xmm7		; xmm9 == p7|p6|p5|p4
			
			punpcklbw xmm7, xmm0  ; xmm7 == p5 | p4
			
			movups xmm8, xmm7	 ;xmm8 == p5|p4

			punpckhwd xmm8, xmm0 ; xmm8 == p5a | p5r | p5g |p5b
			
			punpckhbw xmm9, xmm0  ; xmm9 == p7 | p6
			
			movups xmm7, xmm9  ; xmm7 == p7 | p6
			
			punpcklwd xmm7, xmm0	; xmm7 == p6a | p6r | p6g |p6b
			
			cvtdq2ps xmm8, xmm8
			cvtdq2ps xmm7, xmm7		; PASO AMBOS A FLOAT PARA PODER MULTIPLICAR POR EL VALOR DE CADA ALPHA

			mulps xmm7, xmm6
			mulps xmm8, xmm5
			
			cvtps2dq xmm8, xmm8
			cvtps2dq xmm7, xmm7

			packssdw xmm8, xmm7 ; quyedan pixel1|pixel0

			packsswb xmm8, xmm8 ; quedan pixel1|pixel0|pixel1|pixel0
			
			movq [rsi + r10*4], xmm8
			

			add r10, 2
			cmp r10, rdx
			jne .ciclo2
		
		add r9, 1 
		
		jmp .ciclo1

	.fin:
		add rsp, 8 
		pop r12
		ret
	
	

; pasarle un registro con floats sino no funca naAaaaaa!
pasarDeMenosUnoAUnoYDeCeroAMenosUno:
; en xmm0 me viene el registro a cambiar de a dobles words son

pxor xmm14, xmm14 ; foward clean
cvtdq2ps xmm14, xmm14

movdqu xmm15, [MenosUnosEnDobleW]	; les meto toddas F
cvtdq2ps xmm15, xmm15		; los convierto en floats



mulps xmm0, xmm15		; multiplico todos los valores por menos uno, asi que lo que era -1 ahora es 1 y lo que es cero sigue siendo cero

movups xmm13, xmm0

cmpps xmm13, xmm14, 0		; en donde habia ceros ahora hay menos unos y donde habia unos quedan ceros

cvtps2dq xmm0, xmm0

paddd xmm0,xmm13

ret






