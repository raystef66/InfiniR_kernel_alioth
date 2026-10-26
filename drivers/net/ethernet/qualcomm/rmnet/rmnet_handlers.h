/* SPDX-License-Identifier: GPL-2.0 */
/* Copyright (c) 2013, 2016-2019 The Linux Foundation. All rights reserved.
 *
 * RMNET Data ingress/egress handler
 *
 */

#ifndef _RMNET_HANDLERS_H_
#define _RMNET_HANDLERS_H_

#include "rmnet_config.h"
#include <linux/rcupdate.h>

enum rmnet_packet_context {
	RMNET_NET_RX_CTX,
	RMNET_WQ_CTX,
};

void rmnet_egress_handler(struct sk_buff *skb);
void rmnet_deliver_skb(struct sk_buff *skb, struct rmnet_port *port);
void rmnet_deliver_skb_wq(struct sk_buff *skb, struct rmnet_port *port,
			  enum rmnet_packet_context ctx);
void rmnet_set_skb_proto(struct sk_buff *skb);
bool rmnet_slow_start_on(u32 hash_key);
rx_handler_result_t _rmnet_map_ingress_handler(struct sk_buff *skb,
					       struct rmnet_port *port);
rx_handler_result_t rmnet_rx_handler(struct sk_buff **pskb);

struct sk_buff;
struct rmnet_port;
struct rmnet_frag_descriptor;

/* Apply the RCU address space to the pointed-to function, not its pointer. */
typedef int rmnet_perf_deag_fn(struct sk_buff *skb, struct rmnet_port *port);
typedef void rmnet_perf_desc_fn(struct rmnet_frag_descriptor *frag_desc,
			       struct rmnet_port *port);
typedef void rmnet_perf_chain_fn(void);

extern rmnet_perf_deag_fn __rcu *rmnet_perf_deag_entry;
extern rmnet_perf_desc_fn __rcu *rmnet_perf_desc_entry;
extern rmnet_perf_chain_fn __rcu *rmnet_perf_chain_end;


#endif /* _RMNET_HANDLERS_H_ */
