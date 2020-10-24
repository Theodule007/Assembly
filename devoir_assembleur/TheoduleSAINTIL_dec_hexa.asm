.model small
.stack 100h
.data                                      
message db 'saisissez le nombre a convertir!',13,10,'$'
;;;;;;;;;;;; on stock la valeur a convertir dans d1 
d1 dw 999
 
 

; this macro prints a char in AL and advances
; the current cursor position:
putc    macro   char
        push    ax
        mov     al, char
        mov     ah, 0eh
        int     10h     
        pop     ax
endm



.code

main proc far
	;;;;;;chargement du segment de donnees 
	mov ax, @data
	mov ds, ax
	;;;;;; fin chargement du segment de donnees
   
	call debut
	
	;;;;;;;;;;;;;fin du programme
	mov ah, 4ch
	int 21h

main endp

;;;;;;;;definition de ma procedure
print proc
	;;;;;;;;;CX taille de la pile qui va recevoir les nombres
	mov cx, 0
	;;;;;;;;dx recoit le reste le la division
	mov dx, 0

	;;;;;;;;on compare AX a 0
	label1:
		cmp ax, 0
		je print1
	;;on charge bx  a la valeur 16
	mov bx, 16
	;;;;;;;;;;;on divise par 16 pour la conversion en hexadecimal
	;;;;;;;;;;;AX est divise par BX, le quotient est dans ax (plus precisement AL) et le reste dans dx
	div bx
	push dx
	;;;;;;;;on incremente cx car pour chaque division on push le quotient dans la pile
	inc cx
	;;;;;;;;;;on met dx, qui recoit le reste de la division a 0 (xor est plus efficace que mov dx,0)
    xor dx, dx
	jmp label1

	print1:
		;;;;;;;;ve
		
		
		rifier si CX est > 0 por savoir s'il reste un element a convertir (en lettre) dans la pile 
		cmp cx,0
		je exit

	pop dx                                                                                                               
	;;;;;;;comparer avec 9 pour mettre des lettres
	cmp dx, 9
	jle continue
	;;;;;;; si DX > 9 on ajoute 7 pour avoir le code ascii de la lettre correspondante
	add dx, 7

	continue:
		;;;;;;;;;;;normalement on ajoute 48 pour avoir la representation ascii des digit
		add dx, 48

	;;;;;;;;afficher la valeur popee
	mov ah, 02h
	int 21h

	dec cx                       
	jmp print1

	exit: 
	    putc 'h'
		ret   
		
		
		

print endp   

debut proc
           mov ah,09h
           mov dx,offset message
           int 21h
           
	       xor ax, ax
	       call  SCAN_NUM 
           
           mov al, 0ah
           mov ah, 0eh
           int 10h
           
           mov al, 0dh
           mov ah, 0eh
           int 10h
                
           mov ax, cx
           xor cx, cx
	       call print
debut endp


; gets the multi-digit SIGNED number from the keyboard,
; and stores the result in CX register:
  SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 0Dh  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_minus      DB      ?       ; used as a flag.
SCAN_NUM        ENDP

ten             DW      10      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.



end main




 
 
   