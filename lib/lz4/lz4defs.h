#ifndef __LZ4DEFS_H__
#define __LZ4DEFS_H__
/*
   LZ4 - Fast LZ compression algorithm
   Copyright (C) 2011-2023, Yann Collet.

   BSD 2-Clause License (http://www.opensource.org/licenses/bsd-license.php)

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

       * Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
       * Redistributions in binary form must reproduce the above
   copyright notice, this list of conditions and the following disclaimer
   in the documentation and/or other materials provided with the
   distribution.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

   You can contact the author at :
    - LZ4 homepage : http://www.lz4.org
    - LZ4 source repository : https://github.com/lz4/lz4
*/

/*-************************************
*  Tuning parameters
**************************************/
/*
 * LZ4_HEAPMODE :
 * Select how stateless compression functions like `LZ4_compress_default()`
 * allocate memory for their hash table,
 * in memory stack (0:default, fastest), or in memory heap (1:requires malloc()).
 */
#ifndef LZ4_HEAPMODE
#define LZ4_HEAPMODE 0
#endif

/*
 * LZ4_ACCELERATION_DEFAULT :
 * Select "acceleration" for LZ4_compress_fast() when parameter value <= 0
 */
#define LZ4_ACCELERATION_DEFAULT 1
/*
 * LZ4_ACCELERATION_MAX :
 * Any "acceleration" value higher than this threshold
 * get treated as LZ4_ACCELERATION_MAX instead (fix #876)
 */
#define LZ4_ACCELERATION_MAX 65537

/*-************************************
*  CPU Feature Detection
**************************************/
/* LZ4_FORCE_MEMORY_ACCESS
 * By default, access to unaligned memory is controlled by `memcpy()`, which is safe and portable.
 * Unfortunately, on some target/compiler combinations, the generated assembly is sub-optimal.
 * The below switch allow to select different access method for improved performance.
 * Method 0 (default) : use `memcpy()`. Safe and portable.
 * Method 1 : `__packed` statement. It depends on compiler extension (ie, not portable).
 *            This method is safe if your compiler supports it, and *generally* as fast or faster than `memcpy`.
 * Method 2 : direct access. This method is portable but violate C standard.
 *            It can generate buggy code on targets which assembly generation depends on alignment.
 *            But in some circumstances, it's the only known way to get the most performance (ie GCC + ARMv6)
 * See https://fastcompression.blogspot.fr/2015/08/accessing-unaligned-memory.html for details.
 * Prefer these methods in priority order (0 > 1 > 2)
 */
#ifndef LZ4_FORCE_MEMORY_ACCESS /* can be defined externally */
#if defined(__GNUC__) &&                                                       \
	(defined(__ARM_ARCH_6__) || defined(__ARM_ARCH_6J__) ||                \
	 defined(__ARM_ARCH_6K__) || defined(__ARM_ARCH_6Z__) ||               \
	 defined(__ARM_ARCH_6ZK__) || defined(__ARM_ARCH_6T2__))
#define LZ4_FORCE_MEMORY_ACCESS 2
#elif (defined(__INTEL_COMPILER) && !defined(_WIN32)) || defined(__GNUC__) ||  \
	defined(_MSC_VER)
#define LZ4_FORCE_MEMORY_ACCESS 1
#endif
#endif

/*
 * LZ4_FORCE_SW_BITCOUNT
 * Define this parameter if your target system or compiler does not support hardware bit count
 */
#if defined(_MSC_VER) &&                                                       \
	defined(_WIN32_WCE) /* Visual Studio for WinCE doesn't support Hardware bit count */
#undef LZ4_FORCE_SW_BITCOUNT /* avoid double def */
#define LZ4_FORCE_SW_BITCOUNT
#endif

/*-************************************
*  Dependency
**************************************/
/*
 * LZ4_SRC_INCLUDED:
 * Amalgamation flag, whether lz4.c is included
 */
#ifndef LZ4_SRC_INCLUDED
#define LZ4_SRC_INCLUDED 1
#endif

#ifndef LZ4_DISABLE_DEPRECATE_WARNINGS
#define LZ4_DISABLE_DEPRECATE_WARNINGS /* due to LZ4_decompress_safe_withPrefix64k */
#endif

