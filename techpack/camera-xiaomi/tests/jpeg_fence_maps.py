#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Compile and exercise the production JPEG fence-map loop with host stubs.

This isolates mapping logic, not packet validation or hardware execution.
Run with python3; CC/CFLAGS can select a host compiler and sanitizers.
"""
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

source = (Path(__file__).resolve().parents[1] /
          "drivers/cam_jpeg/jpeg_hw/cam_jpeg_hw_mgr.c").read_text()
start = source.index("static int cam_jpeg_mgr_prepare_hw_update(")
match = re.search(r"\tfor \(i = 0, j = 0, k = 0;.*?\n\t}\n\n\n", source[start:], re.S)
if not match:
    raise RuntimeError("Cannot locate production JPEG fence-map loop")

prefix = r"""
#include <assert.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#define CAM_BUF_INPUT 1
#define CAM_DBG(...) ((void)0)
#define CAM_ERR(...) ((void)0)
struct entry { uint32_t resource_handle; int sync_id; };
struct io { uint32_t direction, resource_type; int fence; };
struct packet { unsigned int num_io_configs; };
struct args {
        unsigned int num_in_map_entries, num_out_map_entries;
        unsigned int max_in_map_entries, max_out_map_entries;
        struct entry *in_map_entries, *out_map_entries;
};
static int map(struct packet *packet, struct args *prepare_args,
               struct io *io_cfg_ptr)
{
        unsigned int i, j, k;
"""
suffix = r"""
        return 0;
}
static void check(unsigned int input_capacity, unsigned int output_capacity,
                  unsigned int ni, unsigned int no,
                  unsigned int reverse)
{
        struct entry in[22], out[22];
        struct io io[44];
        struct packet packet = {ni + no};
        struct args args = {0, 0, input_capacity, output_capacity, &in[1], &out[1]};
        unsigned int i, n = 0;
        int rc;

        memset(in, 0xa5, sizeof(in));
        memset(out, 0xa5, sizeof(out));
        if (reverse)
                for (i = 0; i < no; i++)
                        io[n++] = (struct io){2, 200 + i, 2000 + i};
        for (i = 0; i < ni; i++)
                io[n++] = (struct io){1, 100 + i, 1000 + i};
        if (!reverse)
                for (i = 0; i < no; i++)
                        io[n++] = (struct io){2, 200 + i, 2000 + i};
        rc = map(&packet, &args, io);
        assert(rc == ((ni > input_capacity || no > output_capacity) ? -EINVAL : 0));
        assert(args.num_in_map_entries <= input_capacity);
        assert(args.num_out_map_entries <= output_capacity);
        if (!rc) {
                assert(args.num_in_map_entries == ni);
                assert(args.num_out_map_entries == no);
        }
        for (i = 0; i < 22; i++) {
                struct entry ei, eo;
                memset(&ei, 0xa5, sizeof(ei));
                memset(&eo, 0xa5, sizeof(eo));
                if (i && i <= args.num_in_map_entries)
                        ei = (struct entry){100 + i - 1, 1000 + i - 1};
                if (i && i <= args.num_out_map_entries)
                        eo = (struct entry){200 + i - 1, 2000 + i - 1};
                assert(memcmp(&in[i], &ei, sizeof(ei)) == 0);
                assert(memcmp(&out[i], &eo, sizeof(eo)) == 0);
        }
}
int main(void)
{
        unsigned int capacity, ni, no, reverse, cases = 0;
        for (capacity = 0; capacity <= 20; capacity++)
                for (ni = 0; ni <= capacity + 1; ni++)
                        for (no = 0; no <= capacity + 1; no++)
                                for (reverse = 0; reverse < 2; reverse++, cases++)
                                        check(capacity, capacity, ni, no, reverse);
        for (reverse = 0; reverse < 2; reverse++) {
                check(0, 20, 0, 20, reverse);
                check(20, 0, 20, 0, reverse);
                check(0, 20, 1, 20, reverse);
                check(20, 0, 20, 1, reverse);
                cases += 4;
        }
        printf("PASS: %u JPEG fence-map cases; metadata and guards checked\n", cases);
        return 0;
}
"""
with tempfile.TemporaryDirectory(prefix="jpeg-fence-maps-") as temp:
    path = Path(temp) / "test.c"
    binary = Path(temp) / "test"
    path.write_text(prefix + match.group() + suffix)
    subprocess.run(shlex.split(os.environ.get("CC", "cc"))
                   + ["-std=gnu99", "-Wall", "-Wextra", "-Werror"]
                   + shlex.split(os.environ.get("CFLAGS", ""))
                   + [str(path), "-o", str(binary)], check=True)
    subprocess.run([str(binary)], check=True)
