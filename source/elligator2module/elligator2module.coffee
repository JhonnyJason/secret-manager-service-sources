elligator2module = {name: "elligator2module"}
############################################################
#region printLogFunctions
log = (arg) ->
    if allModules.debugmodule.modulesToDebug["elligator2module"]?  then console.log "[elligator2module]: " + arg
    return
ostr = (obj) -> JSON.stringify(obj, null, 4)
olog = (obj) -> log "\n" + ostr(obj)
print = (arg) -> console.log(arg)
#endregion

############################################################
utl = null

############################################################
elligator2module.initialize = () ->
    log "elligator2module.initialize"
    utl = allModules.bufferutilmodule
    return
    
############################################################
#region 
elligator2module.stringToPoint = (stringHex) ->
    log "elligator2module.stringToPoint"
    # static const fe ufactor={-1917299, 15887451, -18755900, -7000830, -24778944, 544946, -16816446, 4011309, -653372, 10741468,};
    # TODO figure out how to use this number
    ufactor = [
        -1917299, # FFE2BE8D
        15887451, # 00F26C5B
        -18755900, # FEE1CEC4
        -7000830, # FF952D02
        -24778944, # FE85E740
        544946, # 000850B2
        -16816446, # FEFF66C2
        4011309, # 003D352D
        -653372, # FFF607C4
        10741468 # 00A3E6DC
    ]
    
    ufactorHex = "FFE2BE8D00F26C5BFEE1CEC4FF952D02FE85E740000850B2FEFF66C2003D352DFFF607C400A3E6DC"

    # static const fe A = {486662};
    A = 486662n
    
    # static const fe A2 = {12721188, 3529,};
    # TODO figure out how to use this number
    A2 = [
        12721188, # 00C21C24
        3529 # 0DC9
        0,
        0,
        0

    ]



    # the two first bits are ignored
    # u8 clamped[32];
    # COPY(clamped, hidden, 32);
    data = Buffer.from(stringHex, "hex")

    # the two first bits are ignored
    # clamped[31] &= 0x3f;
    data[31] &= 0x3f

    # fe r, u, t1, t2, t3;
    # fe_frombytes(r, clamped);
    r =  utl.bytesToBigInt(data)

    # fe_sq2(t1, r) => t1 = 2 * r^2
    t1 = 2n * (r ** 2n)

    # fe_add(u, t1, fe_one);
    u = t1 + 1n
    
    # fe_sq (t2, u);
    t2 = u ** 2n

    # fe_mul(t3, A2, t1);
    t3 = A2 * t1

    # fe_sub(t3, t3, t2);
    t3 = t3 - t2

    # fe_mul(t3, t3, A);
    t3 = t3 * A

    # fe_mul(t1, t2, u);
    t1 = t2 * u

    # fe_mul(t1, t3, t1);
    t1 = t3 * t1

#     int is_square = invsqrt(t1, t1);

    # fe_sq(u, r);
    u = r ** 2n

    # fe_mul(u, u, ufactor);
    u = u * ufactor

#     fe_ccopy(u, fe_one, is_square);

    # fe_sq (t1, t1);
    t1 = t1 ** 2n

    # fe_mul(u, u, A);
    u = u * A

    # fe_mul(u, u, t3);
    u = u * t3

    # fe_mul(u, u, t2);
    u = u * t2

    # fe_mul(u, u, t1);
    u =  u * t1

    # fe_neg(u, u);
    u = -u

#     fe_tobytes(curve, u);

    return u




module.exports = elligator2module

# ///////////////////
# /// Elligator 2 ///
# ///////////////////
# static const fe A = {486662};

