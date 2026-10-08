# SPDX-License-Identifier: GPL-2.0
# Shared selection for compilation and packing; never scan stale outputs.
xiaomi-sm8250-dtbo-y :=
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_ALIOTH) += alioth-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_APOLLO) += apollo-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_CAS) += cas-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_CMI) += cmi-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_DAGU) += dagu-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_ENUMA) += enuma-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_ELISH) += elish-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_LMI) += lmi-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_MUNCH) += munch-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_PSYCHE) += psyche-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_THYME) += thyme-sm8250-overlay.dtbo
xiaomi-sm8250-dtbo-$(CONFIG_MACH_XIAOMI_UMI) += umi-sm8250-overlay.dtbo
