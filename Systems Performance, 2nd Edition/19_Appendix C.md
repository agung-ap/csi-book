## Appendix C

bpftrace One-Liners

This appendix contains some handy bpftrace one-liners. Apart from being useful in themselves, they can help you learn bpftrace, one line at a time. Most of these were included in previous chapters. Many may not work right away: They may depend on the presence of certain tracepoints or functions, or on a specific kernel version or configuration.

See [Chapter 15](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/ch15.xhtml#ch15), [Section 15.2](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/ch15.xhtml#ch15lev2), for an introduction to bpftrace.

### CPUs

Trace new processes with arguments:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg803-1a)

```
bpftrace -e 'tracepoint:syscalls:sys_enter_execve { join(args->argv); }'
```

Count syscalls by process:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg803-2a)

```
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[pid, comm] = count(); }'
```

Count syscalls by syscall probe name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg803-3a)

```
bpftrace -e 'tracepoint:syscalls:sys_enter_* { @[probe] = count(); }'
```

Sample running process names at 99 Hertz:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg803-4a)

```
bpftrace -e 'profile:hz:99 { @[comm] = count(); }'
```

Sample user and kernel stacks at 49 Hertz, system wide, with the process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg803-5a)

```
bpftrace -e 'profile:hz:49 { @[kstack, ustack, comm] = count(); }'
```

Sample user-level stacks at 49 Hertz, for PID 189:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg803-6a)

```
bpftrace -e 'profile:hz:49 /pid == 189/ { @[ustack] = count(); }'
```

Sample user-level stacks 5 frames deep at 49 Hertz, for PID 189:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg803-7a)

```
bpftrace -e 'profile:hz:49 /pid == 189/ { @[ustack(5)] = count(); }'
```

Sample user-level stacks at 49 Hertz, for processes named “mysqld”:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-1a)

```
bpftrace -e 'profile:hz:49 /comm == "mysqld"/ { @[ustack] = count(); }'
```

Count kernel CPU scheduler tracepoints:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-2a)

```
bpftrace -e 'tracepont:sched:* { @[probe] = count(); }'
```

Count off-CPU kernel stacks for context switch events:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-3a)

```
bpftrace -e 'tracepont:sched:sched_switch { @[kstack] = count(); }'
```

Count kernel function calls beginning with “vfs_”:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-4a)

```
bpftrace -e 'kprobe:vfs_* { @[func] = count(); }'
```

Trace new threads via pthread_create():

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-5a)

```
bpftrace -e 'u:/lib/x86_64-linux-gnu/libpthread-2.27.so:pthread_create {
    printf("%s by %s (%d)\n", probe, comm, pid); }'
```

### Memory

Sum libc malloc() request bytes by user stack and process (high overhead):

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-6a)

```
bpftrace -e 'u:/lib/x86_64-linux-gnu/libc.so.6:malloc {
    @[ustack, comm] = sum(arg0); }'
```

Sum libc malloc() request bytes by user stack for PID 181 (high overhead):

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-7a)

```
bpftrace -e 'u:/lib/x86_64-linux-gnu/libc.so.6:malloc /pid == 181/ {
    @[ustack] = sum(arg0); }'
```

Show libc malloc() request bytes by user stack for PID 181 as a power-of-2 histogram (high overhead):

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-8a)

```
bpftrace -e 'u:/lib/x86_64-linux-gnu/libc.so.6:malloc /pid == 181/ {
    @[ustack] = hist(arg0); }'
```

Sum kernel kmem cache allocation bytes by kernel stack trace:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-9a)

```
bpftrace -e 't:kmem:kmem_cache_alloc { @bytes[kstack] = sum(args->bytes_alloc); }'
```

Count process heap expansion (brk(2)) by code path:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-10a)

```
bpftrace -e 'tracepoint:syscalls:sys_enter_brk { @[ustack, comm] = count(); }'
```

Count page faults by process:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg804-11a)

```
bpftrace -e 'software:page-fault:1 { @[comm, pid] = count(); }'
```

Count user page faults by user-level stack trace:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-1a)

