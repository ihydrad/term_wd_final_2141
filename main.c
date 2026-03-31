#ifndef F_CPU
#define F_CPU 4000000UL
#endif

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <util/delay.h>
#include <avr/pgmspace.h>

#define delay_ms(x)  _delay_ms(x)
#define delay_us(x)  _delay_us(x)

#define SBI(BYTE,BIT)         BYTE|=(1<<BIT)
#define CBI(BYTE,BIT)         BYTE&=~(1<<BIT)

/* DS18B20 команды 1-Wire */
#define W1_CMD_SKIP_ROM     0xCC
#define W1_CMD_CONVERT      0x44
#define W1_CMD_MATCH_ROM    0x55
#define W1_CMD_READ_SCRATCH 0xBE
#define W1_CMD_WRITE_CFGROM 0x4E
#define W1_CMD_SEARCH_ROM   0xF0

/* Таймер1: OCR для периода ~3с при F_CPU=4МГц, prescaler=1024
   TOP = F_CPU / prescaler / Hz - 1 = 4000000/1024/0.333 ≈ 0x5B8E */
#define TIMER1_TOP_H  0x5B
#define TIMER1_TOP_L  0x8E

#define SEGMENT_DELAY_US    500
#define DISPLAY_ON_TICKS  60/TIMER_HZ   //sec
#define TIMER_HZ          3

#define SEG_PORT    PORTB
#define DIG1_ON     (PORTD |= (1 << PD4))
#define DIG2_ON     (PORTD |= (1 << PD3))
#define DIG3_ON     (PORTD |= (1 << PD5))

#define DIGITS_OFF  PORTD  = 0x00

#define CHK_FLAG(I) (flag & (1 << I))

/* flag bits:
   1 - REFRESH_ST  : trigger sensor read in main loop
   2 - SOURCE_ST   : active sensor (0=ROOM, 1=OUT)
   3 - ERROR_ST    : sensor 0 CRC error
   4 - ERROR_ST+1  : sensor 1 CRC error
   7 - STATE_ON    : display enabled                 */
#define REFRESH_ST  1
#define SOURCE_ST   2
#define ERROR_ST    3
#define STATE_ON    7

signed char   temperature;

volatile unsigned char flag = 0;

unsigned char sensor_count,
              scratchpad[9],
              crc_buf,
              sensor_idx,
              digits[4],
              rom_code[2][9];

