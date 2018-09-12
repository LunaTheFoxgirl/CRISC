#define TEST 32
#define TEST_A 64
mov TEST @0x0
mov TEST_A @0x1

dbg PRT_REG @0x0
dbg PRT_REG @0x1


#define TEST_DEF
#ifdef TEST_DEF

dbg PRT_REG @0x0

#endif

#ifndef TEST_DEF

dbg PRT_REG @0x1

#endif
