#ifndef F_CPU
#define F_CPU 4000000UL
#endif

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <util/delay.h>
#include <avr/pgmspace.h>

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
#define DISPLAY_OFF_TICKS  (60/TIMER_HZ)   /* сек в выкл. состоянии до включения */
#define DISPLAY_WORK_TICKS  (15/TIMER_HZ)   /* сек в вкл. состоянии до выключения */
#define TIMER_HZ          3

#define SEG_PORT    PORTB
#define DIG1_ON     (PORTD |= (1 << PD4))
#define DIG2_ON     (PORTD |= (1 << PD3))
#define DIG3_ON     (PORTD |= (1 << PD5))

#define DIGITS_OFF  PORTD  = 0x00

#define CHK_FLAG(I) (flag & (1 << I))

/* flag bits:
   0 - BUTTON_ST   : button press pending debounce
   1 - REFRESH_ST  : trigger sensor read in main loop
   2 - SOURCE_ST   : active sensor (0=ROOM, 1=OUT)
   3 - ERROR_ST    : sensor 0 CRC error
   4 - ERROR_ST+1  : sensor 1 CRC error
   5 - TOGGLE_ST   : pending source switch (set in main, cleared in ISR)
   7 - STATE_ON    : display enabled                 */
#define BUTTON_ST   0
#define REFRESH_ST  1
#define SOURCE_ST   2
#define ERROR_ST    3
#define TOGGLE_ST   5
#define STATE_ON    7
#define SENSOR_ERR(idx)  (ERROR_ST + (idx))   /* бит ошибки датчика idx */

signed char   temperature;

volatile unsigned char flag = 0;

#define DIG_UNITS  0            /* позиция единиц */
#define DIG_TENS   1            /* позиция десятков */
#define DIG_HI     2            /* позиция сотен или знака '-' */

unsigned char sensor_count,        /* количество найденных датчиков (0..2) */
              sensor_idx,           /* индекс активного датчика (0=ROOM, 1=OUT) */
              digits[3],            /* цифры дисплея [DIG_UNITS/DIG_TENS/DIG_HI] */
              rom_code[2][9];       /* ROM-коды датчиков: [0..1][0..7]=ROM, [8]=CRC */

/* Таблица сегментов во флеше — экономит 14 байт из 128 байт RAM */
#define CHAR_MINUS  10   /* '-' */
#define CHAR_DEG    11   /* '°' */
#define CHAR_E      12   /* 'E' */
#define CHAR_R      13   /* 'r' */
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

void hw_init(void)
{
    /* PORTB: PB0 = 1-Wire (input, внешний pull-up)
              PB1..PB7 = выходы сегментов */
    DDRB  = (1<<PB7)|(1<<PB6)|(1<<PB5)|(1<<PB4)|(1<<PB3)|(1<<PB2)|(1<<PB1);
    PORTB = 0x00;

    /* PORTD: PD2 = кнопка INT0 (вход)
              PD3,PD4,PD5 = управление анодами цифр
              PD6 = выход (не используется, подтянут к GND) */
    DDRD  = (1<<PD6)|(1<<PD5)|(1<<PD4)|(1<<PD3);
    PORTD = 0x00;

    /* Timer1: CTC-режим (WGM12), prescaler=1024
       TCNT1 сбрасывается аппаратно при совпадении с OCR1A → период ≈ 3с */
    TIMSK  = (1 << OCIE1A);
    TCCR1B = (1 << WGM12) | (1 << CS12) | (1 << CS10);   /* CTC, clk/1024 */
    OCR1AH = TIMER1_TOP_H;
    OCR1AL = TIMER1_TOP_L;

    /* INT0: падающий фронт (отпускание кнопки к GND) */
    MCUCR = (1 << ISC01);
    GIMSK = (1 << INT0);

    /* Watchdog: сброс при зависании >2с */
    cli();
    wdt_reset();
    wdt_enable(WDTO_2S);

    /* DS18B20: ждём стабилизации питания, затем установить разрешение 9-бит (0xFF в байте конфигурации),
       затем найти все датчики на шине */
    _delay_ms(200);
    w1_init();
    w1_write(W1_CMD_SKIP_ROM);
    w1_write(W1_CMD_WRITE_CFGROM);
    w1_write(0x00);
    w1_write(0x00);
    w1_write(0xFF);

    w1_init();
    sensor_count = w1_search(W1_CMD_SEARCH_ROM, rom_code);
}

