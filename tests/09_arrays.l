extern printf(string str, int val): void;

func main(): int {
    int arr[5];
    int i = 0;
    while (i < 5) {
        arr[i] = i * i;
        i = i + 1;
    }
    printf("%d", arr[4]);
    return 0;
}
