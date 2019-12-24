
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 40 1a 10 f0 	movl   $0xf0101a40,(%esp)
f0100055:	e8 83 09 00 00       	call   f01009dd <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 01 07 00 00       	call   f0100788 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 5c 1a 10 f0 	movl   $0xf0101a5c,(%esp)
f0100092:	e8 46 09 00 00       	call   f01009dd <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 44 29 11 f0       	mov    $0xf0112944,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 6e 14 00 00       	call   f0101533 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 93 04 00 00       	call   f010055d <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 77 1a 10 f0 	movl   $0xf0101a77,(%esp)
f01000d9:	e8 ff 08 00 00       	call   f01009dd <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 72 07 00 00       	call   f0100868 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 40 29 11 f0 00 	cmpl   $0x0,0xf0112940
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 40 29 11 f0    	mov    %esi,0xf0112940

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 92 1a 10 f0 	movl   $0xf0101a92,(%esp)
f010012c:	e8 ac 08 00 00       	call   f01009dd <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 6d 08 00 00       	call   f01009aa <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 43 1d 10 f0 	movl   $0xf0101d43,(%esp)
f0100144:	e8 94 08 00 00       	call   f01009dd <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 13 07 00 00       	call   f0100868 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 aa 1a 10 f0 	movl   $0xf0101aaa,(%esp)
f0100176:	e8 62 08 00 00       	call   f01009dd <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 20 08 00 00       	call   f01009aa <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 43 1d 10 f0 	movl   $0xf0101d43,(%esp)
f0100191:	e8 47 08 00 00       	call   f01009dd <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001b7:	a8 01                	test   $0x1,%al
f01001b9:	74 08                	je     f01001c3 <serial_proc_data+0x15>
f01001bb:	b2 f8                	mov    $0xf8,%dl
f01001bd:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001be:	0f b6 c0             	movzbl %al,%eax
f01001c1:	eb 05                	jmp    f01001c8 <serial_proc_data+0x1a>
		return -1;
f01001c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 26                	jmp    f01001fb <cons_intr+0x31>
		if (c == 0)
f01001d5:	85 d2                	test   %edx,%edx
f01001d7:	74 22                	je     f01001fb <cons_intr+0x31>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	a1 24 25 11 f0       	mov    0xf0112524,%eax
f01001de:	88 90 20 23 11 f0    	mov    %dl,-0xfeedce0(%eax)
f01001e4:	8d 50 01             	lea    0x1(%eax),%edx
		if (cons.wpos == CONSBUFSIZE)
f01001e7:	81 fa 00 02 00 00    	cmp    $0x200,%edx
			cons.wpos = 0;
f01001ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01001f2:	0f 44 d0             	cmove  %eax,%edx
f01001f5:	89 15 24 25 11 f0    	mov    %edx,0xf0112524
	while ((c = (*proc)()) != -1) {
f01001fb:	ff d3                	call   *%ebx
f01001fd:	89 c2                	mov    %eax,%edx
f01001ff:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100202:	75 d1                	jne    f01001d5 <cons_intr+0xb>
	}
}
f0100204:	83 c4 04             	add    $0x4,%esp
f0100207:	5b                   	pop    %ebx
f0100208:	5d                   	pop    %ebp
f0100209:	c3                   	ret    

f010020a <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010020a:	55                   	push   %ebp
f010020b:	89 e5                	mov    %esp,%ebp
f010020d:	57                   	push   %edi
f010020e:	56                   	push   %esi
f010020f:	53                   	push   %ebx
f0100210:	83 ec 2c             	sub    $0x2c,%esp
f0100213:	89 c7                	mov    %eax,%edi
f0100215:	bb 01 32 00 00       	mov    $0x3201,%ebx
f010021a:	be fd 03 00 00       	mov    $0x3fd,%esi
f010021f:	eb 05                	jmp    f0100226 <cons_putc+0x1c>
		delay();
