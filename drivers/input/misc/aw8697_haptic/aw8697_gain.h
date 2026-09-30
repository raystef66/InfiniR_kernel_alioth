/* SPDX-License-Identifier: GPL-2.0 */
#ifndef _AW8697_GAIN_H
#define _AW8697_GAIN_H

/* Optional fourth FF_CUSTOM short. Legacy magnitudes are not decoded here. */
static inline int aw8697_decode_ram_gain(unsigned short word)
{
	if ((word & 0xff00) != 0x4700 || (word & 0xff) > 128)
		return -1;
	return word & 0xff;
}

#endif
