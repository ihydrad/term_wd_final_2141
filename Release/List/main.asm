
;CodeVisionAVR C Compiler V3.12 Advanced
;(C) Copyright 1998-2014 Pavel Haiduc, HP InfoTech s.r.l.
;http://www.hpinfotech.com

;Build configuration    : Release
;Chip type              : ATtiny2313
;Program type           : Application
;Clock frequency        : 8,000000 MHz
;Memory model           : Tiny
;Optimize for           : Size
;(s)printf features     : int
;(s)scanf features      : int, width
;External RAM size      : 0
;Data Stack size        : 32 byte(s)
;Heap size              : 0 byte(s)
;Promote 'char' to 'int': Yes
;'char' is unsigned     : Yes
;8 bit enums            : Yes
;Global 'const' stored in FLASH: No
;Enhanced function parameter passing: Yes
;Enhanced core instructions: On
;Automatic register allocation for global variables: On
;Smart register allocation: On

	#define _MODEL_TINY_

	#pragma AVRPART ADMIN PART_NAME ATtiny2313
	#pragma AVRPART MEMORY PROG_FLASH 2048
	#pragma AVRPART MEMORY EEPROM 128
	#pragma AVRPART MEMORY INT_SRAM SIZE 128
	#pragma AVRPART MEMORY INT_SRAM START_ADDR 0x60

	.LISTMAC
	.EQU UDRE=0x5
	.EQU RXC=0x7
	.EQU USR=0xB
	.EQU UDR=0xC
	.EQU EERE=0x0
	.EQU EEWE=0x1
	.EQU EEMWE=0x2
	.EQU EECR=0x1C
	.EQU EEDR=0x1D
	.EQU EEARL=0x1E
	.EQU WDTCR=0x21
	.EQU WDTCSR=0x21
	.EQU MCUSR=0x34
	.EQU MCUCR=0x35
	.EQU SPL=0x3D
	.EQU SREG=0x3F
	.EQU GPIOR0=0x13
	.EQU GPIOR1=0x14
	.EQU GPIOR2=0x15

	.DEF R0X0=R0
	.DEF R0X1=R1
	.DEF R0X2=R2
	.DEF R0X3=R3
	.DEF R0X4=R4
	.DEF R0X5=R5
	.DEF R0X6=R6
	.DEF R0X7=R7
	.DEF R0X8=R8
	.DEF R0X9=R9
	.DEF R0XA=R10
	.DEF R0XB=R11
	.DEF R0XC=R12
	.DEF R0XD=R13
	.DEF R0XE=R14
	.DEF R0XF=R15
	.DEF R0X10=R16
	.DEF R0X11=R17
	.DEF R0X12=R18
	.DEF R0X13=R19
	.DEF R0X14=R20
	.DEF R0X15=R21
	.DEF R0X16=R22
	.DEF R0X17=R23
	.DEF R0X18=R24
	.DEF R0X19=R25
	.DEF R0X1A=R26
	.DEF R0X1B=R27
	.DEF R0X1C=R28
	.DEF R0X1D=R29
	.DEF R0X1E=R30
	.DEF R0X1F=R31

	.EQU __SRAM_START=0x0060
	.EQU __SRAM_END=0x00DF
	.EQU __DSTACK_SIZE=0x0020
	.EQU __HEAP_SIZE=0x0000
	.EQU __CLEAR_SRAM_SIZE=__SRAM_END-__SRAM_START+1

	.MACRO __CPD1N
	CPI  R30,LOW(@0)
	LDI  R26,HIGH(@0)
	CPC  R31,R26
	LDI  R26,BYTE3(@0)
	CPC  R22,R26
	LDI  R26,BYTE4(@0)
	CPC  R23,R26
	.ENDM

	.MACRO __CPD2N
	CPI  R26,LOW(@0)
	LDI  R30,HIGH(@0)
	CPC  R27,R30
	LDI  R30,BYTE3(@0)
	CPC  R24,R30
	LDI  R30,BYTE4(@0)
	CPC  R25,R30
	.ENDM

	.MACRO __CPWRR
	CP   R@0,R@2
	CPC  R@1,R@3
	.ENDM

	.MACRO __CPWRN
	CPI  R@0,LOW(@2)
	LDI  R30,HIGH(@2)
	CPC  R@1,R30
	.ENDM

	.MACRO __ADDB1MN
	SUBI R30,LOW(-@0-(@1))
	.ENDM

	.MACRO __ADDB2MN
	SUBI R26,LOW(-@0-(@1))
	.ENDM

	.MACRO __ADDW1MN
	SUBI R30,LOW(-@0-(@1))
	SBCI R31,HIGH(-@0-(@1))
	.ENDM

	.MACRO __ADDW2MN
	SUBI R26,LOW(-@0-(@1))
	SBCI R27,HIGH(-@0-(@1))
	.ENDM

	.MACRO __ADDW1FN
	SUBI R30,LOW(-2*@0-(@1))
	SBCI R31,HIGH(-2*@0-(@1))
	.ENDM

	.MACRO __ADDD1FN
	SUBI R30,LOW(-2*@0-(@1))
	SBCI R31,HIGH(-2*@0-(@1))
	SBCI R22,BYTE3(-2*@0-(@1))
	.ENDM

	.MACRO __ADDD1N
	SUBI R30,LOW(-@0)
	SBCI R31,HIGH(-@0)
	SBCI R22,BYTE3(-@0)
	SBCI R23,BYTE4(-@0)
	.ENDM

	.MACRO __ADDD2N
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	SBCI R24,BYTE3(-@0)
	SBCI R25,BYTE4(-@0)
	.ENDM

	.MACRO __SUBD1N
	SUBI R30,LOW(@0)
	SBCI R31,HIGH(@0)
	SBCI R22,BYTE3(@0)
	SBCI R23,BYTE4(@0)
	.ENDM

	.MACRO __SUBD2N
	SUBI R26,LOW(@0)
	SBCI R27,HIGH(@0)
	SBCI R24,BYTE3(@0)
	SBCI R25,BYTE4(@0)
	.ENDM

	.MACRO __ANDBMNN
	LDS  R30,@0+(@1)
	ANDI R30,LOW(@2)
	STS  @0+(@1),R30
	.ENDM

	.MACRO __ANDWMNN
	LDS  R30,@0+(@1)
	ANDI R30,LOW(@2)
	STS  @0+(@1),R30
	LDS  R30,@0+(@1)+1
	ANDI R30,HIGH(@2)
	STS  @0+(@1)+1,R30
	.ENDM

	.MACRO __ANDD1N
	ANDI R30,LOW(@0)
	ANDI R31,HIGH(@0)
	ANDI R22,BYTE3(@0)
	ANDI R23,BYTE4(@0)
	.ENDM

	.MACRO __ANDD2N
	ANDI R26,LOW(@0)
	ANDI R27,HIGH(@0)
	ANDI R24,BYTE3(@0)
	ANDI R25,BYTE4(@0)
	.ENDM

	.MACRO __ORBMNN
	LDS  R30,@0+(@1)
	ORI  R30,LOW(@2)
	STS  @0+(@1),R30
	.ENDM

	.MACRO __ORWMNN
	LDS  R30,@0+(@1)
	ORI  R30,LOW(@2)
	STS  @0+(@1),R30
	LDS  R30,@0+(@1)+1
	ORI  R30,HIGH(@2)
	STS  @0+(@1)+1,R30
	.ENDM

	.MACRO __ORD1N
	ORI  R30,LOW(@0)
	ORI  R31,HIGH(@0)
	ORI  R22,BYTE3(@0)
	ORI  R23,BYTE4(@0)
	.ENDM

	.MACRO __ORD2N
	ORI  R26,LOW(@0)
	ORI  R27,HIGH(@0)
	ORI  R24,BYTE3(@0)
	ORI  R25,BYTE4(@0)
	.ENDM

	.MACRO __DELAY_USB
	LDI  R24,LOW(@0)
__DELAY_USB_LOOP:
	DEC  R24
	BRNE __DELAY_USB_LOOP
	.ENDM

	.MACRO __DELAY_USW
	LDI  R24,LOW(@0)
	LDI  R25,HIGH(@0)
