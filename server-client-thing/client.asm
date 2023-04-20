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
    exiting db "exiting normally, closing sockets...",0xA
    exiting_length equ $ - exiting

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
    
