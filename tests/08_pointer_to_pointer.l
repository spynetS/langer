extern printf(string str, int val): void;

func main(): int {
    int x = 42;
    *int p = x&;
    **int pp = p&;

    *int p2 = pp^;
    printf("%d", p2^);
    return 0;
}