# // Elligator direct map
# //
# // Computes the point corresponding to a representative, encoded in 32
# // bytes (little Endian).  Since positive representatives fits in 254
# // bits, The two most significant bits are ignored.
# //
# // From the paper:
# // w = -A / (fe(1) + non_square * r^2)
# // e = chi(w^3 + A*w^2 + w)
# // u = e*w - (fe(1)-e)*(A//2)
# // v = -e * sqrt(u^3 + A*u^2 + u)
# //
# // We ignore v because we don't need it for X25519 (the Montgomery
# // ladder only uses u).
# //
# // Note that e is either 0, 1 or -1
# // if e = 0    u = 0  and v = 0
# // if e = 1    u = w
# // if e = -1   u = -w - A = w * non_square * r^2
# //
# // Let r1 = non_square * r^2
# // Let r2 = 1 + r1
# // Note that r2 cannot be zero, -1/non_square is not a square.
# // We can (tediously) verify that:
# //   w^3 + A*w^2 + w = (A^2*r1 - r2^2) * A / r2^3
# // Therefore:
# //   chi(w^3 + A*w^2 + w) = chi((A^2*r1 - r2^2) * (A / r2^3))
# //   chi(w^3 + A*w^2 + w) = chi((A^2*r1 - r2^2) * (A / r2^3)) * 1
# //   chi(w^3 + A*w^2 + w) = chi((A^2*r1 - r2^2) * (A / r2^3)) * chi(r2^6)
# //   chi(w^3 + A*w^2 + w) = chi((A^2*r1 - r2^2) * (A / r2^3)  *     r2^6)
# //   chi(w^3 + A*w^2 + w) = chi((A^2*r1 - r2^2) *  A * r2^3)
# // Corollary:
# //   e =  1 if (A^2*r1 - r2^2) *  A * r2^3) is a non-zero square
# //   e = -1 if (A^2*r1 - r2^2) *  A * r2^3) is not a square
# //   Note that w^3 + A*w^2 + w (and therefore e) can never be zero:
# //     w^3 + A*w^2 + w = w * (w^2 + A*w + 1)
# //     w^3 + A*w^2 + w = w * (w^2 + A*w + A^2/4 - A^2/4 + 1)
# //     w^3 + A*w^2 + w = w * (w + A/2)^2        - A^2/4 + 1)
# //     which is zero only if:
# //       w = 0                   (impossible)
# //       (w + A/2)^2 = A^2/4 - 1 (impossible, because A^2/4-1 is not a square)
# //
# // Let isr   = invsqrt((A^2*r1 - r2^2) *  A * r2^3)
# //     isr   = sqrt(1        / ((A^2*r1 - r2^2) *  A * r2^3)) if e =  1
# //     isr   = strt(sqrt(-1) / ((A^2*r1 - r2^2) *  A * r2^3)) if e = -1
# //
# // if e = 1
# //   let u1 = -A * (A^2*r1 - r2^2) * A * r2^2 * isr^2
# //       u1 = w
# //       u1 = u
# //
# // if e = -1
# //   let ufactor = -non_square * sqrt(-1) * r^2
# //   let vfactor = sqrt(ufactor)
# //   let u2 = -A * (A^2*r1 - r2^2) * A * r2^2 * isr^2 * ufactor
# //       u2 = w * -1 * -non_square * r^2
# //       u2 = w * non_square * r^2
# //       u2 = u

# void crypto_hidden_to_curve(uint8_t curve[32], const uint8_t hidden[32])
# {
#      // -sqrt(-1) * 2
#     static const fe ufactor={-1917299, 15887451, -18755900, -7000830, -24778944,
#                              544946, -16816446, 4011309, -653372, 10741468,};
#     static const fe A2 = {12721188, 3529,};

#     // Representatives are encoded in 254 bits.
#     // The two most significant ones are random padding that must be ignored.
#     u8 clamped[32];
#     COPY(clamped, hidden, 32);
#     clamped[31] &= 0x3f;

