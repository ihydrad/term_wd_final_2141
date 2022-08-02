#include <io.h>
#include <1wire.h>
#include <delay.h>

#define SBI(BYTE,BIT)         BYTE|=(1<<BIT)
#define CBI(BYTE,BIT)         BYTE&=~(1<<BIT)

#define ROOM        0
#define OUT         1

#define DEL         500
#define DEL_ON      60/DIV   //sec
#define DIV         3

#define SEG_PORT    PORTB
#define DIG0_ON     PORTD.6 = 1   //no
#define DIG1_ON     PORTD.4 = 1
#define DIG2_ON     PORTD.3 = 1
#define DIG3_ON     PORTD.5 = 1

#define DIGITS_OFF  PORTD  = 0x00
#define DIGITS_ON   PORTD |= 0x78

#define CHK_FLAG(I) (flag & (1 << I))
#define SOURCE      CHK_FLAG(SOURCE_ST)


#define FIRST_ST    0
#define REFRESH_ST  1
#define SOURCE_ST   2
#define ERROR_ST   3


#define STATE_ON    7

signed char   temperature;

unsigned char devices,
              data[9],
              flag = 1,
              crc,
              source,
              num[4],
              rom_code[3][9],
              chars[14] = {
               0xBE,  //  0
               0x0A,  //  1
               0xDC,  //  2
               0x5E,  //  3
               0x6A,  //  4
               0x76,  //  5
               0xF6,  //  6
               0x0E,  //  7
               0xFE,  //  8
               0x7E,  //  9
               0x40,  //  -
               0x6C,  //  gr
               0xF4,  //  E
               0xC0   //  r
              };

eeprom unsigned char swap = 0;

void initdev()
{
DDRB = 0xFE;
PORTB = 0x00;

DDRD = 0x78;
PORTD = 0x00;

TIMSK  = 0x40;
TCCR1B = 0x05;
OCR1AH = 0x5B;
OCR1AL = 0x8E;

GIMSK = 0x40;
MCUCR = 0x02;
}

void disp_drv()
{
 if(!CHK_FLAG(ERROR_ST))
   {
    DIGITS_OFF;
    DIG1_ON;
    SEG_PORT = chars[num[1]];
    delay_us(DEL);

    if( num[2] || ( (num[3] > 0) && (num[3] < 10) ) )
     {
      DIGITS_OFF;
      DIG2_ON;
      SEG_PORT = chars[num[2]];
      delay_us(DEL);
     }

    if(num[3])
     {
      DIGITS_OFF;
      DIG3_ON;
      SEG_PORT = chars[num[3]];
      delay_us(DEL);
     }
   }

 else
   {
     DIGITS_OFF;
     DIG1_ON;
     SEG_PORT = chars[13];
     delay_us(DEL);

     DIGITS_OFF;
     DIG2_ON;
     SEG_PORT = chars[13];
     delay_us(DEL);

     DIGITS_OFF;
     DIG3_ON;
     SEG_PORT = chars[12];
     delay_us(DEL);

   }
   DIGITS_OFF;
}

unsigned char checkCRC()
{
  unsigned char a, b, i, j, crc = 0;

  for(i = 0; i < 9; i++)
  {
    a = data[i];

    for(j = 0; j < 8; j++)
    {
      b = a;
      a ^= crc;
      if(a & 1) crc = ((crc ^ 0x18) >> 1) | 0x80;
      else crc >>= 1;
      a = b >> 1;
    }
  }

  if(crc == 0) return 1;
  else return 0;
}

void WD()
{
 #asm("cli")
 #asm("wdr")
 WDTCSR |= (1<<WDCE) | (1<<WDE);
 WDTCSR = (1<<WDE) | (1<<WDP2) | (1<<WDP0);
 #asm("sei")
}

void read_data()
{
 unsigned char i = 0;

 if(devices == 1) source = 0;

 if(devices)
   {
    w1_init();
    w1_write(0xCC);   // skip rom
    w1_write(0x44);   // start conv
    while(!PINB.0){}

    w1_init();
    w1_write(0x55);  // match rom

    for(i = 0; i < 8; i++)
       w1_write(rom_code[source][i]);

    w1_write(0xBE);  // read scratch pad

    for(i = 0; i < 9; i++)
       data[i] = w1_read();

    w1_init();
   }
}

signed char conv_data()
{
 signed char t = 0;

 if( (data[1] >> 4) & 0x0F )
     {
      t = ~(data[0] >> 4);
      t += ~(data[1] << 4);
      t += 2;

      if((data[0] >> 3) & 0x01 ) t++;  // округление до целых

      t = -t;
     }

    else
     {
      t = data[0] >> 4;
      t += data[1] << 4;
     }

 return t;
}

void prepare_disp_data()
{
    if(temperature < 0)
     {
     num[3] = 10;
     temperature = ~temperature;
     temperature += 1;
     }
     else
     {
     if(temperature /  100) {num[3] = temperature /  100; temperature = temperature - 100;}
     else num[3] = 0;
     }

    if(temperature /  10 ) num[2] = temperature /  10;
    else num[2] = 0;

    num[1] = temperature %  10;
}

void main()
{
 initdev();
 WD();
 delay_ms(200);

 TCNT1H = 0x5B;
 TCNT1L = 0x88;
 SBI(flag, STATE_ON);

 w1_init();
 w1_write(0xCC);
 w1_write(0x4E);
 w1_write(0x00);
 w1_write(0x00);
 w1_write(0xFF);

 w1_init();
 devices = w1_search(0xF0, rom_code);
 #asm("sei")

while (1)
    {
     #asm("wdr")

     if(CHK_FLAG(REFRESH_ST))
      {
      CBI(flag, (source + ERROR_ST));
      source = CHK_FLAG(SOURCE_ST) >> 2;
      read_data();
      crc = checkCRC();

       if(crc)
         {
          temperature = conv_data();
          prepare_disp_data();
         }

       else SBI(flag, (source + ERROR_ST));

      CBI(flag, REFRESH_ST);
      }

      if(CHK_FLAG(STATE_ON))
     disp_drv();
    }
}

interrupt [TIM1_COMPA] void delay_3s()
{
 static char time_on, time_worked;

 /*=========================================
                   TIMER
 =========================================*/

 if(!CHK_FLAG(STATE_ON)) time_on++;

 if( time_on > DEL_ON)
   {
    time_on = 0;
    SBI(flag, STATE_ON);
   }

 if(CHK_FLAG(STATE_ON)) time_worked++;
 if(time_worked > 4)
   {
    time_worked = 0;
    CBI(flag, STATE_ON);
   }
 /*=========================================
 =========================================*/


 if(swap)
  {
   if( CHK_FLAG(SOURCE_ST) ) CBI(flag, SOURCE_ST);
   else SBI(flag, SOURCE_ST);
  }

 SBI(flag, REFRESH_ST);
 TCNT1H = 0;
 TCNT1L = 0;
}

interrupt [EXT_INT0] void int0()
{
 swap = ~swap;
 delay_ms(50);
}
