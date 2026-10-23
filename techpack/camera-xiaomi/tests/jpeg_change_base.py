#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Host regression test: python3 techpack/camera-xiaomi/tests/jpeg_change_base.py.

Compile the production JPEG insertion function and CDM change-base writer with
minimal host stubs. No kernel build or camera hardware is needed. CC and CFLAGS
may select a host compiler and sanitizers. Temporary files are removed on exit.
"""

import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile


def function(source, name):
    match = re.search(r"^(?:static )?(?:int|uint32_t \*?)\s*" + name
                      + r"\([^;]*?\)\n\{.*?^\}", source, re.M | re.S)
    if not match:
        raise RuntimeError("Cannot extract " + name)
    return match.group()


camera = Path(__file__).resolve().parents[1]
jpeg = (camera / "drivers/cam_jpeg/jpeg_hw/cam_jpeg_hw_mgr.c").read_text()
cdm = (camera / "drivers/cam_cdm/cam_cdm_util.c").read_text()
cdm_header = (camera / "drivers/cam_cdm/cam_cdm_util.h").read_text()
enum = re.search(r"enum\s+\w+\s*\{[^}]*CAM_CDM_CMD_CHANGE_BASE[^}]*\};",
                 cdm_header, re.S).group()
sizes = re.search(r"static unsigned int CDMCmdHeaderSizes\[.*?\n\};",
                  cdm, re.S).group()
header = re.search(r"struct cdm_changebase_cmd \{.*?\}.*?;", cdm, re.S).group()

stubs = r'''
#include <assert.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define CAM_CDM_SW_CMD_COUNT 2
#define CAM_JPEG_CHBASE 0
#define CAM_ERR(...) ((void)0)
#define CAM_DBG(...) ((void)0)
struct cam_hw_update_entry { int handle; uint32_t offset; };
struct cam_hw_config_args { struct cam_hw_update_entry *hw_update_entries; };
struct cam_cdm_bl_cmd {
        struct { int mem_handle; } bl_addr;
        uint32_t offset, len;
};
struct cam_cdm_bl_request {
        uint32_t cmd_arrary_count;
        struct cam_cdm_bl_cmd cmd[1];
};
struct cam_jpeg_hw_ctx_data {
        struct { uint32_t dev_type; } jpeg_dev_acquire_info;
        struct cam_cdm_bl_request *cdm_cmd;
};
struct cam_cdm_utils_ops {
        uint32_t (*cdm_required_size_changebase)(void);
        uint32_t *(*cdm_write_changebase)(uint32_t *, uint32_t);
};
struct cam_soc_reg_map { uint32_t mem_cam_base; };
struct cam_jpeg_hw_mgr {
        struct cam_soc_reg_map *cdm_reg_map[1][1];
        struct { struct cam_cdm_utils_ops *cdm_ops; } cdm_info[1][1];
};
static uint32_t buffer[20];
static size_t mapped_len;
static int map_rc;
static int cam_mem_get_cpu_buf(int handle, uintptr_t *addr, size_t *len)
{
        assert(handle == 7);
        *addr = (uintptr_t)&buffer[1];
        *len = mapped_len;
        return map_rc;
}
'''

tests = r'''
static void check(size_t len, uint32_t offset, int error)
{
        struct cam_cdm_utils_ops ops = {
                cdm_required_size_changebase, cdm_write_changebase
        };
        struct cam_soc_reg_map reg = { .mem_cam_base = 0x1234 };
        struct cam_jpeg_hw_mgr mgr = {
                .cdm_reg_map = {{&reg}}, .cdm_info = {{{&ops}}}
        };
        struct cam_cdm_bl_request cmd = {0};
        struct cam_jpeg_hw_ctx_data ctx = { .cdm_cmd = &cmd };
        struct cam_hw_update_entry entry = { .handle = 7, .offset = offset };
        struct cam_hw_config_args args = { .hw_update_entries = &entry };
        uint32_t expected[20];
        int valid = !error && offset % 4 == 0 && (uint64_t)offset + 12 <= len;
        int rc;

        memset(buffer, 0xa5, sizeof(buffer));
        memcpy(expected, buffer, sizeof(buffer));
        mapped_len = len;
        map_rc = error;
        rc = cam_jpeg_insert_cdm_change_base(&args, &ctx, &mgr);
        if (rc != (error ? error : valid ? 0 : -EINVAL)) {
                fprintf(stderr, "len=%zu offset=%u rc=%d\n", len, offset, rc);
                assert(0);
        }
        if (valid) {
                expected[1 + offset / 4] = 0x08001234;
                expected[2 + offset / 4] = 0;
                expected[3 + offset / 4] = 0;
                assert(cmd.cmd[0].bl_addr.mem_handle == 7);
                assert(cmd.cmd[0].offset == offset);
                assert(cmd.cmd[0].len == 4);
        }
        assert(cmd.cmd_arrary_count == (unsigned int)valid);
        assert(memcmp(buffer, expected, sizeof(buffer)) == 0);
}
int main(void)
{
        size_t len;
        uint32_t offset;

        assert(cdm_required_size_changebase() == 1);
        assert(sizeof(struct cdm_changebase_cmd) == 4);
        /* Includes short buffers, exact fits, last valid and unaligned offsets. */
        for (len = 0; len <= 64; len++)
                for (offset = 0; offset <= 68; offset++)
                        check(len, offset, 0);
        for (offset = UINT32_MAX - 15; offset != UINT32_MAX; offset++)
                check(64, offset, 0);
        check(64, UINT32_MAX, 0);
        check(UINT32_MAX, UINT32_MAX - 11, 0);
        check(12, 0, -EIO);
        puts("PASS: 4503 JPEG change-base cases; writes and sentinels checked");
        return 0;
}
'''

parts = [stubs, enum, sizes, header]
for name in ("cdm_get_cmd_header_size", "cdm_required_size_changebase",
             "cdm_write_changebase"):
    parts.append(function(cdm, name))
parts.extend([function(jpeg, "cam_jpeg_insert_cdm_change_base"), tests])
with tempfile.TemporaryDirectory(prefix="jpeg-change-base-") as temp:
    source = Path(temp) / "test.c"
    binary = Path(temp) / "test"
    source.write_text("\n".join(parts))
    subprocess.run(shlex.split(os.environ.get("CC", "cc"))
                   + ["-std=gnu89", "-Wall", "-Wextra", "-Werror"]
                   + shlex.split(os.environ.get("CFLAGS", ""))
                   + [str(source), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