f0100221:	e8 7a ff ff ff       	call   f01001a0 <delay>
f0100226:	89 f2                	mov    %esi,%edx
f0100228:	ec                   	in     (%dx),%al
	for (i = 0;
f0100229:	a8 20                	test   $0x20,%al
f010022b:	75 05                	jne    f0100232 <cons_putc+0x28>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010022d:	83 eb 01             	sub    $0x1,%ebx
f0100230:	75 ef                	jne    f0100221 <cons_putc+0x17>
	outb(COM1 + COM_TX, c);
f0100232:	89 f8                	mov    %edi,%eax
f0100234:	25 ff 00 00 00       	and    $0xff,%eax
f0100239:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100241:	ee                   	out    %al,(%dx)
f0100242:	bb 01 32 00 00       	mov    $0x3201,%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100247:	be 79 03 00 00       	mov    $0x379,%esi
f010024c:	eb 05                	jmp    f0100253 <cons_putc+0x49>
		delay();
f010024e:	e8 4d ff ff ff       	call   f01001a0 <delay>
f0100253:	89 f2                	mov    %esi,%edx
f0100255:	ec                   	in     (%dx),%al
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100256:	84 c0                	test   %al,%al
f0100258:	78 05                	js     f010025f <cons_putc+0x55>
f010025a:	83 eb 01             	sub    $0x1,%ebx
f010025d:	75 ef                	jne    f010024e <cons_putc+0x44>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010025f:	ba 78 03 00 00       	mov    $0x378,%edx
f0100264:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100268:	ee                   	out    %al,(%dx)
f0100269:	b2 7a                	mov    $0x7a,%dl
f010026b:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100270:	ee                   	out    %al,(%dx)
f0100271:	b8 08 00 00 00       	mov    $0x8,%eax
f0100276:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100277:	89 fa                	mov    %edi,%edx
f0100279:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010027f:	89 f8                	mov    %edi,%eax
f0100281:	80 cc 07             	or     $0x7,%ah
f0100284:	85 d2                	test   %edx,%edx
f0100286:	0f 44 f8             	cmove  %eax,%edi
	switch (c & 0xff) {
f0100289:	89 f8                	mov    %edi,%eax
f010028b:	25 ff 00 00 00       	and    $0xff,%eax
f0100290:	83 f8 09             	cmp    $0x9,%eax
f0100293:	74 7a                	je     f010030f <cons_putc+0x105>
f0100295:	83 f8 09             	cmp    $0x9,%eax
f0100298:	7f 0b                	jg     f01002a5 <cons_putc+0x9b>
f010029a:	83 f8 08             	cmp    $0x8,%eax
f010029d:	0f 85 a0 00 00 00    	jne    f0100343 <cons_putc+0x139>
f01002a3:	eb 13                	jmp    f01002b8 <cons_putc+0xae>
f01002a5:	83 f8 0a             	cmp    $0xa,%eax
f01002a8:	74 3f                	je     f01002e9 <cons_putc+0xdf>
f01002aa:	83 f8 0d             	cmp    $0xd,%eax
f01002ad:	8d 76 00             	lea    0x0(%esi),%esi
f01002b0:	0f 85 8d 00 00 00    	jne    f0100343 <cons_putc+0x139>
f01002b6:	eb 39                	jmp    f01002f1 <cons_putc+0xe7>
		if (crt_pos > 0) {
f01002b8:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002bf:	66 85 c0             	test   %ax,%ax
f01002c2:	0f 84 e5 00 00 00    	je     f01003ad <cons_putc+0x1a3>
			crt_pos--;
f01002c8:	83 e8 01             	sub    $0x1,%eax
f01002cb:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002d1:	0f b7 c0             	movzwl %ax,%eax
f01002d4:	81 e7 00 ff ff ff    	and    $0xffffff00,%edi
f01002da:	83 cf 20             	or     $0x20,%edi
f01002dd:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f01002e3:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002e7:	eb 77                	jmp    f0100360 <cons_putc+0x156>
		crt_pos += CRT_COLS;
f01002e9:	66 83 05 34 25 11 f0 	addw   $0x50,0xf0112534
f01002f0:	50 
		crt_pos -= (crt_pos % CRT_COLS);
f01002f1:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f01002f8:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002fe:	c1 e8 16             	shr    $0x16,%eax
f0100301:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100304:	c1 e0 04             	shl    $0x4,%eax
f0100307:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
f010030d:	eb 51                	jmp    f0100360 <cons_putc+0x156>
		cons_putc(' ');
f010030f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100314:	e8 f1 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100319:	b8 20 00 00 00       	mov    $0x20,%eax
f010031e:	e8 e7 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100323:	b8 20 00 00 00       	mov    $0x20,%eax
f0100328:	e8 dd fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f010032d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100332:	e8 d3 fe ff ff       	call   f010020a <cons_putc>
		cons_putc(' ');
f0100337:	b8 20 00 00 00       	mov    $0x20,%eax
f010033c:	e8 c9 fe ff ff       	call   f010020a <cons_putc>
f0100341:	eb 1d                	jmp    f0100360 <cons_putc+0x156>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100343:	0f b7 05 34 25 11 f0 	movzwl 0xf0112534,%eax
f010034a:	0f b7 c8             	movzwl %ax,%ecx
f010034d:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
f0100353:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100357:	83 c0 01             	add    $0x1,%eax
f010035a:	66 a3 34 25 11 f0    	mov    %ax,0xf0112534
	if (crt_pos >= CRT_SIZE) {
f0100360:	66 81 3d 34 25 11 f0 	cmpw   $0x7cf,0xf0112534
f0100367:	cf 07 
f0100369:	76 42                	jbe    f01003ad <cons_putc+0x1a3>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010036b:	a1 30 25 11 f0       	mov    0xf0112530,%eax
f0100370:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100377:	00 
f0100378:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010037e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100382:	89 04 24             	mov    %eax,(%esp)
f0100385:	e8 07 12 00 00       	call   f0101591 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f010038a:	8b 15 30 25 11 f0    	mov    0xf0112530,%edx
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100390:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100395:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010039b:	83 c0 01             	add    $0x1,%eax
f010039e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003a3:	75 f0                	jne    f0100395 <cons_putc+0x18b>
		crt_pos -= CRT_COLS;
f01003a5:	66 83 2d 34 25 11 f0 	subw   $0x50,0xf0112534
f01003ac:	50 
	outb(addr_6845, 14);
f01003ad:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01003b3:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003b8:	89 ca                	mov    %ecx,%edx
f01003ba:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003bb:	0f b7 1d 34 25 11 f0 	movzwl 0xf0112534,%ebx
f01003c2:	8d 71 01             	lea    0x1(%ecx),%esi
f01003c5:	89 d8                	mov    %ebx,%eax
f01003c7:	66 c1 e8 08          	shr    $0x8,%ax
f01003cb:	89 f2                	mov    %esi,%edx
f01003cd:	ee                   	out    %al,(%dx)
f01003ce:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003d3:	89 ca                	mov    %ecx,%edx
f01003d5:	ee                   	out    %al,(%dx)
f01003d6:	89 d8                	mov    %ebx,%eax
f01003d8:	89 f2                	mov    %esi,%edx
f01003da:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003db:	83 c4 2c             	add    $0x2c,%esp
f01003de:	5b                   	pop    %ebx
f01003df:	5e                   	pop    %esi
f01003e0:	5f                   	pop    %edi
f01003e1:	5d                   	pop    %ebp
f01003e2:	c3                   	ret    

f01003e3 <kbd_proc_data>:
{
f01003e3:	55                   	push   %ebp
f01003e4:	89 e5                	mov    %esp,%ebp
f01003e6:	53                   	push   %ebx
f01003e7:	83 ec 14             	sub    $0x14,%esp
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003ea:	ba 64 00 00 00       	mov    $0x64,%edx
f01003ef:	ec                   	in     (%dx),%al
	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003f0:	a8 01                	test   $0x1,%al
f01003f2:	0f 84 e5 00 00 00    	je     f01004dd <kbd_proc_data+0xfa>
f01003f8:	b2 60                	mov    $0x60,%dl
f01003fa:	ec                   	in     (%dx),%al
f01003fb:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f01003fd:	3c e0                	cmp    $0xe0,%al
f01003ff:	75 11                	jne    f0100412 <kbd_proc_data+0x2f>
		shift |= E0ESC;
f0100401:	83 0d 28 25 11 f0 40 	orl    $0x40,0xf0112528
		return 0;
f0100408:	bb 00 00 00 00       	mov    $0x0,%ebx
f010040d:	e9 d0 00 00 00       	jmp    f01004e2 <kbd_proc_data+0xff>
	} else if (data & 0x80) {
f0100412:	84 c0                	test   %al,%al
f0100414:	79 37                	jns    f010044d <kbd_proc_data+0x6a>
		data = (shift & E0ESC ? data : data & 0x7F);
f0100416:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f010041c:	89 cb                	mov    %ecx,%ebx
f010041e:	83 e3 40             	and    $0x40,%ebx
f0100421:	83 e0 7f             	and    $0x7f,%eax
f0100424:	85 db                	test   %ebx,%ebx
f0100426:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100429:	0f b6 d2             	movzbl %dl,%edx
f010042c:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100433:	83 c8 40             	or     $0x40,%eax
f0100436:	0f b6 c0             	movzbl %al,%eax
f0100439:	f7 d0                	not    %eax
f010043b:	21 c1                	and    %eax,%ecx
f010043d:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
		return 0;
f0100443:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100448:	e9 95 00 00 00       	jmp    f01004e2 <kbd_proc_data+0xff>
	} else if (shift & E0ESC) {
f010044d:	8b 0d 28 25 11 f0    	mov    0xf0112528,%ecx
f0100453:	f6 c1 40             	test   $0x40,%cl
f0100456:	74 0e                	je     f0100466 <kbd_proc_data+0x83>
		data |= 0x80;
f0100458:	89 c2                	mov    %eax,%edx
f010045a:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010045d:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100460:	89 0d 28 25 11 f0    	mov    %ecx,0xf0112528
	shift |= shiftcode[data];
f0100466:	0f b6 d2             	movzbl %dl,%edx
f0100469:	0f b6 82 00 1b 10 f0 	movzbl -0xfefe500(%edx),%eax
f0100470:	0b 05 28 25 11 f0    	or     0xf0112528,%eax
	shift ^= togglecode[data];
f0100476:	0f b6 8a 00 1c 10 f0 	movzbl -0xfefe400(%edx),%ecx
f010047d:	31 c8                	xor    %ecx,%eax
f010047f:	a3 28 25 11 f0       	mov    %eax,0xf0112528
	c = charcode[shift & (CTL | SHIFT)][data];
f0100484:	89 c1                	mov    %eax,%ecx
f0100486:	83 e1 03             	and    $0x3,%ecx
f0100489:	8b 0c 8d 00 1d 10 f0 	mov    -0xfefe300(,%ecx,4),%ecx
f0100490:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100494:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100497:	a8 08                	test   $0x8,%al
f0100499:	74 1b                	je     f01004b6 <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f010049b:	89 da                	mov    %ebx,%edx
f010049d:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01004a0:	83 f9 19             	cmp    $0x19,%ecx
f01004a3:	77 05                	ja     f01004aa <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004a5:	83 eb 20             	sub    $0x20,%ebx
f01004a8:	eb 0c                	jmp    f01004b6 <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004aa:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01004ad:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01004b0:	83 fa 19             	cmp    $0x19,%edx
f01004b3:	0f 46 d9             	cmovbe %ecx,%ebx
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004b6:	f7 d0                	not    %eax
f01004b8:	a8 06                	test   $0x6,%al
f01004ba:	75 26                	jne    f01004e2 <kbd_proc_data+0xff>
f01004bc:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004c2:	75 1e                	jne    f01004e2 <kbd_proc_data+0xff>
		cprintf("Rebooting!\n");
f01004c4:	c7 04 24 c4 1a 10 f0 	movl   $0xf0101ac4,(%esp)
f01004cb:	e8 0d 05 00 00       	call   f01009dd <cprintf>
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d0:	ba 92 00 00 00       	mov    $0x92,%edx
f01004d5:	b8 03 00 00 00       	mov    $0x3,%eax
f01004da:	ee                   	out    %al,(%dx)
f01004db:	eb 05                	jmp    f01004e2 <kbd_proc_data+0xff>
		return -1;
f01004dd:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
}
f01004e2:	89 d8                	mov    %ebx,%eax
f01004e4:	83 c4 14             	add    $0x14,%esp
f01004e7:	5b                   	pop    %ebx
f01004e8:	5d                   	pop    %ebp
f01004e9:	c3                   	ret    

f01004ea <serial_intr>:
	if (serial_exists)
f01004ea:	80 3d 00 23 11 f0 00 	cmpb   $0x0,0xf0112300
f01004f1:	74 11                	je     f0100504 <serial_intr+0x1a>
{
f01004f3:	55                   	push   %ebp
f01004f4:	89 e5                	mov    %esp,%ebp
f01004f6:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01004f9:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f01004fe:	e8 c7 fc ff ff       	call   f01001ca <cons_intr>
}
f0100503:	c9                   	leave  
f0100504:	f3 c3                	repz ret 

f0100506 <kbd_intr>:
{
f0100506:	55                   	push   %ebp
f0100507:	89 e5                	mov    %esp,%ebp
f0100509:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010050c:	b8 e3 03 10 f0       	mov    $0xf01003e3,%eax
f0100511:	e8 b4 fc ff ff       	call   f01001ca <cons_intr>
}
f0100516:	c9                   	leave  
f0100517:	c3                   	ret    

f0100518 <cons_getc>:
{
f0100518:	55                   	push   %ebp
f0100519:	89 e5                	mov    %esp,%ebp
f010051b:	83 ec 08             	sub    $0x8,%esp
	serial_intr();
f010051e:	e8 c7 ff ff ff       	call   f01004ea <serial_intr>
	kbd_intr();
f0100523:	e8 de ff ff ff       	call   f0100506 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100528:	8b 15 20 25 11 f0    	mov    0xf0112520,%edx
f010052e:	3b 15 24 25 11 f0    	cmp    0xf0112524,%edx
f0100534:	74 20                	je     f0100556 <cons_getc+0x3e>
		c = cons.buf[cons.rpos++];
f0100536:	0f b6 82 20 23 11 f0 	movzbl -0xfeedce0(%edx),%eax
f010053d:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
f0100540:	81 fa 00 02 00 00    	cmp    $0x200,%edx
		c = cons.buf[cons.rpos++];
f0100546:	b9 00 00 00 00       	mov    $0x0,%ecx
f010054b:	0f 44 d1             	cmove  %ecx,%edx
f010054e:	89 15 20 25 11 f0    	mov    %edx,0xf0112520
f0100554:	eb 05                	jmp    f010055b <cons_getc+0x43>
	return 0;
f0100556:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010055b:	c9                   	leave  
f010055c:	c3                   	ret    

f010055d <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f010055d:	55                   	push   %ebp
f010055e:	89 e5                	mov    %esp,%ebp
f0100560:	57                   	push   %edi
f0100561:	56                   	push   %esi
f0100562:	53                   	push   %ebx
f0100563:	83 ec 1c             	sub    $0x1c,%esp
	was = *cp;
f0100566:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100574:	5a a5 
	if (*cp != 0xA55A) {
f0100576:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100581:	74 11                	je     f0100594 <cons_init+0x37>
		addr_6845 = MONO_BASE;
f0100583:	c7 05 2c 25 11 f0 b4 	movl   $0x3b4,0xf011252c
f010058a:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058d:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100592:	eb 16                	jmp    f01005aa <cons_init+0x4d>
		*cp = was;
f0100594:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059b:	c7 05 2c 25 11 f0 d4 	movl   $0x3d4,0xf011252c
f01005a2:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a5:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
	outb(addr_6845, 14);
f01005aa:	8b 0d 2c 25 11 f0    	mov    0xf011252c,%ecx
f01005b0:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b5:	89 ca                	mov    %ecx,%edx
f01005b7:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005b8:	8d 59 01             	lea    0x1(%ecx),%ebx
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005bb:	89 da                	mov    %ebx,%edx
f01005bd:	ec                   	in     (%dx),%al
f01005be:	0f b6 f0             	movzbl %al,%esi
f01005c1:	c1 e6 08             	shl    $0x8,%esi
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c9:	89 ca                	mov    %ecx,%edx
f01005cb:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cc:	89 da                	mov    %ebx,%edx
f01005ce:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01005cf:	89 3d 30 25 11 f0    	mov    %edi,0xf0112530
	pos |= inb(addr_6845 + 1);
f01005d5:	0f b6 d8             	movzbl %al,%ebx
f01005d8:	09 de                	or     %ebx,%esi
	crt_pos = pos;
f01005da:	66 89 35 34 25 11 f0 	mov    %si,0xf0112534
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e1:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005e6:	b8 00 00 00 00       	mov    $0x0,%eax
f01005eb:	89 f2                	mov    %esi,%edx
f01005ed:	ee                   	out    %al,(%dx)
f01005ee:	b2 fb                	mov    $0xfb,%dl
f01005f0:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f5:	ee                   	out    %al,(%dx)
f01005f6:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005fb:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100600:	89 da                	mov    %ebx,%edx
f0100602:	ee                   	out    %al,(%dx)
f0100603:	b2 f9                	mov    $0xf9,%dl
f0100605:	b8 00 00 00 00       	mov    $0x0,%eax
f010060a:	ee                   	out    %al,(%dx)
f010060b:	b2 fb                	mov    $0xfb,%dl
f010060d:	b8 03 00 00 00       	mov    $0x3,%eax
f0100612:	ee                   	out    %al,(%dx)
f0100613:	b2 fc                	mov    $0xfc,%dl
f0100615:	b8 00 00 00 00       	mov    $0x0,%eax
f010061a:	ee                   	out    %al,(%dx)
f010061b:	b2 f9                	mov    $0xf9,%dl
f010061d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100622:	ee                   	out    %al,(%dx)
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100623:	b2 fd                	mov    $0xfd,%dl
f0100625:	ec                   	in     (%dx),%al
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100626:	3c ff                	cmp    $0xff,%al
f0100628:	0f 95 c1             	setne  %cl
f010062b:	88 0d 00 23 11 f0    	mov    %cl,0xf0112300
f0100631:	89 f2                	mov    %esi,%edx
f0100633:	ec                   	in     (%dx),%al
f0100634:	89 da                	mov    %ebx,%edx
f0100636:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100637:	84 c9                	test   %cl,%cl
f0100639:	75 0c                	jne    f0100647 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f010063b:	c7 04 24 d0 1a 10 f0 	movl   $0xf0101ad0,(%esp)
f0100642:	e8 96 03 00 00       	call   f01009dd <cprintf>
}
f0100647:	83 c4 1c             	add    $0x1c,%esp
f010064a:	5b                   	pop    %ebx
f010064b:	5e                   	pop    %esi
f010064c:	5f                   	pop    %edi
f010064d:	5d                   	pop    %ebp
f010064e:	c3                   	ret    

f010064f <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010064f:	55                   	push   %ebp
f0100650:	89 e5                	mov    %esp,%ebp
f0100652:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100655:	8b 45 08             	mov    0x8(%ebp),%eax
f0100658:	e8 ad fb ff ff       	call   f010020a <cons_putc>
}
f010065d:	c9                   	leave  
f010065e:	c3                   	ret    

f010065f <getchar>:

int
getchar(void)
{
f010065f:	55                   	push   %ebp
f0100660:	89 e5                	mov    %esp,%ebp
f0100662:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100665:	e8 ae fe ff ff       	call   f0100518 <cons_getc>
f010066a:	85 c0                	test   %eax,%eax
f010066c:	74 f7                	je     f0100665 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010066e:	c9                   	leave  
f010066f:	c3                   	ret    

f0100670 <iscons>:

int
iscons(int fdnum)
{
f0100670:	55                   	push   %ebp
f0100671:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100673:	b8 01 00 00 00       	mov    $0x1,%eax
f0100678:	5d                   	pop    %ebp
f0100679:	c3                   	ret    
f010067a:	66 90                	xchg   %ax,%ax
f010067c:	66 90                	xchg   %ax,%ax
f010067e:	66 90                	xchg   %ax,%ax

f0100680 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100686:	c7 04 24 10 1d 10 f0 	movl   $0xf0101d10,(%esp)
f010068d:	e8 4b 03 00 00       	call   f01009dd <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100692:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100699:	00 
f010069a:	c7 04 24 cc 1d 10 f0 	movl   $0xf0101dcc,(%esp)
f01006a1:	e8 37 03 00 00       	call   f01009dd <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ad:	00 
f01006ae:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 f4 1d 10 f0 	movl   $0xf0101df4,(%esp)
f01006bd:	e8 1b 03 00 00       	call   f01009dd <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c2:	c7 44 24 08 3f 1a 10 	movl   $0x101a3f,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 3f 1a 10 	movl   $0xf0101a3f,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 18 1e 10 f0 	movl   $0xf0101e18,(%esp)
f01006d9:	e8 ff 02 00 00       	call   f01009dd <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006de:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006e5:	00 
f01006e6:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 3c 1e 10 f0 	movl   $0xf0101e3c,(%esp)
f01006f5:	e8 e3 02 00 00       	call   f01009dd <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006fa:	c7 44 24 08 44 29 11 	movl   $0x112944,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 44 29 11 	movl   $0xf0112944,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 60 1e 10 f0 	movl   $0xf0101e60,(%esp)
f0100711:	e8 c7 02 00 00       	call   f01009dd <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100716:	b8 43 2d 11 f0       	mov    $0xf0112d43,%eax
f010071b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100720:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100725:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072b:	85 c0                	test   %eax,%eax
f010072d:	0f 48 c2             	cmovs  %edx,%eax
f0100730:	c1 f8 0a             	sar    $0xa,%eax
f0100733:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100737:	c7 04 24 84 1e 10 f0 	movl   $0xf0101e84,(%esp)
f010073e:	e8 9a 02 00 00       	call   f01009dd <cprintf>
	return 0;
}
f0100743:	b8 00 00 00 00       	mov    $0x0,%eax
f0100748:	c9                   	leave  
f0100749:	c3                   	ret    

f010074a <mon_help>:
{
f010074a:	55                   	push   %ebp
f010074b:	89 e5                	mov    %esp,%ebp
f010074d:	56                   	push   %esi
f010074e:	53                   	push   %ebx
f010074f:	83 ec 10             	sub    $0x10,%esp
f0100752:	bb c4 1f 10 f0       	mov    $0xf0101fc4,%ebx
mon_help(int argc, char **argv, struct Trapframe *tf)
f0100757:	be e8 1f 10 f0       	mov    $0xf0101fe8,%esi
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010075c:	8b 03                	mov    (%ebx),%eax
f010075e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100762:	8b 43 fc             	mov    -0x4(%ebx),%eax
f0100765:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100769:	c7 04 24 29 1d 10 f0 	movl   $0xf0101d29,(%esp)
f0100770:	e8 68 02 00 00       	call   f01009dd <cprintf>
f0100775:	83 c3 0c             	add    $0xc,%ebx
	for (i = 0; i < NCOMMANDS; i++)
f0100778:	39 f3                	cmp    %esi,%ebx
f010077a:	75 e0                	jne    f010075c <mon_help+0x12>
}
f010077c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100781:	83 c4 10             	add    $0x10,%esp
f0100784:	5b                   	pop    %ebx
f0100785:	5e                   	pop    %esi
f0100786:	5d                   	pop    %ebp
f0100787:	c3                   	ret    

f0100788 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100788:	55                   	push   %ebp
f0100789:	89 e5                	mov    %esp,%ebp
f010078b:	56                   	push   %esi
f010078c:	53                   	push   %ebx
f010078d:	83 ec 40             	sub    $0x40,%esp
	// Your code here.
	uint32_t *ebp;
	struct Eipdebuginfo info;
	int result;

    	ebp = (uint32_t *)read_ebp();
f0100790:	89 eb                	mov    %ebp,%ebx

    	cprintf("Stack backtrace:\r\n");
f0100792:	c7 04 24 32 1d 10 f0 	movl   $0xf0101d32,(%esp)
f0100799:	e8 3f 02 00 00       	call   f01009dd <cprintf>

    	while (ebp)
    	{
       	 cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, ebp[1], ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
		memset(&info, 0, sizeof(struct Eipdebuginfo));
f010079e:	8d 75 e0             	lea    -0x20(%ebp),%esi
    	while (ebp)
f01007a1:	e9 ae 00 00 00       	jmp    f0100854 <mon_backtrace+0xcc>
       	 cprintf("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\r\n", ebp, ebp[1], ebp[2], ebp[3], ebp[4], ebp[5], ebp[6]);
f01007a6:	8b 43 18             	mov    0x18(%ebx),%eax
f01007a9:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007ad:	8b 43 14             	mov    0x14(%ebx),%eax
f01007b0:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007b4:	8b 43 10             	mov    0x10(%ebx),%eax
f01007b7:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007bb:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007be:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007c2:	8b 43 08             	mov    0x8(%ebx),%eax
f01007c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007c9:	8b 43 04             	mov    0x4(%ebx),%eax
f01007cc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007d0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01007d4:	c7 04 24 b0 1e 10 f0 	movl   $0xf0101eb0,(%esp)
f01007db:	e8 fd 01 00 00       	call   f01009dd <cprintf>
		memset(&info, 0, sizeof(struct Eipdebuginfo));
f01007e0:	c7 44 24 08 18 00 00 	movl   $0x18,0x8(%esp)
f01007e7:	00 
f01007e8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01007ef:	00 
f01007f0:	89 34 24             	mov    %esi,(%esp)
f01007f3:	e8 3b 0d 00 00       	call   f0101533 <memset>

        	result = debuginfo_eip(ebp[1], &info);
f01007f8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007fc:	8b 43 04             	mov    0x4(%ebx),%eax
f01007ff:	89 04 24             	mov    %eax,(%esp)
f0100802:	e8 cd 02 00 00       	call   f0100ad4 <debuginfo_eip>
        	if (0 != result)
f0100807:	85 c0                	test   %eax,%eax
f0100809:	74 15                	je     f0100820 <mon_backtrace+0x98>
        	{
            		cprintf("failed to get debuginfo for eip %x.\r\n", ebp[1]);
f010080b:	8b 43 04             	mov    0x4(%ebx),%eax
f010080e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100812:	c7 04 24 e8 1e 10 f0 	movl   $0xf0101ee8,(%esp)
f0100819:	e8 bf 01 00 00       	call   f01009dd <cprintf>
f010081e:	eb 32                	jmp    f0100852 <mon_backtrace+0xca>
        	}
        	else
        	{
            		cprintf("\t%s:%d: %.*s+%u\r\n", info.eip_file, info.eip_line, info.eip_fn_namelen, info.eip_fn_name, ebp[1] - info.eip_fn_addr);
f0100820:	8b 43 04             	mov    0x4(%ebx),%eax
f0100823:	2b 45 f0             	sub    -0x10(%ebp),%eax
f0100826:	89 44 24 14          	mov    %eax,0x14(%esp)
f010082a:	8b 45 e8             	mov    -0x18(%ebp),%eax
f010082d:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100831:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100834:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100838:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010083b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010083f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100842:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100846:	c7 04 24 45 1d 10 f0 	movl   $0xf0101d45,(%esp)
f010084d:	e8 8b 01 00 00       	call   f01009dd <cprintf>
        	}
        	ebp = (uint32_t *)*ebp;
f0100852:	8b 1b                	mov    (%ebx),%ebx
    	while (ebp)
f0100854:	85 db                	test   %ebx,%ebx
f0100856:	0f 85 4a ff ff ff    	jne    f01007a6 <mon_backtrace+0x1e>
    	}
	return 0;
}
f010085c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100861:	83 c4 40             	add    $0x40,%esp
f0100864:	5b                   	pop    %ebx
f0100865:	5e                   	pop    %esi
f0100866:	5d                   	pop    %ebp
f0100867:	c3                   	ret    

f0100868 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100868:	55                   	push   %ebp
f0100869:	89 e5                	mov    %esp,%ebp
f010086b:	57                   	push   %edi
f010086c:	56                   	push   %esi
f010086d:	53                   	push   %ebx
f010086e:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100871:	c7 04 24 10 1f 10 f0 	movl   $0xf0101f10,(%esp)
f0100878:	e8 60 01 00 00       	call   f01009dd <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010087d:	c7 04 24 34 1f 10 f0 	movl   $0xf0101f34,(%esp)
f0100884:	e8 54 01 00 00       	call   f01009dd <cprintf>
    	//cprintf("H%x Wo%s", 57616, &i);
	//cprintf("x=%d y=%d", 3);


	while (1) {
		buf = readline("K> ");
f0100889:	c7 04 24 57 1d 10 f0 	movl   $0xf0101d57,(%esp)
f0100890:	e8 4b 0a 00 00       	call   f01012e0 <readline>
f0100895:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100897:	85 c0                	test   %eax,%eax
f0100899:	74 ee                	je     f0100889 <monitor+0x21>
	argv[argc] = 0;
f010089b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01008a2:	bb 00 00 00 00       	mov    $0x0,%ebx
f01008a7:	eb 06                	jmp    f01008af <monitor+0x47>
			*buf++ = 0;
f01008a9:	c6 06 00             	movb   $0x0,(%esi)
f01008ac:	83 c6 01             	add    $0x1,%esi
		while (*buf && strchr(WHITESPACE, *buf))
f01008af:	0f b6 06             	movzbl (%esi),%eax
f01008b2:	84 c0                	test   %al,%al
f01008b4:	74 63                	je     f0100919 <monitor+0xb1>
f01008b6:	0f be c0             	movsbl %al,%eax
f01008b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008bd:	c7 04 24 5b 1d 10 f0 	movl   $0xf0101d5b,(%esp)
f01008c4:	e8 2d 0c 00 00       	call   f01014f6 <strchr>
f01008c9:	85 c0                	test   %eax,%eax
f01008cb:	75 dc                	jne    f01008a9 <monitor+0x41>
		if (*buf == 0)
f01008cd:	80 3e 00             	cmpb   $0x0,(%esi)
f01008d0:	74 47                	je     f0100919 <monitor+0xb1>
		if (argc == MAXARGS-1) {
f01008d2:	83 fb 0f             	cmp    $0xf,%ebx
f01008d5:	75 16                	jne    f01008ed <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008d7:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008de:	00 
f01008df:	c7 04 24 60 1d 10 f0 	movl   $0xf0101d60,(%esp)
f01008e6:	e8 f2 00 00 00       	call   f01009dd <cprintf>
f01008eb:	eb 9c                	jmp    f0100889 <monitor+0x21>
		argv[argc++] = buf;
f01008ed:	89 74 9d a8          	mov    %esi,-0x58(%ebp,%ebx,4)
f01008f1:	83 c3 01             	add    $0x1,%ebx
f01008f4:	eb 03                	jmp    f01008f9 <monitor+0x91>
			buf++;
f01008f6:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008f9:	0f b6 06             	movzbl (%esi),%eax
f01008fc:	84 c0                	test   %al,%al
f01008fe:	74 af                	je     f01008af <monitor+0x47>
f0100900:	0f be c0             	movsbl %al,%eax
f0100903:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100907:	c7 04 24 5b 1d 10 f0 	movl   $0xf0101d5b,(%esp)
f010090e:	e8 e3 0b 00 00       	call   f01014f6 <strchr>
f0100913:	85 c0                	test   %eax,%eax
f0100915:	74 df                	je     f01008f6 <monitor+0x8e>
f0100917:	eb 96                	jmp    f01008af <monitor+0x47>
	argv[argc] = 0;
f0100919:	c7 44 9d a8 00 00 00 	movl   $0x0,-0x58(%ebp,%ebx,4)
f0100920:	00 
	if (argc == 0)
f0100921:	85 db                	test   %ebx,%ebx
f0100923:	0f 84 60 ff ff ff    	je     f0100889 <monitor+0x21>
f0100929:	bf c0 1f 10 f0       	mov    $0xf0101fc0,%edi
f010092e:	be 00 00 00 00       	mov    $0x0,%esi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100933:	8b 07                	mov    (%edi),%eax
f0100935:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100939:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010093c:	89 04 24             	mov    %eax,(%esp)
f010093f:	e8 54 0b 00 00       	call   f0101498 <strcmp>
f0100944:	85 c0                	test   %eax,%eax
f0100946:	75 24                	jne    f010096c <monitor+0x104>
			return commands[i].func(argc, argv, tf);
f0100948:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010094b:	8b 55 08             	mov    0x8(%ebp),%edx
f010094e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100952:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100955:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100959:	89 1c 24             	mov    %ebx,(%esp)
f010095c:	ff 14 85 c8 1f 10 f0 	call   *-0xfefe038(,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100963:	85 c0                	test   %eax,%eax
f0100965:	78 28                	js     f010098f <monitor+0x127>
f0100967:	e9 1d ff ff ff       	jmp    f0100889 <monitor+0x21>
	for (i = 0; i < NCOMMANDS; i++) {
f010096c:	83 c6 01             	add    $0x1,%esi
f010096f:	83 c7 0c             	add    $0xc,%edi
f0100972:	83 fe 03             	cmp    $0x3,%esi
f0100975:	75 bc                	jne    f0100933 <monitor+0xcb>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100977:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010097a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010097e:	c7 04 24 7d 1d 10 f0 	movl   $0xf0101d7d,(%esp)
f0100985:	e8 53 00 00 00       	call   f01009dd <cprintf>
f010098a:	e9 fa fe ff ff       	jmp    f0100889 <monitor+0x21>
				break;
	}
}
f010098f:	83 c4 5c             	add    $0x5c,%esp
f0100992:	5b                   	pop    %ebx
f0100993:	5e                   	pop    %esi
f0100994:	5f                   	pop    %edi
f0100995:	5d                   	pop    %ebp
f0100996:	c3                   	ret    

f0100997 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100997:	55                   	push   %ebp
f0100998:	89 e5                	mov    %esp,%ebp
f010099a:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010099d:	8b 45 08             	mov    0x8(%ebp),%eax
f01009a0:	89 04 24             	mov    %eax,(%esp)
f01009a3:	e8 a7 fc ff ff       	call   f010064f <cputchar>
	*cnt++;
}
f01009a8:	c9                   	leave  
f01009a9:	c3                   	ret    

f01009aa <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01009aa:	55                   	push   %ebp
f01009ab:	89 e5                	mov    %esp,%ebp
f01009ad:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01009b0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01009b7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01009ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009be:	8b 45 08             	mov    0x8(%ebp),%eax
f01009c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009c5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009c8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cc:	c7 04 24 97 09 10 f0 	movl   $0xf0100997,(%esp)
f01009d3:	e8 8d 04 00 00       	call   f0100e65 <vprintfmt>
	return cnt;
}
f01009d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009db:	c9                   	leave  
f01009dc:	c3                   	ret    

f01009dd <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009dd:	55                   	push   %ebp
f01009de:	89 e5                	mov    %esp,%ebp
f01009e0:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009e3:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ed:	89 04 24             	mov    %eax,(%esp)
f01009f0:	e8 b5 ff ff ff       	call   f01009aa <vcprintf>
	va_end(ap);

	return cnt;
}
f01009f5:	c9                   	leave  
f01009f6:	c3                   	ret    

f01009f7 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009f7:	55                   	push   %ebp
f01009f8:	89 e5                	mov    %esp,%ebp
f01009fa:	57                   	push   %edi
f01009fb:	56                   	push   %esi
f01009fc:	53                   	push   %ebx
f01009fd:	83 ec 10             	sub    $0x10,%esp
f0100a00:	89 c6                	mov    %eax,%esi
f0100a02:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100a05:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100a08:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a0b:	8b 1a                	mov    (%edx),%ebx
f0100a0d:	8b 09                	mov    (%ecx),%ecx
f0100a0f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100a12:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100a19:	eb 77                	jmp    f0100a92 <stab_binsearch+0x9b>
		int true_m = (l + r) / 2, m = true_m;
f0100a1b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a1e:	01 d8                	add    %ebx,%eax
f0100a20:	b9 02 00 00 00       	mov    $0x2,%ecx
f0100a25:	99                   	cltd   
f0100a26:	f7 f9                	idiv   %ecx
f0100a28:	89 c1                	mov    %eax,%ecx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a2a:	eb 01                	jmp    f0100a2d <stab_binsearch+0x36>
			m--;
f0100a2c:	49                   	dec    %ecx
		while (m >= l && stabs[m].n_type != type)
f0100a2d:	39 d9                	cmp    %ebx,%ecx
f0100a2f:	7c 1d                	jl     f0100a4e <stab_binsearch+0x57>
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a31:	6b d1 0c             	imul   $0xc,%ecx,%edx
		while (m >= l && stabs[m].n_type != type)
f0100a34:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100a39:	39 fa                	cmp    %edi,%edx
f0100a3b:	75 ef                	jne    f0100a2c <stab_binsearch+0x35>
f0100a3d:	89 4d ec             	mov    %ecx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a40:	6b d1 0c             	imul   $0xc,%ecx,%edx
f0100a43:	8b 54 16 08          	mov    0x8(%esi,%edx,1),%edx
f0100a47:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100a4a:	73 18                	jae    f0100a64 <stab_binsearch+0x6d>
f0100a4c:	eb 05                	jmp    f0100a53 <stab_binsearch+0x5c>
			l = true_m + 1;
f0100a4e:	8d 58 01             	lea    0x1(%eax),%ebx
			continue;
f0100a51:	eb 3f                	jmp    f0100a92 <stab_binsearch+0x9b>
			*region_left = m;
f0100a53:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a56:	89 0a                	mov    %ecx,(%edx)
			l = true_m + 1;
f0100a58:	8d 58 01             	lea    0x1(%eax),%ebx
		any_matches = 1;
f0100a5b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a62:	eb 2e                	jmp    f0100a92 <stab_binsearch+0x9b>
		} else if (stabs[m].n_value > addr) {
f0100a64:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0100a67:	73 15                	jae    f0100a7e <stab_binsearch+0x87>
			*region_right = m - 1;
f0100a69:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100a6c:	49                   	dec    %ecx
f0100a6d:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100a70:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a73:	89 08                	mov    %ecx,(%eax)
		any_matches = 1;
f0100a75:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a7c:	eb 14                	jmp    f0100a92 <stab_binsearch+0x9b>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a7e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100a81:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a84:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0100a86:	ff 45 0c             	incl   0xc(%ebp)
f0100a89:	89 cb                	mov    %ecx,%ebx
		any_matches = 1;
f0100a8b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
	while (l <= r) {
f0100a92:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0100a95:	7e 84                	jle    f0100a1b <stab_binsearch+0x24>
		}
	}

	if (!any_matches)
f0100a97:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a9b:	75 0d                	jne    f0100aaa <stab_binsearch+0xb3>
		*region_right = *region_left - 1;
f0100a9d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100aa0:	8b 02                	mov    (%edx),%eax
f0100aa2:	48                   	dec    %eax
f0100aa3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100aa6:	89 01                	mov    %eax,(%ecx)
f0100aa8:	eb 22                	jmp    f0100acc <stab_binsearch+0xd5>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100aaa:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100aad:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100aaf:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100ab2:	8b 0a                	mov    (%edx),%ecx
		for (l = *region_right;
f0100ab4:	eb 01                	jmp    f0100ab7 <stab_binsearch+0xc0>
		     l--)
f0100ab6:	48                   	dec    %eax
		for (l = *region_right;
f0100ab7:	39 c1                	cmp    %eax,%ecx
f0100ab9:	7d 0c                	jge    f0100ac7 <stab_binsearch+0xd0>
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100abb:	6b d0 0c             	imul   $0xc,%eax,%edx
		     l > *region_left && stabs[l].n_type != type;
f0100abe:	0f b6 54 16 04       	movzbl 0x4(%esi,%edx,1),%edx
f0100ac3:	39 fa                	cmp    %edi,%edx
f0100ac5:	75 ef                	jne    f0100ab6 <stab_binsearch+0xbf>
			/* do nothing */;
		*region_left = l;
f0100ac7:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100aca:	89 02                	mov    %eax,(%edx)
	}
}
f0100acc:	83 c4 10             	add    $0x10,%esp
f0100acf:	5b                   	pop    %ebx
f0100ad0:	5e                   	pop    %esi
f0100ad1:	5f                   	pop    %edi
f0100ad2:	5d                   	pop    %ebp
f0100ad3:	c3                   	ret    

f0100ad4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ad4:	55                   	push   %ebp
f0100ad5:	89 e5                	mov    %esp,%ebp
f0100ad7:	83 ec 48             	sub    $0x48,%esp
f0100ada:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100add:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100ae0:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100ae3:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100ae6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ae9:	c7 03 e4 1f 10 f0    	movl   $0xf0101fe4,(%ebx)
	info->eip_line = 0;
f0100aef:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100af6:	c7 43 08 e4 1f 10 f0 	movl   $0xf0101fe4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100afd:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100b04:	89 7b 10             	mov    %edi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100b07:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b0e:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100b14:	76 12                	jbe    f0100b28 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b16:	b8 b4 76 10 f0       	mov    $0xf01076b4,%eax
f0100b1b:	3d 7d 5d 10 f0       	cmp    $0xf0105d7d,%eax
f0100b20:	0f 86 a5 01 00 00    	jbe    f0100ccb <debuginfo_eip+0x1f7>
f0100b26:	eb 1c                	jmp    f0100b44 <debuginfo_eip+0x70>
  	        panic("User address");
f0100b28:	c7 44 24 08 ee 1f 10 	movl   $0xf0101fee,0x8(%esp)
f0100b2f:	f0 
f0100b30:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b37:	00 
f0100b38:	c7 04 24 fb 1f 10 f0 	movl   $0xf0101ffb,(%esp)
f0100b3f:	e8 b4 f5 ff ff       	call   f01000f8 <_panic>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b44:	80 3d b3 76 10 f0 00 	cmpb   $0x0,0xf01076b3
f0100b4b:	0f 85 81 01 00 00    	jne    f0100cd2 <debuginfo_eip+0x1fe>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b51:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b58:	b8 7c 5d 10 f0       	mov    $0xf0105d7c,%eax
f0100b5d:	2d 30 22 10 f0       	sub    $0xf0102230,%eax
f0100b62:	c1 f8 02             	sar    $0x2,%eax
f0100b65:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b6b:	83 e8 01             	sub    $0x1,%eax
f0100b6e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b71:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100b75:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b7c:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b7f:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b82:	b8 30 22 10 f0       	mov    $0xf0102230,%eax
f0100b87:	e8 6b fe ff ff       	call   f01009f7 <stab_binsearch>
	if (lfile == 0)
f0100b8c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b8f:	85 c0                	test   %eax,%eax
f0100b91:	0f 84 42 01 00 00    	je     f0100cd9 <debuginfo_eip+0x205>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b97:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100b9a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b9d:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100ba0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ba4:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100bab:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100bae:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100bb1:	b8 30 22 10 f0       	mov    $0xf0102230,%eax
f0100bb6:	e8 3c fe ff ff       	call   f01009f7 <stab_binsearch>

	if (lfun <= rfun) {
f0100bbb:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100bbe:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100bc1:	7f 30                	jg     f0100bf3 <debuginfo_eip+0x11f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bc3:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100bc6:	8d 90 30 22 10 f0    	lea    -0xfefddd0(%eax),%edx
f0100bcc:	8b 80 30 22 10 f0    	mov    -0xfefddd0(%eax),%eax
f0100bd2:	b9 b4 76 10 f0       	mov    $0xf01076b4,%ecx
f0100bd7:	81 e9 7d 5d 10 f0    	sub    $0xf0105d7d,%ecx
f0100bdd:	39 c8                	cmp    %ecx,%eax
f0100bdf:	73 08                	jae    f0100be9 <debuginfo_eip+0x115>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100be1:	05 7d 5d 10 f0       	add    $0xf0105d7d,%eax
f0100be6:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100be9:	8b 42 08             	mov    0x8(%edx),%eax
f0100bec:	89 43 10             	mov    %eax,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100bef:	29 c7                	sub    %eax,%edi
f0100bf1:	eb 06                	jmp    f0100bf9 <debuginfo_eip+0x125>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bf3:	89 7b 10             	mov    %edi,0x10(%ebx)
		lline = lfile;
f0100bf6:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100bf9:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100c00:	00 
f0100c01:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c04:	89 04 24             	mov    %eax,(%esp)
f0100c07:	e8 0b 09 00 00       	call   f0101517 <strfind>
f0100c0c:	2b 43 08             	sub    0x8(%ebx),%eax
f0100c0f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lfun, &rfun, N_SLINE, addr - info->eip_fn_addr);
f0100c12:	2b 7b 10             	sub    0x10(%ebx),%edi
f0100c15:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c19:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100c20:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c23:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c26:	b8 30 22 10 f0       	mov    $0xf0102230,%eax
f0100c2b:	e8 c7 fd ff ff       	call   f01009f7 <stab_binsearch>

    	if (lfun <= rfun)
f0100c30:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100c33:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c36:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100c39:	39 c1                	cmp    %eax,%ecx
f0100c3b:	7f 0d                	jg     f0100c4a <debuginfo_eip+0x176>
    	{
        	info->eip_line = stabs[lfun].n_desc;
f0100c3d:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100c40:	0f b7 80 36 22 10 f0 	movzwl -0xfefddca(%eax),%eax
f0100c47:	89 43 04             	mov    %eax,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c4a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c4d:	89 45 d0             	mov    %eax,-0x30(%ebp)
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100c50:	6b c6 0c             	imul   $0xc,%esi,%eax
f0100c53:	05 30 22 10 f0       	add    $0xf0102230,%eax
f0100c58:	eb 06                	jmp    f0100c60 <debuginfo_eip+0x18c>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c5a:	83 ee 01             	sub    $0x1,%esi
f0100c5d:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100c60:	3b 75 d0             	cmp    -0x30(%ebp),%esi
f0100c63:	7c 33                	jl     f0100c98 <debuginfo_eip+0x1c4>
	       && stabs[lline].n_type != N_SOL
f0100c65:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0100c69:	80 fa 84             	cmp    $0x84,%dl
f0100c6c:	74 0b                	je     f0100c79 <debuginfo_eip+0x1a5>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c6e:	80 fa 64             	cmp    $0x64,%dl
f0100c71:	75 e7                	jne    f0100c5a <debuginfo_eip+0x186>
f0100c73:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c77:	74 e1                	je     f0100c5a <debuginfo_eip+0x186>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c79:	6b f6 0c             	imul   $0xc,%esi,%esi
f0100c7c:	8b 86 30 22 10 f0    	mov    -0xfefddd0(%esi),%eax
f0100c82:	ba b4 76 10 f0       	mov    $0xf01076b4,%edx
f0100c87:	81 ea 7d 5d 10 f0    	sub    $0xf0105d7d,%edx
f0100c8d:	39 d0                	cmp    %edx,%eax
f0100c8f:	73 07                	jae    f0100c98 <debuginfo_eip+0x1c4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c91:	05 7d 5d 10 f0       	add    $0xf0105d7d,%eax
f0100c96:	89 03                	mov    %eax,(%ebx)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100c98:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100c9d:	3b 4d d4             	cmp    -0x2c(%ebp),%ecx
f0100ca0:	7d 43                	jge    f0100ce5 <debuginfo_eip+0x211>
		for (lline = lfun + 1;
f0100ca2:	8d 51 01             	lea    0x1(%ecx),%edx
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0100ca5:	6b c1 0c             	imul   $0xc,%ecx,%eax
f0100ca8:	05 30 22 10 f0       	add    $0xf0102230,%eax
		for (lline = lfun + 1;
f0100cad:	eb 07                	jmp    f0100cb6 <debuginfo_eip+0x1e2>
			info->eip_fn_narg++;
f0100caf:	83 43 14 01          	addl   $0x1,0x14(%ebx)
		     lline++)
f0100cb3:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100cb6:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100cb9:	74 25                	je     f0100ce0 <debuginfo_eip+0x20c>
f0100cbb:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100cbe:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f0100cc2:	74 eb                	je     f0100caf <debuginfo_eip+0x1db>
	return 0;
f0100cc4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cc9:	eb 1a                	jmp    f0100ce5 <debuginfo_eip+0x211>
		return -1;
f0100ccb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd0:	eb 13                	jmp    f0100ce5 <debuginfo_eip+0x211>
f0100cd2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cd7:	eb 0c                	jmp    f0100ce5 <debuginfo_eip+0x211>
		return -1;
f0100cd9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100cde:	eb 05                	jmp    f0100ce5 <debuginfo_eip+0x211>
	return 0;
f0100ce0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100ce5:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100ce8:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100ceb:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100cee:	89 ec                	mov    %ebp,%esp
f0100cf0:	5d                   	pop    %ebp
f0100cf1:	c3                   	ret    
f0100cf2:	66 90                	xchg   %ax,%ax
f0100cf4:	66 90                	xchg   %ax,%ax
f0100cf6:	66 90                	xchg   %ax,%ax
f0100cf8:	66 90                	xchg   %ax,%ax
f0100cfa:	66 90                	xchg   %ax,%ax
f0100cfc:	66 90                	xchg   %ax,%ax
f0100cfe:	66 90                	xchg   %ax,%ax

f0100d00 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d00:	55                   	push   %ebp
f0100d01:	89 e5                	mov    %esp,%ebp
f0100d03:	57                   	push   %edi
f0100d04:	56                   	push   %esi
f0100d05:	53                   	push   %ebx
f0100d06:	83 ec 4c             	sub    $0x4c,%esp
f0100d09:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100d0c:	89 d7                	mov    %edx,%edi
f0100d0e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100d11:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f0100d14:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100d17:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100d1a:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d1d:	85 db                	test   %ebx,%ebx
f0100d1f:	75 08                	jne    f0100d29 <printnum+0x29>
f0100d21:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100d24:	39 5d 10             	cmp    %ebx,0x10(%ebp)
f0100d27:	77 6c                	ja     f0100d95 <printnum+0x95>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100d29:	8b 5d 18             	mov    0x18(%ebp),%ebx
f0100d2c:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0100d30:	83 ee 01             	sub    $0x1,%esi
f0100d33:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d37:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100d3a:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100d3e:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100d42:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100d46:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100d49:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100d4c:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d53:	00 
f0100d54:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100d57:	89 1c 24             	mov    %ebx,(%esp)
f0100d5a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100d5d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100d61:	e8 fa 09 00 00       	call   f0101760 <__udivdi3>
f0100d66:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0100d69:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d6c:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100d70:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d74:	89 04 24             	mov    %eax,(%esp)
f0100d77:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d7b:	89 fa                	mov    %edi,%edx
f0100d7d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d80:	e8 7b ff ff ff       	call   f0100d00 <printnum>
f0100d85:	eb 1b                	jmp    f0100da2 <printnum+0xa2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d87:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d8b:	8b 45 18             	mov    0x18(%ebp),%eax
f0100d8e:	89 04 24             	mov    %eax,(%esp)
f0100d91:	ff d3                	call   *%ebx
f0100d93:	eb 03                	jmp    f0100d98 <printnum+0x98>
f0100d95:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
		while (--width > 0)
f0100d98:	83 ee 01             	sub    $0x1,%esi
f0100d9b:	85 f6                	test   %esi,%esi
f0100d9d:	7f e8                	jg     f0100d87 <printnum+0x87>
f0100d9f:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100da2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100da6:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100daa:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100dad:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100db1:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100db8:	00 
f0100db9:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0100dbc:	89 1c 24             	mov    %ebx,(%esp)
f0100dbf:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100dc2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100dc6:	e8 e5 0a 00 00       	call   f01018b0 <__umoddi3>
f0100dcb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dcf:	0f be 80 09 20 10 f0 	movsbl -0xfefdff7(%eax),%eax
f0100dd6:	89 04 24             	mov    %eax,(%esp)
f0100dd9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100ddc:	ff d0                	call   *%eax
}
f0100dde:	83 c4 4c             	add    $0x4c,%esp
f0100de1:	5b                   	pop    %ebx
f0100de2:	5e                   	pop    %esi
f0100de3:	5f                   	pop    %edi
f0100de4:	5d                   	pop    %ebp
f0100de5:	c3                   	ret    

f0100de6 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100de6:	55                   	push   %ebp
f0100de7:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100de9:	83 fa 01             	cmp    $0x1,%edx
f0100dec:	7e 0e                	jle    f0100dfc <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100dee:	8b 10                	mov    (%eax),%edx
f0100df0:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100df3:	89 08                	mov    %ecx,(%eax)
f0100df5:	8b 02                	mov    (%edx),%eax
f0100df7:	8b 52 04             	mov    0x4(%edx),%edx
f0100dfa:	eb 22                	jmp    f0100e1e <getuint+0x38>
	else if (lflag)
f0100dfc:	85 d2                	test   %edx,%edx
f0100dfe:	74 10                	je     f0100e10 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100e00:	8b 10                	mov    (%eax),%edx
f0100e02:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e05:	89 08                	mov    %ecx,(%eax)
f0100e07:	8b 02                	mov    (%edx),%eax
f0100e09:	ba 00 00 00 00       	mov    $0x0,%edx
f0100e0e:	eb 0e                	jmp    f0100e1e <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100e10:	8b 10                	mov    (%eax),%edx
f0100e12:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100e15:	89 08                	mov    %ecx,(%eax)
f0100e17:	8b 02                	mov    (%edx),%eax
f0100e19:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100e1e:	5d                   	pop    %ebp
f0100e1f:	c3                   	ret    

f0100e20 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e20:	55                   	push   %ebp
f0100e21:	89 e5                	mov    %esp,%ebp
f0100e23:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e26:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e2a:	8b 10                	mov    (%eax),%edx
f0100e2c:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e2f:	73 0a                	jae    f0100e3b <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e31:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100e34:	88 0a                	mov    %cl,(%edx)
f0100e36:	83 c2 01             	add    $0x1,%edx
f0100e39:	89 10                	mov    %edx,(%eax)
}
f0100e3b:	5d                   	pop    %ebp
f0100e3c:	c3                   	ret    

f0100e3d <printfmt>:
{
f0100e3d:	55                   	push   %ebp
f0100e3e:	89 e5                	mov    %esp,%ebp
f0100e40:	83 ec 18             	sub    $0x18,%esp
	va_start(ap, fmt);
f0100e43:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e46:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e4a:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e4d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e51:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e58:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e5b:	89 04 24             	mov    %eax,(%esp)
f0100e5e:	e8 02 00 00 00       	call   f0100e65 <vprintfmt>
}
f0100e63:	c9                   	leave  
f0100e64:	c3                   	ret    

f0100e65 <vprintfmt>:
{
f0100e65:	55                   	push   %ebp
f0100e66:	89 e5                	mov    %esp,%ebp
f0100e68:	57                   	push   %edi
f0100e69:	56                   	push   %esi
f0100e6a:	53                   	push   %ebx
f0100e6b:	83 ec 4c             	sub    $0x4c,%esp
f0100e6e:	8b 75 08             	mov    0x8(%ebp),%esi
f0100e71:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e74:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e77:	eb 11                	jmp    f0100e8a <vprintfmt+0x25>
			if (ch == '\0')
f0100e79:	85 c0                	test   %eax,%eax
f0100e7b:	0f 84 cf 03 00 00    	je     f0101250 <vprintfmt+0x3eb>
			putch(ch, putdat);
f0100e81:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e85:	89 04 24             	mov    %eax,(%esp)
f0100e88:	ff d6                	call   *%esi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e8a:	0f b6 07             	movzbl (%edi),%eax
f0100e8d:	83 c7 01             	add    $0x1,%edi
f0100e90:	83 f8 25             	cmp    $0x25,%eax
f0100e93:	75 e4                	jne    f0100e79 <vprintfmt+0x14>
f0100e95:	c6 45 e4 20          	movb   $0x20,-0x1c(%ebp)
f0100e99:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100ea0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0100ea7:	c7 45 d8 ff ff ff ff 	movl   $0xffffffff,-0x28(%ebp)
f0100eae:	ba 00 00 00 00       	mov    $0x0,%edx
f0100eb3:	eb 2b                	jmp    f0100ee0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0100eb5:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '-';
f0100eb8:	c6 45 e4 2d          	movb   $0x2d,-0x1c(%ebp)
f0100ebc:	eb 22                	jmp    f0100ee0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0100ebe:	8b 7d e0             	mov    -0x20(%ebp),%edi
			padc = '0';
f0100ec1:	c6 45 e4 30          	movb   $0x30,-0x1c(%ebp)
f0100ec5:	eb 19                	jmp    f0100ee0 <vprintfmt+0x7b>
		switch (ch = *(unsigned char *) fmt++) {
f0100ec7:	8b 7d e0             	mov    -0x20(%ebp),%edi
				width = 0;
f0100eca:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0100ed1:	eb 0d                	jmp    f0100ee0 <vprintfmt+0x7b>
				width = precision, precision = -1;
f0100ed3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ed6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100ed9:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100ee0:	0f b6 07             	movzbl (%edi),%eax
f0100ee3:	8d 4f 01             	lea    0x1(%edi),%ecx
f0100ee6:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100ee9:	0f b6 0f             	movzbl (%edi),%ecx
f0100eec:	83 e9 23             	sub    $0x23,%ecx
f0100eef:	80 f9 55             	cmp    $0x55,%cl
f0100ef2:	0f 87 3b 03 00 00    	ja     f0101233 <vprintfmt+0x3ce>
f0100ef8:	0f b6 c9             	movzbl %cl,%ecx
f0100efb:	ff 24 8d a0 20 10 f0 	jmp    *-0xfefdf60(,%ecx,4)
f0100f02:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100f05:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100f0c:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f0f:	ba 00 00 00 00       	mov    $0x0,%edx
				precision = precision * 10 + ch - '0';
f0100f14:	8d 14 92             	lea    (%edx,%edx,4),%edx
f0100f17:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f0100f1b:	0f be 07             	movsbl (%edi),%eax
				if (ch < '0' || ch > '9')
f0100f1e:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100f21:	83 f9 09             	cmp    $0x9,%ecx
f0100f24:	77 2f                	ja     f0100f55 <vprintfmt+0xf0>
			for (precision = 0; ; ++fmt) {
f0100f26:	83 c7 01             	add    $0x1,%edi
			}
f0100f29:	eb e9                	jmp    f0100f14 <vprintfmt+0xaf>
			precision = va_arg(ap, int);
f0100f2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2e:	8d 48 04             	lea    0x4(%eax),%ecx
f0100f31:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100f34:	8b 00                	mov    (%eax),%eax
f0100f36:	89 45 dc             	mov    %eax,-0x24(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f39:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto process_precision;
f0100f3c:	eb 1d                	jmp    f0100f5b <vprintfmt+0xf6>
			if (width < 0)
f0100f3e:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f42:	78 83                	js     f0100ec7 <vprintfmt+0x62>
		switch (ch = *(unsigned char *) fmt++) {
f0100f44:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100f47:	eb 97                	jmp    f0100ee0 <vprintfmt+0x7b>
f0100f49:	8b 7d e0             	mov    -0x20(%ebp),%edi
			altflag = 1;
f0100f4c:	c7 45 d0 01 00 00 00 	movl   $0x1,-0x30(%ebp)
			goto reswitch;
f0100f53:	eb 8b                	jmp    f0100ee0 <vprintfmt+0x7b>
f0100f55:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0100f58:	8b 55 e0             	mov    -0x20(%ebp),%edx
			if (width < 0)
f0100f5b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0100f5f:	0f 89 7b ff ff ff    	jns    f0100ee0 <vprintfmt+0x7b>
f0100f65:	e9 69 ff ff ff       	jmp    f0100ed3 <vprintfmt+0x6e>
			lflag++;
f0100f6a:	83 c2 01             	add    $0x1,%edx
		switch (ch = *(unsigned char *) fmt++) {
f0100f6d:	8b 7d e0             	mov    -0x20(%ebp),%edi
			goto reswitch;
f0100f70:	e9 6b ff ff ff       	jmp    f0100ee0 <vprintfmt+0x7b>
			putch(va_arg(ap, int), putdat);
f0100f75:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f78:	8d 50 04             	lea    0x4(%eax),%edx
f0100f7b:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f7e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f82:	8b 00                	mov    (%eax),%eax
f0100f84:	89 04 24             	mov    %eax,(%esp)
f0100f87:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f0100f89:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f0100f8c:	e9 f9 fe ff ff       	jmp    f0100e8a <vprintfmt+0x25>
			err = va_arg(ap, int);
f0100f91:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f94:	8d 50 04             	lea    0x4(%eax),%edx
f0100f97:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f9a:	8b 00                	mov    (%eax),%eax
f0100f9c:	89 c2                	mov    %eax,%edx
f0100f9e:	c1 fa 1f             	sar    $0x1f,%edx
f0100fa1:	31 d0                	xor    %edx,%eax
f0100fa3:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fa5:	83 f8 07             	cmp    $0x7,%eax
f0100fa8:	7f 0b                	jg     f0100fb5 <vprintfmt+0x150>
f0100faa:	8b 14 85 00 22 10 f0 	mov    -0xfefde00(,%eax,4),%edx
f0100fb1:	85 d2                	test   %edx,%edx
f0100fb3:	75 20                	jne    f0100fd5 <vprintfmt+0x170>
				printfmt(putch, putdat, "error %d", err);
f0100fb5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fb9:	c7 44 24 08 21 20 10 	movl   $0xf0102021,0x8(%esp)
f0100fc0:	f0 
f0100fc1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fc5:	89 34 24             	mov    %esi,(%esp)
f0100fc8:	e8 70 fe ff ff       	call   f0100e3d <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f0100fcd:	8b 7d e0             	mov    -0x20(%ebp),%edi
				printfmt(putch, putdat, "error %d", err);
f0100fd0:	e9 b5 fe ff ff       	jmp    f0100e8a <vprintfmt+0x25>
				printfmt(putch, putdat, "%s", p);
f0100fd5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100fd9:	c7 44 24 08 2a 20 10 	movl   $0xf010202a,0x8(%esp)
f0100fe0:	f0 
f0100fe1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fe5:	89 34 24             	mov    %esi,(%esp)
f0100fe8:	e8 50 fe ff ff       	call   f0100e3d <printfmt>
		switch (ch = *(unsigned char *) fmt++) {
f0100fed:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100ff0:	e9 95 fe ff ff       	jmp    f0100e8a <vprintfmt+0x25>
f0100ff5:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100ff8:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0100ffb:	89 7d cc             	mov    %edi,-0x34(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
f0100ffe:	8b 45 14             	mov    0x14(%ebp),%eax
f0101001:	8d 50 04             	lea    0x4(%eax),%edx
f0101004:	89 55 14             	mov    %edx,0x14(%ebp)
f0101007:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101009:	85 ff                	test   %edi,%edi
f010100b:	b8 1a 20 10 f0       	mov    $0xf010201a,%eax
f0101010:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0101013:	80 7d e4 2d          	cmpb   $0x2d,-0x1c(%ebp)
f0101017:	0f 84 9b 00 00 00    	je     f01010b8 <vprintfmt+0x253>
f010101d:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0101021:	0f 8e 9f 00 00 00    	jle    f01010c6 <vprintfmt+0x261>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101027:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010102b:	89 3c 24             	mov    %edi,(%esp)
f010102e:	e8 95 03 00 00       	call   f01013c8 <strnlen>
f0101033:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0101036:	29 c2                	sub    %eax,%edx
f0101038:	89 55 d8             	mov    %edx,-0x28(%ebp)
					putch(padc, putdat);
f010103b:	0f be 4d e4          	movsbl -0x1c(%ebp),%ecx
f010103f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101042:	89 7d c8             	mov    %edi,-0x38(%ebp)
f0101045:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101047:	eb 0f                	jmp    f0101058 <vprintfmt+0x1f3>
					putch(padc, putdat);
f0101049:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010104d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101050:	89 04 24             	mov    %eax,(%esp)
f0101053:	ff d6                	call   *%esi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101055:	83 ef 01             	sub    $0x1,%edi
f0101058:	85 ff                	test   %edi,%edi
f010105a:	7f ed                	jg     f0101049 <vprintfmt+0x1e4>
f010105c:	8b 7d c8             	mov    -0x38(%ebp),%edi
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f010105f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101063:	b8 00 00 00 00       	mov    $0x0,%eax
f0101068:	0f 49 45 d8          	cmovns -0x28(%ebp),%eax
f010106c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010106f:	29 c2                	sub    %eax,%edx
f0101071:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101074:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0101077:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f010107a:	89 d3                	mov    %edx,%ebx
f010107c:	eb 54                	jmp    f01010d2 <vprintfmt+0x26d>
				if (altflag && (ch < ' ' || ch > '~'))
f010107e:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0101082:	74 20                	je     f01010a4 <vprintfmt+0x23f>
f0101084:	0f be d2             	movsbl %dl,%edx
f0101087:	83 ea 20             	sub    $0x20,%edx
f010108a:	83 fa 5e             	cmp    $0x5e,%edx
f010108d:	76 15                	jbe    f01010a4 <vprintfmt+0x23f>
					putch('?', putdat);
f010108f:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0101092:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101096:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010109d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010a0:	ff d0                	call   *%eax
f01010a2:	eb 0f                	jmp    f01010b3 <vprintfmt+0x24e>
					putch(ch, putdat);
f01010a4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010a7:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010ab:	89 04 24             	mov    %eax,(%esp)
f01010ae:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01010b1:	ff d1                	call   *%ecx
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01010b3:	83 eb 01             	sub    $0x1,%ebx
f01010b6:	eb 1a                	jmp    f01010d2 <vprintfmt+0x26d>
f01010b8:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01010bb:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01010be:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01010c1:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01010c4:	eb 0c                	jmp    f01010d2 <vprintfmt+0x26d>
f01010c6:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f01010c9:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01010cc:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01010cf:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01010d2:	0f b6 17             	movzbl (%edi),%edx
f01010d5:	0f be c2             	movsbl %dl,%eax
f01010d8:	83 c7 01             	add    $0x1,%edi
f01010db:	85 c0                	test   %eax,%eax
f01010dd:	74 29                	je     f0101108 <vprintfmt+0x2a3>
f01010df:	85 f6                	test   %esi,%esi
f01010e1:	78 9b                	js     f010107e <vprintfmt+0x219>
f01010e3:	83 ee 01             	sub    $0x1,%esi
f01010e6:	79 96                	jns    f010107e <vprintfmt+0x219>
f01010e8:	89 5d d8             	mov    %ebx,-0x28(%ebp)
f01010eb:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01010ee:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f01010f1:	8b 7d d8             	mov    -0x28(%ebp),%edi
f01010f4:	eb 1a                	jmp    f0101110 <vprintfmt+0x2ab>
				putch(' ', putdat);
f01010f6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010fa:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101101:	ff d6                	call   *%esi
			for (; width > 0; width--)
f0101103:	83 ef 01             	sub    $0x1,%edi
f0101106:	eb 08                	jmp    f0101110 <vprintfmt+0x2ab>
f0101108:	89 df                	mov    %ebx,%edi
f010110a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010110d:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0101110:	85 ff                	test   %edi,%edi
f0101112:	7f e2                	jg     f01010f6 <vprintfmt+0x291>
		switch (ch = *(unsigned char *) fmt++) {
f0101114:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101117:	e9 6e fd ff ff       	jmp    f0100e8a <vprintfmt+0x25>
	if (lflag >= 2)
f010111c:	83 fa 01             	cmp    $0x1,%edx
f010111f:	7e 16                	jle    f0101137 <vprintfmt+0x2d2>
		return va_arg(*ap, long long);
f0101121:	8b 45 14             	mov    0x14(%ebp),%eax
f0101124:	8d 50 08             	lea    0x8(%eax),%edx
f0101127:	89 55 14             	mov    %edx,0x14(%ebp)
f010112a:	8b 10                	mov    (%eax),%edx
f010112c:	8b 48 04             	mov    0x4(%eax),%ecx
f010112f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101132:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101135:	eb 32                	jmp    f0101169 <vprintfmt+0x304>
	else if (lflag)
f0101137:	85 d2                	test   %edx,%edx
f0101139:	74 18                	je     f0101153 <vprintfmt+0x2ee>
		return va_arg(*ap, long);
f010113b:	8b 45 14             	mov    0x14(%ebp),%eax
f010113e:	8d 50 04             	lea    0x4(%eax),%edx
f0101141:	89 55 14             	mov    %edx,0x14(%ebp)
f0101144:	8b 00                	mov    (%eax),%eax
f0101146:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101149:	89 c1                	mov    %eax,%ecx
f010114b:	c1 f9 1f             	sar    $0x1f,%ecx
f010114e:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101151:	eb 16                	jmp    f0101169 <vprintfmt+0x304>
		return va_arg(*ap, int);
f0101153:	8b 45 14             	mov    0x14(%ebp),%eax
f0101156:	8d 50 04             	lea    0x4(%eax),%edx
f0101159:	89 55 14             	mov    %edx,0x14(%ebp)
f010115c:	8b 00                	mov    (%eax),%eax
f010115e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101161:	89 c7                	mov    %eax,%edi
f0101163:	c1 ff 1f             	sar    $0x1f,%edi
f0101166:	89 7d d4             	mov    %edi,-0x2c(%ebp)
			num = getint(&ap, lflag);
f0101169:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010116c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
			base = 10;
f010116f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			if ((long long) num < 0) {
f0101174:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101178:	79 7d                	jns    f01011f7 <vprintfmt+0x392>
				putch('-', putdat);
f010117a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010117e:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101185:	ff d6                	call   *%esi
				num = -(long long) num;
f0101187:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010118a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010118d:	f7 d8                	neg    %eax
f010118f:	83 d2 00             	adc    $0x0,%edx
f0101192:	f7 da                	neg    %edx
			base = 10;
f0101194:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0101199:	eb 5c                	jmp    f01011f7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f010119b:	8d 45 14             	lea    0x14(%ebp),%eax
f010119e:	e8 43 fc ff ff       	call   f0100de6 <getuint>
			base = 10;
f01011a3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01011a8:	eb 4d                	jmp    f01011f7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f01011aa:	8d 45 14             	lea    0x14(%ebp),%eax
f01011ad:	e8 34 fc ff ff       	call   f0100de6 <getuint>
    			base = 8;
f01011b2:	b9 08 00 00 00       	mov    $0x8,%ecx
    			goto number;
f01011b7:	eb 3e                	jmp    f01011f7 <vprintfmt+0x392>
			putch('0', putdat);
f01011b9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011bd:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01011c4:	ff d6                	call   *%esi
			putch('x', putdat);
f01011c6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ca:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01011d1:	ff d6                	call   *%esi
				(uintptr_t) va_arg(ap, void *);
f01011d3:	8b 45 14             	mov    0x14(%ebp),%eax
f01011d6:	8d 50 04             	lea    0x4(%eax),%edx
f01011d9:	89 55 14             	mov    %edx,0x14(%ebp)
			num = (unsigned long long)
f01011dc:	8b 00                	mov    (%eax),%eax
f01011de:	ba 00 00 00 00       	mov    $0x0,%edx
			base = 16;
f01011e3:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01011e8:	eb 0d                	jmp    f01011f7 <vprintfmt+0x392>
			num = getuint(&ap, lflag);
f01011ea:	8d 45 14             	lea    0x14(%ebp),%eax
f01011ed:	e8 f4 fb ff ff       	call   f0100de6 <getuint>
			base = 16;
f01011f2:	b9 10 00 00 00       	mov    $0x10,%ecx
			printnum(putch, putdat, num, base, width, padc);
f01011f7:	0f be 7d e4          	movsbl -0x1c(%ebp),%edi
f01011fb:	89 7c 24 10          	mov    %edi,0x10(%esp)
f01011ff:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0101202:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101206:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010120a:	89 04 24             	mov    %eax,(%esp)
f010120d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101211:	89 da                	mov    %ebx,%edx
f0101213:	89 f0                	mov    %esi,%eax
f0101215:	e8 e6 fa ff ff       	call   f0100d00 <printnum>
			break;
f010121a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010121d:	e9 68 fc ff ff       	jmp    f0100e8a <vprintfmt+0x25>
			putch(ch, putdat);
f0101222:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101226:	89 04 24             	mov    %eax,(%esp)
f0101229:	ff d6                	call   *%esi
		switch (ch = *(unsigned char *) fmt++) {
f010122b:	8b 7d e0             	mov    -0x20(%ebp),%edi
			break;
f010122e:	e9 57 fc ff ff       	jmp    f0100e8a <vprintfmt+0x25>
			putch('%', putdat);
f0101233:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101237:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f010123e:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101240:	eb 03                	jmp    f0101245 <vprintfmt+0x3e0>
f0101242:	83 ef 01             	sub    $0x1,%edi
f0101245:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0101249:	75 f7                	jne    f0101242 <vprintfmt+0x3dd>
f010124b:	e9 3a fc ff ff       	jmp    f0100e8a <vprintfmt+0x25>
}
f0101250:	83 c4 4c             	add    $0x4c,%esp
f0101253:	5b                   	pop    %ebx
f0101254:	5e                   	pop    %esi
f0101255:	5f                   	pop    %edi
f0101256:	5d                   	pop    %ebp
f0101257:	c3                   	ret    

f0101258 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101258:	55                   	push   %ebp
f0101259:	89 e5                	mov    %esp,%ebp
f010125b:	83 ec 28             	sub    $0x28,%esp
f010125e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101261:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101264:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101267:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010126b:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010126e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101275:	85 d2                	test   %edx,%edx
f0101277:	7e 30                	jle    f01012a9 <vsnprintf+0x51>
f0101279:	85 c0                	test   %eax,%eax
f010127b:	74 2c                	je     f01012a9 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010127d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101280:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101284:	8b 45 10             	mov    0x10(%ebp),%eax
f0101287:	89 44 24 08          	mov    %eax,0x8(%esp)
f010128b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010128e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101292:	c7 04 24 20 0e 10 f0 	movl   $0xf0100e20,(%esp)
f0101299:	e8 c7 fb ff ff       	call   f0100e65 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010129e:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01012a1:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01012a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012a7:	eb 05                	jmp    f01012ae <vsnprintf+0x56>
		return -E_INVAL;
f01012a9:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
}
f01012ae:	c9                   	leave  
f01012af:	c3                   	ret    

f01012b0 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01012b0:	55                   	push   %ebp
f01012b1:	89 e5                	mov    %esp,%ebp
f01012b3:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01012b6:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01012b9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012bd:	8b 45 10             	mov    0x10(%ebp),%eax
f01012c0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ce:	89 04 24             	mov    %eax,(%esp)
f01012d1:	e8 82 ff ff ff       	call   f0101258 <vsnprintf>
	va_end(ap);

	return rc;
}
f01012d6:	c9                   	leave  
f01012d7:	c3                   	ret    
f01012d8:	66 90                	xchg   %ax,%ax
f01012da:	66 90                	xchg   %ax,%ax
f01012dc:	66 90                	xchg   %ax,%ax
f01012de:	66 90                	xchg   %ax,%ax

f01012e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01012e0:	55                   	push   %ebp
f01012e1:	89 e5                	mov    %esp,%ebp
f01012e3:	57                   	push   %edi
f01012e4:	56                   	push   %esi
f01012e5:	53                   	push   %ebx
f01012e6:	83 ec 1c             	sub    $0x1c,%esp
f01012e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01012ec:	85 c0                	test   %eax,%eax
f01012ee:	74 10                	je     f0101300 <readline+0x20>
		cprintf("%s", prompt);
f01012f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f4:	c7 04 24 2a 20 10 f0 	movl   $0xf010202a,(%esp)
f01012fb:	e8 dd f6 ff ff       	call   f01009dd <cprintf>

	i = 0;
	echoing = iscons(0);
f0101300:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101307:	e8 64 f3 ff ff       	call   f0100670 <iscons>
f010130c:	89 c7                	mov    %eax,%edi
	i = 0;
f010130e:	be 00 00 00 00       	mov    $0x0,%esi
	while (1) {
		c = getchar();
f0101313:	e8 47 f3 ff ff       	call   f010065f <getchar>
f0101318:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010131a:	85 c0                	test   %eax,%eax
f010131c:	79 17                	jns    f0101335 <readline+0x55>
			cprintf("read error: %e\n", c);
f010131e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101322:	c7 04 24 20 22 10 f0 	movl   $0xf0102220,(%esp)
f0101329:	e8 af f6 ff ff       	call   f01009dd <cprintf>
			return NULL;
f010132e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101333:	eb 6d                	jmp    f01013a2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101335:	83 f8 7f             	cmp    $0x7f,%eax
f0101338:	74 05                	je     f010133f <readline+0x5f>
f010133a:	83 f8 08             	cmp    $0x8,%eax
f010133d:	75 19                	jne    f0101358 <readline+0x78>
f010133f:	85 f6                	test   %esi,%esi
f0101341:	7e 15                	jle    f0101358 <readline+0x78>
			if (echoing)
f0101343:	85 ff                	test   %edi,%edi
f0101345:	74 0c                	je     f0101353 <readline+0x73>
				cputchar('\b');
f0101347:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010134e:	e8 fc f2 ff ff       	call   f010064f <cputchar>
			i--;
f0101353:	83 ee 01             	sub    $0x1,%esi
f0101356:	eb bb                	jmp    f0101313 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101358:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010135e:	7f 1c                	jg     f010137c <readline+0x9c>
f0101360:	83 fb 1f             	cmp    $0x1f,%ebx
f0101363:	7e 17                	jle    f010137c <readline+0x9c>
			if (echoing)
f0101365:	85 ff                	test   %edi,%edi
f0101367:	74 08                	je     f0101371 <readline+0x91>
				cputchar(c);
f0101369:	89 1c 24             	mov    %ebx,(%esp)
f010136c:	e8 de f2 ff ff       	call   f010064f <cputchar>
			buf[i++] = c;
f0101371:	88 9e 40 25 11 f0    	mov    %bl,-0xfeedac0(%esi)
f0101377:	83 c6 01             	add    $0x1,%esi
f010137a:	eb 97                	jmp    f0101313 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010137c:	83 fb 0d             	cmp    $0xd,%ebx
f010137f:	74 05                	je     f0101386 <readline+0xa6>
f0101381:	83 fb 0a             	cmp    $0xa,%ebx
f0101384:	75 8d                	jne    f0101313 <readline+0x33>
			if (echoing)
f0101386:	85 ff                	test   %edi,%edi
f0101388:	74 0c                	je     f0101396 <readline+0xb6>
				cputchar('\n');
f010138a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101391:	e8 b9 f2 ff ff       	call   f010064f <cputchar>
			buf[i] = 0;
f0101396:	c6 86 40 25 11 f0 00 	movb   $0x0,-0xfeedac0(%esi)
			return buf;
f010139d:	b8 40 25 11 f0       	mov    $0xf0112540,%eax
		}
	}
}
f01013a2:	83 c4 1c             	add    $0x1c,%esp
f01013a5:	5b                   	pop    %ebx
f01013a6:	5e                   	pop    %esi
f01013a7:	5f                   	pop    %edi
f01013a8:	5d                   	pop    %ebp
f01013a9:	c3                   	ret    
f01013aa:	66 90                	xchg   %ax,%ax
f01013ac:	66 90                	xchg   %ax,%ax
f01013ae:	66 90                	xchg   %ax,%ax

f01013b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01013b0:	55                   	push   %ebp
f01013b1:	89 e5                	mov    %esp,%ebp
f01013b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01013b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01013bb:	eb 03                	jmp    f01013c0 <strlen+0x10>
		n++;
f01013bd:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01013c0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01013c4:	75 f7                	jne    f01013bd <strlen+0xd>
	return n;
}
f01013c6:	5d                   	pop    %ebp
f01013c7:	c3                   	ret    

f01013c8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01013c8:	55                   	push   %ebp
f01013c9:	89 e5                	mov    %esp,%ebp
f01013cb:	8b 4d 08             	mov    0x8(%ebp),%ecx
strnlen(const char *s, size_t size)
f01013ce:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013d1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013d6:	eb 03                	jmp    f01013db <strnlen+0x13>
		n++;
f01013d8:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01013db:	39 d0                	cmp    %edx,%eax
f01013dd:	74 06                	je     f01013e5 <strnlen+0x1d>
f01013df:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01013e3:	75 f3                	jne    f01013d8 <strnlen+0x10>
	return n;
}
f01013e5:	5d                   	pop    %ebp
f01013e6:	c3                   	ret    

f01013e7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01013e7:	55                   	push   %ebp
f01013e8:	89 e5                	mov    %esp,%ebp
f01013ea:	53                   	push   %ebx
f01013eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ee:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01013f1:	89 c2                	mov    %eax,%edx
f01013f3:	0f b6 19             	movzbl (%ecx),%ebx
f01013f6:	88 1a                	mov    %bl,(%edx)
f01013f8:	83 c2 01             	add    $0x1,%edx
f01013fb:	83 c1 01             	add    $0x1,%ecx
f01013fe:	84 db                	test   %bl,%bl
f0101400:	75 f1                	jne    f01013f3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101402:	5b                   	pop    %ebx
f0101403:	5d                   	pop    %ebp
f0101404:	c3                   	ret    

f0101405 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0101405:	55                   	push   %ebp
f0101406:	89 e5                	mov    %esp,%ebp
f0101408:	53                   	push   %ebx
f0101409:	83 ec 08             	sub    $0x8,%esp
f010140c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010140f:	89 1c 24             	mov    %ebx,(%esp)
f0101412:	e8 99 ff ff ff       	call   f01013b0 <strlen>
	strcpy(dst + len, src);
f0101417:	8b 55 0c             	mov    0xc(%ebp),%edx
f010141a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010141e:	01 d8                	add    %ebx,%eax
f0101420:	89 04 24             	mov    %eax,(%esp)
f0101423:	e8 bf ff ff ff       	call   f01013e7 <strcpy>
	return dst;
}
f0101428:	89 d8                	mov    %ebx,%eax
f010142a:	83 c4 08             	add    $0x8,%esp
f010142d:	5b                   	pop    %ebx
f010142e:	5d                   	pop    %ebp
f010142f:	c3                   	ret    

f0101430 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101430:	55                   	push   %ebp
f0101431:	89 e5                	mov    %esp,%ebp
f0101433:	56                   	push   %esi
f0101434:	53                   	push   %ebx
f0101435:	8b 75 08             	mov    0x8(%ebp),%esi
f0101438:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010143b:	89 f3                	mov    %esi,%ebx
f010143d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101440:	89 f2                	mov    %esi,%edx
f0101442:	eb 0e                	jmp    f0101452 <strncpy+0x22>
		*dst++ = *src;
f0101444:	0f b6 01             	movzbl (%ecx),%eax
f0101447:	88 02                	mov    %al,(%edx)
f0101449:	83 c2 01             	add    $0x1,%edx
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010144c:	80 39 01             	cmpb   $0x1,(%ecx)
f010144f:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101452:	39 da                	cmp    %ebx,%edx
f0101454:	75 ee                	jne    f0101444 <strncpy+0x14>
	}
	return ret;
}
f0101456:	89 f0                	mov    %esi,%eax
f0101458:	5b                   	pop    %ebx
f0101459:	5e                   	pop    %esi
f010145a:	5d                   	pop    %ebp
f010145b:	c3                   	ret    

f010145c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010145c:	55                   	push   %ebp
f010145d:	89 e5                	mov    %esp,%ebp
f010145f:	56                   	push   %esi
f0101460:	53                   	push   %ebx
f0101461:	8b 75 08             	mov    0x8(%ebp),%esi
f0101464:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101467:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010146a:	89 f0                	mov    %esi,%eax
strlcpy(char *dst, const char *src, size_t size)
f010146c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	if (size > 0) {
f0101470:	85 c9                	test   %ecx,%ecx
f0101472:	75 0a                	jne    f010147e <strlcpy+0x22>
f0101474:	eb 1c                	jmp    f0101492 <strlcpy+0x36>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101476:	88 08                	mov    %cl,(%eax)
f0101478:	83 c0 01             	add    $0x1,%eax
f010147b:	83 c2 01             	add    $0x1,%edx
		while (--size > 0 && *src != '\0')
f010147e:	39 d8                	cmp    %ebx,%eax
f0101480:	74 0b                	je     f010148d <strlcpy+0x31>
f0101482:	0f b6 0a             	movzbl (%edx),%ecx
f0101485:	84 c9                	test   %cl,%cl
f0101487:	75 ed                	jne    f0101476 <strlcpy+0x1a>
f0101489:	89 c2                	mov    %eax,%edx
f010148b:	eb 02                	jmp    f010148f <strlcpy+0x33>
f010148d:	89 c2                	mov    %eax,%edx
		*dst = '\0';
f010148f:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0101492:	29 f0                	sub    %esi,%eax
}
f0101494:	5b                   	pop    %ebx
f0101495:	5e                   	pop    %esi
f0101496:	5d                   	pop    %ebp
f0101497:	c3                   	ret    

f0101498 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101498:	55                   	push   %ebp
f0101499:	89 e5                	mov    %esp,%ebp
f010149b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010149e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01014a1:	eb 06                	jmp    f01014a9 <strcmp+0x11>
		p++, q++;
f01014a3:	83 c1 01             	add    $0x1,%ecx
f01014a6:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01014a9:	0f b6 01             	movzbl (%ecx),%eax
f01014ac:	84 c0                	test   %al,%al
f01014ae:	74 04                	je     f01014b4 <strcmp+0x1c>
f01014b0:	3a 02                	cmp    (%edx),%al
f01014b2:	74 ef                	je     f01014a3 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01014b4:	0f b6 c0             	movzbl %al,%eax
f01014b7:	0f b6 12             	movzbl (%edx),%edx
f01014ba:	29 d0                	sub    %edx,%eax
}
f01014bc:	5d                   	pop    %ebp
f01014bd:	c3                   	ret    

