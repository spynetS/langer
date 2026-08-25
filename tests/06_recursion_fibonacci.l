extern printf(string str, int val): void;

func fib(int n): int {
    if (n < 2) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

func main(): int {
    int i = 0;
    while (i < 10) {
        printf("%d", fib(i));
        i = i + 1;
    }
    return 0;
}