#ifndef LZ4_STATIC_LINKING_ONLY
#define LZ4_STATIC_LINKING_ONLY
#endif
#include <linux/lz4.h>
/* see also "memory routines" below */

/*-************************************
*  Compiler Options
**************************************/
#if defined(_MSC_VER) && (_MSC_VER >= 1400) /* Visual Studio 2005+ */
#include <intrin.h> /* only present in VS2005+ */
#pragma warning(                                                               \
	disable                                                                \
	: 4127) /* disable: C4127: conditional expression is constant */
#pragma warning(                                                               \
	disable                                                                \
	: 6237) /* disable: C6237: conditional expression is always 0 */
#pragma warning(                                                               \
	disable                                                                \
	: 6239) /* disable: C6239: (<non-zero constant> && <expression>) always evaluates to the result of <expression> */
#pragma warning(                                                               \
	disable                                                                \
	: 6240) /* disable: C6240: (<expression> && <non-zero constant>) always evaluates to the result of <expression> */
#pragma warning(                                                               \
	disable                                                                \
	: 6326) /* disable: C6326: Potential comparison of a constant with another constant */
#endif /* _MSC_VER */

#define LZ4_FORCE_INLINE static __always_inline

#ifndef LZ4_FORCE_INLINE
#if defined(_MSC_VER) && !defined(__clang__) /* MSVC */
#define LZ4_FORCE_INLINE static __forceinline
#else
#if defined(__cplusplus) ||                                                    \
	defined(__STDC_VERSION__) && __STDC_VERSION__ >= 199901L /* C99 */
#if defined(__GNUC__) || defined(__clang__)
#define LZ4_FORCE_INLINE static inline __attribute__((always_inline))
#else
#define LZ4_FORCE_INLINE static inline
#endif
#else
#define LZ4_FORCE_INLINE static
#endif /* __STDC_VERSION__ */
#endif /* _MSC_VER */
#endif /* LZ4_FORCE_INLINE */

/* LZ4_FORCE_O2 and LZ4_FORCE_INLINE
 * gcc on ppc64le generates an unrolled SIMDized loop for LZ4_wildCopy8,
 * together with a simple 8-byte copy loop as a fall-back path.
 * However, this optimization hurts the decompression speed by >30%,
 * because the execution does not go to the optimized loop
 * for typical compressible data, and all of the preamble checks
 * before going to the fall-back path become useless overhead.
 * This optimization happens only with the -O3 flag, and -O2 generates
 * a simple 8-byte copy loop.
 * With gcc on ppc64le, all of the LZ4_decompress_* and LZ4_wildCopy8
 * functions are annotated with __attribute__((optimize("O2"))),
 * and also LZ4_wildCopy8 is forcibly inlined, so that the O2 attribute
 * of LZ4_wildCopy8 does not affect the compression speed.
 */
#if defined(__PPC64__) && defined(__LITTLE_ENDIAN__) && defined(__GNUC__) &&   \
	!defined(__clang__)
#define LZ4_FORCE_O2 __attribute__((optimize("O2")))
#undef LZ4_FORCE_INLINE
#define LZ4_FORCE_INLINE                                                       \
	static __inline __attribute__((optimize("O2"), always_inline))
#else
#define LZ4_FORCE_O2
#endif

#if (defined(__GNUC__) && (__GNUC__ >= 3)) ||                                  \
	(defined(__INTEL_COMPILER) && (__INTEL_COMPILER >= 800)) ||            \
	defined(__clang__)
#define expect(expr, value) (__builtin_expect((expr), (value)))
#else
#define expect(expr, value) (expr)
#endif

#ifndef likely
#define likely(expr) expect((expr) != 0, 1)
#endif
#ifndef unlikely
#define unlikely(expr) expect((expr) != 0, 0)
#endif

/* Should the alignment test prove unreliable, for some reason,
 * it can be disabled by setting LZ4_ALIGN_TEST to 0 */
#ifndef LZ4_ALIGN_TEST /* can be externally provided */
#define LZ4_ALIGN_TEST 1
#endif