f01014be <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01014be:	55                   	push   %ebp
f01014bf:	89 e5                	mov    %esp,%ebp
f01014c1:	53                   	push   %ebx
f01014c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c5:	8b 55 0c             	mov    0xc(%ebp),%edx
strncmp(const char *p, const char *q, size_t n)
f01014c8:	89 c3                	mov    %eax,%ebx
f01014ca:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01014cd:	eb 06                	jmp    f01014d5 <strncmp+0x17>
		n--, p++, q++;
f01014cf:	83 c0 01             	add    $0x1,%eax
f01014d2:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01014d5:	39 d8                	cmp    %ebx,%eax
f01014d7:	74 15                	je     f01014ee <strncmp+0x30>
f01014d9:	0f b6 08             	movzbl (%eax),%ecx
f01014dc:	84 c9                	test   %cl,%cl
f01014de:	74 04                	je     f01014e4 <strncmp+0x26>
f01014e0:	3a 0a                	cmp    (%edx),%cl
f01014e2:	74 eb                	je     f01014cf <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01014e4:	0f b6 00             	movzbl (%eax),%eax
f01014e7:	0f b6 12             	movzbl (%edx),%edx
f01014ea:	29 d0                	sub    %edx,%eax
f01014ec:	eb 05                	jmp    f01014f3 <strncmp+0x35>
		return 0;
