package std.mem;

extern malloc(size: int): *byte;
extern free(ptr: *void);


func alloc(size: int): *byte {
	return malloc(size);
}

func fre(ptr: *byte) {
	free(ptr)
}