```
bpftrace -e 't:exceptions:page_fault_user { @[ustack, comm] = count(); }'
```

Count vmscan operations by tracepoint:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-2a)

```
bpftrace -e 'tracepoint:vmscan:* { @[probe]++; }'
```

Count swapins by process:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-3a)

```
bpftrace -e 'kprobe:swap_readpage { @[comm, pid] = count(); }'
```

Count page migrations:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-4a)

```
bpftrace -e 'tracepoint:migrate:mm_migrate_pages { @ = count(); }'
```

Trace compaction events:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-5a)

```
bpftrace -e 't:compaction:mm_compaction_begin { time(); }'
```

List USDT probes in libc:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-6a)

```
bpftrace -l 'usdt:/lib/x86_64-linux-gnu/libc.so.6:*'
```

List kernel kmem tracepoints:

```
bpftrace -l 't:kmem:*'
```

List all memory subsystem (mm) tracepoints:

```
bpftrace -l 't:*:mm_*'
```

### File Systems

Trace files opened via openat(2) with process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-7a)

```
bpftrace -e 't:syscalls:sys_enter_openat { printf("%s %s\n", comm,
    str(args->filename)); }'
```

Count read syscalls by syscall type:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-8a)

```
bpftrace -e 'tracepoint:syscalls:sys_enter_*read* { @[probe] = count(); }'
```

Count write syscalls by syscall type:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-9a)

```
bpftrace -e 'tracepoint:syscalls:sys_enter_*write* { @[probe] = count(); }'
```

Show the distribution of read() syscall request sizes:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg805-10a)

```
bpftrace -e 'tracepoint:syscalls:sys_enter_read { @ = hist(args->count); }'
```

Show the distribution of read() syscall read bytes (and errors):

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-1a)

```
bpftrace -e 'tracepoint:syscalls:sys_exit_read { @ = hist(args->ret); }'
```

Count read() syscall errors by error code:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-2a)

```
bpftrace -e 't:syscalls:sys_exit_read /args->ret < 0/ { @[- args->ret] = count(); }'
```

Count VFS calls:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-3a)

```
bpftrace -e 'kprobe:vfs_* { @[probe] = count(); }'
```

Count VFS calls for PID 181:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-4a)

```
bpftrace -e 'kprobe:vfs_* /pid == 181/ { @[probe] = count(); }'
```

Count ext4 tracepoints:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-5a)

```
bpftrace -e 'tracepoint:ext4:* { @[probe] = count(); }'
```

Count xfs tracepoints:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-6a)

```
bpftrace -e 'tracepoint:xfs:* { @[probe] = count(); }'
```

Count ext4 file reads by process name and user-level stack:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-7a)

```
bpftrace -e 'kprobe:ext4_file_read_iter { @[ustack, comm] = count(); }'
```

Trace ZFS spa_sync() times:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-8a)

```
bpftrace -e 'kprobe:spa_sync { time("%H:%M:%S ZFS spa_sync()\n"); }'
```

Count dcache references by process name and PID:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-9a)

```
bpftrace -e 'kprobe:lookup_fast { @[comm, pid] = count(); }'
```

### Disks

Count block I/O tracepoints events:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-10a)

```
bpftrace -e 'tracepoint:block:* { @[probe] = count(); }'
```

Summarize block I/O size as a histogram:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-11a)

```
bpftrace -e 't:block:block_rq_issue { @bytes = hist(args->bytes); }'
```

Count block I/O request user stack traces:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-12a)

```
bpftrace -e 't:block:block_rq_issue { @[ustack] = count(); }'
```

Count block I/O type flags:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg806-13a)

```
bpftrace -e 't:block:block_rq_issue { @[args->rwbs] = count(); }'
```

Trace block I/O errors with device and I/O type:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-1a)

```
bpftrace -e 't:block:block_rq_complete /args->error/ {
    printf("dev %d type %s error %d\n", args->dev, args->rwbs, args->error); }'
```

Count SCSI opcodes:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-2a)

```
bpftrace -e 't:scsi:scsi_dispatch_cmd_start { @opcode[args->opcode] =
    count(); }'
```

