; this fucking thing doesn't even work yet.

; DISCLAIMER:   this is filthy shit-code, please don't ever write assembly like this
;               the purpose of this pile of garbage is to be a point of reference for anyone else 
;               deranged enough to start with assembly socket programming

; PS: Some people yelled at me for using mov eax, 0 instead of xor eax, eax... tough shit
; PS.PS: the error handling hardly works :((

section .data
    connect_error db "connect call failed", 0xA
    connect_error_length equ $ - connect_error 
    connect_success db "connect call succeeded", 0xA
    connect_success_length equ $ - connect_success
    exiting db "exiting normally, closing sockets...",0xA
    exiting_length equ $ - exiting
    input_text db "input message:"
    input_text_length equ $ - input_text
    socket_error db "socket call failed",0xA
    socket_error_length equ $ - socket_error
    socket_success db "socket call succeeded",0xA
    socket_success_length equ $ - socket_success
    
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

    push socket_success
    push socket_success_length
    call print
    add esp, 8
    mov DWORD[pfd],eax

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

    ; clients use the sys_connect system call instead of sys_bind
    mov eax, 0x16a          ; connect
    mov ebx, DWORD[pfd]     ; socket file descriptor
    mov ecx, host_addr      ; address information of the host you're trying to connect to       
    mov edx, 16             ; sizeof host_addr

    int 0x80

    cmp eax, -1
    je end_connect

    mov DWORD[pfd],eax      ; file descriptor that connect returned gets copied into pfd
    push connect_success    
    push connect_success_length
    call print
    add esp, 8

    push input_text
    push input_text_length
    call print
    add esp, 8

    mov eax, 0x03           ; sys_read
    mov ebx, 0              ; stdin
    mov ecx, client_message ; buffer for message
    mov edx, 50             ; buffer size of 50

    int 0x80


    mov ebp, esp
    sub esp, 16
    mov eax, DWORD[pfd]
    mov DWORD[esp],eax
    mov DWORD[esp+4],socket_error
    mov DWORD[esp+8],socket_error_length
    mov DWORD[esp+12],0                     ; fill in arguments for sockcall to use

    mov eax, 0x66
    mov ebx, SYS_SEND
    mov ecx, esp

    int 0x80
    cmp eax, 0 
    jb end_socket

    mov esp, ebp

    jmp end_normal
    

    end_connect:
    push connect_error
    push connect_error_length
    call print
    add esp, 8 
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

    end_socket:
    push socket_error
    push socket_error_length
    call print
    add esp, 8

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
