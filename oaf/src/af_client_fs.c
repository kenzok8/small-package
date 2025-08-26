#include <linux/init.h>
#include <linux/fs.h>
#include <linux/netlink.h>
#include <linux/module.h>
#include <linux/skbuff.h>
#include <linux/netdevice.h>
#include <linux/netfilter.h>
#include <linux/version.h>
#include <net/sock.h>
#include <linux/ip.h>
#include <linux/udp.h>
#include <linux/tcp.h>
#include <linux/netfilter_bridge.h>
#include <linux/version.h>
#include <linux/time.h>
#include <linux/seq_file.h>
#include <linux/list.h>
#include <linux/etherdevice.h>
#include <linux/proc_fs.h>
#include <linux/sysctl.h>
#include "af_utils.h"

#include "cJSON.h"
#include "af_log.h"
#include "af_client.h"
extern char *ipv6_to_str(const struct in6_addr *addr, char *str);

extern struct list_head af_client_list_table[MAX_AF_CLIENT_HASH_SIZE];
struct af_client_iter_state
{
    unsigned int bucket;
    void *head;
};

static void *af_client_get_first(struct seq_file *seq)
{
    struct af_client_iter_state *st = seq->private;
    for (st->bucket = 0; st->bucket < MAX_AF_CLIENT_HASH_SIZE; st->bucket++)
    {
        if (!list_empty(&(af_client_list_table[st->bucket])))
        {
            st->head = &(af_client_list_table[st->bucket]);
            return af_client_list_table[st->bucket].next;
        }
    }
    return NULL;
}

static void *af_client_get_next(struct seq_file *seq,
                                void *head)
{
    struct af_client_iter_state *st = seq->private;
    struct hlist_node *node = (struct hlist_node *)head;

    node = node->next;
    if (node != st->head)
    {
        return node;
    }
    else
    {
        st->bucket++;
        for (; st->bucket < MAX_AF_CLIENT_HASH_SIZE; st->bucket++)
        {
            if (!list_empty(&(af_client_list_table[st->bucket])))
            {
                st->head = &(af_client_list_table[st->bucket]);
                return af_client_list_table[st->bucket].next;
            }
        }
        return NULL;
    }
}

static void *af_client_get_idx(struct seq_file *seq, loff_t pos)
{
    void *head = af_client_get_first(seq);

    if (head)
        while (pos && (head = af_client_get_next(seq, head)))
            pos--;

    return pos ? NULL : head;
}

static void *af_client_seq_start(struct seq_file *s, loff_t *pos)
{
    AF_CLIENT_LOCK_R();
    if (*pos == 0)
    {
        return SEQ_START_TOKEN;
    }

    return af_client_get_idx(s, *pos - 1);
}

static void *af_client_seq_next(struct seq_file *s, void *v, loff_t *pos)
{
    (*pos)++;
    if (v == SEQ_START_TOKEN)
        return af_client_get_idx(s, 0);

    return af_client_get_next(s, v);
}

static void af_client_seq_stop(struct seq_file *s, void *v)
{
    AF_CLIENT_UNLOCK_R();
}

static int af_client_seq_show(struct seq_file *s, void *v)
{
    unsigned char mac_str[32] = {0};
    unsigned char ip_str[32] = {0};
	unsigned char ipv6_str[128];

    static int index = 0;
    af_client_info_t *node = (af_client_info_t *)v;
    if (v == SEQ_START_TOKEN)
    {
        index = 0;
        seq_printf(s, "%-4s %-20s %-20s %-32s  %-16s %-16s\n", "Id", "Mac", "IP", "IPv6", "UpRate", "DownRate");
        return 0;
    }
    index++;
    sprintf(mac_str, MAC_FMT, MAC_ARRAY(node->mac));
    sprintf(ip_str, "%pI4", &node->ip);
	ipv6_to_str(&node->ipv6, ipv6_str);

    seq_printf(s, "%-4d %-20s %-20s %-32s %-16d %-16d\n", index, mac_str, ip_str, ipv6_str, node->rate.up_rate, node->rate.down_rate);
    return 0;
}

static const struct seq_operations nf_client_seq_ops = {
    .start = af_client_seq_start,
    .next = af_client_seq_next,
    .stop = af_client_seq_stop,
    .show = af_client_seq_show};