/*-************************************
*  Memory routines
**************************************/

/*! LZ4_STATIC_LINKING_ONLY_DISABLE_MEMORY_ALLOCATION :
 *  Disable relatively high-level LZ4/HC functions that use dynamic memory
 *  allocation functions (malloc(), calloc(), free()).
 *
 *  Note that this is a compile-time switch. And since it disables
 *  public/stable LZ4 v1 API functions, we don't recommend using this
 *  symbol to generate a library for distribution.
 *
 *  The following public functions are removed when this symbol is defined.
 *  - lz4   : LZ4_createStream, LZ4_freeStream,
 *            LZ4_createStreamDecode, LZ4_freeStreamDecode, LZ4_create (deprecated)
 *  - lz4hc : LZ4_createStreamHC, LZ4_freeStreamHC,
 *            LZ4_createHC (deprecated), LZ4_freeHC  (deprecated)
 *  - lz4frame, lz4file : All LZ4F_* functions
 */
#if defined(LZ4_STATIC_LINKING_ONLY_DISABLE_MEMORY_ALLOCATION)
#define ALLOC(s) lz4_error_memory_allocation_is_disabled
#define ALLOC_AND_ZERO(s) lz4_error_memory_allocation_is_disabled
#define FREEMEM(p) lz4_error_memory_allocation_is_disabled
#elif defined(LZ4_USER_MEMORY_FUNCTIONS)
/* memory management functions can be customized by user project.
 * Below functions must exist somewhere in the Project
 * and be available at link time */
void *LZ4_malloc(size_t s);
void *LZ4_calloc(size_t n, size_t s);
void LZ4_free(void *p);
#define ALLOC(s) LZ4_malloc(s)
#define ALLOC_AND_ZERO(s) LZ4_calloc(1, s)
#define FREEMEM(p) LZ4_free(p)
#else
#include <stdlib.h> /* malloc, calloc, free */
#define ALLOC(s) malloc(s)
#define ALLOC_AND_ZERO(s) calloc(1, s)
#define FREEMEM(p) free(p)
#endif

#if !LZ4_FREESTANDING
#include <string.h> /* memset, memcpy */
#endif
#if !defined(LZ4_memset)
#define LZ4_memset(p, v, s) memset((p), (v), (s))
#endif
#define MEM_INIT(p, v, s) LZ4_memset((p), (v), (s))

/*-************************************
*  Common Constants
**************************************/
#define MINMATCH 4

#define WILDCOPYLENGTH 8
#define LASTLITERALS 5 /* see ../doc/lz4_Block_format.md#parsing-restrictions */
#define MFLIMIT 12 /* see ../doc/lz4_Block_format.md#parsing-restrictions */
#define MATCH_SAFEGUARD_DISTANCE                                               \
	((2 * WILDCOPYLENGTH) -                                                \
	 MINMATCH) /* ensure it's possible to write 2 x wildcopyLength without overflowing output buffer */
#define FASTLOOP_SAFE_DISTANCE 64
static const int LZ4_minLength = (MFLIMIT + 1);

#define KB *(1 << 10)
#define MB *(1 << 20)
#define GB *(1U << 30)

#define LZ4_DISTANCE_ABSOLUTE_MAX 65535
#if (LZ4_DISTANCE_MAX >                                                        \
     LZ4_DISTANCE_ABSOLUTE_MAX) /* max supported by LZ4 format */
#error "LZ4_DISTANCE_MAX is too big : must be <= 65535"
#endif

#define ML_BITS 4
#define ML_MASK ((1U << ML_BITS) - 1)
#define RUN_BITS (8 - ML_BITS)
#define RUN_MASK ((1U << RUN_BITS) - 1)

/*-************************************
*  Error detection
**************************************/
#if defined(LZ4_DEBUG) && (LZ4_DEBUG >= 1)
#include <assert.h>
#else
#ifndef assert
#define assert(condition) ((void)0)
#endif
#endif

#define LZ4_STATIC_ASSERT(c)                                                   \
	{                                                                      \
		enum { LZ4_static_assert = 1 / (int)(!!(c)) };                 \
	} /* use after variable declarations */

