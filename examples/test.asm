#define TEST_H @1

call #test
halt

test:
    mov 1 TEST_H
    dbg PRT_REG TEST_H