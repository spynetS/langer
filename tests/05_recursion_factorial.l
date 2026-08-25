extern printf(string str, int val): void;

func factorial(int n): int {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

func main(): int {
    int result = factorial(6);
    printf("%d", result);
    return 0;
}
