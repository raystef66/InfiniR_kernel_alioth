// SPDX-License-Identifier: GPL-2.0-only
#ifndef _NET_BPF_TEST_RUN_H
#define _NET_BPF_TEST_RUN_H

#include <linux/types.h>

/* Global targets retained for BTF-based calling-convention tests. */
struct bpf_fentry_test_t;

int bpf_fentry_test1(int a);
int bpf_fentry_test2(int a, u64 b);
int bpf_fentry_test3(char a, int b, u64 c);
int bpf_fentry_test4(void *a, char b, int c, u64 d);
int bpf_fentry_test5(u64 a, void *b, short c, int d, u64 e);
int bpf_fentry_test6(u64 a, void *b, short c, int d, void *e, u64 f);
int bpf_fentry_test7(struct bpf_fentry_test_t *arg);
int bpf_fentry_test8(struct bpf_fentry_test_t *arg);
int bpf_modify_return_test(int a, int *b);

#endif /* _NET_BPF_TEST_RUN_H */