#if defined(LZ4_DEBUG) && (LZ4_DEBUG >= 2)
#include <stdio.h>
static int g_debuglog_enable = 1;
#define DEBUGLOG(l, ...)                                                       \
	{                                                                      \
		if ((g_debuglog_enable) && (l <= LZ4_DEBUG)) {                 \
			fprintf(stderr, __FILE__ " %i: ", __LINE__);           \
			fprintf(stderr, __VA_ARGS__);                          \
			fprintf(stderr, " \n");                                \
		}                                                              \
	}
#else
#define DEBUGLOG(l, ...)                                                       \
	{                                                                      \
	} /* disabled */
#endif

static inline int LZ4_isAligned(const void *ptr, size_t alignment)
{
	return ((size_t)ptr & (alignment - 1)) == 0;
}

/*-************************************
*  Types
**************************************/
#include <linux/kernel.h>
#include <linux/limits.h>
typedef u8 BYTE;
typedef u16 U16;
typedef u32 U32;
typedef s32 S32;
typedef u64 U64;
typedef uintptr_t uptrval;

#if defined(__x86_64__)
typedef U64 reg_t; /* 64-bits in x32 mode */
#else
typedef size_t reg_t; /* 32-bits in x32 mode */
#endif

typedef enum {
	notLimited = 0,
	limitedOutput = 1,
	fillOutput = 2
} limitedOutput_directive;

/*-************************************
*  Reading and writing into memory
**************************************/

/**
 * LZ4 relies on memcpy with a constant size being inlined. In freestanding
 * environments, the compiler can't assume the implementation of memcpy() is
 * standard compliant, so it can't apply its specialized memcpy() inlining
 * logic. When possible, use __builtin_memcpy() to tell the compiler to analyze
 * memcpy() as if it were standard compliant, so it can inline it in freestanding
 * environments. This is needed when decompressing the Linux Kernel, for example.
 */
#if !defined(LZ4_memcpy)
#if defined(__GNUC__) && (__GNUC__ >= 4)
#define LZ4_memcpy(dst, src, size) __builtin_memcpy(dst, src, size)
#else
#define LZ4_memcpy(dst, src, size) memcpy(dst, src, size)
#endif
#endif

#if !defined(LZ4_memmove)
#if defined(__GNUC__) && (__GNUC__ >= 4)
#define LZ4_memmove __builtin_memmove
#else
#define LZ4_memmove memmove
#endif
#endif

static inline unsigned LZ4_isLittleEndian(void)
{
	const union {
		U32 u;
		BYTE c[4];
	} one = { 1 }; /* don't use static : performance detrimental */
	return one.c[0];
}

#if defined(__GNUC__) || defined(__INTEL_COMPILER)
#define LZ4_PACK(__Declaration__) __Declaration__ __attribute__((__packed__))
#elif defined(_MSC_VER)
#define LZ4_PACK(__Declaration__)                                              \
	__pragma(pack(push, 1)) __Declaration__ __pragma(pack(pop))
#endif

#if defined(LZ4_FORCE_MEMORY_ACCESS) && (LZ4_FORCE_MEMORY_ACCESS == 2)
/* lie to the compiler about data alignment; use with caution */

static inline U16 LZ4_read16(const void *memPtr)
{
	return *(const U16 *)memPtr;
}
static inline U32 LZ4_read32(const void *memPtr)
{
	return *(const U32 *)memPtr;
}
static inline reg_t LZ4_read_ARCH(const void *memPtr)
{
	return *(const reg_t *)memPtr;
}

static inline void LZ4_write16(void *memPtr, U16 value)
{
	*(U16 *)memPtr = value;
}
static inline void LZ4_write32(void *memPtr, U32 value)
{
	*(U32 *)memPtr = value;
}

#elif defined(LZ4_FORCE_MEMORY_ACCESS) && (LZ4_FORCE_MEMORY_ACCESS == 1)

/* __pack instructions are safer, but compiler specific, hence potentially problematic for some compilers */
/* currently only defined for gcc and icc */
LZ4_PACK(typedef struct { U16 u16; }) LZ4_unalign16;
LZ4_PACK(typedef struct { U32 u32; }) LZ4_unalign32;
LZ4_PACK(typedef struct { reg_t uArch; }) LZ4_unalignST;

