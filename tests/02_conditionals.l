extern printf(string str, int val): void;

func classify(int n): int {
    if (n < 0) {
        return -1;
    } else if (n == 0) {
        return 0;
    } else {
        return 1;
    }
}

func main(): int {
    printf("%d", classify(-5));
    printf("%d", classify(0));
    printf("%d", classify(42));
    return 0;
}