__DELAY_USW_LOOP:
	SBIW R24,1
	BRNE __DELAY_USW_LOOP
	.ENDM

	.MACRO __GETD1S
	LDD  R30,Y+@0
	LDD  R31,Y+@0+1
	LDD  R22,Y+@0+2
	LDD  R23,Y+@0+3
	.ENDM

	.MACRO __GETD2S
	LDD  R26,Y+@0
	LDD  R27,Y+@0+1
	LDD  R24,Y+@0+2
	LDD  R25,Y+@0+3
	.ENDM

	.MACRO __PUTD1S
	STD  Y+@0,R30
	STD  Y+@0+1,R31
	STD  Y+@0+2,R22
	STD  Y+@0+3,R23
	.ENDM

	.MACRO __PUTD2S
	STD  Y+@0,R26
	STD  Y+@0+1,R27
	STD  Y+@0+2,R24
	STD  Y+@0+3,R25
	.ENDM

	.MACRO __PUTDZ2
	STD  Z+@0,R26
	STD  Z+@0+1,R27
	STD  Z+@0+2,R24
	STD  Z+@0+3,R25
	.ENDM

	.MACRO __CLRD1S
	STD  Y+@0,R30
	STD  Y+@0+1,R30
	STD  Y+@0+2,R30
	STD  Y+@0+3,R30
	.ENDM

	.MACRO __POINTB1MN
	LDI  R30,LOW(@0+(@1))
	.ENDM

	.MACRO __POINTW1MN
	LDI  R30,LOW(@0+(@1))
	LDI  R31,HIGH(@0+(@1))
	.ENDM

	.MACRO __POINTD1M
	LDI  R30,LOW(@0)
	LDI  R31,HIGH(@0)
	LDI  R22,BYTE3(@0)
	LDI  R23,BYTE4(@0)
	.ENDM

	.MACRO __POINTW1FN
	LDI  R30,LOW(2*@0+(@1))
	LDI  R31,HIGH(2*@0+(@1))
	.ENDM

	.MACRO __POINTD1FN
	LDI  R30,LOW(2*@0+(@1))
	LDI  R31,HIGH(2*@0+(@1))
	LDI  R22,BYTE3(2*@0+(@1))
	LDI  R23,BYTE4(2*@0+(@1))
	.ENDM

	.MACRO __POINTB2MN
	LDI  R26,LOW(@0+(@1))
	.ENDM

	.MACRO __POINTW2MN
	LDI  R26,LOW(@0+(@1))
	LDI  R27,HIGH(@0+(@1))
	.ENDM

	.MACRO __POINTW2FN
	LDI  R26,LOW(2*@0+(@1))
	LDI  R27,HIGH(2*@0+(@1))
	.ENDM

	.MACRO __POINTD2FN
	LDI  R26,LOW(2*@0+(@1))
	LDI  R27,HIGH(2*@0+(@1))
	LDI  R24,BYTE3(2*@0+(@1))
	LDI  R25,BYTE4(2*@0+(@1))
	.ENDM

	.MACRO __POINTBRM
	LDI  R@0,LOW(@1)
	.ENDM

	.MACRO __POINTWRM
	LDI  R@0,LOW(@2)
	LDI  R@1,HIGH(@2)
	.ENDM

	.MACRO __POINTBRMN
	LDI  R@0,LOW(@1+(@2))
	.ENDM

	.MACRO __POINTWRMN
	LDI  R@0,LOW(@2+(@3))
	LDI  R@1,HIGH(@2+(@3))
	.ENDM

	.MACRO __POINTWRFN
	LDI  R@0,LOW(@2*2+(@3))
	LDI  R@1,HIGH(@2*2+(@3))
	.ENDM

	.MACRO __GETD1N
	LDI  R30,LOW(@0)
	LDI  R31,HIGH(@0)
	LDI  R22,BYTE3(@0)
	LDI  R23,BYTE4(@0)
	.ENDM

	.MACRO __GETD2N
	LDI  R26,LOW(@0)
	LDI  R27,HIGH(@0)
	LDI  R24,BYTE3(@0)
	LDI  R25,BYTE4(@0)
	.ENDM

	.MACRO __GETB1MN
	LDS  R30,@0+(@1)
	.ENDM

	.MACRO __GETB1HMN
	LDS  R31,@0+(@1)
	.ENDM

	.MACRO __GETW1MN
	LDS  R30,@0+(@1)
	LDS  R31,@0+(@1)+1
	.ENDM

	.MACRO __GETD1MN
	LDS  R30,@0+(@1)
	LDS  R31,@0+(@1)+1
	LDS  R22,@0+(@1)+2
	LDS  R23,@0+(@1)+3
	.ENDM

	.MACRO __GETBRMN
	LDS  R@0,@1+(@2)
	.ENDM

	.MACRO __GETWRMN
	LDS  R@0,@2+(@3)
	LDS  R@1,@2+(@3)+1
	.ENDM

	.MACRO __GETWRZ
	LDD  R@0,Z+@2
	LDD  R@1,Z+@2+1
	.ENDM

	.MACRO __GETD2Z
	LDD  R26,Z+@0
	LDD  R27,Z+@0+1
	LDD  R24,Z+@0+2
	LDD  R25,Z+@0+3
	.ENDM

	.MACRO __GETB2MN
	LDS  R26,@0+(@1)
	.ENDM

	.MACRO __GETW2MN
	LDS  R26,@0+(@1)
	LDS  R27,@0+(@1)+1
	.ENDM

	.MACRO __GETD2MN
	LDS  R26,@0+(@1)
	LDS  R27,@0+(@1)+1
	LDS  R24,@0+(@1)+2
	LDS  R25,@0+(@1)+3
	.ENDM

	.MACRO __PUTB1MN
	STS  @0+(@1),R30
	.ENDM

	.MACRO __PUTW1MN
	STS  @0+(@1),R30
	STS  @0+(@1)+1,R31
	.ENDM

	.MACRO __PUTD1MN
	STS  @0+(@1),R30
	STS  @0+(@1)+1,R31
	STS  @0+(@1)+2,R22
	STS  @0+(@1)+3,R23
	.ENDM

	.MACRO __PUTB1EN
	LDI  R26,LOW(@0+(@1))
	LDI  R27,HIGH(@0+(@1))
	RCALL __EEPROMWRB
	.ENDM

	.MACRO __PUTW1EN
	LDI  R26,LOW(@0+(@1))
	LDI  R27,HIGH(@0+(@1))
	RCALL __EEPROMWRW
	.ENDM

	.MACRO __PUTD1EN
	LDI  R26,LOW(@0+(@1))
	LDI  R27,HIGH(@0+(@1))
	RCALL __EEPROMWRD
	.ENDM

	.MACRO __PUTBR0MN
	STS  @0+(@1),R0
	.ENDM

	.MACRO __PUTBMRN
	STS  @0+(@1),R@2
	.ENDM

	.MACRO __PUTWMRN
	STS  @0+(@1),R@2
	STS  @0+(@1)+1,R@3
	.ENDM

	.MACRO __PUTBZR
	STD  Z+@1,R@0
	.ENDM

	.MACRO __PUTWZR
	STD  Z+@2,R@0
	STD  Z+@2+1,R@1
	.ENDM

	.MACRO __GETW1R
	MOV  R30,R@0
	MOV  R31,R@1
	.ENDM

	.MACRO __GETW2R
	MOV  R26,R@0
	MOV  R27,R@1
	.ENDM

	.MACRO __GETWRN
	LDI  R@0,LOW(@2)
	LDI  R@1,HIGH(@2)
	.ENDM

	.MACRO __PUTW1R
	MOV  R@0,R30
	MOV  R@1,R31
	.ENDM

	.MACRO __PUTW2R
	MOV  R@0,R26
	MOV  R@1,R27
	.ENDM

	.MACRO __ADDWRN
	SUBI R@0,LOW(-@2)
	SBCI R@1,HIGH(-@2)
	.ENDM

	.MACRO __ADDWRR
	ADD  R@0,R@2
	ADC  R@1,R@3
	.ENDM

	.MACRO __SUBWRN
	SUBI R@0,LOW(@2)
	SBCI R@1,HIGH(@2)
	.ENDM

	.MACRO __SUBWRR
	SUB  R@0,R@2
	SBC  R@1,R@3
	.ENDM

	.MACRO __ANDWRN
	ANDI R@0,LOW(@2)
	ANDI R@1,HIGH(@2)
	.ENDM

	.MACRO __ANDWRR
	AND  R@0,R@2
	AND  R@1,R@3
	.ENDM

	.MACRO __ORWRN
	ORI  R@0,LOW(@2)
	ORI  R@1,HIGH(@2)
	.ENDM

	.MACRO __ORWRR
	OR   R@0,R@2
	OR   R@1,R@3
	.ENDM

	.MACRO __EORWRR
	EOR  R@0,R@2
	EOR  R@1,R@3
	.ENDM

	.MACRO __GETWRS
	LDD  R@0,Y+@2
	LDD  R@1,Y+@2+1
	.ENDM

	.MACRO __PUTBSR
	STD  Y+@1,R@0
	.ENDM

	.MACRO __PUTWSR
	STD  Y+@2,R@0
	STD  Y+@2+1,R@1
	.ENDM

	.MACRO __MOVEWRR
	MOV  R@0,R@2
	MOV  R@1,R@3
	.ENDM

	.MACRO __INWR
	IN   R@0,@2
	IN   R@1,@2+1
	.ENDM

	.MACRO __OUTWR
	OUT  @2+1,R@1
	OUT  @2,R@0
	.ENDM

	.MACRO __CALL1MN
	LDS  R30,@0+(@1)
	LDS  R31,@0+(@1)+1
	ICALL
	.ENDM

	.MACRO __CALL1FN
	LDI  R30,LOW(2*@0+(@1))
	LDI  R31,HIGH(2*@0+(@1))
	RCALL __GETW1PF
	ICALL
	.ENDM

	.MACRO __CALL2EN
	PUSH R26
	PUSH R27
	LDI  R26,LOW(@0+(@1))
	LDI  R27,HIGH(@0+(@1))
	RCALL __EEPROMRDW
	POP  R27
	POP  R26
	ICALL
	.ENDM

	.MACRO __CALL2EX
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	RCALL __EEPROMRDD
	ICALL
	.ENDM

	.MACRO __GETW1STACK
	IN   R30,SPL
	IN   R31,SPH
	ADIW R30,@0+1
	LD   R0,Z+
	LD   R31,Z
	MOV  R30,R0
	.ENDM

	.MACRO __GETD1STACK
	IN   R30,SPL
	IN   R31,SPH
	ADIW R30,@0+1
	LD   R0,Z+
	LD   R1,Z+
	LD   R22,Z
	MOVW R30,R0
	.ENDM

	.MACRO __NBST
	BST  R@0,@1
	IN   R30,SREG
	LDI  R31,0x40
	EOR  R30,R31
	OUT  SREG,R30
	.ENDM


	.MACRO __PUTB1SN
	LDD  R26,Y+@0
	SUBI R26,-@1
	ST   X,R30
	.ENDM

	.MACRO __PUTW1SN
	LDD  R26,Y+@0
	SUBI R26,-@1
	ST   X+,R30
	ST   X,R31
	.ENDM

	.MACRO __PUTD1SN
	LDD  R26,Y+@0
	SUBI R26,-@1
	RCALL __PUTDP1
	.ENDM

	.MACRO __PUTB1SNS
	LDD  R26,Y+@0
	SUBI R26,-@1
	ST   X,R30
	.ENDM

	.MACRO __PUTW1SNS
	LDD  R26,Y+@0
	SUBI R26,-@1
	ST   X+,R30
	ST   X,R31
	.ENDM

	.MACRO __PUTD1SNS
	LDD  R26,Y+@0
	SUBI R26,-@1
	RCALL __PUTDP1
	.ENDM

	.MACRO __PUTB1RN
	MOV  R26,R@0
	SUBI R26,-@1
	ST   X,R30
	.ENDM

	.MACRO __PUTW1RN
	MOV  R26,R@0
	SUBI R26,-@1
	ST   X+,R30
	ST   X,R31
	.ENDM

	.MACRO __PUTD1RN
	MOV  R26,R@0
	SUBI R26,-@1
	RCALL __PUTDP1
	.ENDM

	.MACRO __PUTB1RNS
	MOV  R26,R@0
	SUBI R26,-@1
	ST   X,R30
	.ENDM

	.MACRO __PUTW1RNS
	MOV  R26,R@0
	SUBI R26,-@1
	ST   X+,R30
	ST   X,R31
	.ENDM

	.MACRO __PUTD1RNS
	MOV  R26,R@0
	SUBI R26,-@1
	RCALL __PUTDP1
	.ENDM

	.MACRO __PUTB1PMN
	LDS  R26,@0
	SUBI R26,-@1
	ST   X,R30
	.ENDM

	.MACRO __PUTW1PMN
	LDS  R26,@0
	SUBI R26,-@1
	ST   X+,R30
	ST   X,R31
	.ENDM

	.MACRO __PUTD1PMN
	LDS  R26,@0
	SUBI R26,-@1
	RCALL __PUTDP1
	.ENDM

	.MACRO __PUTB1PMNS
	LDS  R26,@0
	SUBI R26,-@1
	ST   X,R30
	.ENDM

	.MACRO __PUTW1PMNS
	LDS  R26,@0
	SUBI R26,-@1
	ST   X+,R30
	ST   X,R31
	.ENDM

	.MACRO __PUTD1PMNS
	LDS  R26,@0
	SUBI R26,-@1
	RCALL __PUTDP1
	.ENDM

	.MACRO __GETB1SX
	MOVW R30,R28
	SUBI R30,LOW(-@0)
	SBCI R31,HIGH(-@0)
	LD   R30,Z
	.ENDM

	.MACRO __GETB1HSX
	MOVW R30,R28
	SUBI R30,LOW(-@0)
	SBCI R31,HIGH(-@0)
	LD   R31,Z
	.ENDM

	.MACRO __GETW1SX
	MOVW R30,R28
	SUBI R30,LOW(-@0)
	SBCI R31,HIGH(-@0)
	LD   R0,Z+
	LD   R31,Z
	MOV  R30,R0
	.ENDM

	.MACRO __GETD1SX
	MOVW R30,R28
	SUBI R30,LOW(-@0)
	SBCI R31,HIGH(-@0)
	LD   R0,Z+
	LD   R1,Z+
	LD   R22,Z+
	LD   R23,Z
	MOVW R30,R0
	.ENDM

	.MACRO __GETB2SX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	LD   R26,X
	.ENDM

	.MACRO __GETW2SX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	LD   R0,X+
	LD   R27,X
	MOV  R26,R0
	.ENDM

	.MACRO __GETD2SX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	LD   R0,X+
	LD   R1,X+
	LD   R24,X+
	LD   R25,X
	MOVW R26,R0
	.ENDM

	.MACRO __GETBRSX
	MOVW R30,R28
	SUBI R30,LOW(-@1)
	SBCI R31,HIGH(-@1)
	LD   R@0,Z
	.ENDM

	.MACRO __GETWRSX
	MOVW R30,R28
	SUBI R30,LOW(-@2)
	SBCI R31,HIGH(-@2)
	LD   R@0,Z+
	LD   R@1,Z
	.ENDM

	.MACRO __GETBRSX2
	MOVW R26,R28
	SUBI R26,LOW(-@1)
	SBCI R27,HIGH(-@1)
	LD   R@0,X
	.ENDM

	.MACRO __GETWRSX2
	MOVW R26,R28
	SUBI R26,LOW(-@2)
	SBCI R27,HIGH(-@2)
	LD   R@0,X+
	LD   R@1,X
	.ENDM

	.MACRO __LSLW8SX
	MOVW R30,R28
	SUBI R30,LOW(-@0)
	SBCI R31,HIGH(-@0)
	LD   R31,Z
	CLR  R30
	.ENDM

	.MACRO __PUTB1SX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	ST   X,R30
	.ENDM

	.MACRO __PUTW1SX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	ST   X+,R30
	ST   X,R31
	.ENDM

	.MACRO __PUTD1SX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	ST   X+,R30
	ST   X+,R31
	ST   X+,R22
	ST   X,R23
	.ENDM

	.MACRO __CLRW1SX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	ST   X+,R30
	ST   X,R30
	.ENDM

	.MACRO __CLRD1SX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	ST   X+,R30
	ST   X+,R30
	ST   X+,R30
	ST   X,R30
	.ENDM

	.MACRO __PUTB2SX
	MOVW R30,R28
	SUBI R30,LOW(-@0)
	SBCI R31,HIGH(-@0)
	ST   Z,R26
	.ENDM

	.MACRO __PUTW2SX
	MOVW R30,R28
	SUBI R30,LOW(-@0)
	SBCI R31,HIGH(-@0)
	ST   Z+,R26
	ST   Z,R27
	.ENDM

	.MACRO __PUTD2SX
	MOVW R30,R28
	SUBI R30,LOW(-@0)
	SBCI R31,HIGH(-@0)
	ST   Z+,R26
	ST   Z+,R27
	ST   Z+,R24
	ST   Z,R25
	.ENDM

	.MACRO __PUTBSRX
	MOVW R30,R28
	SUBI R30,LOW(-@1)
	SBCI R31,HIGH(-@1)
	ST   Z,R@0
	.ENDM

	.MACRO __PUTWSRX
	MOVW R30,R28
	SUBI R30,LOW(-@2)
	SBCI R31,HIGH(-@2)
	ST   Z+,R@0
	ST   Z,R@1
	.ENDM

	.MACRO __PUTB1SNX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	LD   R0,X+
	LD   R27,X
	MOV  R26,R0
	SUBI R26,LOW(-@1)
	SBCI R27,HIGH(-@1)
	ST   X,R30
	.ENDM

	.MACRO __PUTW1SNX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	LD   R0,X+
	LD   R27,X
	MOV  R26,R0
	SUBI R26,LOW(-@1)
	SBCI R27,HIGH(-@1)
	ST   X+,R30
	ST   X,R31
	.ENDM

	.MACRO __PUTD1SNX
	MOVW R26,R28
	SUBI R26,LOW(-@0)
	SBCI R27,HIGH(-@0)
	LD   R0,X+
	LD   R27,X
	MOV  R26,R0
	SUBI R26,LOW(-@1)
	SBCI R27,HIGH(-@1)
	ST   X+,R30
	ST   X+,R31
	ST   X+,R22
	ST   X,R23
	.ENDM

