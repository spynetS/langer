package std.fmt;

extern func printf(fmt: *byte, str: *byte, age: int): void;

func print(str: *byte): void {
	printf("%s\n", str, 0)
}

func print_int(num: int): void {
	printf("%s%d\n", "", num)
}