f01014ee:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014f3:	5b                   	pop    %ebx
f01014f4:	5d                   	pop    %ebp
f01014f5:	c3                   	ret    

f01014f6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01014f6:	55                   	push   %ebp
f01014f7:	89 e5                	mov    %esp,%ebp
f01014f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01014fc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101500:	eb 07                	jmp    f0101509 <strchr+0x13>
		if (*s == c)
f0101502:	38 ca                	cmp    %cl,%dl
f0101504:	74 0f                	je     f0101515 <strchr+0x1f>
	for (; *s; s++)
f0101506:	83 c0 01             	add    $0x1,%eax
f0101509:	0f b6 10             	movzbl (%eax),%edx
f010150c:	84 d2                	test   %dl,%dl
f010150e:	75 f2                	jne    f0101502 <strchr+0xc>
			return (char *) s;
	return 0;
f0101510:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101515:	5d                   	pop    %ebp
f0101516:	c3                   	ret    

f0101517 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101517:	55                   	push   %ebp
f0101518:	89 e5                	mov    %esp,%ebp
f010151a:	8b 45 08             	mov    0x8(%ebp),%eax
f010151d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101521:	eb 07                	jmp    f010152a <strfind+0x13>
		if (*s == c)
f0101523:	38 ca                	cmp    %cl,%dl
f0101525:	74 0a                	je     f0101531 <strfind+0x1a>
	for (; *s; s++)
