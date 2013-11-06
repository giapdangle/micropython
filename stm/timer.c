#include <stdint.h>
#include <stdio.h>

#include "stm_misc.h"
#include "stm32f4xx_rcc.h"
#include "stm32f4xx_tim.h"

#include "nlr.h"
#include "misc.h"
#include "mpyconfig.h"
#include "parse.h"
#include "compile.h"
#include "runtime.h"

#include "timer.h"

// TIM6 is used as an internal interrup to schedule something at a specific rate
py_obj_t timer_py_callback;

py_obj_t timer_py_set_callback(py_obj_t f) {
    timer_py_callback = f;
    return py_const_none;
}

py_obj_t timer_py_set_period(py_obj_t period) {
    TIM6->ARR = py_obj_get_int(period) & 0xffff;
    //TIM6->PSC = prescaler & 0xffff;
    return py_const_none;
}

py_obj_t timer_py_get_value(void) {
    return py_obj_new_int(TIM6->CNT & 0xfffff);
}

void timer_init(void) {
    timer_py_callback = py_const_none;

    // TIM6 clock enable
    RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM6, ENABLE);

    // Compute the prescaler value so TIM6 runs at 10kHz
    uint16_t PrescalerValue = (uint16_t) ((SystemCoreClock / 2) / 10000) - 1;

    // Time base configuration
    TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
    TIM_TimeBaseStructure.TIM_Period = 10000; // timer cycles at 1Hz
    TIM_TimeBaseStructure.TIM_Prescaler = PrescalerValue;
    TIM_TimeBaseStructure.TIM_ClockDivision = 0; // unused for TIM6
    TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up; // unused for TIM6
    TIM_TimeBaseInit(TIM6, &TIM_TimeBaseStructure);

    // enable perhipheral preload register
    TIM_ARRPreloadConfig(TIM6, ENABLE);

    // enable interrupt when counter overflows
    TIM_ITConfig(TIM6, TIM_IT_Update, ENABLE);

    // set up interrupt
    NVIC_InitTypeDef NVIC_InitStructure;
    NVIC_InitStructure.NVIC_IRQChannel = TIM6_DAC_IRQn;
    NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0x0f; // lowest priority
    NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0x0f; // lowest priority
    NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
    NVIC_Init(&NVIC_InitStructure);

    // TIM6 enable counter
    TIM_Cmd(TIM6, ENABLE);

    // Python interface
    py_obj_t m = py_module_new();
    rt_store_attr(m, qstr_from_str_static("callback"), rt_make_function_1(timer_py_set_callback));
    rt_store_attr(m, qstr_from_str_static("period"), rt_make_function_1(timer_py_set_period));
    rt_store_attr(m, qstr_from_str_static("value"), rt_make_function_0(timer_py_get_value));
    rt_store_name(qstr_from_str_static("timer"), m);
}

void timer_interrupt(void) {
    if (timer_py_callback != py_const_none) {
        nlr_buf_t nlr;
        if (nlr_push(&nlr) == 0) {
            rt_call_function_0(timer_py_callback);
            nlr_pop();
        } else {
            // uncaught exception
            printf("exception in timer interrupt\n");
            py_obj_print((py_obj_t)nlr.ret_val);
            printf("\n");
        }
    }
}