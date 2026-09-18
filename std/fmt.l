package std.fmt;

func printf(fmt: string, str: string, age: int): void

func print(str: string):void {
	printf("%s\n", str, 0)
}
func print_int(str: int):void {
	printf("%s%d\n", "", str)
}

