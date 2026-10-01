package std.mem;

func malloc(size: int): *byte;
func free(ptr: *void): void;


public func alloc(size: int): *byte {
	return std.mem.malloc(size);
}

