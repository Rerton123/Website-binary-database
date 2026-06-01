global main
extern FCGX_GetStr
extern FCGX_Init
extern FCGX_InitRequest
extern FCGX_Accept_r
extern FCGX_PutStr
extern FCGX_Finish_r
extern FCGX_GetParam


%include 'macros.asm'

section .data

LoginUser db 16 dup(0)
LoginPass db 16 dup(0)
RegUser db 16 dup(0)
RegPass db 16 dup(0)

Newline db 10

HashStr db 16 dup(0)
HashStrL dq 16

start db "Content-Type: text/html",10
startl  equ $ - start
CkUserL db "Set-Cookie:userL=                ; Path=/app; HttpOnly",10
CkUserLL equ $ - CkUserL
CkPassL db "Set-Cookie:passL=                ; Path=/app; HttpOnly",10
CkPassLL equ $ - CkPassL
CkUserR db "Set-Cookie:userR=                ; Path=/app; HttpOnly",10
CkUserRL equ $ - CkUserR
CkPassR db "Set-Cookie:passR=                ; Path=/app; HttpOnly",10
CkPassRL equ $ - CkPassR
CkToken db "Set-Cookie:Token=     ; Path=/app; HttpOnly",10
CkTokenL equ $ - CkToken
Wrong db "<h1>Wrong Password!</h1>",10
WrongL equ $ - Wrong

debugA db 16 dup(0)

HashN dq 0
Token db 16 dup(0)
filename db "data",0
fd dq 0
data dq 0
TestM db 0

ArgL dq 0
h1 db 10,"<div class='block-button' style='z-index:-1;background-size:cover;width:100%;height:100%;background-image:url(/img/Tittle.png);border:none;padding:0;margin:0;box-sizing:border-box;position:absolute;top:0;left:0;'></div>",10,\
"<form method='POST' style='position:absolute; top:500px; left:0px; display:flex; gap:10px; max-width:400px; margin:20px'>",10,\
"<input type='text' name='lu' pattern='[A-Za-z0-9]+' maxlength='16' placeholder='Username' style='flex:1;padding:8px;font-size:16px'>",10,\
"<input type='text' name='lp' pattern='[A-Za-z0-9]+' maxlength='16' placeholder='Password' style='flex:1;padding:8px;font-size:16px'>",10,\
"<button type='submit' style='padding:8px 16px; font-size:16px; cursor:pointer'>Login</button>",10,\
"</form>",10,\
"<form method='POST' style='position:absolute; top:550px; left:0px; display:flex;gap:10px;max-width:400px;margin:20px'>",10,\
"<input type='text' name='ru' pattern='[A-Za-z0-9]+' maxlength='16' placeholder='Username' style='flex:1;padding:8px;font-size:16px'>",10,\
"<input type='text' name='rp' pattern='[A-Za-z0-9]+' maxlength='16' placeholder='Password' style='flex:1;padding:8px;font-size:16px'>",10,\
"<button type='submit' style='padding:8px 16px;font-size:16px;cursor:pointer'>Register</button>",10,\
"</form>",10,\
0
h1l equ $ - h1

req db 1024 dup(0); request struct

content_len db "CONTENT_LENGTH",0; parametro pasirinkimas
cookieParm db "HTTP_COOKIE",0
; MESSAGES for debugging
Debug1 db "[Slot is NOT taken]"
Debug1L equ $ - Debug1
Debug2 db "|Slot is taken|"
Debug2L equ $ - Debug2
Debug3 db "[Login state active]"
Debug3L equ $ - Debug3
Debug4 db "[Register state active]"
Debug4L equ $ - Debug4
Debug5 db "|Username taken!|"
Debug5L equ $ - Debug5
Debug6 db "|Username doesn't exist!|"
Debug6L equ $ - Debug6
Debug7 db "|+Username match+|"
Debug7L equ $ - Debug7
Debug8 db "|Username not match|"
Debug8L equ $ - Debug8
Debug9 db "|-Password no match-|"
Debug9L equ $ - Debug9
Debug10 db "|+Password Match+|"
Debug10L equ $ - Debug10
True db "<h1>Logged in!</h1>",10
TrueL equ $ - True
False db "<h1>Incorrect password or username.</h1>",10
FalseL equ $ - False
True2 db "<h1>Registered</h1>"
True2L equ $ - True2
False2 db "<h1>This username already exist</h1>"
False2L equ $ - False2


section .bss

align 8
postbuf resb 1024
postlen resd 1
section .text


