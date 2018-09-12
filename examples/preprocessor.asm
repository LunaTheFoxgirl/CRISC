#define TEST 32
#define TEST_A 64
mov TEST @0x0
mov TEST_A @0x1

dbg PRT_REG @0x0
dbg PRT_REG @0x1