static inline U16 LZ4_read16(const void *ptr)
{
	return ((const LZ4_unalign16 *)ptr)->u16;
}
static inline U32 LZ4_read32(const void *ptr)
{
	return ((const LZ4_unalign32 *)ptr)->u32;
}
static inline reg_t LZ4_read_ARCH(const void *ptr)
{
	return ((const LZ4_unalignST *)ptr)->uArch;
}

static inline void LZ4_write16(void *memPtr, U16 value)
{
	((LZ4_unalign16 *)memPtr)->u16 = value;
}
static inline void LZ4_write32(void *memPtr, U32 value)
{
	((LZ4_unalign32 *)memPtr)->u32 = value;
}

#else /* safe and portable access using memcpy() */

static inline U16 LZ4_read16(const void *memPtr)
{
	U16 val;
	LZ4_memcpy(&val, memPtr, sizeof(val));
	return val;
}

static inline U32 LZ4_read32(const void *memPtr)
{
	U32 val;
	LZ4_memcpy(&val, memPtr, sizeof(val));
	return val;
}

static inline reg_t LZ4_read_ARCH(const void *memPtr)
{
	reg_t val;
	LZ4_memcpy(&val, memPtr, sizeof(val));
	return val;
}

static inline void LZ4_write16(void *memPtr, U16 value)
{
	LZ4_memcpy(memPtr, &value, sizeof(value));
}

static inline void LZ4_write32(void *memPtr, U32 value)
{
	LZ4_memcpy(memPtr, &value, sizeof(value));
}

#endif /* LZ4_FORCE_MEMORY_ACCESS */

static inline U16 LZ4_readLE16(const void *memPtr)
{
	if (LZ4_isLittleEndian()) {
		return LZ4_read16(memPtr);
	} else {
		const BYTE *p = (const BYTE *)memPtr;
		return (U16)((U16)p[0] | (p[1] << 8));
	}
}

#ifdef LZ4_STATIC_LINKING_ONLY_ENDIANNESS_INDEPENDENT_OUTPUT
static inline U32 LZ4_readLE32(const void *memPtr)
{
	if (LZ4_isLittleEndian()) {
		return LZ4_read32(memPtr);
	} else {
		const BYTE *p = (const BYTE *)memPtr;
		return (U32)p[0] | (p[1] << 8) | (p[2] << 16) | (p[3] << 24);
	}
}
#endif

static inline void LZ4_writeLE16(void *memPtr, U16 value)
{
	if (LZ4_isLittleEndian()) {
		LZ4_write16(memPtr, value);
	} else {
		BYTE *p = (BYTE *)memPtr;
		p[0] = (BYTE)value;
		p[1] = (BYTE)(value >> 8);
	}
}

/* customized variant of memcpy, which can overwrite up to 8 bytes beyond dstEnd */
LZ4_FORCE_INLINE
void LZ4_wildCopy8(void *dstPtr, const void *srcPtr, void *dstEnd)
{
	BYTE *d = (BYTE *)dstPtr;
	const BYTE *s = (const BYTE *)srcPtr;
	BYTE *const e = (BYTE *)dstEnd;

	do {
		LZ4_memcpy(d, s, 8);
		d += 8;
		s += 8;
	} while (d < e);
}

static const unsigned inc32table[8] = { 0, 1, 2, 1, 0, 4, 4, 4 };
static const int dec64table[8] = { 0, 0, 0, -1, -4, 1, 2, 3 };

#ifndef LZ4_FAST_DEC_LOOP
#if defined __i386__ || defined _M_IX86 || defined __x86_64__ || defined _M_X64
#define LZ4_FAST_DEC_LOOP 1
#elif defined(__aarch64__) && defined(__APPLE__)
#define LZ4_FAST_DEC_LOOP 1
#elif defined(__aarch64__) && !defined(__clang__)
/* On non-Apple aarch64, we disable this optimization for clang because
      * on certain mobile chipsets, performance is reduced with clang. For
      * more information refer to https://github.com/lz4/lz4/pull/707 */