#     fe r, u, t1, t2, t3;
#     fe_frombytes(r, clamped);
#     fe_sq2(t1, r);
#     fe_add(u, t1, fe_one);
#     fe_sq (t2, u);
#     fe_mul(t3, A2, t1);
#     fe_sub(t3, t3, t2);
#     fe_mul(t3, t3, A);
#     fe_mul(t1, t2, u);
#     fe_mul(t1, t3, t1);
#     int is_square = invsqrt(t1, t1);
#     fe_sq(u, r);
#     fe_mul(u, u, ufactor);
#     fe_ccopy(u, fe_one, is_square);
#     fe_sq (t1, t1);
#     fe_mul(u, u, A);
#     fe_mul(u, u, t3);
#     fe_mul(u, u, t2);
#     fe_mul(u, u, t1);
#     fe_neg(u, u);
#     fe_tobytes(curve, u);

#     WIPE_BUFFER(t1);  WIPE_BUFFER(r);
#     WIPE_BUFFER(t2);  WIPE_BUFFER(u);
#     WIPE_BUFFER(t3);  WIPE_BUFFER(clamped);
# }

# // Elligator inverse map
# //
# // Computes the representative of a point, if possible.  If not, it does
# // nothing and returns -1.  Note that the success of the operation
# // depends only on the point (more precisely its u coordinate).  The
# // tweak parameter is used only upon success
# //
# // The tweak should be a random byte.  Beyond that, its contents are an
# // implementation detail. Currently, the tweak comprises:
# // - Bit  1  : sign of the v coordinate (0 if positive, 1 if negative)
# // - Bit  2-5: not used
# // - Bits 6-7: random padding
# //
# // From the paper:
# // Let sq = -non_square * u * (u+A)
# // if sq is not a square, or u = -A, there is no mapping
# // Assuming there is a mapping:
# //   if v is positive: r = sqrt(-(u+A) / u)
# //   if v is negative: r = sqrt(-u / (u+A))
# //
# // We compute isr = invsqrt(-non_square * u * (u+A))
# // if it wasn't a non-zero square, abort.
# // else, isr = sqrt(-1 / (non_square * u * (u+A))
# //
# // This causes us to abort if u is zero, even though we shouldn't. This
# // never happens in practice, because (i) a random point in the curve has
# // a negligible chance of being zero, and (ii) scalar multiplication with
# // a trimmed scalar *never* yields zero.
# //
# // Since:
# //   isr * (u+A) = sqrt(-1     / (non_square * u * (u+A)) * (u+A)
# //   isr * (u+A) = sqrt(-(u+A) / (non_square * u * (u+A))
# // and:
# //   isr = u = sqrt(-1 / (non_square * u * (u+A)) * u
# //   isr = u = sqrt(-u / (non_square * u * (u+A))
# // Therefore:
# //   if v is positive: r = isr * (u+A)
# //   if v is negative: r = isr * u
# int crypto_curve_to_hidden(u8 hidden[32], const u8 public_key[32], u8 tweak)
# {
#     fe t1, t2, t3;
#     fe_frombytes(t1, public_key);

#     fe_add(t2, t1, A);
#     fe_mul(t3, t1, t2);
#     fe_mul_small(t3, t3, -2);
#     int is_square = invsqrt(t3, t3);
#     if (!is_square) {
#         // The only variable time bit.  This ultimately reveals how many
#         // tries it took us to find a representable key.
#         // This does not affect security as long as we try keys at random.
#         WIPE_BUFFER(t1);
#         WIPE_BUFFER(t2);
#         WIPE_BUFFER(t3);
#         return -1;
#     }
#     fe_ccopy(t1, t2, tweak & 1);
#     fe_mul  (t3, t1, t3);
#     fe_add  (t1, t3, t3);
#     fe_neg  (t2, t3);
#     fe_ccopy(t3, t2, fe_isodd(t1));
#     fe_tobytes(hidden, t3);

#     // Pad with two random bits
#     hidden[31] |= tweak & 0xc0;

#     WIPE_BUFFER(t1);
#     WIPE_BUFFER(t2);
#     WIPE_BUFFER(t3);
#     return 0;
# }









