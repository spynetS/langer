extern printf(string str, int val): void;
extern malloc(int size): *int;

func increment(*int ptr) {
    ptr^ = ptr^ + 1;
}

func main(): int {
    *int ptr = malloc(16);
    ptr^ = 41;
    increment(ptr);
    printf("%d", ptr^);

    int age = 25;
    ptr = age&;
    printf("%d", ptr^);
    return 0;
}