#define LZ4_FAST_DEC_LOOP 1
#else
#define LZ4_FAST_DEC_LOOP 0
#endif
#endif

#if LZ4_FAST_DEC_LOOP

LZ4_FORCE_INLINE void LZ4_memcpy_using_offset_base(BYTE *dstPtr,
						   const BYTE *srcPtr,
						   BYTE *dstEnd,
						   const size_t offset)
{
	assert(srcPtr + offset == dstPtr);
	if (offset < 8) {
		LZ4_write32(dstPtr,
			    0); /* silence an msan warning when offset==0 */
		dstPtr[0] = srcPtr[0];
		dstPtr[1] = srcPtr[1];
		dstPtr[2] = srcPtr[2];
		dstPtr[3] = srcPtr[3];
		srcPtr += inc32table[offset];
		LZ4_memcpy(dstPtr + 4, srcPtr, 4);
		srcPtr -= dec64table[offset];
		dstPtr += 8;
	} else {
		LZ4_memcpy(dstPtr, srcPtr, 8);
		dstPtr += 8;
		srcPtr += 8;
	}

	LZ4_wildCopy8(dstPtr, srcPtr, dstEnd);
}

/* customized variant of memcpy, which can overwrite up to 32 bytes beyond dstEnd
 * this version copies two times 16 bytes (instead of one time 32 bytes)
 * because it must be compatible with offsets >= 16. */
LZ4_FORCE_INLINE void LZ4_wildCopy32(void *dstPtr, const void *srcPtr,
				     void *dstEnd)
{
	BYTE *d = (BYTE *)dstPtr;
	const BYTE *s = (const BYTE *)srcPtr;
	BYTE *const e = (BYTE *)dstEnd;

	do {
		LZ4_memcpy(d, s, 16);
		LZ4_memcpy(d + 16, s + 16, 16);
		d += 32;
		s += 32;
	} while (d < e);
}

/* LZ4_memcpy_using_offset()  presumes :
 * - dstEnd >= dstPtr + MINMATCH
 * - there is at least 12 bytes available to write after dstEnd */
LZ4_FORCE_INLINE void LZ4_memcpy_using_offset(BYTE *dstPtr, const BYTE *srcPtr,
					      BYTE *dstEnd, const size_t offset)
{
	BYTE v[8];

	assert(dstEnd >= dstPtr + MINMATCH);

	switch (offset) {
	case 1:
		MEM_INIT(v, *srcPtr, 8);
		break;
	case 2:
		LZ4_memcpy(v, srcPtr, 2);
		LZ4_memcpy(&v[2], srcPtr, 2);
#if defined(_MSC_VER) && (_MSC_VER <= 1937) /* MSVC 2022 ver 17.7 or earlier */
#pragma warning(push)
#pragma warning(disable                                                        \
		: 6385) /* warning C6385: Reading invalid data from 'v'. */
#endif
		LZ4_memcpy(&v[4], v, 4);
#if defined(_MSC_VER) && (_MSC_VER <= 1937) /* MSVC 2022 ver 17.7 or earlier */
#pragma warning(pop)
#endif
		break;
	case 4:
		LZ4_memcpy(v, srcPtr, 4);
		LZ4_memcpy(&v[4], srcPtr, 4);
		break;
	default:
		LZ4_memcpy_using_offset_base(dstPtr, srcPtr, dstEnd, offset);
		return;
	}

	LZ4_memcpy(dstPtr, v, 8);
	dstPtr += 8;
	while (dstPtr < dstEnd) {
		LZ4_memcpy(dstPtr, v, 8);
		dstPtr += 8;
	}
}
#endif