;NAME DEFINITIONS FOR GLOBAL VARIABLES ALLOCATED TO REGISTERS
	.DEF _temperature=R3
	.DEF _devices=R2
	.DEF _flag=R5
	.DEF _crc=R4
	.DEF _source=R7

;GPIOR0-GPIOR2 INITIALIZATION VALUES
	.EQU __GPIOR0_INIT=0x00
	.EQU __GPIOR1_INIT=0x00
	.EQU __GPIOR2_INIT=0x00

	.CSEG
	.ORG 0x00

;START OF CODE MARKER
__START_OF_CODE:

;INTERRUPT VECTORS
	RJMP __RESET
	RJMP _int0
	RJMP 0x00
	RJMP 0x00
	RJMP _delay_3s
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00
	RJMP 0x00

;GLOBAL REGISTER VARIABLES INITIALIZATION
__REG_VARS:
	.DB  0x1

_0x3:
	.DB  0xBE,0xA,0xDC,0x5E,0x6A,0x76,0xF6,0xE
	.DB  0xFE,0x7E,0x40,0x6C,0xF4,0xC0

__GLOBAL_INI_TBL:
	.DW  0x01
	.DW  0x05
	.DW  __REG_VARS*2

	.DW  0x0E
	.DW  _chars
	.DW  _0x3*2

