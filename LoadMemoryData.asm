mov rax,2
mov rdi,filename
mov rsi,2
mov rdx,0
syscall
mov [fd],rax

mov rax,9
xor rdi,rdi
mov rsi,10485760
mov rdx,3
mov r10,1
mov r8,[fd]
xor r9,r9
syscall
mov [data],rax