main:
    push rbp
    mov rbp, rsp
    push rbx
    sub rsp, 8

    %include "LoadMemoryData.asm"; loads data memory

    call FCGX_Init; prepares FCGX stuff, no inouts needed

    ; init request
    lea rdi, [req];location/pointer to FCGX_Request struct
    xor esi, esi; sock, 0 mostly
    xor edx, edx; flags, 0 mostly 
    call FCGX_InitRequest

    .loop:; NOTE all memory is for all users, so i reset at the end memory back
        lea rdi, [req]
        call FCGX_Accept_r;waits for next request
        cmp eax, 0
        jl .done

        print start, startl, [req + 16]; Prints html start line

        mov rdi, content_len; Receaves POST
        mov rsi, [req + 32]
        call FCGX_GetParam
        test rax, rax;Jeigu post nera, iseina
        jz .no_post; if no POST it just skips this part

        xor rcx, rcx
        .parse_len:; kartoja iki 0 gale| convertuoja string 'skaiciu' y skaiciu (ilgiai)
            mov bl, [rax]
            test bl, bl
            jz .got_len;
            
            imul rcx, rcx, 10; shiftina decimal skaicius '0'

            sub bl, '0'; is string y numery
            movzx rbx, bl; isvalo kitus bits, neskaitant bl pacio
            add rcx, rbx; prie ecx prideda skaiciu

            inc rax; kitas array elementas
            jmp .parse_len

        .got_len:
            mov [postlen], ecx
            lea rdi, [postbuf]; y kur yrasyti resultata
            mov rsi, rcx; bytes to read
            mov rdx, [req + 8]; skaito req 8 bytes
            call FCGX_GetStr; returnina rax, kuris yra kiekis raidziu isvestu be 0

            lea rbx, [postbuf];pradzia stringo post
            add rbx, rax; pabaiga stringo post
            mov byte [rbx], 0; nustato pabaiga stringe

            mov r10,0; 0bit - 1 or nd post| 1bit - login or reg

            mov r9,0
            lea rax,[postbuf]; post string
            xor esi,esi
            
            mov ecx, [postlen]; post ilgis

            mov byte bl,[rax]
            cmp bl,'l'
            jne .RegPost ; nustato ar register post ar login
                bts r10,1
            .RegPost:
            
            xor rcx,rcx
            .set:; Skaito post kintamuosius
                mov bl, [rax+rcx]
                cmp bl,0
                je .skip3
                cmp bl,'='
                jne .skipa
                    btc r10,0
                    mov r9,0
                    mov esi,1
                    jmp .skip2
                .skipa:
                    cmp bl,'&'
                    jne .skipb
                        mov [ArgL],r9
                        mov bl,"'"
                        mov byte [query+r9+41],bl; closes querry with '
                        bts r10,0
                        mov r9,0
                        mov esi,0
                        jmp .skip2
                .skipb:
                    bt esi,0
                    jnc .skip2
                        bt r10,1
                        jnc .RegPostA
                            bt r10,0
                            jnc .post2a
                                mov bl,[rax+rcx]
                                mov byte [LoginUser+r9],bl
                                mov byte [CkUserL+r9+17],bl
                                mov byte [query+r9+41],bl
                                inc r9
                                jmp .skip2
                            .post2a:
                                mov bl,[rax+rcx]
                                mov byte [LoginPass+r9],bl
                                mov byte [CkPassL+r9+17],bl
                                inc r9
                                jmp .skip2
                        .RegPostA:
                            bt r10,0
                            jnc .post2b
                                mov bl,[rax+rcx]
                                mov byte [RegUser+r9],bl
                                mov byte [CkUserR+r9+17],bl
                                mov byte [query+r9+41],bl
                                inc r9
                                jmp .skip2
                            .post2b:
                                mov bl,[rax+rcx]
                                mov byte [RegPass+r9],bl
                                mov byte [CkPassR+r9+17],bl
                                inc r9              
                .skip2:
                inc rcx
                jmp .set
            .skip3:
            
        .no_post:
        print h1,h1l,[req + 16]
        Log
        
        
        print debugA,16,[req + 16]
        ;print RegUser,2,[req + 16]
        ;print RegPass,2,[req + 16]
        ;print LoginUser,2,[req + 16]
        ;print LoginPass,2,[req + 16]
        ;print Token,5,[req + 16]

        movzx ax,byte [TestM]
        cmp ax,1
        jne .c2
            print Debug1,Debug1L,[req + 16]
        .c2:
        cmp ax,2
        jne .c3
            print Debug2,Debug2L,[req + 16]
        jne .c3
        .c3:

        .NoLog:
        
        lea rdi, [req]; finish request
        call FCGX_Finish_r

        mov ecx,16
        .ClearPostL:; clears data to be used for next request
            mov byte [LoginUser+ecx-1],0
            mov byte [LoginPass+ecx-1],0
            mov byte [RegUser+ecx-1],0
            mov byte [RegPass+ecx-1],0
            mov byte [CkUserL+ecx+16],0
            mov byte [CkPassL+ecx+16],0
            mov byte [CkUserR+ecx+16],0
            mov byte [CkPassR+ecx+16],0
            mov byte [CkToken+ecx+16],0
            dec ecx
            jnz .ClearPostL
        mov byte [query+57], 0
        mov qword [SqlArrayL],0
        mov byte [TestM],0
        mov byte [TestM],0
        mov qword [HashN],0
        jmp .loop

.done:
    add rsp, 8
    pop rbx
    pop rbp
    xor eax, eax
    ret
