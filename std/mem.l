package std.mem;

public extern malloc(size: int): *byte;
extern free(ptr: *void);


public func alloc(size: int): *byte {
	return malloc(size);
}

public func fre(ptr: *byte) {
	free(ptr)
}
