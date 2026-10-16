/*
 * Bare-metal "breathing" LED blinky for STM32F407 / STM32F303 / STM32L4 / STM32C0.
 * Identical effect on every board: 1 kHz PWM carrier, brightness follows a
 * quadratic triangle ramp with a PERIOD_MS period (default 2 s), timed by a
 * 1 ms SysTick derived from the reset-default clock of each family.
 */
#include <stdint.h>

#define REG(addr) (*(volatile uint32_t *)(addr))

/* GPIO / TIM register offsets are identical across these families */
#define GPIO_MODER   0x00
#define GPIO_OSPEEDR 0x08
#define GPIO_BSRR    0x18
#define GPIO_AFRL    0x20
#define TIM_CR1   0x00
#define TIM_SR    0x10
#define TIM_EGR   0x14
#define TIM_CCMR1 0x18
#define TIM_CCMR2 0x1C
#define TIM_CCER  0x20
#define TIM_PSC   0x28
#define TIM_ARR   0x2C
#define TIM_CCR1  0x34
#define TIM_BDTR  0x44

#define SYST_CSR 0xE000E010
#define SYST_RVR 0xE000E014
#define SYST_CVR 0xE000E018

#if defined(BOARD_F407DISCO)      /* LD4 green, PD12 = TIM4_CH1 AF2, HSI 16 MHz */
# define CLK_HZ 16000000u
# define GPIO   0x40020C00u
# define PIN    12
# define AF     2
# define TIM    0x40000800u
# define CH     1
static void clocks(void) { REG(0x40023830) |= 1u << 3; REG(0x40023840) |= 1u << 2; }
#elif defined(BOARD_F3DISCO)      /* LD7 green, PE11 = TIM1_CH2 AF2, HSI 8 MHz */
# define CLK_HZ 8000000u
# define GPIO   0x48001000u
# define PIN    11
# define AF     2
# define TIM    0x40012C00u
# define CH     2
# define ADVANCED_TIM
static void clocks(void) { REG(0x40021014) |= 1u << 21; REG(0x40021018) |= 1u << 11; }
#elif defined(BOARD_L4NUCLEO64)   /* LD2 green, PA5 = TIM2_CH1 AF1, MSI 4 MHz */
# define CLK_HZ 4000000u
# define GPIO   0x48000000u
# define PIN    5
# define AF     1
# define TIM    0x40000000u
# define CH     1
static void clocks(void) { REG(0x4002104C) |= 1u << 0; REG(0x40021058) |= 1u << 0; }
#elif defined(BOARD_L4NUCLEO32)   /* LD3 green, PB3 = TIM2_CH2 AF1, MSI 4 MHz */
# define CLK_HZ 4000000u
# define GPIO   0x48000400u
# define PIN    3
# define AF     1
# define TIM    0x40000000u
# define CH     2
static void clocks(void) { REG(0x4002104C) |= 1u << 1; REG(0x40021058) |= 1u << 0; }
#elif defined(BOARD_C0NUCLEO)     /* LD4/LD1 green on PA5, HSISYS 12 MHz, TIM3 drives a GPIO PWM */
# define CLK_HZ 12000000u
# define GPIO   0x50000000u
# define PIN    5
# define TIM    0x40000400u
# define CH     1
# define SOFT_OUTPUT   /* timer generates the PWM, compare/update flags drive the pin */
static void clocks(void) { REG(0x40021034) |= 1u << 0; REG(0x4002103C) |= 1u << 1; }
#else
# error "define a BOARD_*"
#endif

#ifndef PERIOD_MS
# define PERIOD_MS 2000u                     /* full breathing cycle, up + down */
#endif

#define PWM_TOP 1000u                        /* 1 MHz timer clock / 1000 = 1 kHz PWM */
#define CCR (TIM + TIM_CCR1 + 4 * (CH - 1))

static void gpio_init(void)
{
#ifdef SOFT_OUTPUT
    REG(GPIO + GPIO_MODER) = (REG(GPIO + GPIO_MODER) & ~(3u << (2 * PIN))) | (1u << (2 * PIN));
#else
    uint32_t afr = GPIO + GPIO_AFRL + 4 * (PIN / 8);
    REG(afr) = (REG(afr) & ~(0xFu << (4 * (PIN % 8)))) | ((uint32_t)AF << (4 * (PIN % 8)));
    REG(GPIO + GPIO_MODER) = (REG(GPIO + GPIO_MODER) & ~(3u << (2 * PIN))) | (2u << (2 * PIN));
#endif
}

static void tim_init(void)
{
    REG(TIM + TIM_PSC) = CLK_HZ / 1000000u - 1;
    REG(TIM + TIM_ARR) = PWM_TOP - 1;
    REG(CCR) = 0;
    uint32_t ccmr = TIM + (CH <= 2 ? TIM_CCMR1 : TIM_CCMR2);
    uint32_t sh = ((CH - 1) % 2) * 8;
    REG(ccmr) = (REG(ccmr) & ~(0xFFu << sh)) | ((6u << 4 | 1u << 3) << sh);   /* PWM mode 1 + preload */
#ifndef SOFT_OUTPUT
    REG(TIM + TIM_CCER) |= 1u << (4 * (CH - 1));
#endif
#ifdef ADVANCED_TIM
    REG(TIM + TIM_BDTR) |= 1u << 15;                                          /* MOE */
#endif
    REG(TIM + TIM_EGR) = 1;
    REG(TIM + TIM_CR1) = 1u << 7 | 1u;                                        /* ARPE | CEN */
}

void main(void)
{
    clocks();
    gpio_init();
    tim_init();

    REG(SYST_RVR) = CLK_HZ / 1000u - 1;
    REG(SYST_CVR) = 0;
    REG(SYST_CSR) = 5;                    /* processor clock, enabled, no interrupt */

    uint32_t ms = 0;
    for (;;) {
        if (REG(SYST_CSR) & (1u << 16)) { /* COUNTFLAG: one millisecond elapsed */
            ms = (ms + 1) % PERIOD_MS;
            uint32_t h = ms < PERIOD_MS / 2 ? ms : PERIOD_MS - ms;
            uint32_t t = h * 2000u / PERIOD_MS;            /* 0..1000..0 */
            REG(CCR) = t * t / PWM_TOP;                     /* perceptual (quadratic) ramp */
        }
#ifdef SOFT_OUTPUT
        uint32_t sr = REG(TIM + TIM_SR);
        if (sr & 1u) {                                     /* update: start of period */
            REG(TIM + TIM_SR) = ~1u;
            if (REG(CCR)) REG(GPIO + GPIO_BSRR) = 1u << PIN;
        }
        if (sr & (1u << CH)) {                             /* compare match: end of duty */
            REG(TIM + TIM_SR) = ~(1u << CH);
            REG(GPIO + GPIO_BSRR) = 1u << (PIN + 16);
        }
#endif
    }
}

/* minimal startup */
extern uint32_t _estack, _sbss, _ebss;
void Reset_Handler(void)
{
    for (uint32_t *p = &_sbss; p < &_ebss; p++) *p = 0;
    main();
}
void Default_Handler(void) { for (;;); }

__attribute__((section(".isr_vector"), used))
const void *vectors[16] = {
    &_estack, Reset_Handler, Default_Handler, Default_Handler,
};