/*-************************************
*  Common functions
**************************************/
static unsigned LZ4_NbCommonBytes(reg_t val)
{
	assert(val != 0);
	if (LZ4_isLittleEndian()) {
		if (sizeof(val) == 8) {
#if defined(_MSC_VER) && (_MSC_VER >= 1800) &&                                 \
	(defined(_M_AMD64) && !defined(_M_ARM64EC)) &&                         \
	!defined(LZ4_FORCE_SW_BITCOUNT)
/*-*************************************************************************************************
* ARM64EC is a Microsoft-designed ARM64 ABI compatible with AMD64 applications on ARM64 Windows 11.
* The ARM64EC ABI does not support AVX/AVX2/AVX512 instructions, nor their relevant intrinsics
* including _tzcnt_u64. Therefore, we need to neuter the _tzcnt_u64 code path for ARM64EC.
****************************************************************************************************/
#if defined(__clang__) && (__clang_major__ < 10)
			/* Avoid undefined clang-cl intrinsics issue.
             * See https://github.com/lz4/lz4/pull/1017 for details. */
			return (unsigned)__builtin_ia32_tzcnt_u64(val) >> 3;
#else
			/* x64 CPUS without BMI support interpret `TZCNT` as `REP BSF` */
			return (unsigned)_tzcnt_u64(val) >> 3;
#endif
#elif defined(_MSC_VER) && defined(_WIN64) && !defined(LZ4_FORCE_SW_BITCOUNT)
			unsigned long r = 0;
			_BitScanForward64(&r, (U64)val);
			return (unsigned)r >> 3;
#elif (defined(__clang__) ||                                                   \
       (defined(__GNUC__) &&                                                   \
	((__GNUC__ > 3) || ((__GNUC__ == 3) && (__GNUC_MINOR__ >= 4))))) &&    \
	!defined(LZ4_FORCE_SW_BITCOUNT)
			return (unsigned)__builtin_ctzll((U64)val) >> 3;
#else
			const U64 m = 0x0101010101010101ULL;
			val ^= val - 1;
			return (unsigned)(((U64)((val & (m - 1)) * m)) >> 56);
#endif
		} else /* 32 bits */ {
#if defined(_MSC_VER) && (_MSC_VER >= 1400) && !defined(LZ4_FORCE_SW_BITCOUNT)
			unsigned long r;
			_BitScanForward(&r, (U32)val);
			return (unsigned)r >> 3;
#elif (defined(__clang__) ||                                                   \
       (defined(__GNUC__) &&                                                   \
	((__GNUC__ > 3) || ((__GNUC__ == 3) && (__GNUC_MINOR__ >= 4))))) &&    \
	!defined(__TINYC__) && !defined(LZ4_FORCE_SW_BITCOUNT)
			return (unsigned)__builtin_ctz((U32)val) >> 3;
#else
			const U32 m = 0x01010101;
			return (unsigned)((((val - 1) ^ val) & (m - 1)) * m) >>
			       24;
#endif
		}
	} else /* Big Endian CPU */ {
		if (sizeof(val) == 8) {
#if (defined(__clang__) ||                                                     \
     (defined(__GNUC__) &&                                                     \
      ((__GNUC__ > 3) || ((__GNUC__ == 3) && (__GNUC_MINOR__ >= 4))))) &&      \
	!defined(__TINYC__) && !defined(LZ4_FORCE_SW_BITCOUNT)
			return (unsigned)__builtin_clzll((U64)val) >> 3;
#else
#if 1
			/* this method is probably faster,
             * but adds a 128 bytes lookup table */
			static const unsigned char ctz7_tab[128] = {
				7, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
				4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
				5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
				4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
				6, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
				4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
				5, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
				4, 0, 1, 0, 2, 0, 1, 0, 3, 0, 1, 0, 2, 0, 1, 0,
			};
			U64 const mask = 0x0101010101010101ULL;
			U64 const t = (((val >> 8) - mask) | val) & mask;
			return ctz7_tab[(t * 0x0080402010080402ULL) >> 57];
#else
			/* this method doesn't consume memory space like the previous one,
             * but it contains several branches,
             * that may end up slowing execution */
			static const U32 by32 =
				sizeof(val) *
				4; /* 32 on 64 bits (goal), 16 on 32 bits.
            Just to avoid some static analyzer complaining about shift by 32 on 32-bits target.
            Note that this code path is never triggered in 32-bits mode. */
			unsigned r;
			if (!(val >> by32)) {
				r = 4;
			} else {
				r = 0;
				val >>= by32;
			}
			if (!(val >> 16)) {
				r += 2;
				val >>= 8;
			} else {
				val >>= 24;
			}
			r += (!val);
			return r;
#endif
#endif
		} else /* 32 bits */ {
#if (defined(__clang__) ||                                                     \
     (defined(__GNUC__) &&                                                     \
      ((__GNUC__ > 3) || ((__GNUC__ == 3) && (__GNUC_MINOR__ >= 4))))) &&      \
	!defined(LZ4_FORCE_SW_BITCOUNT)
			return (unsigned)__builtin_clz((U32)val) >> 3;