_0xFFFFFFFF:
	.DW  0

#define __GLOBAL_INI_TBL_PRESENT 1

__RESET:
	CLI
	CLR  R30
	OUT  EECR,R30
	OUT  MCUCR,R30

;CLEAR R2-R14
	LDI  R24,(14-2)+1
	LDI  R26,2
__CLEAR_REG:
	ST   X+,R30
	DEC  R24
	BRNE __CLEAR_REG

;CLEAR SRAM
	LDI  R24,__CLEAR_SRAM_SIZE
	LDI  R26,__SRAM_START
__CLEAR_SRAM:
	ST   X+,R30
	DEC  R24
	BRNE __CLEAR_SRAM

;GLOBAL VARIABLES INITIALIZATION
	LDI  R30,LOW(__GLOBAL_INI_TBL*2)
	LDI  R31,HIGH(__GLOBAL_INI_TBL*2)
__GLOBAL_INI_NEXT:
	LPM  R24,Z+
	LPM  R25,Z+
	SBIW R24,0
	BREQ __GLOBAL_INI_END
	LPM  R26,Z+
	LPM  R27,Z+
	LPM  R0,Z+
	LPM  R1,Z+
	MOVW R22,R30
	MOVW R30,R0
__GLOBAL_INI_LOOP:
	LPM  R0,Z+
	ST   X+,R0
	SBIW R24,1
	BRNE __GLOBAL_INI_LOOP
	MOVW R30,R22
	RJMP __GLOBAL_INI_NEXT
__GLOBAL_INI_END:

;GPIOR0-GPIOR2 INITIALIZATION
	LDI  R30,__GPIOR0_INIT
	OUT  GPIOR0,R30
	;__GPIOR1_INIT = __GPIOR0_INIT
	OUT  GPIOR1,R30
	;__GPIOR2_INIT = __GPIOR0_INIT
	OUT  GPIOR2,R30

;HARDWARE STACK POINTER INITIALIZATION
	LDI  R30,LOW(__SRAM_END-__HEAP_SIZE)
	OUT  SPL,R30

;DATA STACK POINTER INITIALIZATION
	LDI  R28,LOW(__SRAM_START+__DSTACK_SIZE)

	RJMP _main

	.ESEG
	.ORG 0

	.DSEG
	.ORG 0x80

	.CSEG
;#include <io.h>
	#ifndef __SLEEP_DEFINED__
	#define __SLEEP_DEFINED__
	.EQU __se_bit=0x20
	.EQU __sm_mask=0x50
	.EQU __sm_powerdown=0x10
	.EQU __sm_standby=0x40
	.SET power_ctrl_reg=mcucr
	#endif
;#include <1wire.h>
;#include <delay.h>
;
;#define SBI(BYTE,BIT)         BYTE|=(1<<BIT)
;#define CBI(BYTE,BIT)         BYTE&=~(1<<BIT)
;
;#define ROOM        0
;#define OUT         1
;
;#define DEL         500
;#define DEL_ON      60/DIV   //sec
;#define DIV         3
;
;#define SEG_PORT    PORTB
;#define DIG0_ON     PORTD.6 = 1   //no
;#define DIG1_ON     PORTD.4 = 1
;#define DIG2_ON     PORTD.3 = 1
;#define DIG3_ON     PORTD.5 = 1
;
;#define DIGITS_OFF  PORTD  = 0x00
;#define DIGITS_ON   PORTD |= 0x78
;
;#define CHK_FLAG(I) (flag & (1 << I))
;#define SOURCE      CHK_FLAG(SOURCE_ST)
;
;
;#define FIRST_ST    0
;#define REFRESH_ST  1
;#define SOURCE_ST   2
;#define ERROR_ST   3
;
;
;#define STATE_ON    7
;
;signed char   temperature;
;
;unsigned char devices,
;              data[9],
;              flag = 1,
;              crc,
;              source,
;              num[4],
;              rom_code[3][9],
;              chars[14] = {
;               0xBE,  //  0
;               0x0A,  //  1
;               0xDC,  //  2
;               0x5E,  //  3
;               0x6A,  //  4
;               0x76,  //  5
;               0xF6,  //  6
;               0x0E,  //  7
;               0xFE,  //  8
;               0x7E,  //  9
;               0x40,  //  -
;               0x6C,  //  gr
;               0xF4,  //  E
;               0xC0   //  r
;              };

	.DSEG
;
;eeprom unsigned char swap = 0;
;
;void initdev()
; 0000 0041 {

	.CSEG
_initdev:
; .FSTART _initdev
; 0000 0042 DDRB = 0xFE;
	LDI  R30,LOW(254)
	OUT  0x17,R30
; 0000 0043 PORTB = 0x00;
	LDI  R30,LOW(0)
	OUT  0x18,R30
; 0000 0044 
; 0000 0045 DDRD = 0x78;
	LDI  R30,LOW(120)
	OUT  0x11,R30
; 0000 0046 PORTD = 0x00;
	RCALL SUBOPT_0x0
; 0000 0047 
; 0000 0048 TIMSK  = 0x40;
	LDI  R30,LOW(64)
	OUT  0x39,R30
; 0000 0049 TCCR1B = 0x05;
	LDI  R30,LOW(5)
	OUT  0x2E,R30
; 0000 004A OCR1AH = 0x5B;
	LDI  R30,LOW(91)
	OUT  0x2B,R30
; 0000 004B OCR1AL = 0x8E;
	LDI  R30,LOW(142)
	OUT  0x2A,R30
; 0000 004C 
; 0000 004D GIMSK = 0x40;
	LDI  R30,LOW(64)
	OUT  0x3B,R30
; 0000 004E MCUCR = 0x02;
	LDI  R30,LOW(2)
	OUT  0x35,R30
; 0000 004F }
	RET
