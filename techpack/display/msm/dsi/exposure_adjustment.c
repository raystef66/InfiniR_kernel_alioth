/*
 * An exposure adjustment driver based on Qcom DSPP for OLED devices
 *
 * Copyright (C) 2012-2014, The Linux Foundation. All rights reserved.
 * Copyright (C) Sony Mobile Communications Inc. All rights reserved.
 * Copyright (C) 2014-2018, AngeloGioacchino Del Regno <kholk11@gmail.com>
 * Copyright (C) 2018, Devries <therkduan@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#include <linux/device.h>
#include <linux/platform_device.h>
#include <linux/notifier.h>

#include "dsi_display.h"
#include "dsi_panel.h"
#include "../sde/sde_crtc.h"
#include "../sde/sde_plane.h"
#include "exposure_adjustment.h"

static bool pcc_backlight_enable = false;
static u32 last_level;
static bool pcc_attenuated;

static int ea_panel_send_pcc(u32 bl_lvl)
{
	int rc;
	struct drm_crtc *crtc = NULL;
	struct drm_msm_pcc pcc_blk = {0};
	struct drm_property *prop;
	struct drm_property_blob *blob;
	struct dsi_display *display = NULL;
	struct msm_drm_private *priv;
	u32 ea_coeff;

	display = get_main_display();
	if (!display || !display->drm_conn || !display->drm_conn->state)
		return -ENODEV;
	crtc = display->drm_conn->state->crtc;
	if (!crtc) {
		pr_err("ERROR: Cannot find display panel with CRTC\n");
		return -ENODEV;
	}

	priv = crtc->dev->dev_private;
	prop = priv->cp_property[1]; // SDE_CP_CRTC_DSPP_PCC

	if (prop == NULL) {
		pr_err("FAIL! PCC is not supported!!?!?!\n");
		return -EINVAL;
	}

	pr_debug("%s: Backlight = %d\n", __func__, bl_lvl);

	if (bl_lvl < ELVSS_OFF_THRESHOLD) {
		/* Divide after multiplying to keep the threshold continuous. */
		ea_coeff = EXPOSURE_ADJUSTMENT_MIN +
			DIV_ROUND_CLOSEST(bl_lvl * (EXPOSURE_ADJUSTMENT_MAX -
			EXPOSURE_ADJUSTMENT_MIN), ELVSS_OFF_THRESHOLD);
	} else {
		ea_coeff = EXPOSURE_ADJUSTMENT_MAX;
	}

	pr_debug("%s: coeff = %d\n", __func__, ea_coeff);

	pcc_blk.r.r = ea_coeff;
	pcc_blk.g.g = ea_coeff;
	pcc_blk.b.b = ea_coeff;

	blob = drm_property_create_blob(crtc->dev, sizeof(pcc_blk), &pcc_blk);
	if (IS_ERR_OR_NULL(blob)) {
		pr_err("Failed to create blob. Bailing out.\n");
		return -EINVAL;
	}
	pr_debug("DSPP Blob ID %d has length %zu\n",
			prop->base.id, blob->length);

	rc = sde_cp_crtc_set_property(crtc, prop, blob->base.id);
	if (rc) {
		pr_err("DSPP: Cannot set PCC: %d.\n", rc);
	}

	/* The color-processing node retains its own reference on success. */
	drm_property_blob_put(blob);
	if (!rc)
		pcc_attenuated = bl_lvl < ELVSS_OFF_THRESHOLD;
	return rc;
}

bool ea_panel_is_enabled(void)
{
	return pcc_backlight_enable;
}

void ea_panel_mode_ctrl(struct dsi_panel *panel, bool enable)
{
	if (!panel || pcc_backlight_enable == enable)
		return;

	pcc_backlight_enable = enable;
	/* last_level includes zero, so toggling cannot relight a blanked panel. */
	dsi_panel_set_backlight(panel, last_level);
}

u32 ea_panel_calc_backlight(u32 bl_lvl)
{
	last_level = bl_lvl;

	if (pcc_backlight_enable && bl_lvl && bl_lvl < ELVSS_OFF_THRESHOLD) {
		/* Never raise the panel brightness if attenuation could not be set. */
		if (ea_panel_send_pcc(bl_lvl)) {
			pr_err("Failed to apply exposure attenuation\n");
			return bl_lvl;
		}
		return ELVSS_OFF_THRESHOLD;
	}

	/* Restore unity when disabling, blanking, or crossing the threshold. */
	if (pcc_attenuated && ea_panel_send_pcc(ELVSS_OFF_THRESHOLD))
		pr_err("Failed to restore exposure attenuation\n");

	return bl_lvl;
}
