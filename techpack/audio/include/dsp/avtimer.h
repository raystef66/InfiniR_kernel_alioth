/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef _DSP_AVTIMER_H_
#define _DSP_AVTIMER_H_

#include <linux/types.h>

int avcs_core_open(void);
int avcs_core_disable_power_collapse(int enable);
int avcs_core_query_timer(uint64_t *avtimer_tick);

#endif