; .FEND
;
;void disp_drv()
; 0000 0052 {
_disp_drv:
; .FSTART _disp_drv
; 0000 0053  if(!CHK_FLAG(ERROR_ST))
	SBRC R5,3
	RJMP _0x4
; 0000 0054    {
; 0000 0055     DIGITS_OFF;
	RCALL SUBOPT_0x0
; 0000 0056     DIG1_ON;
	SBI  0x12,4
; 0000 0057     SEG_PORT = chars[num[1]];
	__GETB1MN _num,1
	RCALL SUBOPT_0x1
; 0000 0058     delay_us(DEL);
; 0000 0059 
; 0000 005A     if( num[2] || ( (num[3] > 0) && (num[3] < 10) ) )
	__GETB1MN _num,2
	CPI  R30,0
	BRNE _0x8
	__GETB2MN _num,3
	CPI  R26,LOW(0x1)
	BRLO _0x9
	__GETB2MN _num,3
	CPI  R26,LOW(0xA)
	BRLO _0x8
_0x9:
	RJMP _0x7
_0x8:
; 0000 005B      {
; 0000 005C       DIGITS_OFF;
	RCALL SUBOPT_0x0
; 0000 005D       DIG2_ON;
	SBI  0x12,3
; 0000 005E       SEG_PORT = chars[num[2]];
	__GETB1MN _num,2
	RCALL SUBOPT_0x1
; 0000 005F       delay_us(DEL);
; 0000 0060      }
; 0000 0061 
; 0000 0062     if(num[3])
_0x7:
	__GETB1MN _num,3
	CPI  R30,0
	BREQ _0xE
; 0000 0063      {
; 0000 0064       DIGITS_OFF;
	RCALL SUBOPT_0x0
; 0000 0065       DIG3_ON;
	SBI  0x12,5
; 0000 0066       SEG_PORT = chars[num[3]];
	__GETB1MN _num,3
	RCALL SUBOPT_0x1
; 0000 0067       delay_us(DEL);
; 0000 0068      }
; 0000 0069    }
_0xE:
; 0000 006A 
; 0000 006B  else
	RJMP _0x11
_0x4:
; 0000 006C    {
; 0000 006D      DIGITS_OFF;
	RCALL SUBOPT_0x0
; 0000 006E      DIG1_ON;
	SBI  0x12,4
; 0000 006F      SEG_PORT = chars[13];
	RCALL SUBOPT_0x2
; 0000 0070      delay_us(DEL);
; 0000 0071 
; 0000 0072      DIGITS_OFF;
; 0000 0073      DIG2_ON;
	SBI  0x12,3
; 0000 0074      SEG_PORT = chars[13];
	RCALL SUBOPT_0x2
; 0000 0075      delay_us(DEL);
; 0000 0076 
; 0000 0077      DIGITS_OFF;
; 0000 0078      DIG3_ON;
	SBI  0x12,5
; 0000 0079      SEG_PORT = chars[12];
	__GETB1MN _chars,12
	OUT  0x18,R30
; 0000 007A      delay_us(DEL);
	__DELAY_USW 1000
; 0000 007B 
; 0000 007C    }
_0x11:
; 0000 007D    DIGITS_OFF;
	RCALL SUBOPT_0x0
; 0000 007E }
	RET
; .FEND
;
;unsigned char checkCRC()
; 0000 0081 {
_checkCRC:
; .FSTART _checkCRC
; 0000 0082   unsigned char a, b, i, j, crc = 0;
; 0000 0083 
; 0000 0084   for(i = 0; i < 9; i++)
	RCALL __SAVELOCR6
;	a -> R17
;	b -> R16
;	i -> R19
;	j -> R18
;	crc -> R21
	LDI  R21,0
	LDI  R19,LOW(0)
_0x19:
	CPI  R19,9
	BRSH _0x1A
; 0000 0085   {
; 0000 0086     a = data[i];
	LDI  R26,LOW(_data)
	ADD  R26,R19
	LD   R17,X
; 0000 0087 
; 0000 0088     for(j = 0; j < 8; j++)
	LDI  R18,LOW(0)
_0x1C:
	CPI  R18,8
	BRSH _0x1D
; 0000 0089     {
; 0000 008A       b = a;
	MOV  R16,R17
; 0000 008B       a ^= crc;
	EOR  R17,R21
; 0000 008C       if(a & 1) crc = ((crc ^ 0x18) >> 1) | 0x80;
	SBRS R17,0
	RJMP _0x1E
	LDI  R30,LOW(24)
	EOR  R30,R21
	LDI  R31,0
	ASR  R31
	ROR  R30
	ORI  R30,0x80
	MOV  R21,R30
; 0000 008D       else crc >>= 1;
	RJMP _0x1F
_0x1E:
	LSR  R21
; 0000 008E       a = b >> 1;
_0x1F:
	MOV  R30,R16
	LSR  R30
	MOV  R17,R30
; 0000 008F     }
	SUBI R18,-1
	RJMP _0x1C
_0x1D:
; 0000 0090   }
	SUBI R19,-1
	RJMP _0x19
_0x1A:
; 0000 0091 
; 0000 0092   if(crc == 0) return 1;
	CPI  R21,0
	BRNE _0x20
	LDI  R30,LOW(1)
	RJMP _0x2000002
; 0000 0093   else return 0;
_0x20:
	LDI  R30,LOW(0)
; 0000 0094 }
_0x2000002:
	RCALL __LOADLOCR6
	ADIW R28,6
	RET
; .FEND
;
;void WD()
; 0000 0097 {
_WD:
; .FSTART _WD
; 0000 0098  #asm("cli")
	cli
; 0000 0099  #asm("wdr")
	wdr
; 0000 009A  WDTCSR |= (1<<WDCE) | (1<<WDE);
	IN   R30,0x21
	ORI  R30,LOW(0x18)
	OUT  0x21,R30
; 0000 009B  WDTCSR = (1<<WDE) | (1<<WDP2) | (1<<WDP0);
	LDI  R30,LOW(13)
	OUT  0x21,R30
; 0000 009C  #asm("sei")
	sei
; 0000 009D }
	RET
; .FEND
;
;void read_data()
; 0000 00A0 {
_read_data:
; .FSTART _read_data
; 0000 00A1  unsigned char i = 0;
; 0000 00A2 
; 0000 00A3  if(devices == 1) source = 0;
	ST   -Y,R17
;	i -> R17
	LDI  R17,0
	LDI  R30,LOW(1)
	CP   R30,R2
	BRNE _0x22
	CLR  R7
; 0000 00A4 
; 0000 00A5  if(devices)
_0x22:
	TST  R2
	BREQ _0x23
; 0000 00A6    {
; 0000 00A7     w1_init();
	RCALL _w1_init
; 0000 00A8     w1_write(0xCC);   // skip rom
	LDI  R26,LOW(204)
	RCALL _w1_write
; 0000 00A9     w1_write(0x44);   // start conv
	LDI  R26,LOW(68)
	RCALL _w1_write
; 0000 00AA     while(!PINB.0){}
_0x24:
	SBIS 0x16,0
	RJMP _0x24
; 0000 00AB 
; 0000 00AC     w1_init();
	RCALL _w1_init
; 0000 00AD     w1_write(0x55);  // match rom
	LDI  R26,LOW(85)
	RCALL _w1_write
; 0000 00AE 
; 0000 00AF     for(i = 0; i < 8; i++)
	LDI  R17,LOW(0)
_0x28:
	CPI  R17,8
	BRSH _0x29
; 0000 00B0        w1_write(rom_code[source][i]);
	MOV  R30,R7
	LDI  R26,LOW(9)
	RCALL __MULB12U
	SUBI R30,-LOW(_rom_code)
	ADD  R30,R17
	LD   R26,Z
	RCALL _w1_write
	SUBI R17,-1
	RJMP _0x28
_0x29:
; 0000 00B2 w1_write(0xBE);
	LDI  R26,LOW(190)
	RCALL _w1_write
; 0000 00B3 
; 0000 00B4     for(i = 0; i < 9; i++)
	LDI  R17,LOW(0)
_0x2B:
	CPI  R17,9
	BRSH _0x2C
; 0000 00B5        data[i] = w1_read();
	MOV  R30,R17
	SUBI R30,-LOW(_data)
	PUSH R30
	RCALL _w1_read
	POP  R26
	ST   X,R30
	SUBI R17,-1
	RJMP _0x2B
_0x2C:
; 0000 00B7 w1_init();
	RCALL _w1_init
; 0000 00B8    }
; 0000 00B9 }
_0x23:
	RJMP _0x2000001
