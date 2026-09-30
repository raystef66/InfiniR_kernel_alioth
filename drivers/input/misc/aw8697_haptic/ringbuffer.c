/*
* reader shoule NEVER block !!!, if no data is avaliable, just return zero
* writer will block if there is no space, and wakend up by reader or force exit
* there is 1 writer and 1 reader for each buffer, so no lock is used
* writer shoule read rd_index to check if free size is enought, and  then fill this buffer  update wr_index
* reader shoule read wr_index to check if avaliable size is enought, and then read the buffer and update rd_index
* empty: wr_index==rd_index
* full: (wr_index +1) % BUFFER_SIZE == rd_index
* total avaliable size is BUFFER_SIZE -1
*/
#include <linux/errno.h>
#include "ringbuffer.h"

#define MIN(x, y) ((x) < (y) ? (x) : (y))

#define BUFFER_SIZE (1024 * 8 + 1)

struct rb {
	char *gbuffer;
	atomic_t wr_index;
	atomic_t rd_index;
	atomic_t eof;
	atomic_t exit;
	wait_queue_head_t wait_q;
};

struct rb *grb;

int32_t get_free_size(int32_t tail, int32_t head)
{
	if (head == tail)
		return BUFFER_SIZE - 1;
	else if (head < tail)
		return (head + BUFFER_SIZE - 1 - tail);
	else
		return(head - tail - 1);
}

int write_rb(const char *data, int32_t size)
{
	int32_t tail, part;
	int ret;

	if (size < 0 || size >= BUFFER_SIZE)
		return -EINVAL;
	/* Wait on actual space, not a notification bit that can lose wakeups. */
	ret = wait_event_interruptible(grb->wait_q,
		get_rb_free_size() >= size || atomic_read(&grb->exit));
	if (ret)
		return ret;
	if (atomic_read(&grb->exit))
		return -EPERM;

	tail = atomic_read(&grb->wr_index);
	part = MIN(size, BUFFER_SIZE - tail);
	memcpy(grb->gbuffer + tail, data, part);
	memcpy(grb->gbuffer, data + part, size - part);
	tail = (tail + size) % BUFFER_SIZE;
	/* Publish samples before making them visible to the IRQ consumer. */
	atomic_set_release(&grb->wr_index, tail);
	return size;
}

int read_rb(char *data, int32_t size)
{
	int32_t tail;
	int32_t head;
	int32_t filled_size;
	void *buf;
	int32_t read_bytes, part;
	bool eof;

	if (size < 0 || size >= BUFFER_SIZE)
		return -EINVAL;
	buf = data;

	pr_debug("read_rb data:%p, size %d", data, (int)size);

	/* Snapshot EOF before the write index. Observing EOF guarantees that
	 * the final payload was published; never reread EOF after an old tail.
	 */
	eof = atomic_read_acquire(&grb->eof);
	tail = atomic_read_acquire(&grb->wr_index);
	head = atomic_read(&grb->rd_index);
	filled_size = BUFFER_SIZE - 1 - get_free_size(tail, head); // aready write size.

	pr_debug("write index %d, read index %d, filled size %d", tail, head, filled_size);
	read_bytes = MIN (size, filled_size);
	if (size > filled_size)
		pr_debug("buffer underrun , req size %d, filled size %d", size, filled_size);
	part = BUFFER_SIZE - head;
	if (part < read_bytes) {
		memcpy(buf, grb->gbuffer + head, part);
		memcpy((char *)buf + part, grb->gbuffer, read_bytes - part);
		head = read_bytes - part;
	} else {
		memcpy(buf, grb->gbuffer + head, read_bytes);
		head += read_bytes;
		if (head >= BUFFER_SIZE)
			head = head % BUFFER_SIZE;
	}
	atomic_set_release(&grb->rd_index, head);

	//add wakeup here
	wake_up_interruptible(&grb->wait_q);
	pr_debug("read_rb: read %d, write index %d, read index %d", read_bytes, tail, head);

	/* Never replay stale bytes when a streaming producer falls behind. */
	if (read_bytes < size && !eof)
		memset((char *)data + read_bytes, 0, size - read_bytes);
	return eof ? read_bytes : size;
}

int get_rb_free_size(void)
{
	int32_t tail = atomic_read_acquire(&grb->wr_index);
	int32_t head = atomic_read_acquire(&grb->rd_index);
	return get_free_size(tail, head);
}

int get_rb_avalible_size(void)
{
	return BUFFER_SIZE - 1 -  get_rb_free_size();
}

int get_rb_max_size(void)
{
	return BUFFER_SIZE - 1;
}

void rb_force_exit(void)
{
	pr_debug("rb force exit");
	atomic_set(&grb->exit, 1);
	wake_up_interruptible(&grb->wait_q);
}

void rb_end(void)
{
	atomic_set_release(&grb->eof, 1);
}

int rb_shoule_exit(void)
{
	return atomic_read_acquire(&grb->eof) || atomic_read(&grb->exit);
}

int create_rb(void)
{
	grb = kzalloc(sizeof(struct rb), GFP_KERNEL);
	if (grb == NULL) {
		goto err;;
	}
	grb->gbuffer = kzalloc(BUFFER_SIZE, GFP_KERNEL);
	if (grb->gbuffer == NULL) {
		goto err;
	}

	rb_init();

	init_waitqueue_head(&grb->wait_q);

	return 0;
err:
	if (grb) {
		kfree(grb->gbuffer);
		kfree(grb);
		grb = NULL;
	}
	return  -EPERM;
}

void rb_init(void)
{
	pr_debug("rb init");
	atomic_set(&grb->wr_index, 0);
	atomic_set(&grb->rd_index, 0);
	atomic_set(&grb->exit, 0);
	atomic_set(&grb->eof, 0);
}

int release_rb(void)
{
	if (grb  != NULL) {
		if (grb->gbuffer) {
			 kfree(grb->gbuffer);
			 grb->gbuffer = NULL;
		}
		kfree(grb);
		grb  = NULL;
	}
	return 0;
}
