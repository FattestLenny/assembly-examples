; DISCLAIMER:   this is filthy shit-code, please don't ever write assembly like this
;               the purpose of this pile of garbage is to be a point of reference for anyone else 
;               deranged enough to start with assembly socket programming

; PS: Some people yelled at me for using mov eax, 0 instead of xor eax, eax... tough shit
; PS.PS: the error handling hardly works :((

section .data
    socket_error db "socket call failed", 0xA
    socket_error_length equ $ - socket_error
    socket_success db "socket call succeeded", 0xA
    socket_success_length equ $ - socket_success
    bind_success db "bind call succeeded",0xA
    bind_success_length equ $ - bind_success
    bind_error db "bind call failed", 0xA
    bind_error_length equ $ - bind_error
    listen_error db "listen call failed",0xA
    listen_error_length equ $ - listen_error
    listen_success db "listen call succeeded",0xA
    listen_success_length equ $ - listen_success
    exiting db "exiting normally, closing sockets...",0xA
    exiting_length equ $ - exiting
    accept_error db "accept call failed",0xA
    accept_error_length equ $ - accept_error
    accept_success db "accept call succeeded",0xA
    accept_success_length equ $ - accept_success
    listening db "listening...",0xA
    listening_length equ $ - listening
    recv_error db "recv call failed",0xA
    recv_error_length equ $ - recv_error
    recv_success db "recv call succeeded",0xA
    recv_success_length equ $ - recv_success

    SOCK_STREAM equ 1
    AF_INET equ 2
    AF_INET equ 2
    INADDR_ANY equ 0
    MSG_WAITALL equ 0x100
    MSG_DONTWAIT equ 0x40
    SHUT_RDWR equ 2

    SYS_SEND equ 9
    SYS_RECV equ 10

global _start

section .bss
    pfd resd 1
    sfd resd 1
    host_addr resd 4
    host_message resb 50
    client_addr resd 4    
    client_addr_length resd 1
    client_message resb 50
    client_message_length resd 1

section .text
    _start: 

    mov eax, 0x167          ; socket
    mov ebx, AF_INET        ; IPV4
    mov ecx, SOCK_STREAM    ; TCP 
    mov edx, 0              ; unspecified protocol 
    int 0x80

    cmp eax, -1
    je end_socket

    mov DWORD[pfd],eax      ; file descriptor that socket returned gets copied into pfd
    push socket_success
    push socket_success_length
    call print
    add esp, 8
    
    ; typedef struct sockaddr_in {
    ;   short           sin_family;
    ;   short           sin_port;
    ;   struct in_addr  sin_addr;
    ;   uint8_t         sin_zero[8];
    ;}


    mov WORD[host_addr], AF_INET       ; sin_family = IPV4
    mov BYTE[host_addr+2],0x4           ; sin_port = 1045 
    mov BYTE[host_addr+3],0x15
    mov DWORD[host_addr+4],INADDR_ANY   ; Not bound to a specific address = 0 
    ; syscalls expect the data in sockaddr_in to be in net-byte-order, which is big endian
    ; you could normally just use htonl and htons for that, but this solution was more convenient

    mov eax, 0x169          ; bind 
    mov ebx, DWORD[pfd]     ; file descriptor
    mov ecx, host_addr      ; struct sockaddr_in host_addr*
    mov edx, 16             ; sizeof sockaddr_in

    int 0x80
    cmp eax, 0             ; jump to end_bind, if bind returns -1
    jb end_bind             

    push bind_success
    push bind_success_length
    call print
    add esp, 8

    mov eax, 0x16b          ; listen
    mov ebx, DWORD[pfd]     ; file descriptor
    mov ecx, 1              ; 1 backlog 
    int 0x80

    cmp eax, 0              ; jump to end_listen, if listen returns -1
    jb end_listen

    push listen_success
    push listen_success_length
    call print
    add esp,8

    push listening 
    push listening_length 
    call print
    add esp, 8

    mov eax, 0x16C                      ; accept
    mov ebx, DWORD[pfd]                 ; file descriptor
    mov ecx, client_addr                ; information of connecting client gets copied into client_addr
    mov edx, client_addr_length         ; pointer that length of returned struct will be stored in
    mov esi, 0                          ; flags=0 makes accept4 act like accept
    int 0x80


    cmp eax, 0
    jb end_accept

    mov DWORD[sfd],eax      ; accept returns a socket descriptor for the current connection
                            ; that gets moved into sfd
    push accept_success
    push accept_success_length
    call print
    add esp, 8 

    mov ebp, esp
    sub esp, 16
    mov eax, DWORD[sfd]
    mov DWORD[esp],eax
    mov DWORD[esp+4],client_message
    mov DWORD[esp+8],client_message_length
    mov DWORD[esp+12],0                     ; fill in arguments for sockcall to use

    mov eax, 0x66                   ; sockcall 
    mov ebx, SYS_RECV               ; sys_recv
    mov ecx, esp                    ; arguments for sys_recv

    int 0x80
    
    mov esp, ebp

    cmp eax, -1      ; jump to end_accept, if it returns -1
    je end_accept   

    mov DWORD[client_message_length], eax   ; copy the number of received bytes into client_message_length
    
    push recv_success
    push recv_success_length
    call print
    add esp, 8

    ; print the received client message
    push client_message
    push client_message_length
    call print
    add esp, 8

    jmp end_normal

    end_socket: 
    mov eax, 0x04
    mov ebx, 1
    mov ecx, socket_error
    mov edx, socket_error_length
    int 0x80
    jmp end_normal

    end_recv:
    mov eax, 0x04
    mov ebx, 1
    mov ecx, recv_error
    mov edx, recv_error_length
    int 0x80
    jmp end_normal

    end_accept:
    mov eax, 0x04
    mov ebx, 1 
    mov ecx, accept_error
    mov edx, accept_error_length
    int 0x80
    jmp end_normal

    end_bind:
    mov eax, 0x04
    mov ebx, 1
    mov ecx, bind_error
    mov edx, bind_error_length
    int 0x80
    jmp end_normal

    end_listen:
    mov eax, 0x04
    mov ebx, 1
    mov ecx, listen_error
    mov edx, listen_error_length
    int 0x80
    jmp end_normal

    print: 
    push ecx
    push edx
    mov ecx,DWORD[esp+16]
    mov edx,DWORD[esp+12]
    push eax
    push ebx
    mov eax, 0x04
    mov ebx, 1
    int 0x80
    pop ebx
    pop eax
    pop edx
    pop ecx
    ret

    end_normal:

    push exiting
    push exiting_length
    call print
    add esp, 8

    ; close all of the sockets
    mov eax, 0x06
    mov ebx, DWORD[pfd]
    int 0x80

    mov ebx, DWORD[sfd]
    int 0x80

    mov eax, 0x01
    mov ebx, 0
    int 0x80

