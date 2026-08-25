extern printf(string str, int val): void;

func main(): int {
    int a = 5;
    string s = "hello";
    int bad = a + s;
    printf("%d", bad);
    return 0;
}