f0101527:	83 c0 01             	add    $0x1,%eax
f010152a:	0f b6 10             	movzbl (%eax),%edx
f010152d:	84 d2                	test   %dl,%dl
f010152f:	75 f2                	jne    f0101523 <strfind+0xc>
			break;
	return (char *) s;
}
f0101531:	5d                   	pop    %ebp
f0101532:	c3                   	ret    

f0101533 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101533:	55                   	push   %ebp
f0101534:	89 e5                	mov    %esp,%ebp
f0101536:	83 ec 0c             	sub    $0xc,%esp
f0101539:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010153c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010153f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101542:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101545:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101548:	85 c9                	test   %ecx,%ecx
f010154a:	74 36                	je     f0101582 <memset+0x4f>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010154c:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101552:	75 28                	jne    f010157c <memset+0x49>
f0101554:	f6 c1 03             	test   $0x3,%cl
f0101557:	75 23                	jne    f010157c <memset+0x49>
		c &= 0xFF;
f0101559:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010155d:	89 d3                	mov    %edx,%ebx
f010155f:	c1 e3 08             	shl    $0x8,%ebx
f0101562:	89 d6                	mov    %edx,%esi
f0101564:	c1 e6 18             	shl    $0x18,%esi
f0101567:	89 d0                	mov    %edx,%eax
f0101569:	c1 e0 10             	shl    $0x10,%eax
f010156c:	09 f0                	or     %esi,%eax
f010156e:	09 c2                	or     %eax,%edx
f0101570:	89 d0                	mov    %edx,%eax
f0101572:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101574:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101577:	fc                   	cld    
f0101578:	f3 ab                	rep stos %eax,%es:(%edi)
f010157a:	eb 06                	jmp    f0101582 <memset+0x4f>
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010157c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010157f:	fc                   	cld    
f0101580:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101582:	89 f8                	mov    %edi,%eax
f0101584:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101587:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010158a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010158d:	89 ec                	mov    %ebp,%esp
f010158f:	5d                   	pop    %ebp
f0101590:	c3                   	ret    

