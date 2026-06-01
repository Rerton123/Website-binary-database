%macro print 3
    lea rdi, [%1]; array string pointer
    mov rsi, %2; array lenght
    mov rdx, %3; [req + 16]
    call FCGX_PutStr
%endmacro

%macro printA 3
    mov rdi, %1; array string pointer
    mov rsi, %2; array lenght
    mov rdx, %3; [req + 16]
    call FCGX_PutStr
%endmacro

%macro hash 2
    mov rax,5321
    mov rsi,%1
    mov rcx,[%2]
    xor rbx,rbx
    %%Combine:
        mov bl,[rsi]

        mov rdx,rax
        shl rax,5
        add rax,rdx
        add rax,rbx
        
        inc rsi
        dec rcx 
        jnz %%Combine
    xor rdx,rdx
    mov rbx,100000
    div rbx

    mov [HashN],rdx
    lea rsi,[CkToken+4]
    add rsi,17
    mov rax,rdx
    mov rbx,10
    mov ecx,5
    mov r9,0
    %%HashStr:
        xor rdx,rdx
        div rbx

        add dl,"0"
        mov [rsi],dl
        dec rsi
        inc r9
        dec ecx
        jnz %%HashStr
%endmacro

%macro Log 0

    mov rdi, cookieParm; isgauna POST, parametras = ka toky
    mov rsi, [req + 32]
    call FCGX_GetParam
    test rax,rax; rax = pointer y 
    jz %%no_token;Jeigu yra token, jy loadina

        xor rcx,rcx
        xor rbx,rbx
        mov rsi,Token
        xor r9,r9
        %%GetToken:
            mov bl,[rax]
            test bl,bl
            jz %%Turned; 0 = galas string
                cmp bl,"="; skaito skaicius tik po '='
                jne %%NoEq
                    mov r9,1
                    jmp %%NotYet
                %%NoEq:
                test r9,r9
                jz %%NotYet
                    mov [rsi],bl
                    sub bl,"0"
                    imul rcx,rcx,10
                    add rcx,rbx
                    inc rsi
            %%NotYet:
            inc rax
            jmp %%GetToken
        %%Turned:
        mov qword [HashN],rcx
        HashLogin
        jmp %%NoUser
    %%no_token:; jeigu nera token patikrina ar yra duomenys yvesti


    mov bl,0
    cmp byte [LoginUser],bl
    je %%RegHash
        hash LoginUser,ArgL
        ;print CkToken,CkTokenL,[req + 16]
        print Debug3,Debug3L,[req + 16]
        
        HashLogin
        jmp %%NoUser
    %%RegHash:
    cmp byte [RegUser],bl
    je %%NoUser
        hash RegUser,ArgL
        print Debug4,Debug4L, [req + 16]
        ;print CkToken,CkTokenL,[req + 16]
        HashRegister
    %%NoUser:

%endmacro

%macro Hash2ByteIndex 0
    mov rax,[HashN]
    mov rbx,100
    mul rbx

    ;mov rax, 1858900
    push rax
    mov rbx,10
    lea rdi,[debugA + 15]
    mov rcx,16
    %%debug:
        xor rdx,rdx
        div rbx
        add dl,"0"
        mov byte [rdi],dl

        dec rdi
        dec rcx
        jnz %%debug
    pop rax
%endmacro

%macro HashLogin 0
    Hash2ByteIndex; rax = Byte index
    mov rbx,[data]
    add rbx,rax
    push rbx
    %%Search:
        movzx ax, byte [rbx]
        bt ax,0; 0 - nera paskyros; 1 - yra paskyra
        jc %%IsAcc
            print Debug6,Debug6L,[req + 16]; jeigu slot empty, tais nustoja tikrines
            jmp %%over
        %%IsAcc:
            inc rbx; nuo [1 byte skaito
            print Debug2,Debug2L,[req + 16]
            lea rdi, [LoginUser]
            mov rcx,16
            %%CompareUser:
                mov al,[rdi]
                cmp al,byte [rbx]
                jne %%NoMatchU
                    inc rbx
                    inc rdi
                    dec rcx
                    jnz %%CompareUser
            print Debug7,Debug7L,[req + 16]

            lea rdi,[LoginPass]
            mov rcx,16
            %%ComparePass:; palygina sekancius 16 bytes
                mov al,[rdi]
                cmp al,byte [rbx]
                jne %%NoMatchP
                    inc rbx
                    inc rdi
                    dec rcx
                    jnz %%ComparePass
            print Debug10,Debug10L,[req + 16]
            jmp %%over
            %%NoMatchU:
                print Debug8,Debug8L,[req + 16]
                jmp %%continue
            %%NoMatchP:
                print Debug9,Debug9L,[req + 16]
                jmp %%over
            %%continue:
    pop rbx
    add rbx,100
    push rbx
    jmp %%Search
    %%over:
%endmacro

%macro HashRegister 0
Hash2ByteIndex; output rax = Byte index

mov rbx,[data]
add rbx,rax
push rbx

%%Search:
    movzx dx, byte [rbx]; yraso [0] byte
    bt dx,0; 0 - nera paskyros; 1 - yra paskyra
    jc %%IsAcc; jeigu nera paskyros, registrouja
        mov byte [TestM],1; nera

        mov byte [rbx],1; pirmas byte -> 1
        inc rbx; rbx -> byte[1]
        lea rdx,[RegUser]; RegUser pointer
        mov rcx,16
        %%RegisterUser:; yraso Register Username y data,16 byte
            mov al,[rdx]

            mov byte [rbx],al

            inc rdx
            inc rbx
            dec rcx
            jnz %%RegisterUser
        %%DoneRegUser:

        lea rdx,[RegPass]; RegUser pointer
        mov rcx,16
        %%RegisterPass:; yraso Register Username y data,16 byte
            mov al,[rdx]

            mov byte [rbx],al

            inc rdx
            inc rbx
            dec rcx
            jnz %%RegisterPass
        %%DoneRegPass:
        jmp %%over
    %%IsAcc:
        inc rbx
        mov rcx,16
        lea rdi, [RegUser]
        %%CompareUser:   
            mov al, [rdi]
            cmp al, byte [rbx]
            jne %%NotEqual

                inc rdi
                inc rbx

                dec rcx
                jnz %%CompareUser
        
            print Debug5,Debug5L,[req + 16]
            jmp %%over
        %%NotEqual:
            print Debug2,Debug2L,[req + 16]

    pop rbx
    add rbx,100
    push rbx
    jmp %%Search
%%over:
%endmacro