void display_update()
{
    if (!CHK_FLAG(STATE_ON)) return;

    /* Показываем температуру если у текущего датчика (sensor_idx) нет CRC-ошибки.
       При ошибке показываем "Err" (chars[13]=r, chars[12]=E). */
    if (!CHK_FLAG(SENSOR_ERR(sensor_idx)))
    {
        DIGITS_OFF;
        DIG1_ON;
        SEG_PORT = pgm_read_byte(&chars[digits[DIG_UNITS]]);
        _delay_us(SEGMENT_DELAY_US);

        /* DIG2: показываем десятки если они ненулевые,
           или если есть значимые сотни (нужен '0' на месте десятков) */
        if (digits[DIG_TENS] || ((digits[DIG_HI] > 0) && (digits[DIG_HI] < 10)))
        {
            DIGITS_OFF;
            DIG2_ON;
            SEG_PORT = pgm_read_byte(&chars[digits[DIG_TENS]]);
            _delay_us(SEGMENT_DELAY_US);
        }

        if (digits[DIG_HI])
        {
            DIGITS_OFF;
            DIG3_ON;
            SEG_PORT = pgm_read_byte(&chars[digits[DIG_HI]]);
            _delay_us(SEGMENT_DELAY_US);
        }
    }
    else
    {
        /* "Err": слева направо E→r→r на DIG3→DIG2→DIG1 */
        DIGITS_OFF;
        DIG3_ON;
        SEG_PORT = pgm_read_byte(&chars[CHAR_E]);
        _delay_us(SEGMENT_DELAY_US);

        DIGITS_OFF;
        DIG2_ON;
        SEG_PORT = pgm_read_byte(&chars[CHAR_R]);
        _delay_us(SEGMENT_DELAY_US);

        DIGITS_OFF;
        DIG1_ON;
        SEG_PORT = pgm_read_byte(&chars[CHAR_R]);
        _delay_us(SEGMENT_DELAY_US);
    }
    DIGITS_OFF;
}

/* crc_valid — проверяет CRC-8 (Dallas/Maxim) скретчпада DS18B20.
 * Алгоритм: полином x^8 + x^5 + x^4 + 1 (0x31), отражённый LSB-first.
 * Обрабатывает все 9 байт scratchpad[0..8], где [8] — сам байт CRC.
 * При корректных данных финальный остаток равен 0.
 * Возвращает: 1 — CRC совпал, 0 — ошибка.
 */
unsigned char crc_valid(unsigned char *sp)
{
    unsigned char a, b, i, j, crc_buf = 0;

    for (i = 0; i < 9; i++)
    {
        a = sp[i];

        for (j = 0; j < 8; j++)
        {
            b = a;
            a ^= crc_buf;
            if (a & 1) crc_buf = ((crc_buf ^ 0x18) >> 1) | 0x80;
            else crc_buf >>= 1;
            a = b >> 1;
        }
    }

    if (crc_buf == 0) { CBI(flag, SENSOR_ERR(sensor_idx)); return 1; }
    else              { SBI(flag, SENSOR_ERR(sensor_idx)); return 0; }
}

static void sensor_refresh(void);
void sensor_read(unsigned char *sp);
signed char temp_convert(unsigned char *sp);
void display_format(signed char t);