f0101591 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101591:	55                   	push   %ebp
f0101592:	89 e5                	mov    %esp,%ebp
f0101594:	83 ec 08             	sub    $0x8,%esp
f0101597:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010159a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010159d:	8b 45 08             	mov    0x8(%ebp),%eax
f01015a0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015a3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01015a6:	39 c6                	cmp    %eax,%esi
f01015a8:	73 36                	jae    f01015e0 <memmove+0x4f>
f01015aa:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01015ad:	39 d0                	cmp    %edx,%eax
f01015af:	73 2f                	jae    f01015e0 <memmove+0x4f>
		s += n;
		d += n;
f01015b1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015b4:	f6 c2 03             	test   $0x3,%dl
f01015b7:	75 1b                	jne    f01015d4 <memmove+0x43>
f01015b9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01015bf:	75 13                	jne    f01015d4 <memmove+0x43>
f01015c1:	f6 c1 03             	test   $0x3,%cl
f01015c4:	75 0e                	jne    f01015d4 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01015c6:	83 ef 04             	sub    $0x4,%edi
f01015c9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01015cc:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01015cf:	fd                   	std    
f01015d0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015d2:	eb 09                	jmp    f01015dd <memmove+0x4c>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01015d4:	83 ef 01             	sub    $0x1,%edi
f01015d7:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01015da:	fd                   	std    
f01015db:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01015dd:	fc                   	cld    
f01015de:	eb 20                	jmp    f0101600 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015e0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015e6:	75 13                	jne    f01015fb <memmove+0x6a>
f01015e8:	a8 03                	test   $0x3,%al
f01015ea:	75 0f                	jne    f01015fb <memmove+0x6a>
f01015ec:	f6 c1 03             	test   $0x3,%cl
f01015ef:	75 0a                	jne    f01015fb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015f1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01015f4:	89 c7                	mov    %eax,%edi
f01015f6:	fc                   	cld    
f01015f7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015f9:	eb 05                	jmp    f0101600 <memmove+0x6f>
		else
			asm volatile("cld; rep movsb\n"
f01015fb:	89 c7                	mov    %eax,%edi
f01015fd:	fc                   	cld    
f01015fe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101600:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101603:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101606:	89 ec                	mov    %ebp,%esp
f0101608:	5d                   	pop    %ebp
f0101609:	c3                   	ret    

f010160a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010160a:	55                   	push   %ebp
f010160b:	89 e5                	mov    %esp,%ebp
f010160d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101610:	8b 45 10             	mov    0x10(%ebp),%eax
f0101613:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101617:	8b 45 0c             	mov    0xc(%ebp),%eax
f010161a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010161e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101621:	89 04 24             	mov    %eax,(%esp)
f0101624:	e8 68 ff ff ff       	call   f0101591 <memmove>
}
f0101629:	c9                   	leave  
f010162a:	c3                   	ret    

