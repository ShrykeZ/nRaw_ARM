.text
.align 2

// u64 _umul128(u64 m1, u64 m2, u64* hi)
// Returns low 64 bits of m1*m2, stores high 64 bits at *hi
.global _umul128
.type _umul128, @function
_umul128:
    umulh   x3, x0, x1      // x3 = high 64 bits of x0*x1
    mul     x0, x0, x1      // x0 = low 64 bits of x0*x1
    str     x3, [x2]        // Store high bits at *hi
    ret
.size _umul128, .-_umul128

// u8 _addcarry_u64(u8 c_in, u64 a, u64 b, u64* out)
// *out = a + b + c_in, returns carry out
.global _addcarry_u64
.type _addcarry_u64, @function
_addcarry_u64:
    // x0 = c_in, x1 = a, x2 = b, x3 = out
    and     x0, x0, #1      // Ensure c_in is 0 or 1
    
    // Add a + b first
    adds    x4, x1, x2      // x4 = a + b
    cset    x5, cs          // x5 = carry from a + b (0 or 1)
    
    // Add c_in to the result
    adds    x4, x4, x0      // x4 = (a + b) + c_in
    cset    x6, cs          // x6 = carry from (a + b) + c_in (0 or 1)
    
    // Final carry is OR of both potential carries
    orr     x0, x5, x6      // x0 = carry1 OR carry2
    str     x4, [x3]        // Store result
    ret
.size _addcarry_u64, .-_addcarry_u64

// u8 _subborrow_u64(u8 b_in, u64 a, u64 b, u64* out)
// *out = a - b - b_in, returns borrow out
.global _subborrow_u64
.type _subborrow_u64, @function
_subborrow_u64:
    // x0 = b_in, x1 = a, x2 = b, x3 = out
    and     x0, x0, #1      // Ensure b_in is 0 or 1
    
    // Subtract b from a first
    subs    x4, x1, x2      // x4 = a - b
    cset    x5, cc          // x5 = borrow from a - b (0 or 1)
    
    // Subtract b_in from the result
    subs    x4, x4, x0      // x4 = (a - b) - b_in
    cset    x6, cc          // x6 = borrow from (a - b) - b_in (0 or 1)
    
    // Final borrow is OR of both potential borrows
    orr     x0, x5, x6      // x0 = borrow1 OR borrow2
    str     x4, [x3]        // Store result
    ret
.size _subborrow_u64, .-_subborrow_u64

// u64 __shiftleft128(u64 low, u64 high, u8 shift)
// Shift 128-bit value (high:low) left by shift bits, return HIGH 64 bits of result
.global __shiftleft128
.type __shiftleft128, @function
__shiftleft128:
    // x0 = low, x1 = high, x2 = shift
    and     x2, x2, #63     // Mask shift to 0-63
    cbz     x2, 2f          // If shift == 0, return high unchanged
    
    mov     x3, #64
    sub     x3, x3, x2      // x3 = 64 - shift
    
    lsl     x4, x1, x2      // x4 = high << shift
    lsr     x5, x0, x3      // x5 = low >> (64 - shift) - bits that carry over
    orr     x0, x4, x5      // x0 = (high << shift) | (low >> (64 - shift))
    ret
    
2:  // shift == 0 case, return high unchanged
    mov     x0, x1
    ret
.size __shiftleft128, .-__shiftleft128

// u64 __shiftright128(u64 low, u64 high, u8 shift)
// Shift 128-bit value (high:low) right by shift bits, return LOW 64 bits of result  
.global __shiftright128
.type __shiftright128, @function
__shiftright128:
    // x0 = low, x1 = high, x2 = shift
    and     x2, x2, #63     // Mask shift to 0-63
    cbz     x2, 1f          // If shift == 0, return low unchanged
    
    mov     x3, #64
    sub     x3, x3, x2      // x3 = 64 - shift
    
    lsr     x4, x0, x2      // x4 = low >> shift
    lsl     x5, x1, x3      // x5 = high << (64 - shift) - bits that carry over
    orr     x0, x4, x5      // x0 = (low >> shift) | (high << (64 - shift))
    ret
    
1:  // shift == 0 case
    ret
.size __shiftright128, .-__shiftright128 

// void _BitScanReverse64(u32* index, u64 mask)
// Find most significant bit set in mask
.global _BitScanReverse64
.type _BitScanReverse64, @function
_BitScanReverse64:
    // x0 = index*, x1 = mask
    cbz     x1, 1f          // If mask == 0, set index = 0
    clz     x2, x1          // Count leading zeros
    mov     x3, #63
    sub     x2, x3, x2      // index = 63 - clz
    str     w2, [x0]        // Store as 32-bit value
    ret
    
1:  // mask == 0 case
    str     wzr, [x0]       // Store 0
    ret
.size _BitScanReverse64, .-_BitScanReverse64

// void _BitScanForward64(u32* index, u64 mask)
// Find least significant bit set in mask
.global _BitScanForward64  
.type _BitScanForward64, @function
_BitScanForward64:
    // x0 = index*, x1 = mask
    cbz     x1, 1f          // If mask == 0, set index = 0
    rbit    x2, x1          // Reverse bits
    clz     x2, x2          // Count leading zeros of reversed = trailing zeros of original
    str     w2, [x0]        // Store as 32-bit value
    ret
    
1:  // mask == 0 case  
    str     wzr, [x0]       // Store 0
    ret
.size _BitScanForward64, .-_BitScanForward64
