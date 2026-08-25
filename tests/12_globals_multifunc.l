extern printf(string str, int val): void;

int counter = 0;

func increment(): void {
    counter = counter + 1;
}

func reset(): void {
    counter = 0;
}

func main(): int {
    increment();
    increment();
    increment();
    printf("%d", counter);
    reset();
    printf("%d", counter);
    return 0;
}