/* Таблица сегментов во флеше — экономит 14 байт из 128 байт RAM */
static const unsigned char chars[14] PROGMEM = {
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

volatile unsigned char source_toggle  = 0;
volatile unsigned char button_pending = 0;  /* выставляется в ISR, обрабатывается в main */

/* ================================================================
 * 1-Wire driver (software bit-bang, pin PB0)
 * Reset pulse: 480µs low → release → 70µs → sample presence → 410µs
 * Write-1 slot: 6µs low → 64µs high
 * Write-0 slot: 60µs low → 10µs high
 * Read  slot:   6µs low → release → 9µs → sample → 55µs
 * ================================================================ */
#define W1_DDR  DDRB
#define W1_PORT PORTB
#define W1_PIN  PINB
#define W1_BIT  PB0

static void w1_drive_low(void)
{
    W1_DDR  |=  (1 << W1_BIT);
    W1_PORT &= ~(1 << W1_BIT);
}

static void w1_float(void)
{
    W1_DDR &= ~(1 << W1_BIT);   /* external pull-up takes over */
}

static unsigned char w1_sample(void)
{
    return (W1_PIN >> W1_BIT) & 1;
}

unsigned char w1_init(void)
{
    unsigned char presence;
    w1_drive_low();
    _delay_us(480);
    w1_float();
    _delay_us(70);
    presence = !w1_sample();
    _delay_us(410);
    return presence;
}

static void w1_write_bit(unsigned char bit)
{
    if (bit)
    {
        w1_drive_low();
        _delay_us(6);
        w1_float();
        _delay_us(64);
    }
    else
    {
        w1_drive_low();
        _delay_us(60);
        w1_float();
        _delay_us(10);
    }
}

static unsigned char w1_read_bit(void)
{
    unsigned char b;
    w1_drive_low();
    _delay_us(6);
    w1_float();
    _delay_us(9);
    b = w1_sample();
    _delay_us(55);
    return b;
}

void w1_write(unsigned char byte)
{
    unsigned char i;
    for (i = 0; i < 8; i++)
    {
        w1_write_bit(byte & 1);
        byte >>= 1;
    }
}

unsigned char w1_read(void)
{
    unsigned char byte = 0, i;
    for (i = 0; i < 8; i++)
        byte |= (w1_read_bit() << i);
    return byte;
}

/*
 * w1_search — перебирает дерево ROM-кодов на шине.
 * cmd       : 0xF0 (Search ROM) или 0xEC (Alarm Search)
 * rom_codes : выходной массив; каждая запись — 8 байт ROM + 1 байт CRC
 * Возвращает: количество найденных устройств (максимум — размер массива)
 */
unsigned char w1_search(unsigned char cmd, unsigned char rom_codes[][9])
{
    unsigned char found            = 0;
    unsigned char last_discrepancy = 0;
    unsigned char done             = 0;
    unsigned char rom[8];
    unsigned char i;
    unsigned char last_zero, bit_idx;
    unsigned char id_bit, comp_bit, byte_idx, bit_mask, search_dir;

    for (i = 0; i < 8; i++) rom[i] = 0;

    while (!done)
    {
        if (!w1_init()) break;

        w1_write(cmd);
        last_zero = 0;

        for (bit_idx = 1; bit_idx <= 64; bit_idx++)
        {
            id_bit   = w1_read_bit();
            comp_bit = w1_read_bit();
            byte_idx = (bit_idx - 1) >> 3;
            bit_mask = 1 << ((bit_idx - 1) & 7);

            if (id_bit && comp_bit) { done = 1; break; }   /* ошибка на шине */

            if (!id_bit && !comp_bit)
            {
                /* коллизия: выбираем направление обхода */
                if (bit_idx < last_discrepancy)
                    search_dir = (rom[byte_idx] & bit_mask) ? 1 : 0;
                else
                    search_dir = (bit_idx == last_discrepancy) ? 1 : 0;

                if (!search_dir) last_zero = bit_idx;
            }
            else
            {
                search_dir = id_bit;
            }

            if (search_dir) rom[byte_idx] |=  bit_mask;
            else            rom[byte_idx] &= ~bit_mask;

            w1_write_bit(search_dir);
        }

        if (!done)
        {
            for (i = 0; i < 8; i++)
                rom_codes[found][i] = rom[i];
            rom_codes[found][8] = 0;
            found++;
            last_discrepancy = last_zero;
            if (last_zero == 0) done = 1;   /* последнее устройство */
            if (found >= 2)     break;       /* массив заполнен */
        }
    }
    return found;
}

void hw_init()
{
    DDRB = 0xFE;
    PORTB = 0x00;

    DDRD = 0x78;
    PORTD = 0x00;

    TIMSK  = 0x40;
    TCCR1B = 0x05;
    OCR1AH = TIMER1_TOP_H;
    OCR1AL = TIMER1_TOP_L;

    GIMSK = 0x40;
    MCUCR = 0x02;
}

void display_update()
{
    if (!(flag & ((1 << ERROR_ST) | (1 << (ERROR_ST + 1)))))
    {
        DIGITS_OFF;
        DIG1_ON;
        SEG_PORT = pgm_read_byte(&chars[digits[1]]);
        delay_us(SEGMENT_DELAY_US);

        if (digits[2] || ((digits[3] > 0) && (digits[3] < 10)))
        {
            DIGITS_OFF;
            DIG2_ON;
            SEG_PORT = pgm_read_byte(&chars[digits[2]]);
            delay_us(SEGMENT_DELAY_US);
        }

        if (digits[3])
        {
            DIGITS_OFF;
            DIG3_ON;
            SEG_PORT = pgm_read_byte(&chars[digits[3]]);
            delay_us(SEGMENT_DELAY_US);
        }
    }
    else
    {
        DIGITS_OFF;
        DIG1_ON;
        SEG_PORT = pgm_read_byte(&chars[13]);
        delay_us(SEGMENT_DELAY_US);

        DIGITS_OFF;
        DIG2_ON;
        SEG_PORT = pgm_read_byte(&chars[13]);
        delay_us(SEGMENT_DELAY_US);

        DIGITS_OFF;
        DIG3_ON;
        SEG_PORT = pgm_read_byte(&chars[12]);
        delay_us(SEGMENT_DELAY_US);
    }
    DIGITS_OFF;
}

unsigned char crc_valid()
{
    unsigned char a, b, i, j;
    crc_buf = 0;

    for (i = 0; i < 9; i++)
    {
        a = scratchpad[i];

        for (j = 0; j < 8; j++)
        {
            b = a;
            a ^= crc_buf;
            if (a & 1) crc_buf = ((crc_buf ^ 0x18) >> 1) | 0x80;
            else crc_buf >>= 1;
            a = b >> 1;
        }
    }

    if (crc_buf == 0) return 1;
    else return 0;
}

void watchdog_init(void)
{
    cli();
    wdt_reset();
    wdt_enable(WDTO_2S);   /* WDP2|WDP0 = 0b101 ≈ 2s */
}

void sensor_read()
{
    unsigned char i = 0;

    if (sensor_count == 1) sensor_idx = 0;

    if (sensor_count)
    {
        w1_init();
        w1_write(W1_CMD_SKIP_ROM);
        w1_write(W1_CMD_CONVERT);
        /* таймаут 1с: DS18B20 конвертирует макс 750мс. При зависании
           CRC провалится → error_flag выставится штатно.           */
        { unsigned char i; for (i = 0; i < 200 && !(PINB & (1 << PB0)); i++) delay_ms(5); }

        w1_init();
        w1_write(W1_CMD_MATCH_ROM);

        for (i = 0; i < 8; i++)
            w1_write(rom_code[sensor_idx][i]);

        w1_write(W1_CMD_READ_SCRATCH);

        for (i = 0; i < 9; i++)
            scratchpad[i] = w1_read();

        w1_init();
    }
}

signed char temp_convert()
{
    signed int raw = (signed int)((unsigned int)scratchpad[1] << 8 | scratchpad[0]);
    return (signed char)(raw >> 4);
}

void display_format()
{
    signed char t = temperature;  /* локальная копия — не портим глобал */

    if (t < 0)
    {
        digits[3] = 10;
        t = ~t;
        t += 1;
    }
    else
    {
        if (t / 100) { digits[3] = t / 100; t = t - 100; }
        else digits[3] = 0;
    }

    digits[2] = (t / 10) % 10;
    digits[1] = t % 10;
}

int main(void)
{
    hw_init();
    watchdog_init();
    delay_ms(200);

    TCNT1H = TIMER1_TOP_H;
    TCNT1L = TIMER1_TOP_L;
    SBI(flag, STATE_ON);

    w1_init();
    w1_write(W1_CMD_SKIP_ROM);
    w1_write(W1_CMD_WRITE_CFGROM);
    w1_write(0x00);
    w1_write(0x00);
    w1_write(0xFF);

    w1_init();
    sensor_count = w1_search(W1_CMD_SEARCH_ROM, rom_code);
    sei();

    while (1)
    {
        wdt_reset();

        /* Debounce: ждём 50мс и перечитываем пин.
           Если дребезг дал ложный фронт — пин уже высокий, игнор. */
        if (button_pending)
        {
            button_pending = 0;
            delay_ms(50);
            if (!(PIND & (1 << PD2)))
                source_toggle = ~source_toggle;
        }

        if (CHK_FLAG(REFRESH_ST))
        {
            sensor_idx = CHK_FLAG(SOURCE_ST) >> 2;
            CBI(flag, (sensor_idx + ERROR_ST));
            sensor_read();
            crc_buf = crc_valid();

            if (crc_buf)
            {
                temperature = temp_convert();
                display_format();
            }
            else SBI(flag, (sensor_idx + ERROR_ST));

            CBI(flag, REFRESH_ST);
        }

        if (CHK_FLAG(STATE_ON))
            display_update();
    }
    return 0;
}

ISR(TIMER1_COMPA_vect)
{
    static unsigned char time_on, time_worked;

    /*=========================================
                      TIMER
    =========================================*/

    if (!CHK_FLAG(STATE_ON)) time_on++;

    if (time_on > DISPLAY_ON_TICKS)
    {
        time_on = 0;
        SBI(flag, STATE_ON);
    }

    if (CHK_FLAG(STATE_ON)) time_worked++;
    if (time_worked > 4)
    {
        time_worked = 0;
        CBI(flag, STATE_ON);
    }
    /*=========================================
    =========================================*/

    if (source_toggle)
    {
        if (CHK_FLAG(SOURCE_ST)) CBI(flag, SOURCE_ST);
        else SBI(flag, SOURCE_ST);
    }

    SBI(flag, REFRESH_ST);
    TCNT1H = 0;
    TCNT1L = 0;
}

/* Правило: в ISR только флаг. Задержка — в main(), иначе
   мультиплексинг дисплея тормозит весь экран на 50мс.       */
ISR(INT0_vect)
{
    button_pending = 1;
}
