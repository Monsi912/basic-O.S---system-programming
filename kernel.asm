; ** por compatibilidad se omiten tildes **
; ==============================================================================
; TALLER System Programming - ORGANIZACION DE COMPUTADOR II - FCEN
; ==============================================================================

%include "print.mac"

global start
global break_

; COMPLETAR - Agreguen declaraciones extern según vayan necesitando
extern print_text_rm
extern print_text_pm
extern screen_draw_layout
extern GDT_DESC
extern IDT_DESC
extern idt_init
extern pic_reset
extern pic_enable
extern mmu_init_kernel_dir
extern mmu_init_task_dir
extern copy_page
extern tss_init
extern tss_initial
extern tss_idle
extern tss_set

; COMPLETAR - Definan correctamente estas constantes cuando las necesiten
%define CS_RING_0_SEL 0b1000
%define DS_RING_0_SEL 0b11000


BITS 16
;; Saltear seccion de datos
jmp start

;;
;; Seccion de datos.
;; -------------------------------------------------------------------------- ;;
start_rm_msg db     'Iniciando kernel en Modo Real'
start_rm_len equ    $ - start_rm_msg

start_pm_msg db     'Iniciando kernel en Modo Protegido'
start_pm_len equ    $ - start_pm_msg

;;
;; Seccion de código.
;; -------------------------------------------------------------------------- ;;

;; Punto de entrada del kernel.
BITS 16
start:
    ; COMPLETAR - Deshabilitar interrupciones
    cli

    ; Cambiar modo de video a 80 X 50
    mov ax, 0003h
    int 10h ; set mode 03h
    xor bx, bx
    mov ax, 1112h
    int 10h ; load 8x8 font

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO REAL

    print_text_rm start_rm_msg, start_rm_len, 0x5, 0, 0
    
    ; COMPLETAR - Habilitar A20

    ; COMPLETAR - Habilitar A20
    ; (revisar las funciones definidas en a20.asm)

    call A20_enable

    ; COMPLETAR - Cargar la GDT

    LGDT [GDT_DESC]

    ; COMPLETAR - Setear el bit PE del registro CR0
    mov eax, CR0
    or eax, 1
    mov CR0, eax

    ; COMPLETAR - Saltar a modo protegido (far jump)
    ; (recuerden que un far jmp se especifica como jmp CS_selector:address)
    ; Pueden usar la constante CS_RING_0_SEL definida en este archivo
    jmp CS_RING_0_SEL:modo_protegido


BITS 32
modo_protegido:
    
    ; COMPLETAR - A partir de aca, todo el codigo se va a ejectutar en modo protegido
    ; Establecer selectores de segmentos DS, ES, GS, FS y SS en el segmento de datos de nivel 0
    ; Pueden usar la constante DS_RING_0_SEL definida en este archivo

    xor eax, eax
    mov ax, DS_RING_0_SEL

    mov DS, ax
    mov ES, ax
    mov GS, ax
    mov FS, ax
    mov SS, ax

    ; COMPLETAR - Establecer el tope y la base de la pila

    mov ebp, 0x25000
    mov esp, 0x25000

    ; COMPLETAR - Imprimir mensaje de bienvenida - MODO PROTEGIDO
    print_text_pm start_pm_msg, start_pm_len, 0x5, 3, 0

    ; COMPLETAR - Inicializar pantalla
    
    call screen_draw_layout

    call idt_init
    lidt [IDT_DESC]

    ; activar paginacion

    call mmu_init_kernel_dir

    mov CR3, eax
    
    mov eax, CR0
    or eax, 0x80000000
    mov CR0, eax

    ; <<<<<< task managing

    call tss_init

    mov ax, 0b0000000001011000
    LTR ax

    push tss_idle
    push 0

    call tss_set

    mov ax, 0b0000000001100000
    LTR ax

    JMP 0b0000000001100000:0

    xchg bx, bx

    ; interrupciones

    call pic_reset
    call pic_enable
    sti 
    
    ; Ciclar infinitamente 
    
    mov eax, 0xFFFF
    mov ebx, 0xFFFF
    mov ecx, 0xFFFF
    mov edx, 0xFFFF
    jmp $

;; -------------------------------------------------------------------------- ;;

break_:

    xchg bx, bx
    ret

%include "a20.asm"