f010162b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010162b:	55                   	push   %ebp
f010162c:	89 e5                	mov    %esp,%ebp
f010162e:	56                   	push   %esi
f010162f:	53                   	push   %ebx
f0101630:	8b 55 08             	mov    0x8(%ebp),%edx
f0101633:	8b 4d 0c             	mov    0xc(%ebp),%ecx
memcmp(const void *v1, const void *v2, size_t n)
f0101636:	89 d6                	mov    %edx,%esi
f0101638:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010163b:	eb 1a                	jmp    f0101657 <memcmp+0x2c>
		if (*s1 != *s2)
f010163d:	0f b6 02             	movzbl (%edx),%eax
f0101640:	0f b6 19             	movzbl (%ecx),%ebx
f0101643:	38 d8                	cmp    %bl,%al
f0101645:	74 0a                	je     f0101651 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0101647:	0f b6 c0             	movzbl %al,%eax
f010164a:	0f b6 db             	movzbl %bl,%ebx
f010164d:	29 d8                	sub    %ebx,%eax
f010164f:	eb 0f                	jmp    f0101660 <memcmp+0x35>
		s1++, s2++;
f0101651:	83 c2 01             	add    $0x1,%edx
f0101654:	83 c1 01             	add    $0x1,%ecx
	while (n-- > 0) {
f0101657:	39 f2                	cmp    %esi,%edx
f0101659:	75 e2                	jne    f010163d <memcmp+0x12>
	}

	return 0;
f010165b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101660:	5b                   	pop    %ebx
f0101661:	5e                   	pop    %esi
f0101662:	5d                   	pop    %ebp
f0101663:	c3                   	ret    

f0101664 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101664:	55                   	push   %ebp
f0101665:	89 e5                	mov    %esp,%ebp
f0101667:	8b 45 08             	mov    0x8(%ebp),%eax
f010166a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010166d:	89 c2                	mov    %eax,%edx
f010166f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101672:	eb 07                	jmp    f010167b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101674:	38 08                	cmp    %cl,(%eax)
f0101676:	74 07                	je     f010167f <memfind+0x1b>
	for (; s < ends; s++)
f0101678:	83 c0 01             	add    $0x1,%eax
f010167b:	39 d0                	cmp    %edx,%eax
f010167d:	72 f5                	jb     f0101674 <memfind+0x10>
			break;
	return (void *) s;
}
f010167f:	5d                   	pop    %ebp
f0101680:	c3                   	ret    

f0101681 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101681:	55                   	push   %ebp
f0101682:	89 e5                	mov    %esp,%ebp
f0101684:	57                   	push   %edi
f0101685:	56                   	push   %esi
f0101686:	53                   	push   %ebx
f0101687:	83 ec 04             	sub    $0x4,%esp
f010168a:	8b 55 08             	mov    0x8(%ebp),%edx
f010168d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101690:	eb 03                	jmp    f0101695 <strtol+0x14>
		s++;
f0101692:	83 c2 01             	add    $0x1,%edx
	while (*s == ' ' || *s == '\t')
f0101695:	0f b6 02             	movzbl (%edx),%eax
f0101698:	3c 09                	cmp    $0x9,%al
f010169a:	74 f6                	je     f0101692 <strtol+0x11>
f010169c:	3c 20                	cmp    $0x20,%al
f010169e:	74 f2                	je     f0101692 <strtol+0x11>

	// plus/minus sign
	if (*s == '+')
f01016a0:	3c 2b                	cmp    $0x2b,%al
f01016a2:	75 0a                	jne    f01016ae <strtol+0x2d>
		s++;
f01016a4:	83 c2 01             	add    $0x1,%edx
	int neg = 0;
f01016a7:	bf 00 00 00 00       	mov    $0x0,%edi
f01016ac:	eb 10                	jmp    f01016be <strtol+0x3d>
f01016ae:	bf 00 00 00 00       	mov    $0x0,%edi
	else if (*s == '-')
f01016b3:	3c 2d                	cmp    $0x2d,%al
f01016b5:	75 07                	jne    f01016be <strtol+0x3d>
		s++, neg = 1;
f01016b7:	8d 52 01             	lea    0x1(%edx),%edx
f01016ba:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016be:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01016c4:	75 15                	jne    f01016db <strtol+0x5a>
f01016c6:	80 3a 30             	cmpb   $0x30,(%edx)
f01016c9:	75 10                	jne    f01016db <strtol+0x5a>
f01016cb:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016cf:	75 0a                	jne    f01016db <strtol+0x5a>
		s += 2, base = 16;
f01016d1:	83 c2 02             	add    $0x2,%edx
f01016d4:	bb 10 00 00 00       	mov    $0x10,%ebx
f01016d9:	eb 10                	jmp    f01016eb <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f01016db:	85 db                	test   %ebx,%ebx
f01016dd:	75 0c                	jne    f01016eb <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016df:	b3 0a                	mov    $0xa,%bl
	else if (base == 0 && s[0] == '0')
f01016e1:	80 3a 30             	cmpb   $0x30,(%edx)
f01016e4:	75 05                	jne    f01016eb <strtol+0x6a>
		s++, base = 8;
f01016e6:	83 c2 01             	add    $0x1,%edx
f01016e9:	b3 08                	mov    $0x8,%bl
		base = 10;
f01016eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01016f0:	89 5d f0             	mov    %ebx,-0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016f3:	0f b6 0a             	movzbl (%edx),%ecx
f01016f6:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01016f9:	89 f3                	mov    %esi,%ebx
f01016fb:	80 fb 09             	cmp    $0x9,%bl
f01016fe:	77 08                	ja     f0101708 <strtol+0x87>
			dig = *s - '0';
f0101700:	0f be c9             	movsbl %cl,%ecx
f0101703:	83 e9 30             	sub    $0x30,%ecx
f0101706:	eb 22                	jmp    f010172a <strtol+0xa9>
		else if (*s >= 'a' && *s <= 'z')
f0101708:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010170b:	89 f3                	mov    %esi,%ebx
f010170d:	80 fb 19             	cmp    $0x19,%bl
f0101710:	77 08                	ja     f010171a <strtol+0x99>
			dig = *s - 'a' + 10;
f0101712:	0f be c9             	movsbl %cl,%ecx
f0101715:	83 e9 57             	sub    $0x57,%ecx
f0101718:	eb 10                	jmp    f010172a <strtol+0xa9>
		else if (*s >= 'A' && *s <= 'Z')
f010171a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010171d:	89 f3                	mov    %esi,%ebx
f010171f:	80 fb 19             	cmp    $0x19,%bl
f0101722:	77 16                	ja     f010173a <strtol+0xb9>
			dig = *s - 'A' + 10;
f0101724:	0f be c9             	movsbl %cl,%ecx
f0101727:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010172a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010172d:	7d 0f                	jge    f010173e <strtol+0xbd>
			break;
		s++, val = (val * base) + dig;
f010172f:	83 c2 01             	add    $0x1,%edx
f0101732:	0f af 45 f0          	imul   -0x10(%ebp),%eax
f0101736:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101738:	eb b9                	jmp    f01016f3 <strtol+0x72>
		else if (*s >= 'A' && *s <= 'Z')
f010173a:	89 c1                	mov    %eax,%ecx
f010173c:	eb 02                	jmp    f0101740 <strtol+0xbf>
		if (dig >= base)
f010173e:	89 c1                	mov    %eax,%ecx

	if (endptr)
f0101740:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101744:	74 05                	je     f010174b <strtol+0xca>
		*endptr = (char *) s;
