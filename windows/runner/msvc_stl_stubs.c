/*
 * msvc_stl_stubs.c
 *
 * Stub implementations of MSVC STL vectorized intrinsics introduced in VS2022.
 * These are required when linking against Firebase C++ SDK prebuilt libs that
 * were compiled with VS2022 STL, while the project is built with VS2019 (v142).
 *
 * The stubs are functionally correct (scalar) replacements for the SIMD-optimized
 * versions present in VS2022's msvcp140.dll / vcruntime140.dll.
 */

#include <stdint.h>
#include <stddef.h>

/* __std_find_trivial_1: find first occurrence of a 1-byte value */
void* __std_find_trivial_1(const void* first, const void* last, uint8_t val) {
    const uint8_t* p = (const uint8_t*)first;
    const uint8_t* e = (const uint8_t*)last;
    while (p != e) {
        if (*p == val) return (void*)p;
        ++p;
    }
    return (void*)last;
}

/* __std_find_trivial_8: find first occurrence of an 8-byte (pointer) value */
void* __std_find_trivial_8(const void* first, const void* last, uint64_t val) {
    const uint64_t* p = (const uint64_t*)first;
    const uint64_t* e = (const uint64_t*)last;
    while (p != e) {
        if (*p == val) return (void*)p;
        ++p;
    }
    return (void*)last;
}

/* __std_find_last_trivial_1: find last occurrence of a 1-byte value */
const void* __std_find_last_trivial_1(const void* first, const void* last, uint8_t val) {
    const uint8_t* p = (const uint8_t*)last;
    const uint8_t* f = (const uint8_t*)first;
    while (p != f) {
        --p;
        if (*p == val) return (const void*)p;
    }
    return (const void*)last; /* not found: return end (as per STL convention) */
}

/* __std_find_first_of_trivial_1: find first element matching any in a 1-byte set */
const void* __std_find_first_of_trivial_1(const void* first, const void* last,
                                           const void* s_first, const void* s_last) {
    const uint8_t* p  = (const uint8_t*)first;
    const uint8_t* e  = (const uint8_t*)last;
    const uint8_t* sf = (const uint8_t*)s_first;
    const uint8_t* sl = (const uint8_t*)s_last;
    while (p != e) {
        const uint8_t* s = sf;
        while (s != sl) {
            if (*p == *s) return (const void*)p;
            ++s;
        }
        ++p;
    }
    return (const void*)last;
}

/* __std_remove_8: remove 8-byte elements equal to val (stable, in-place) */
void* __std_remove_8(void* first, void* last, uint64_t val) {
    uint64_t* out = (uint64_t*)first;
    uint64_t* p   = (uint64_t*)first;
    uint64_t* e   = (uint64_t*)last;
    while (p != e) {
        if (*p != val) {
            *out = *p;
            ++out;
        }
        ++p;
    }
    return (void*)out;
}

/* __std_find_last_of_trivial_pos_1: find last position of any 1-byte char in set,
   returns index or (size_t)-1 if not found */
size_t __std_find_last_of_trivial_pos_1(const void* ptr, size_t count,
                                         const void* s_ptr, size_t s_count) {
    const uint8_t* p  = (const uint8_t*)ptr;
    const uint8_t* sp = (const uint8_t*)s_ptr;
    size_t i = count;
    while (i > 0) {
        --i;
        size_t j;
        for (j = 0; j < s_count; ++j) {
            if (p[i] == sp[j]) return i;
        }
    }
    return (size_t)-1; /* npos */
}