; .FEND
;
;signed char conv_data()
; 0000 00BC {
_conv_data:
; .FSTART _conv_data
; 0000 00BD  signed char t = 0;
; 0000 00BE 
; 0000 00BF  if( (data[1] >> 4) & 0x0F )
	ST   -Y,R17
;	t -> R17
	LDI  R17,0
	__GETB1MN _data,1
	LDI  R31,0
	RCALL __ASRW4
	ANDI R30,LOW(0xF)
	BREQ _0x2D
; 0000 00C0      {
; 0000 00C1       t = ~(data[0] >> 4);
	LDS  R30,_data
	SWAP R30
	ANDI R30,0xF
	COM  R30
	RCALL SUBOPT_0x3
; 0000 00C2       t += ~(data[1] << 4);
	COM  R30
	ADD  R17,R30
; 0000 00C3       t += 2;
	SUBI R17,-LOW(2)
; 0000 00C4 
; 0000 00C5       if((data[0] >> 3) & 0x01 ) t++;  // округление до целых
	LDS  R30,_data
	LDI  R31,0
	RCALL __ASRW3
	ANDI R30,LOW(0x1)
	BREQ _0x2E
	SUBI R17,-1
; 0000 00C6 
; 0000 00C7       t = -t;
_0x2E:
	NEG  R17
; 0000 00C8      }
; 0000 00C9 
; 0000 00CA     else
	RJMP _0x2F
_0x2D:
; 0000 00CB      {
; 0000 00CC       t = data[0] >> 4;
	LDS  R30,_data
	SWAP R30
	ANDI R30,0xF
	RCALL SUBOPT_0x3
; 0000 00CD       t += data[1] << 4;
	ADD  R17,R30
; 0000 00CE      }
_0x2F:
; 0000 00CF 
; 0000 00D0  return t;
	MOV  R30,R17
_0x2000001:
	LD   R17,Y+
	RET
; 0000 00D1 }
; .FEND
;
;void prepare_disp_data()
; 0000 00D4 {
_prepare_disp_data:
; .FSTART _prepare_disp_data
; 0000 00D5     if(temperature < 0)
	LDI  R30,LOW(0)
	CP   R3,R30
	BRGE _0x30
; 0000 00D6      {
; 0000 00D7      num[3] = 10;
	LDI  R30,LOW(10)
	__PUTB1MN _num,3
; 0000 00D8      temperature = ~temperature;
	COM  R3
; 0000 00D9      temperature += 1;
	INC  R3
; 0000 00DA      }
; 0000 00DB      else
	RJMP _0x31
_0x30:
; 0000 00DC      {
; 0000 00DD      if(temperature /  100) {num[3] = temperature /  100; temperature = temperature - 100;}
	RCALL SUBOPT_0x4
	SBIW R30,0
	BREQ _0x32
	RCALL SUBOPT_0x4
	__PUTB1MN _num,3
	LDI  R30,LOW(100)
	SUB  R3,R30
; 0000 00DE      else num[3] = 0;
	RJMP _0x33
_0x32:
	LDI  R30,LOW(0)
	__PUTB1MN _num,3
; 0000 00DF      }
_0x33:
_0x31:
; 0000 00E0 
; 0000 00E1     if(temperature /  10 ) num[2] = temperature /  10;
	RCALL SUBOPT_0x5
	SBIW R30,0
	BREQ _0x34
	RCALL SUBOPT_0x5
	RJMP _0x45
; 0000 00E2     else num[2] = 0;
_0x34:
	LDI  R30,LOW(0)
_0x45:
	__PUTB1MN _num,2
; 0000 00E3 
; 0000 00E4     num[1] = temperature %  10;
	MOV  R26,R3
	LDI  R27,0
	SBRC R26,7
	SER  R27
	LDI  R30,LOW(10)
	LDI  R31,HIGH(10)
	RCALL __MODW21
	__PUTB1MN _num,1
; 0000 00E5 }
	RET
; .FEND
;
;void main()
; 0000 00E8 {
_main:
; .FSTART _main
; 0000 00E9  initdev();
	RCALL _initdev
; 0000 00EA  WD();
	RCALL _WD
; 0000 00EB  delay_ms(200);
	LDI  R26,LOW(200)
	LDI  R27,0
	RCALL _delay_ms
; 0000 00EC 
; 0000 00ED  TCNT1H = 0x5B;
	LDI  R30,LOW(91)
	OUT  0x2D,R30
; 0000 00EE  TCNT1L = 0x88;
	LDI  R30,LOW(136)
	OUT  0x2C,R30
; 0000 00EF  SBI(flag, STATE_ON);
	LDI  R30,LOW(128)
	OR   R5,R30
; 0000 00F0 
; 0000 00F1  w1_init();
	RCALL _w1_init
; 0000 00F2  w1_write(0xCC);
	LDI  R26,LOW(204)
	RCALL _w1_write
; 0000 00F3  w1_write(0x4E);
	LDI  R26,LOW(78)
	RCALL _w1_write
; 0000 00F4  w1_write(0x00);
	LDI  R26,LOW(0)
	RCALL _w1_write
; 0000 00F5  w1_write(0x00);
	LDI  R26,LOW(0)
	RCALL _w1_write
; 0000 00F6  w1_write(0xFF);
	LDI  R26,LOW(255)
	RCALL _w1_write
; 0000 00F7 
; 0000 00F8  w1_init();
	RCALL _w1_init
; 0000 00F9  devices = w1_search(0xF0, rom_code);
	LDI  R30,LOW(240)
	ST   -Y,R30
	LDI  R26,LOW(_rom_code)
	RCALL _w1_search
	MOV  R2,R30
; 0000 00FA  #asm("sei")
	sei
; 0000 00FB 
; 0000 00FC while (1)
_0x36:
; 0000 00FD     {
; 0000 00FE      #asm("wdr")
	wdr
; 0000 00FF 
; 0000 0100      if(CHK_FLAG(REFRESH_ST))
	SBRS R5,1
	RJMP _0x39
; 0000 0101       {
; 0000 0102       CBI(flag, (source + ERROR_ST));
	RCALL SUBOPT_0x6
	COM  R30
	AND  R5,R30
; 0000 0103       source = CHK_FLAG(SOURCE_ST) >> 2;
	MOV  R30,R5
	ANDI R30,LOW(0x4)
	LDI  R31,0
	RCALL __ASRW2
	MOV  R7,R30
; 0000 0104       read_data();
	RCALL _read_data
; 0000 0105       crc = checkCRC();
	RCALL _checkCRC
	MOV  R4,R30
; 0000 0106 
; 0000 0107        if(crc)
	TST  R4
	BREQ _0x3A
; 0000 0108          {
; 0000 0109           temperature = conv_data();
	RCALL _conv_data
	MOV  R3,R30
; 0000 010A           prepare_disp_data();
	RCALL _prepare_disp_data
; 0000 010B          }
; 0000 010C 
; 0000 010D        else SBI(flag, (source + ERROR_ST));
	RJMP _0x3B
_0x3A:
	RCALL SUBOPT_0x6
	OR   R5,R30
; 0000 010E 
; 0000 010F       CBI(flag, REFRESH_ST);
_0x3B:
	LDI  R30,LOW(253)
	AND  R5,R30
; 0000 0110       }
; 0000 0111 
; 0000 0112       if(CHK_FLAG(STATE_ON))
_0x39:
	SBRC R5,7
; 0000 0113      disp_drv();
	RCALL _disp_drv
; 0000 0114     }
	RJMP _0x36
; 0000 0115 }
_0x3D:
	RJMP _0x3D
