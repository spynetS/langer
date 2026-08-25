extern printf(string str, int val): void;

func main(): int {
    int a = 5;
    int b = 7;
    int sum = a + b;
    int diff = b - a;
    int prod = a * b;
    int quot = b / a;
    int rem = b % a;
    printf("%d", sum);
    printf("%d", diff);
    printf("%d", prod);
    printf("%d", quot);
    printf("%d", rem);
    return 0;
}