Count SCSI result codes:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-3a)

```
bpftrace -e 't:scsi:scsi_dispatch_cmd_done { @result[args->result] = count(); }'
```

Count SCSI driver function calls:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-4a)

```
bpftrace -e 'kprobe:scsi* { @[func] = count(); }'
```

### Networking

Count socket accept(2)s by PID and process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-5a)

```
bpftrace -e 't:syscalls:sys_enter_accept* { @[pid, comm] = count(); }'
```

Count socket connect(2)s by PID and process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-6a)

```
bpftrace -e 't:syscalls:sys_enter_connect { @[pid, comm] = count(); }'
```

Count socket connect(2)s by user stack trace:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-7a)

```
bpftrace -e 't:syscalls:sys_enter_connect { @[ustack, comm] = count(); }'
```

Count socket send/receives by direction, on-CPU PID, and process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-8a)

```
bpftrace -e 'k:sock_sendmsg,k:sock_recvmsg { @[func, pid, comm] = count(); }'
```

Count socket send/receive bytes by on-CPU PID and process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-9a)

```
bpftrace -e 'kr:sock_sendmsg,kr:sock_recvmsg /(int32)retval > 0/ { @[pid, comm] =
    sum((int32)retval); }'
```

Count TCP connects by on-CPU PID and process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-10a)

```
bpftrace -e 'k:tcp_v*_connect { @[pid, comm] = count(); }'
```

Count TCP accepts by on-CPU PID and process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg807-11a)

```
bpftrace -e 'k:inet_csk_accept { @[pid, comm] = count(); }'
```

Count TCP send/receives by on-CPU PID and process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-1a)

```
bpftrace -e 'k:tcp_sendmsg,k:tcp_recvmsg { @[func, pid, comm] = count(); }'
```

TCP send bytes as a histogram:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-2a)

```
bpftrace -e 'k:tcp_sendmsg { @send_bytes = hist(arg2); }'
```

TCP receive bytes as a histogram:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-3a)

```
bpftrace -e 'kr:tcp_recvmsg /retval >= 0/ { @recv_bytes = hist(retval); }'
```

Count TCP retransmits by type and remote host (assumes IPv4):

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-4a)

```
bpftrace -e 't:tcp:tcp_retransmit_* { @[probe, ntop(2, args->saddr)] = count(); }'
```

Count all TCP functions (adds high overhead to TCP):

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-5a)

```
bpftrace -e 'k:tcp_* { @[func] = count(); }'
```

Count UDP send/receives by on-CPU PID and process name:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-6a)

```
bpftrace -e 'k:udp*_sendmsg,k:udp*_recvmsg { @[func, pid, comm] = count(); }'
```

UDP send bytes as a histogram:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-7a)

```
bpftrace -e 'k:udp_sendmsg { @send_bytes = hist(arg2); }'
```

UDP receive bytes as a histogram:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-8a)

```
bpftrace -e 'kr:udp_recvmsg /retval >= 0/ { @recv_bytes = hist(retval); }'
```

Count transmit kernel stack traces:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-9a)

```
bpftrace -e 't:net:net_dev_xmit { @[kstack] = count(); }'
```

Show receive CPU histogram for each device:

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-10a)

```
bpftrace -e 't:net:netif_receive_skb { @[str(args->name)] = lhist(cpu, 0, 128, 1); }'
```

Count ieee80211 layer functions (adds high overhead to packets):

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-11a)

```
bpftrace -e 'k:ieee80211_* { @[func] = count()'
```

Count all ixgbevf device driver functions (adds high overhead to ixgbevf):

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-12a)

```
bpftrace -e 'k:ixgbevf_* { @[func] = count(); }'
```

Count all iwl device driver tracepoints (adds high overhead to iwl):

[Click here to view code image](https://learning.oreilly.com/library/view/systems-performance-2nd/9780136821694/appc_images.xhtml#pg808-13a)

```
bpftrace -e 't:iwlwifi:*,t:iwlwifi_io:* { @[probe] = count(); }'
```