; .FEND
;
;interrupt [TIM1_COMPA] void delay_3s()
; 0000 0118 {
_delay_3s:
; .FSTART _delay_3s
	ST   -Y,R26
	ST   -Y,R27
	ST   -Y,R30
	IN   R30,SREG
	ST   -Y,R30
; 0000 0119  static char time_on, time_worked;
; 0000 011A 
; 0000 011B  /*=========================================
; 0000 011C                    TIMER
; 0000 011D  =========================================*/
; 0000 011E 
; 0000 011F  if(!CHK_FLAG(STATE_ON)) time_on++;
	SBRC R5,7
	RJMP _0x3E
	LDS  R30,_time_on_S0000008000
	SUBI R30,-LOW(1)
	STS  _time_on_S0000008000,R30
; 0000 0120 
; 0000 0121  if( time_on > DEL_ON)
_0x3E:
	LDS  R26,_time_on_S0000008000
	CPI  R26,LOW(0x15)
	BRLO _0x3F
; 0000 0122    {
; 0000 0123     time_on = 0;
	LDI  R30,LOW(0)
	STS  _time_on_S0000008000,R30
; 0000 0124     SBI(flag, STATE_ON);
	LDI  R30,LOW(128)
	OR   R5,R30
; 0000 0125    }
; 0000 0126 
; 0000 0127  if(CHK_FLAG(STATE_ON)) time_worked++;
_0x3F:
	SBRS R5,7
	RJMP _0x40
	LDS  R30,_time_worked_S0000008000
	SUBI R30,-LOW(1)
	STS  _time_worked_S0000008000,R30
; 0000 0128  if(time_worked > 4)
_0x40:
	LDS  R26,_time_worked_S0000008000
	CPI  R26,LOW(0x5)
	BRLO _0x41
; 0000 0129    {
; 0000 012A     time_worked = 0;
	LDI  R30,LOW(0)
	STS  _time_worked_S0000008000,R30
; 0000 012B     CBI(flag, STATE_ON);
	LDI  R30,LOW(127)
	AND  R5,R30
; 0000 012C    }
; 0000 012D  /*=========================================
; 0000 012E  =========================================*/
; 0000 012F 
; 0000 0130 
; 0000 0131  if(swap)
_0x41:
	LDI  R26,LOW(_swap)
	LDI  R27,HIGH(_swap)
	RCALL __EEPROMRDB
	CPI  R30,0
	BREQ _0x42
; 0000 0132   {
; 0000 0133    if( CHK_FLAG(SOURCE_ST) ) CBI(flag, SOURCE_ST);
	SBRS R5,2
	RJMP _0x43
	LDI  R30,LOW(251)
	AND  R5,R30
; 0000 0134    else SBI(flag, SOURCE_ST);
	RJMP _0x44
_0x43:
	LDI  R30,LOW(4)
	OR   R5,R30
; 0000 0135   }
_0x44:
; 0000 0136 
; 0000 0137  SBI(flag, REFRESH_ST);
_0x42:
	LDI  R30,LOW(2)
	OR   R5,R30
; 0000 0138  TCNT1H = 0;
	LDI  R30,LOW(0)
	OUT  0x2D,R30
; 0000 0139  TCNT1L = 0;
	OUT  0x2C,R30
; 0000 013A }
	LD   R30,Y+
	OUT  SREG,R30
	LD   R30,Y+
	LD   R27,Y+
	LD   R26,Y+
	RETI
; .FEND
;
;interrupt [EXT_INT0] void int0()
; 0000 013D {
_int0:
; .FSTART _int0
	ST   -Y,R0
	ST   -Y,R1
	ST   -Y,R15
	ST   -Y,R22
	ST   -Y,R23
	ST   -Y,R24
	ST   -Y,R25
	ST   -Y,R26
	ST   -Y,R27
	ST   -Y,R30
	ST   -Y,R31
	IN   R30,SREG
	ST   -Y,R30
; 0000 013E  swap = ~swap;
	LDI  R26,LOW(_swap)
	LDI  R27,HIGH(_swap)
	RCALL __EEPROMRDB
	COM  R30
	LDI  R26,LOW(_swap)
	LDI  R27,HIGH(_swap)
	RCALL __EEPROMWRB
; 0000 013F  delay_ms(50);
	LDI  R26,LOW(50)
	LDI  R27,0
	RCALL _delay_ms
; 0000 0140 }
	LD   R30,Y+
	OUT  SREG,R30
	LD   R31,Y+
	LD   R30,Y+
	LD   R27,Y+
	LD   R26,Y+
	LD   R25,Y+
	LD   R24,Y+
	LD   R23,Y+
	LD   R22,Y+
	LD   R15,Y+
	LD   R1,Y+
	LD   R0,Y+
	RETI
; .FEND

	.DSEG
_data:
	.BYTE 0x9
_num:
	.BYTE 0x4
_rom_code:
	.BYTE 0x1B
_chars:
	.BYTE 0xE

	.ESEG
_swap:
	.DB  0x0

	.DSEG
_time_on_S0000008000:
	.BYTE 0x1
_time_worked_S0000008000:
	.BYTE 0x1

	.CSEG
;OPTIMIZER ADDED SUBROUTINE, CALLED 8 TIMES, CODE SIZE REDUCTION:5 WORDS
SUBOPT_0x0:
	LDI  R30,LOW(0)
	OUT  0x12,R30
	RET

;OPTIMIZER ADDED SUBROUTINE, CALLED 3 TIMES, CODE SIZE REDUCTION:10 WORDS
SUBOPT_0x1:
	SUBI R30,-LOW(_chars)
	LD   R30,Z
	OUT  0x18,R30
	__DELAY_USW 1000
	RET

;OPTIMIZER ADDED SUBROUTINE, CALLED 2 TIMES, CODE SIZE REDUCTION:5 WORDS
SUBOPT_0x2:
	__GETB1MN _chars,13
	OUT  0x18,R30
	__DELAY_USW 1000
	RJMP SUBOPT_0x0

;OPTIMIZER ADDED SUBROUTINE, CALLED 2 TIMES, CODE SIZE REDUCTION:2 WORDS
SUBOPT_0x3:
	MOV  R17,R30
	__GETB1MN _data,1
	SWAP R30
	ANDI R30,0xF0
	RET

;OPTIMIZER ADDED SUBROUTINE, CALLED 2 TIMES, CODE SIZE REDUCTION:4 WORDS
SUBOPT_0x4:
	MOV  R26,R3
	LDI  R27,0
	SBRC R26,7
	SER  R27
	LDI  R30,LOW(100)
	LDI  R31,HIGH(100)
	RCALL __DIVW21
	RET

;OPTIMIZER ADDED SUBROUTINE, CALLED 2 TIMES, CODE SIZE REDUCTION:4 WORDS
SUBOPT_0x5:
	MOV  R26,R3
	LDI  R27,0
	SBRC R26,7
	SER  R27
	LDI  R30,LOW(10)
	LDI  R31,HIGH(10)
	RCALL __DIVW21
	RET

;OPTIMIZER ADDED SUBROUTINE, CALLED 2 TIMES, CODE SIZE REDUCTION:1 WORDS
SUBOPT_0x6:
	MOV  R30,R7
	SUBI R30,-LOW(3)
	LDI  R26,LOW(1)
	RCALL __LSLB12
	RET


	.CSEG
_delay_ms:
	adiw r26,0
	breq __delay_ms1
__delay_ms0:
	__DELAY_USW 0x7D0
	wdr
	sbiw r26,1
	brne __delay_ms0
__delay_ms1:
	ret

	.equ __w1_port=0x18
	.equ __w1_bit=0x00

_w1_init:
	clr  r30
	cbi  __w1_port,__w1_bit
	sbi  __w1_port-1,__w1_bit
	__DELAY_USW 0x3C0
	cbi  __w1_port-1,__w1_bit
	__DELAY_USB 0x25
	sbis __w1_port-2,__w1_bit
	ret
	__DELAY_USB 0xCB
	sbis __w1_port-2,__w1_bit
	ldi  r30,1
	__DELAY_USW 0x30C
	ret

