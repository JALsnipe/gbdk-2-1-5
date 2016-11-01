   .include "global.s"

	.area	_CODE

	;; 16-bit multiplication
	;; 
	;; Entry conditions
	;;   BC = multiplicand
	;;   DE = multiplier
	;; 
	;; Exit conditions
	;;   DE = less significant word of product
	;;
	;; Register used: AF,BC,DE,HL

.mul8::
.mulu8::
;   LD    B, #0x00                      ; Sign extend is not necessary with mul
;   LD    D, B

; Table must be page aligned.
; .db (-256*-256)/4,(-255)*(-255)/4,...,(-1*-1)/4, then msb's
; .db 0*0/4,1*1/4,...,255*255/4,                   then msb's
; .db 256*256/4,257*257/4,...,511*511/4            then msb's
; .db 0*0/4,1*1/4,...,255*255/4,                   then msb's

;input:
; C,E=multiplicands
;output:
; DE=product
;mul8:

;   LDH   A, (0xF0)
;   PUSH  AF
;   LD    A, #0x0E
;   LDH   (0xF0), A
;   LD    (0x2000), A
;
;   LD    A, C
;   SUB   E
;   LD    L, A
;   SBC   A, A
;   SBC   A, #256-0x42
;   LD    H, A
;
;   LD    A, C
;   ADD   A, E
;   LD    C, A
;   SBC   A, A
;   SBC   A, #256-0x46
;   LD    B, A
;
;   LD    A, (BC)
;   SUB   (HL)
;   LD    E, A
;   INC   B
;   INC   H
;   LD    A, (BC)
;   SBC   A, (HL)
;   LD    D, A
;
;   POP   AF
;   LDH   (0xF0), A
;   LD    (0x2000), A
;
;   RET

.mul16::
.mulu16::
   LDH   A, (0xF0)
   PUSH  AF
   LD    A, #0x0E
   LDH   (0xF0), A
   LD    (0x2000), A

   LD    A, C                  ; C*E
   SUB   E
   LD    L, A
   SBC   A, A
   SBC   A, #256-0x42
   LD    H, A

   LD    A, C
   LD    C, E
   PUSH  BC
   LD    E, A
   PUSH  DE
   ADD   A, C
   LD    C, A
   SBC   A, A
   SBC   A, #256-0x46
   LD    B, A

   LD    A, (BC)
   SUB   (HL)
   LD    E, A
   INC   B
   INC   H
   LD    A, (BC)
   SBC   A, (HL)
   LD    B, D
   LD    D, A

   POP   BC

   LD    A, C                  ; C*D
   SUB   B
   LD    L, A
   SBC   A, A
   SBC   A, #256-0x42
   LD    H, A

   LD    A, C
   ADD   A, B
   LD    C, A
   SBC   A, A
   SBC   A, #256-0x46
   LD    B, A

   LD    A, (BC)
   SUB   (HL)
   ADD   A, D
   LD    D, A

   POP   BC

   LD    A, B                  ; B*E
   SUB   C
   LD    L, A
   SBC   A, A
   SBC   A, #256-0x42
   LD    H, A

   LD    A, B
   ADD   A, C
   LD    C, A
   SBC   A, A
   SBC   A, #256-0x46
   LD    B, A

   LD    A, (BC)
   SUB   (HL)
   ADD   A, D
   LD    D, A

   LD    BC, #0x20F0
   POP   AF
   LDH   (C), A
   LD    (BC), A

   RET

;   LD HL,#0x00 ; Product = 0
;   LD A,#15    ; Count = bit length - 1
;   ;; Shift-and-add algorithm
;   ;; If MSB of multiplier is 1, add multiplicand to partial product
;   ;; Shift partial product, multiplier left 1 bit
;.mlp:
;   SLA   E     ; Shift multiplier left 1 bit
;   RL D
;   JR NC,.mlp1 ; Jump if MSB of multiplier = 0
;   ADD   HL,BC    ; Add multiplicand to partial product
;.mlp1:
;   ADD   HL,HL    ; Shift partial product left
;   DEC   A
;   JR NZ,.mlp     ; Continue until count = 0
;   ;; Add multiplicand one last time if MSB of multiplier is 1
;   BIT   7,D      ; Get MSB of multiplier
;   JR Z,.mend     ; Exit if MSB of multiplier is 0
;   ADD   HL,BC    ; Add multiplicand to product
;.mend:
;   LD D,H      ; DE = result
;   LD E,L
;   RET

;;----------------------------------------------------------------------------
;;[ MUL_DE_S ] by Hideaki Omuro
;; optimized for time (87 bytes, 104-120 clocks)
;;
;;parameters:
;; BC = 16-bit multiplicand, DE = 16-bit multiplier
;;returns:
;; DE = 16-bit product
;;----------------------------------------------------------------------------
;MUL_DE_S:
;   LD    A, D                          ; AC=multiplicand
;   LD    HL, 0                         ; result=0
;
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip1_1             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip1_1:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip1_2             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip1_2:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip1_3             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip1_3:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip1_4             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip1_4:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip1_5             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip1_5:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip1_6             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip1_6:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip1_7             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip1_7:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip1_8             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip1_8:
;
;   LD    A, E                          ;
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip2_1             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip2_1:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip2_2             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip2_2:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip2_3             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip2_3:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip2_4             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip2_4:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip2_5             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip2_5:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip2_6             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip2_6:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip2_7             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip2_7:
;
;   ADD   HL, HL                        ; 16-bit shift
;   ADD   A, A                          ; test bit
;   JR    NC, _CMDE_skip2_8             ; if shifted bit is set then
;   ADD   HL, BC                        ; add the multiplier
;_CMDE_skip2_8:
;
;   LD    D, H
;   LD    E, L
;
;   RET
