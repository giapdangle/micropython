/*
 * This file is part of the Micro Python project, http://micropython.org/
 *
 * The MIT License (MIT)
 *
 * Copyright (c) 2013, 2014 Damien P. George
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#if defined(__x86_64__) && !MICROPY_NLR_SETJMP
/* x64 callee save: bx, bp, sp, r12, r13, r14, r15 */

    .file   "nlr.s"
    .text

#if !defined(__CYGWIN__)

/* uint nlr_push(rdi=nlr_buf_t *nlr) */
#if !(defined(__APPLE__) && defined(__MACH__))
    .globl  nlr_push
    .type   nlr_push, @function
nlr_push:
#else
    .globl  _nlr_push
_nlr_push:
#endif
    movq    (%rsp), %rax            # load return %rip
    movq    %rax, 16(%rdi)          # store %rip into nlr_buf
    movq    %rbp, 24(%rdi)          # store %rbp into nlr_buf
    movq    %rsp, 32(%rdi)          # store %rsp into nlr_buf
    movq    %rbx, 40(%rdi)          # store %rbx into nlr_buf
    movq    %r12, 48(%rdi)          # store %r12 into nlr_buf
    movq    %r13, 56(%rdi)          # store %r13 into nlr_buf
    movq    %r14, 64(%rdi)          # store %r14 into nlr_buf
    movq    %r15, 72(%rdi)          # store %r15 into nlr_buf
    movq    nlr_top(%rip), %rax     # get last nlr_buf
    movq    %rax, (%rdi)            # store it
    movq    %rdi, nlr_top(%rip)     # stor new nlr_buf (to make linked list)
    xorq    %rax, %rax              # return 0, normal return
    ret                             # return
#if !(defined(__APPLE__) && defined(__MACH__))
    .size   nlr_push, .-nlr_push
#endif

/* void nlr_pop() */
#if !(defined(__APPLE__) && defined(__MACH__))
    .globl  nlr_pop
    .type   nlr_pop, @function
nlr_pop:
#else
    .globl  _nlr_pop
_nlr_pop:
#endif
    movq    nlr_top(%rip), %rax     # get nlr_top into %rax
    movq    (%rax), %rax            # load prev nlr_buf
    movq    %rax, nlr_top(%rip)     # store prev nlr_buf (to unlink list)
    ret                             # return
#if !(defined(__APPLE__) && defined(__MACH__))
    .size   nlr_pop, .-nlr_pop
#endif

/* void nlr_jump(rdi=uint val) */
#if !(defined(__APPLE__) && defined(__MACH__))
    .globl  nlr_jump
    .type   nlr_jump, @function
nlr_jump:
#else
    .globl  _nlr_jump
    _nlr_jump:
#endif
    movq    %rdi, %rax              # put return value in %rax
    movq    nlr_top(%rip), %rdi     # get nlr_top into %rdi
    test    %rdi, %rdi              # check for nlr_top being NULL
    je      .fail                   # fail if nlr_top is NULL
    movq    %rax, 8(%rdi)           # store return value
    movq    (%rdi), %rax            # load prev nlr_buf
    movq    %rax, nlr_top(%rip)     # store prev nlr_buf (to unlink list)
    movq    72(%rdi), %r15          # load saved %r15
    movq    64(%rdi), %r14          # load saved %r14
    movq    56(%rdi), %r13          # load saved %r13
    movq    48(%rdi), %r12          # load saved %r12
    movq    40(%rdi), %rbx          # load saved %rbx
    movq    32(%rdi), %rsp          # load saved %rsp
    movq    24(%rdi), %rbp          # load saved %rbp
    movq    16(%rdi), %rax          # load saved %rip
    movq    %rax, (%rsp)            # store saved %rip to stack
    xorq    %rax, %rax              # clear return register
    inc     %al                     # increase to make 1, non-local return
    ret                             # return
.fail:
    movq    %rax, %rdi              # put argument back in first-arg register
    je      nlr_jump_fail           # transfer control to nlr_jump_fail
#if !(defined(__APPLE__) && defined(__MACH__))
    .size   nlr_jump, .-nlr_jump
#endif

    .bss
#if !(defined(__APPLE__) && defined(__MACH__))
    .local  nlr_top
#endif
    .comm   nlr_top,8,8

#else // !defined(__CYGWIN__)

/* uint nlr_push(rcx=nlr_buf_t *nlr) */
    .globl  nlr_push
nlr_push:
    movq    (%rsp), %rax            # load return %rip
    movq    %rax, 16(%rcx)          # store %rip into nlr_buf
    movq    %rbp, 24(%rcx)          # store %rbp into nlr_buf
    movq    %rsp, 32(%rcx)          # store %rsp into nlr_buf
    movq    %rbx, 40(%rcx)          # store %rbx into nlr_buf
    movq    %r12, 48(%rcx)          # store %r12 into nlr_buf
    movq    %r13, 56(%rcx)          # store %r13 into nlr_buf
    movq    %r14, 64(%rcx)          # store %r14 into nlr_buf
    movq    %r15, 72(%rcx)          # store %r15 into
    movq    %rdi, 80(%rcx)          # store %rdr into
    movq    %rsi, 88(%rcx)          # store %rsi into
    movq    nlr_top(%rip), %rax     # get last nlr_buf
    movq    %rax, (%rcx)            # store it
    movq    %rcx, nlr_top(%rip)     # stor new nlr_buf (to make linked list)
    xorq    %rax, %rax              # return 0, normal return
    ret                             # return

/* void nlr_pop() */
    .globl  nlr_pop
nlr_pop:
    movq    nlr_top(%rip), %rax     # get nlr_top into %rax
    movq    (%rax), %rax            # load prev nlr_buf
    movq    %rax, nlr_top(%rip)     # store prev nlr_buf (to unlink list)
    ret                             # return

/* void nlr_jump(rcx=uint val) */
    .globl  nlr_jump
nlr_jump:
    movq    %rcx, %rax              # put return value in %rax
    movq    nlr_top(%rip), %rcx     # get nlr_top into %rcx
    test    %rcx, %rcx              # check for nlr_top being NULL
    je      .fail                   # fail if nlr_top is NULL
    movq    %rax, 8(%rcx)           # store return value
    movq    (%rcx), %rax            # load prev nlr_buf
    movq    %rax, nlr_top(%rip)     # store prev nlr_buf (to unlink list)
    movq    72(%rcx), %r15          # load saved %r15
    movq    64(%rcx), %r14          # load saved %r14
    movq    56(%rcx), %r13          # load saved %r13
    movq    48(%rcx), %r12          # load saved %r12
    movq    40(%rcx), %rbx          # load saved %rbx
    movq    32(%rcx), %rsp          # load saved %rsp
    movq    24(%rcx), %rbp          # load saved %rbp
    movq    16(%rcx), %rax          # load saved %rip
    movq    80(%rcx), %rdi          # store %rdr into
    movq    88(%rcx), %rsi          # store %rsi into
    movq    %rax, (%rsp)            # store saved %rip to stack
    xorq    %rax, %rax              # clear return register
    inc     %al                     # increase to make 1, non-local return
    ret                             # return
.fail:
    movq    %rax, %rcx              # put argument back in first-arg register
    je      nlr_jump_fail           # transfer control to nlr_jump_fail

    .bss
    .comm   nlr_top,8,8

#endif // !defined(__CYGWIN__)

#endif // __x86_64__