__w1_read_bit:
	sbi  __w1_port-1,__w1_bit
	__DELAY_USB 0x5
	cbi  __w1_port-1,__w1_bit
	__DELAY_USB 0x1D
	clc
	sbic __w1_port-2,__w1_bit
	sec
	ror  r30
	__DELAY_USB 0xD5
	ret

__w1_write_bit:
	clt
	sbi  __w1_port-1,__w1_bit
	__DELAY_USB 0x5
	sbrc r23,0
	cbi  __w1_port-1,__w1_bit
	__DELAY_USB 0x23
	sbic __w1_port-2,__w1_bit
	rjmp __w1_write_bit0
	sbrs r23,0
	rjmp __w1_write_bit1
	ret
__w1_write_bit0:
	sbrs r23,0
	ret
__w1_write_bit1:
	__DELAY_USB 0xC8
	cbi  __w1_port-1,__w1_bit
	__DELAY_USB 0xD
	set
	ret

_w1_read:
	ldi  r22,8
	__w1_read0:
	rcall __w1_read_bit
	dec  r22
	brne __w1_read0
	ret

_w1_write:
	mov  r23,r26
	ldi  r22,8
	clr  r30
__w1_write0:
	rcall __w1_write_bit
	brtc __w1_write1
	ror  r23
	dec  r22
	brne __w1_write0
	inc  r30
__w1_write1:
	ret

_w1_search:
	push r20
	push r21
	clr  r1
	clr  r20
	clr  r27
__w1_search0:
	mov  r0,r1
	clr  r1
	rcall _w1_init
	tst  r30
	breq __w1_search7
	push r26
	ld   r26,y
	rcall _w1_write
	pop  r26
	ldi  r21,1
__w1_search1:
	cp   r21,r0
	brsh __w1_search6
	rcall __w1_read_bit
	sbrc r30,7
	rjmp __w1_search2
	rcall __w1_read_bit
	sbrc r30,7
	rjmp __w1_search3
	rcall __sel_bit
	and  r24,r25
	brne __w1_search3
	mov  r1,r21
	rjmp __w1_search3
__w1_search2:
	rcall __w1_read_bit
__w1_search3:
	rcall __sel_bit
	and  r24,r25
	ldi  r23,0
	breq __w1_search5
__w1_search4:
	ldi  r23,1
__w1_search5:
	rcall __w1_write_bit
	rjmp __w1_search13
__w1_search6:
	rcall __w1_read_bit
	sbrs r30,7
	rjmp __w1_search9
	rcall __w1_read_bit
	sbrs r30,7
	rjmp __w1_search8
__w1_search7:
	mov  r30,r20
	pop  r21
	pop  r20
	adiw r28,1
	ret
__w1_search8:
	set
	rcall __set_bit
	rjmp __w1_search4
__w1_search9:
	rcall __w1_read_bit
	sbrs r30,7
	rjmp __w1_search10
	rjmp __w1_search11
__w1_search10:
	cp   r21,r0
	breq __w1_search12
	mov  r1,r21
__w1_search11:
	clt
	rcall __set_bit
	clr  r23
	rcall __w1_write_bit
	rjmp __w1_search13
__w1_search12:
	set
	rcall __set_bit
	ldi  r23,1
	rcall __w1_write_bit
__w1_search13:
	inc  r21
	cpi  r21,65
	brlt __w1_search1
	rcall __w1_read_bit
	rol  r30
	rol  r30
	andi r30,1
	adiw r26,8
	st   x,r30
	sbiw r26,8
	inc  r20
	tst  r1
	breq __w1_search7
	ldi  r21,9
__w1_search14:
	ld   r30,x
	adiw r26,9
	st   x,r30
	sbiw r26,8
	dec  r21
	brne __w1_search14
	rjmp __w1_search0

__sel_bit:
	mov  r30,r21
	dec  r30
	mov  r22,r30
	lsr  r30
	lsr  r30
	lsr  r30
	add  r30,r26
	clr  r31
	ld   r24,z
	ldi  r25,1
	andi r22,7
__sel_bit0:
	breq __sel_bit1
	lsl  r25
	dec  r22
	rjmp __sel_bit0
__sel_bit1:
	ret

__set_bit:
	rcall __sel_bit
	brts __set_bit2
	com  r25
	and  r24,r25
	rjmp __set_bit3
__set_bit2:
	or   r24,r25
__set_bit3:
	st   z,r24
	ret

__ANEGW1:
	NEG  R31
	NEG  R30
	SBCI R31,0
	RET

__LSLB12:
	TST  R30
	MOV  R0,R30
	MOV  R30,R26
	BREQ __LSLB12R
__LSLB12L:
	LSL  R30
	DEC  R0
	BRNE __LSLB12L
__LSLB12R:
	RET

__ASRW4:
	ASR  R31
	ROR  R30
__ASRW3:
	ASR  R31
	ROR  R30
__ASRW2:
	ASR  R31
	ROR  R30
	ASR  R31
	ROR  R30
	RET

__MULB12U:
	MOV  R0,R26
	SUB  R26,R26
	LDI  R27,9
	RJMP __MULB12U1
__MULB12U3:
	BRCC __MULB12U2
	ADD  R26,R0
__MULB12U2:
	LSR  R26
__MULB12U1:
	ROR  R30
	DEC  R27
	BRNE __MULB12U3
	RET

__DIVW21U:
	CLR  R0
	CLR  R1
	LDI  R25,16
__DIVW21U1:
	LSL  R26
	ROL  R27
	ROL  R0
	ROL  R1
	SUB  R0,R30
	SBC  R1,R31
	BRCC __DIVW21U2
	ADD  R0,R30
	ADC  R1,R31
	RJMP __DIVW21U3
__DIVW21U2:
	SBR  R26,1
__DIVW21U3:
	DEC  R25
	BRNE __DIVW21U1
	MOVW R30,R26
	MOVW R26,R0
	RET

__DIVW21:
	RCALL __CHKSIGNW
	RCALL __DIVW21U
	BRTC __DIVW211
	RCALL __ANEGW1
__DIVW211:
	RET

__MODW21:
	CLT
	SBRS R27,7
	RJMP __MODW211
	COM  R26
	COM  R27
	ADIW R26,1
	SET
__MODW211:
	SBRC R31,7
	RCALL __ANEGW1
	RCALL __DIVW21U
	MOVW R30,R26
	BRTC __MODW212
	RCALL __ANEGW1
__MODW212:
	RET

__CHKSIGNW:
	CLT
	SBRS R31,7
	RJMP __CHKSW1
	RCALL __ANEGW1
	SET
__CHKSW1:
	SBRS R27,7
	RJMP __CHKSW2
	COM  R26
	COM  R27
	ADIW R26,1
	BLD  R0,0
	INC  R0
	BST  R0,0
__CHKSW2:
	RET

__EEPROMRDB:
	SBIC EECR,EEWE
	RJMP __EEPROMRDB
	PUSH R31
	IN   R31,SREG
	CLI
	OUT  EEARL,R26
	SBI  EECR,EERE
	IN   R30,EEDR
	OUT  SREG,R31
	POP  R31
	RET

__EEPROMWRB:
	SBIS EECR,EEWE
	RJMP __EEPROMWRB1
	WDR
	RJMP __EEPROMWRB
__EEPROMWRB1:
	IN   R25,SREG
	CLI
	OUT  EEARL,R26
	SBI  EECR,EERE
	IN   R24,EEDR
	CP   R30,R24
	BREQ __EEPROMWRB0
	OUT  EEDR,R30
	SBI  EECR,EEMWE
	SBI  EECR,EEWE
__EEPROMWRB0:
	OUT  SREG,R25
	RET

__SAVELOCR6:
	ST   -Y,R21
__SAVELOCR5:
	ST   -Y,R20
__SAVELOCR4:
	ST   -Y,R19
__SAVELOCR3:
	ST   -Y,R18
__SAVELOCR2:
	ST   -Y,R17
	ST   -Y,R16
	RET

__LOADLOCR6:
	LDD  R21,Y+5
__LOADLOCR5:
	LDD  R20,Y+4
__LOADLOCR4:
	LDD  R19,Y+3
__LOADLOCR3:
	LDD  R18,Y+2
__LOADLOCR2:
	LDD  R17,Y+1
	LD   R16,Y
	RET

;END OF CODE MARKER
__END_OF_CODE:
