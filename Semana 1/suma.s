	.file	"suma.c"
	.intel_syntax noprefix
	.text
	.globl	suma
	.type	suma, @function
suma:
	endbr64
	push	rbp
	mov	rbp, rsp
	mov	DWORD PTR [rbp-20], edi
	mov	DWORD PTR [rbp-24], esi
	mov	edx, DWORD PTR [rbp-20]
	mov	eax, DWORD PTR [rbp-24]
	add	eax, edx
	mov	DWORD PTR [rbp-4], eax
	mov	eax, DWORD PTR [rbp-4]
	pop	rbp
	ret
	.size	suma, .-suma
	.ident	"GCC: (Ubuntu 15.2.0-16ubuntu1) 15.2.0"
	.section	.note.GNU-stack,"",@progbits
	.section	.note.gnu.property,"a"
	.align 8
	.long	1f - 0f
	.long	4f - 1f
	.long	5
0:
	.string	"GNU"
1:
	.align 8
	.long	0xc0000002
	.long	3f - 2f
2:
	.long	0x3
3:
	.align 8
4:
