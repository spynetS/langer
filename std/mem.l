package std.mem;

// func malloc(size: int): *byte;
// func free(ptr: *void): void;

struct Person {
age: int
}


func printf(fmt: *byte, age: int):void;

public func print(age: int): void {
	std.mem.printf("%d\n", age);
}

public func alloc(size: int): byte {
//return std.mem.malloc(size);
}

