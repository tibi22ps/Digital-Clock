.386
.model flat, stdcall

includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc

includelib kernel32.lib
extern GetLocalTime@4: proc

public start

.data
window_title DB "Exemplu proiect desenare",0
area_width EQU 400
area_height EQU 400
area DD 0

counter DD 0 ; numara evenimentele timerului

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

buton_x EQU 50
buton_y EQU 150
buton_size EQU 300

ora dw 0
min dw 0
sec dw 0

timpstruct struct
		wYear dw ?
		wMonth dw ?
		wDayOfWeek dw ?
		wDay dw ?
		wHour dw ?
		wMinute dw ?
		wSecond dw ?
		wMilliseconds dw ?
timpstruct ends
timp timpstruct <>


.code

oms proc 
		push offset timp
		call GetLocalTime@4
		mov eax, 0
		mov ax, timp.wHour
		mov ora, ax
		mov eax, 0
		mov ax, timp.wMinute
		mov min, ax
		mov eax, 0
		mov ax, timp.wSecond
		mov sec, ax
		mov eax, 0	
	ret
oms endp

; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

linie_o macro x, y ,len , color
	local bucla_linie
		mov eax, y 
		mov ebx, area_width
		mul ebx ; EAX = area_width * y
		add eax, x ; EAX=y* area_width + x
		shl eax, 2 ; EAX= 4 * (y * area_width + x) 
		add eax, area
		mov ecx, len
	bucla_linie:
		mov dword ptr[eax], color
		add eax, 4
		loop bucla_linie
endm
	
linie_v macro x, y ,len , color
	local bucla_linie
		mov eax, y 
		mov ebx, area_width
		mul ebx ; EAX = area_width * y
		add eax, x ; EAX=y* area_width + x
		shl eax, 2 ; EAX= 4 * (y * area_width + x) 
		add eax, area
		mov ecx, len
	bucla_linie:
		mov dword ptr[eax], color
		add eax, area_width * 4 
		loop bucla_linie
endm

punct macro x, y, color
		mov eax, y 
		mov ebx, area_width
		mul ebx ; EAX = area_width * y
		add eax, x ; EAX=y* area_width + x
		shl eax, 2 ; EAX= 4 * (y * area_width + x) 
		add eax, area
		mov dword ptr [eax], color
		mov dword ptr [eax+4], color
		mov dword ptr [eax-4], color
		mov dword ptr [eax + 4 * area_width], color
		mov dword ptr [eax - 4 * area_width], color
		mov dword ptr [eax + 4 * area_width + 4], color
		mov dword ptr [eax + 4 * area_width - 4], color
		mov dword ptr [eax - 4 * area_width + 4], color
		mov dword ptr [eax - 4 * area_width - 4], color
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	jmp afisare_litere
	
evt_click:
	
;coloreaza(din exemplu) 
 
	; mov edi, area
	; mov ecx, area_height
	; mov ebx, [ebp+arg3]
	; and ebx, 7
	; inc ebx
; bucla_linii:
	; mov eax, [ebp+arg2]
	; and eax, 0FFh
	                      ;provide a new (random) color
	; mul eax
	; mul eax
	; add eax, ecx
	; push ecx
	; mov ecx, area_width
; bucla_coloane:
	; mov [edi], eax
	; add edi, 4
	; add eax, ebx
	; loop bucla_coloane
	; pop ecx
	; loop bucla_linii
	jmp afisare_litere
	
evt_timer:
	inc counter
	
afisare_litere:
    call oms 
	mov ebx, 10
	mov eax, 0
	mov ax, ora
	mov edx, 0
	div ebx
	add edx, '0'
	add eax, '0'
	make_text_macro edx, area, 135, 190
	make_text_macro eax, area, 125, 190
	
	mov ebx, 10
	mov eax, 0
	mov ax, min
	mov edx, 0
	div ebx
	add edx, '0'
	add eax, '0'
	make_text_macro edx, area, 185, 190
	make_text_macro eax, area, 175, 190
	
	mov ebx, 10
	mov eax, 0
	mov ax, sec
	mov edx, 0
	div ebx
	add edx, '0'
	add eax, '0'
	make_text_macro edx, area, 235, 190
	make_text_macro eax, area, 225, 190
	
	; cmp edx, 0
	; jne nimic 
	; cmp eax, 0
	; jne nimic
	; jmp coloreaza
; nimic:

	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	
	 make_text_macro 'C', area, 130, 60
	 make_text_macro 'E', area, 140, 60
	 make_text_macro 'A', area, 150, 60
	 make_text_macro 'S', area, 160, 60
	 
	 make_text_macro 'D', area, 180, 60
	 make_text_macro 'I', area, 190, 60
	 make_text_macro 'G', area, 200, 60
	 make_text_macro 'I', area, 210, 60
	 make_text_macro 'T', area, 220, 60
	 make_text_macro 'A', area, 230, 60
	 make_text_macro 'L', area, 240, 60
	
	linie_o buton_x, buton_y, buton_size, 0
	linie_o buton_x, buton_y + 100, buton_size, 0
	linie_v buton_x, buton_y, 100, 0
	linie_v buton_x + 300, buton_y, 100, 0
	punct 160, 195, 0
	punct 160, 205, 0
	punct 210, 195, 0
	punct 210, 205, 0

final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