static void sensor_refresh(void)
{
    unsigned char scratchpad[9];
    if (!CHK_FLAG(REFRESH_ST)) return;
    sensor_idx = CHK_FLAG(SOURCE_ST) ? 1 : 0;
    sensor_read(scratchpad);
    if (crc_valid(scratchpad))
    {
        temperature = temp_convert(scratchpad);
        display_format(temperature);
    }
    CBI(flag, REFRESH_ST);
}

static void button_debounce(void)
{
    if (!CHK_FLAG(BUTTON_ST)) return;
    CBI(flag, BUTTON_ST);
    _delay_ms(50);
    if (!(PIND & (1 << PD2)))
        SBI(flag, TOGGLE_ST);
}

void sensor_read(unsigned char *sp)
{
    unsigned char i = 0, t;

    if (sensor_count == 1) sensor_idx = 0;

    if (sensor_count)
    {
        w1_init();
        w1_write(W1_CMD_SKIP_ROM);
        w1_write(W1_CMD_CONVERT);
        /* таймаут 1с: DS18B20 конвертирует макс 750мс. При зависании
           CRC провалится → error_flag выставится штатно.           */
        for (t = 0; t < 200 && !w1_sample(); t++)
            _delay_ms(5);

        w1_init();
        w1_write(W1_CMD_MATCH_ROM);

        for (i = 0; i < 8; i++)
            w1_write(rom_code[sensor_idx][i]);

        w1_write(W1_CMD_READ_SCRATCH);

        for (i = 0; i < 9; i++)
            sp[i] = w1_read();

        w1_init();
    }
}

/* temp_convert — декодирует сырые данные DS18B20 в градусы Цельсия.
 * Формат scratchpad[1:0]: знаковое 16-битное, шаг 1/16°C.
 * Биты [3:0] — дробная часть, сдвиг >>4 отбрасывает её.
 * Диапазон: -55..+125°C, возвращает целые градусы.
 */
signed char temp_convert(unsigned char *sp)
{
    signed int raw = (signed int)((unsigned int)sp[1] << 8 | sp[0]);
    return (signed char)(raw >> 4);
}

/* display_format — раскладывает temperature по цифрам дисплея.
 * digits[DIG_UNITS] = единицы, digits[DIG_TENS] = десятки, digits[DIG_HI] = сотни или знак '-'.
 * Для отрицательных чисел digits[DIG_HI] = 10 (индекс символа '-' в chars[]).
 */
void display_format(signed char t)
{

    if (t < 0)
    {
        digits[DIG_HI] = CHAR_MINUS;
        t = -t;   /* two's complement: получаем |t| */
    }
    else
    {
        digits[DIG_HI] = t / 100;   /* 0 или 1 (макс +125°C) */
        t %= 100;
    }

    digits[DIG_TENS]  = t / 10;     /* t < 100 после %= 100, % 10 не нужен */
    digits[DIG_UNITS] = t % 10;
}

int main(void)
{
    hw_init();
    SBI(flag, STATE_ON);
    SBI(flag, REFRESH_ST);
    sei();

    while (1)
    {
        wdt_reset();
        button_debounce();
        sensor_refresh();
        display_update();
    }
    return 0;
}

ISR(TIMER1_COMPA_vect)
{
    static unsigned char timer = 0;

    if (CHK_FLAG(STATE_ON))
    {
        if (++timer > DISPLAY_WORK_TICKS)
        {
            timer = 0;
            CBI(flag, STATE_ON);
        }
    }
    else
    {
        if (++timer > DISPLAY_OFF_TICKS)
        {
            timer = 0;
            SBI(flag, STATE_ON);
        }
    }

    if (CHK_FLAG(TOGGLE_ST))
    {
        flag ^= (1 << SOURCE_ST);   /* toggle источника */
        CBI(flag, TOGGLE_ST);
    }

    SBI(flag, REFRESH_ST);
}

/* Правило: в ISR только флаг. Задержка — в main(), иначе
   мультиплексинг дисплея тормозит весь экран на 50мс.       */
ISR(INT0_vect)
{
    SBI(flag, BUTTON_ST);
}
