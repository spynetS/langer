package std.mem;

extern func malloc(size: int): *byte;
extern func free(ptr: *void): int;


func alloc(size: int): *byte {
    return malloc(size);
}

func free(size: int): int {
    return free(size);
}