# // Inverse square root.
# // Returns true if x is a non zero square, false otherwise.
# // After the call:
# //   isr = sqrt(1/x)        if x is non-zero square.
# //   isr = sqrt(sqrt(-1)/x) if x is not a square.
# //   isr = 0                if x is zero.
# // We do not guarantee the sign of the square root.
# //
# // Notes:
# // Let quartic = x^((p-1)/4)
# //
# // x^((p-1)/2) = chi(x)
# // quartic^2   = chi(x)
# // quartic     = sqrt(chi(x))
# // quartic     = 1 or -1 or sqrt(-1) or -sqrt(-1)
# //
# // Note that x is a square if quartic is 1 or -1
# // There are 4 cases to consider:
# //
# // if   quartic         = 1  (x is a square)
# // then x^((p-1)/4)     = 1
# //      x^((p-5)/4) * x = 1
# //      x^((p-5)/4)     = 1/x
# //      x^((p-5)/8)     = sqrt(1/x) or -sqrt(1/x)
# //
# // if   quartic                = -1  (x is a square)
# // then x^((p-1)/4)            = -1
# //      x^((p-5)/4) * x        = -1
# //      x^((p-5)/4)            = -1/x
# //      x^((p-5)/8)            = sqrt(-1)   / sqrt(x)
# //      x^((p-5)/8) * sqrt(-1) = sqrt(-1)^2 / sqrt(x)
# //      x^((p-5)/8) * sqrt(-1) = -1/sqrt(x)
# //      x^((p-5)/8) * sqrt(-1) = -sqrt(1/x) or sqrt(1/x)
# //
# // if   quartic         = sqrt(-1)  (x is not a square)
# // then x^((p-1)/4)     = sqrt(-1)
# //      x^((p-5)/4) * x = sqrt(-1)
# //      x^((p-5)/4)     = sqrt(-1)/x
# //      x^((p-5)/8)     = sqrt(sqrt(-1)/x) or -sqrt(sqrt(-1)/x)
# //
# // Note that the product of two non-squares is always a square:
# //   For any non-squares a and b, chi(a) = -1 and chi(b) = -1.
# //   Since chi(x) = x^((p-1)/2), chi(a)*chi(b) = chi(a*b) = 1.
# //   Therefore a*b is a square.
# //
# //   Since sqrt(-1) and x are both non-squares, their product is a
# //   square, and we can compute their square root.
# //
# // if   quartic                = -sqrt(-1)  (x is not a square)
# // then x^((p-1)/4)            = -sqrt(-1)
# //      x^((p-5)/4) * x        = -sqrt(-1)
# //      x^((p-5)/4)            = -sqrt(-1)/x
# //      x^((p-5)/8)            = sqrt(-sqrt(-1)/x)
# //      x^((p-5)/8)            = sqrt( sqrt(-1)/x) * sqrt(-1)
# //      x^((p-5)/8) * sqrt(-1) = sqrt( sqrt(-1)/x) * sqrt(-1)^2
# //      x^((p-5)/8) * sqrt(-1) = sqrt( sqrt(-1)/x) * -1
# //      x^((p-5)/8) * sqrt(-1) = -sqrt(sqrt(-1)/x) or sqrt(sqrt(-1)/x)
# static int invsqrt(fe isr, const fe x)
# {
#     fe check, quartic;
#     fe_copy(check, x);
#     fe_pow22523(isr, check);
#     fe_sq (quartic, isr);
#     fe_mul(quartic, quartic, check);
#     fe_1  (check);          int p1 = fe_isequal(quartic, check);
#     fe_neg(check, check );  int m1 = fe_isequal(quartic, check);
#     fe_neg(check, sqrtm1);  int ms = fe_isequal(quartic, check);
#     fe_mul(check, isr, sqrtm1);
#     fe_ccopy(isr, check, m1 | ms);
#     WIPE_BUFFER(quartic);
#     WIPE_BUFFER(check);
#     return p1 | m1;
# }