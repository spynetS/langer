package std.mem;

extern func malloc(size: int): *byte;
extern func free(ptr: *void): void;

struct Person {
age: int
}


extern func printf(fmt: *byte, age: int): void;

public func print(age: int): void {
printf("%d\n", age);
}

public func alloc(size: int): *byte {
return malloc(size);
}