static int af_client_open(struct inode *inode, struct file *file)
{
    struct seq_file *seq;
    struct af_client_iter_state *iter;
    int err;

    iter = kzalloc(sizeof(*iter), GFP_KERNEL);
    if (!iter)
        return -ENOMEM;

    err = seq_open(file, &nf_client_seq_ops);
    if (err)
    {
        kfree(iter);
        return err;
    }

    seq = file->private_data;
    seq->private = iter;
    return 0;
}

#if LINUX_VERSION_CODE <= KERNEL_VERSION(5, 5, 0)
static const struct file_operations af_client_fops = {
    .owner = THIS_MODULE,
    .open = af_client_open,
    .read = seq_read,
    .llseek = seq_lseek,
    .release = seq_release_private,
};
#else
static const struct proc_ops af_client_fops = {
    .proc_flags = PROC_ENTRY_PERMANENT,
    .proc_read = seq_read,
    .proc_open = af_client_open,
    .proc_lseek = seq_lseek,
    .proc_release = seq_release_private,
};
#endif

#define AF_CLIENT_PROC_STR "af_client"




static int af_visiting_seq_show(struct seq_file *s, void *v)
{
    unsigned char mac_str[32] = {0};
    unsigned char ip_str[32] = {0};
    static int index = 0;
	int i;
    af_client_info_t *node = (af_client_info_t *)v;
    if (v == SEQ_START_TOKEN)
    {
        index = 0;
        seq_printf(s, "%-20s %-12s %-32s\n", "Mac", "Appid", "Url");
        return 0;
    }
	index++;
	
	sprintf(mac_str, MAC_FMT, MAC_ARRAY(node->mac));
	int visiting_app = 0;
	char visiting_url[64] = {0};
	if (af_get_timestamp_sec()  - node->visiting.app_time < 120){
		visiting_app = node->visiting.visiting_app;
	}
	if ( af_get_timestamp_sec()  - node->visiting.url_time < 120 ){
		strncpy(visiting_url, node->visiting.visiting_url, sizeof(visiting_url));
	}
	else{
		strcpy(visiting_url, "none");
	}
	seq_printf(s, "%-20s %-12d %-32s\n", mac_str, visiting_app, visiting_url);
	
    return 0;
}

static const struct seq_operations nf_visiting_seq_ops = {
    .start = af_client_seq_start,
    .next = af_client_seq_next,
    .stop = af_client_seq_stop,
    .show = af_visiting_seq_show
};


static int af_visiting_open(struct inode *inode, struct file *file)
{
    struct seq_file *seq;
    struct af_client_iter_state *iter;
    int err;

    iter = kzalloc(sizeof(*iter), GFP_KERNEL);
    if (!iter)
        return -ENOMEM;

    err = seq_open(file, &nf_visiting_seq_ops);
    if (err)
    {
        kfree(iter);
        return err;
    }

    seq = file->private_data;
    seq->private = iter;
    return 0;
}




#if LINUX_VERSION_CODE <= KERNEL_VERSION(5, 5, 0)
static const struct file_operations af_visiting_fops = {
    .owner = THIS_MODULE,
    .open = af_visiting_open,
    .read = seq_read,
    .llseek = seq_lseek,
    .release = seq_release_private,
};
#else
static const struct proc_ops af_visiting_fops = {
    .proc_flags = PROC_ENTRY_PERMANENT,
    .proc_read = seq_read,
    .proc_open = af_visiting_open,
    .proc_lseek = seq_lseek,
    .proc_release = seq_release_private,
};
#endif
#define AF_VISIT_INFO "af_visit"

int init_af_client_procfs(void)
{
    struct proc_dir_entry *pde;
    struct net *net = &init_net;
    pde = proc_create(AF_CLIENT_PROC_STR, 0440, net->proc_net, &af_client_fops);

    if (!pde)
    {
        AF_ERROR("nf_client proc file created error\n");
        return -1;
    }
    pde = proc_create(AF_VISIT_INFO, 0440, net->proc_net, &af_visiting_fops);

    if (!pde)
    {
        AF_ERROR("client visiting proc file created error\n");
        return -1;
    }
    return 0;
}

void finit_af_client_procfs(void)
{
    struct net *net = &init_net;
    remove_proc_entry(AF_CLIENT_PROC_STR, net->proc_net);
    remove_proc_entry(AF_VISIT_INFO, net->proc_net);
}
