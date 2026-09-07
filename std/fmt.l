package std.fmt;

extern printf(fmt: string, str: string, age: int);

public func print(str: string) {
	printf("%s\n", str, 0)
}
public func print_int(str: int) {
	printf("%s%d\n", "", str)
}