f0101746:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101749:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f010174b:	89 ca                	mov    %ecx,%edx
f010174d:	f7 da                	neg    %edx
f010174f:	85 ff                	test   %edi,%edi
f0101751:	0f 45 c2             	cmovne %edx,%eax
}
f0101754:	83 c4 04             	add    $0x4,%esp
f0101757:	5b                   	pop    %ebx
f0101758:	5e                   	pop    %esi
f0101759:	5f                   	pop    %edi
f010175a:	5d                   	pop    %ebp
f010175b:	c3                   	ret    
f010175c:	66 90                	xchg   %ax,%ax
f010175e:	66 90                	xchg   %ax,%ax

f0101760 <__udivdi3>:
f0101760:	83 ec 1c             	sub    $0x1c,%esp
f0101763:	8b 44 24 2c          	mov    0x2c(%esp),%eax
f0101767:	89 7c 24 14          	mov    %edi,0x14(%esp)
f010176b:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f010176f:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101773:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0101777:	8b 6c 24 24          	mov    0x24(%esp),%ebp
f010177b:	85 c0                	test   %eax,%eax
f010177d:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101781:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101785:	89 ea                	mov    %ebp,%edx
f0101787:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f010178b:	75 33                	jne    f01017c0 <__udivdi3+0x60>
f010178d:	39 e9                	cmp    %ebp,%ecx
f010178f:	77 6f                	ja     f0101800 <__udivdi3+0xa0>
f0101791:	85 c9                	test   %ecx,%ecx
f0101793:	89 ce                	mov    %ecx,%esi
f0101795:	75 0b                	jne    f01017a2 <__udivdi3+0x42>
f0101797:	b8 01 00 00 00       	mov    $0x1,%eax
f010179c:	31 d2                	xor    %edx,%edx
f010179e:	f7 f1                	div    %ecx
f01017a0:	89 c6                	mov    %eax,%esi
f01017a2:	31 d2                	xor    %edx,%edx
f01017a4:	89 e8                	mov    %ebp,%eax
f01017a6:	f7 f6                	div    %esi
f01017a8:	89 c5                	mov    %eax,%ebp
f01017aa:	89 f8                	mov    %edi,%eax
f01017ac:	f7 f6                	div    %esi
f01017ae:	89 ea                	mov    %ebp,%edx
f01017b0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017b4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017b8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017bc:	83 c4 1c             	add    $0x1c,%esp
f01017bf:	c3                   	ret    
f01017c0:	39 e8                	cmp    %ebp,%eax
f01017c2:	77 24                	ja     f01017e8 <__udivdi3+0x88>
f01017c4:	0f bd c8             	bsr    %eax,%ecx
f01017c7:	83 f1 1f             	xor    $0x1f,%ecx
f01017ca:	89 0c 24             	mov    %ecx,(%esp)
f01017cd:	75 49                	jne    f0101818 <__udivdi3+0xb8>
f01017cf:	8b 74 24 08          	mov    0x8(%esp),%esi
f01017d3:	39 74 24 04          	cmp    %esi,0x4(%esp)
f01017d7:	0f 86 ab 00 00 00    	jbe    f0101888 <__udivdi3+0x128>
f01017dd:	39 e8                	cmp    %ebp,%eax
f01017df:	0f 82 a3 00 00 00    	jb     f0101888 <__udivdi3+0x128>
f01017e5:	8d 76 00             	lea    0x0(%esi),%esi
f01017e8:	31 d2                	xor    %edx,%edx
f01017ea:	31 c0                	xor    %eax,%eax
f01017ec:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017f0:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017f4:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017f8:	83 c4 1c             	add    $0x1c,%esp
f01017fb:	c3                   	ret    
f01017fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101800:	89 f8                	mov    %edi,%eax
f0101802:	f7 f1                	div    %ecx
f0101804:	31 d2                	xor    %edx,%edx
f0101806:	8b 74 24 10          	mov    0x10(%esp),%esi
f010180a:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010180e:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101812:	83 c4 1c             	add    $0x1c,%esp
f0101815:	c3                   	ret    
f0101816:	66 90                	xchg   %ax,%ax
f0101818:	0f b6 0c 24          	movzbl (%esp),%ecx
f010181c:	89 c6                	mov    %eax,%esi
f010181e:	b8 20 00 00 00       	mov    $0x20,%eax
f0101823:	8b 6c 24 04          	mov    0x4(%esp),%ebp
f0101827:	2b 04 24             	sub    (%esp),%eax
f010182a:	8b 7c 24 08          	mov    0x8(%esp),%edi
f010182e:	d3 e6                	shl    %cl,%esi
f0101830:	89 c1                	mov    %eax,%ecx
f0101832:	d3 ed                	shr    %cl,%ebp
f0101834:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101838:	09 f5                	or     %esi,%ebp
f010183a:	8b 74 24 04          	mov    0x4(%esp),%esi
f010183e:	d3 e6                	shl    %cl,%esi
f0101840:	89 c1                	mov    %eax,%ecx
f0101842:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101846:	89 d6                	mov    %edx,%esi
f0101848:	d3 ee                	shr    %cl,%esi
f010184a:	0f b6 0c 24          	movzbl (%esp),%ecx
f010184e:	d3 e2                	shl    %cl,%edx
f0101850:	89 c1                	mov    %eax,%ecx
f0101852:	d3 ef                	shr    %cl,%edi
f0101854:	09 d7                	or     %edx,%edi
f0101856:	89 f2                	mov    %esi,%edx
f0101858:	89 f8                	mov    %edi,%eax
f010185a:	f7 f5                	div    %ebp
f010185c:	89 d6                	mov    %edx,%esi
f010185e:	89 c7                	mov    %eax,%edi
f0101860:	f7 64 24 04          	mull   0x4(%esp)
f0101864:	39 d6                	cmp    %edx,%esi
f0101866:	72 30                	jb     f0101898 <__udivdi3+0x138>
f0101868:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f010186c:	0f b6 0c 24          	movzbl (%esp),%ecx
f0101870:	d3 e5                	shl    %cl,%ebp
f0101872:	39 c5                	cmp    %eax,%ebp
f0101874:	73 04                	jae    f010187a <__udivdi3+0x11a>
f0101876:	39 d6                	cmp    %edx,%esi
f0101878:	74 1e                	je     f0101898 <__udivdi3+0x138>
f010187a:	89 f8                	mov    %edi,%eax
f010187c:	31 d2                	xor    %edx,%edx
f010187e:	e9 69 ff ff ff       	jmp    f01017ec <__udivdi3+0x8c>
f0101883:	90                   	nop
f0101884:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101888:	31 d2                	xor    %edx,%edx
f010188a:	b8 01 00 00 00       	mov    $0x1,%eax
f010188f:	e9 58 ff ff ff       	jmp    f01017ec <__udivdi3+0x8c>
f0101894:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101898:	8d 47 ff             	lea    -0x1(%edi),%eax
f010189b:	31 d2                	xor    %edx,%edx
f010189d:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018a1:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018a5:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018a9:	83 c4 1c             	add    $0x1c,%esp
f01018ac:	c3                   	ret    
f01018ad:	66 90                	xchg   %ax,%ax
f01018af:	90                   	nop

f01018b0 <__umoddi3>:
f01018b0:	83 ec 2c             	sub    $0x2c,%esp
f01018b3:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f01018b7:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f01018bb:	89 74 24 20          	mov    %esi,0x20(%esp)
f01018bf:	8b 74 24 38          	mov    0x38(%esp),%esi
f01018c3:	89 7c 24 24          	mov    %edi,0x24(%esp)
f01018c7:	8b 7c 24 34          	mov    0x34(%esp),%edi
f01018cb:	85 c0                	test   %eax,%eax
f01018cd:	89 c2                	mov    %eax,%edx
f01018cf:	89 6c 24 28          	mov    %ebp,0x28(%esp)
f01018d3:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f01018d7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01018db:	89 74 24 10          	mov    %esi,0x10(%esp)
f01018df:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f01018e3:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01018e7:	75 1f                	jne    f0101908 <__umoddi3+0x58>
f01018e9:	39 fe                	cmp    %edi,%esi
f01018eb:	76 63                	jbe    f0101950 <__umoddi3+0xa0>
f01018ed:	89 c8                	mov    %ecx,%eax
f01018ef:	89 fa                	mov    %edi,%edx
f01018f1:	f7 f6                	div    %esi
f01018f3:	89 d0                	mov    %edx,%eax
f01018f5:	31 d2                	xor    %edx,%edx
f01018f7:	8b 74 24 20          	mov    0x20(%esp),%esi
f01018fb:	8b 7c 24 24          	mov    0x24(%esp),%edi
f01018ff:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101903:	83 c4 2c             	add    $0x2c,%esp
f0101906:	c3                   	ret    
f0101907:	90                   	nop
f0101908:	39 f8                	cmp    %edi,%eax
f010190a:	77 64                	ja     f0101970 <__umoddi3+0xc0>
f010190c:	0f bd e8             	bsr    %eax,%ebp
f010190f:	83 f5 1f             	xor    $0x1f,%ebp
f0101912:	75 74                	jne    f0101988 <__umoddi3+0xd8>
f0101914:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101918:	39 7c 24 10          	cmp    %edi,0x10(%esp)
f010191c:	0f 87 0e 01 00 00    	ja     f0101a30 <__umoddi3+0x180>
f0101922:	8b 7c 24 0c          	mov    0xc(%esp),%edi
f0101926:	29 f1                	sub    %esi,%ecx
f0101928:	19 c7                	sbb    %eax,%edi
f010192a:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f010192e:	89 7c 24 18          	mov    %edi,0x18(%esp)
f0101932:	8b 44 24 14          	mov    0x14(%esp),%eax
f0101936:	8b 54 24 18          	mov    0x18(%esp),%edx
f010193a:	8b 74 24 20          	mov    0x20(%esp),%esi
f010193e:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101942:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101946:	83 c4 2c             	add    $0x2c,%esp
f0101949:	c3                   	ret    
f010194a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101950:	85 f6                	test   %esi,%esi
f0101952:	89 f5                	mov    %esi,%ebp
f0101954:	75 0b                	jne    f0101961 <__umoddi3+0xb1>
f0101956:	b8 01 00 00 00       	mov    $0x1,%eax
f010195b:	31 d2                	xor    %edx,%edx
f010195d:	f7 f6                	div    %esi
f010195f:	89 c5                	mov    %eax,%ebp
f0101961:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101965:	31 d2                	xor    %edx,%edx
f0101967:	f7 f5                	div    %ebp
f0101969:	89 c8                	mov    %ecx,%eax
f010196b:	f7 f5                	div    %ebp
f010196d:	eb 84                	jmp    f01018f3 <__umoddi3+0x43>
f010196f:	90                   	nop
f0101970:	89 c8                	mov    %ecx,%eax
f0101972:	89 fa                	mov    %edi,%edx
f0101974:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101978:	8b 7c 24 24          	mov    0x24(%esp),%edi
f010197c:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101980:	83 c4 2c             	add    $0x2c,%esp
f0101983:	c3                   	ret    
f0101984:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101988:	8b 44 24 10          	mov    0x10(%esp),%eax
f010198c:	be 20 00 00 00       	mov    $0x20,%esi
f0101991:	89 e9                	mov    %ebp,%ecx
f0101993:	29 ee                	sub    %ebp,%esi
f0101995:	d3 e2                	shl    %cl,%edx
f0101997:	89 f1                	mov    %esi,%ecx
f0101999:	d3 e8                	shr    %cl,%eax
f010199b:	89 e9                	mov    %ebp,%ecx
f010199d:	09 d0                	or     %edx,%eax
f010199f:	89 fa                	mov    %edi,%edx
f01019a1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01019a5:	8b 44 24 10          	mov    0x10(%esp),%eax
f01019a9:	d3 e0                	shl    %cl,%eax
f01019ab:	89 f1                	mov    %esi,%ecx
f01019ad:	89 44 24 10          	mov    %eax,0x10(%esp)
f01019b1:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f01019b5:	d3 ea                	shr    %cl,%edx
f01019b7:	89 e9                	mov    %ebp,%ecx
f01019b9:	d3 e7                	shl    %cl,%edi
f01019bb:	89 f1                	mov    %esi,%ecx
f01019bd:	d3 e8                	shr    %cl,%eax
f01019bf:	89 e9                	mov    %ebp,%ecx
f01019c1:	09 f8                	or     %edi,%eax
f01019c3:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f01019c7:	f7 74 24 0c          	divl   0xc(%esp)
f01019cb:	d3 e7                	shl    %cl,%edi
f01019cd:	89 7c 24 18          	mov    %edi,0x18(%esp)
f01019d1:	89 d7                	mov    %edx,%edi
f01019d3:	f7 64 24 10          	mull   0x10(%esp)
f01019d7:	39 d7                	cmp    %edx,%edi
f01019d9:	89 c1                	mov    %eax,%ecx
f01019db:	89 54 24 14          	mov    %edx,0x14(%esp)
f01019df:	72 3b                	jb     f0101a1c <__umoddi3+0x16c>
f01019e1:	39 44 24 18          	cmp    %eax,0x18(%esp)
f01019e5:	72 31                	jb     f0101a18 <__umoddi3+0x168>
f01019e7:	8b 44 24 18          	mov    0x18(%esp),%eax
f01019eb:	29 c8                	sub    %ecx,%eax
f01019ed:	19 d7                	sbb    %edx,%edi
f01019ef:	89 e9                	mov    %ebp,%ecx
f01019f1:	89 fa                	mov    %edi,%edx
f01019f3:	d3 e8                	shr    %cl,%eax
f01019f5:	89 f1                	mov    %esi,%ecx
f01019f7:	d3 e2                	shl    %cl,%edx
f01019f9:	89 e9                	mov    %ebp,%ecx
f01019fb:	09 d0                	or     %edx,%eax
f01019fd:	89 fa                	mov    %edi,%edx
f01019ff:	d3 ea                	shr    %cl,%edx
f0101a01:	8b 74 24 20          	mov    0x20(%esp),%esi
f0101a05:	8b 7c 24 24          	mov    0x24(%esp),%edi
f0101a09:	8b 6c 24 28          	mov    0x28(%esp),%ebp
f0101a0d:	83 c4 2c             	add    $0x2c,%esp
f0101a10:	c3                   	ret    
f0101a11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a18:	39 d7                	cmp    %edx,%edi
f0101a1a:	75 cb                	jne    f01019e7 <__umoddi3+0x137>
f0101a1c:	8b 54 24 14          	mov    0x14(%esp),%edx
f0101a20:	89 c1                	mov    %eax,%ecx
f0101a22:	2b 4c 24 10          	sub    0x10(%esp),%ecx
f0101a26:	1b 54 24 0c          	sbb    0xc(%esp),%edx
f0101a2a:	eb bb                	jmp    f01019e7 <__umoddi3+0x137>
f0101a2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a30:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0101a34:	0f 82 e8 fe ff ff    	jb     f0101922 <__umoddi3+0x72>
f0101a3a:	e9 f3 fe ff ff       	jmp    f0101932 <__umoddi3+0x82>