#else
			val >>= 8;
			val = ((((val + 0x00FFFF00) | 0x00FFFFFF) + val) |
			       (val + 0x00FF0000)) >>
			      24;
			return (unsigned)val ^ 3;
#endif
		}
	}
}

#define STEPSIZE sizeof(reg_t)
LZ4_FORCE_INLINE
unsigned LZ4_count(const BYTE *pIn, const BYTE *pMatch, const BYTE *pInLimit)
{
	const BYTE *const pStart = pIn;

	if (likely(pIn < pInLimit - (STEPSIZE - 1))) {
		reg_t const diff = LZ4_read_ARCH(pMatch) ^ LZ4_read_ARCH(pIn);
		if (!diff) {
			pIn += STEPSIZE;
			pMatch += STEPSIZE;
		} else {
			return LZ4_NbCommonBytes(diff);
		}
	}

	while (likely(pIn < pInLimit - (STEPSIZE - 1))) {
		reg_t const diff = LZ4_read_ARCH(pMatch) ^ LZ4_read_ARCH(pIn);
		if (!diff) {
			pIn += STEPSIZE;
			pMatch += STEPSIZE;
			continue;
		}
		pIn += LZ4_NbCommonBytes(diff);
		return (unsigned)(pIn - pStart);
	}

	if ((STEPSIZE == 8) && (pIn < (pInLimit - 3)) &&
	    (LZ4_read32(pMatch) == LZ4_read32(pIn))) {
		pIn += 4;
		pMatch += 4;
	}
	if ((pIn < (pInLimit - 1)) && (LZ4_read16(pMatch) == LZ4_read16(pIn))) {
		pIn += 2;
		pMatch += 2;
	}
	if ((pIn < pInLimit) && (*pMatch == *pIn))
		pIn++;
	return (unsigned)(pIn - pStart);
}

/*-************************************
*  Local Constants
**************************************/
static const int LZ4_64Klimit = ((64 KB) + (MFLIMIT - 1));
static const U32 LZ4_skipTrigger =
	6; /* Increase this value ==> compression run slower on incompressible data */

/*-************************************
*  Local Structures and types
**************************************/
typedef enum { clearedTable = 0, byPtr, byU32, byU16 } tableType_t;

/**
 * This enum distinguishes several different modes of accessing previous
 * content in the stream.
 *
 * - noDict        : There is no preceding content.
 * - withPrefix64k : Table entries up to ctx->dictSize before the current blob
 *                   blob being compressed are valid and refer to the preceding
 *                   content (of length ctx->dictSize), which is available
 *                   contiguously preceding in memory the content currently
 *                   being compressed.
 * - usingExtDict  : Like withPrefix64k, but the preceding content is somewhere
 *                   else in memory, starting at ctx->dictionary with length
 *                   ctx->dictSize.
 * - usingDictCtx  : Everything concerning the preceding content is
 *                   in a separate context, pointed to by ctx->dictCtx.
 *                   ctx->dictionary, ctx->dictSize, and table entries
 *                   in the current context that refer to positions
 *                   preceding the beginning of the current compression are
 *                   ignored. Instead, ctx->dictCtx->dictionary and ctx->dictCtx
 *                   ->dictSize describe the location and size of the preceding
 *                   content, and matches are found by looking in the ctx
 *                   ->dictCtx->hashTable.
 */
typedef enum {
	noDict = 0,
	withPrefix64k,
	usingExtDict,
	usingDictCtx
} dict_directive;
typedef enum { noDictIssue = 0, dictSmall } dictIssue_directive;

#endif
