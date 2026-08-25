extern printf(string str, int val): void;

struct Point {
    int x;
    int y;
}

func main(): int {
    Point p;
    p.x = 3;
    p.y = 4;
    int sum = p.x + p.y;
    printf("%d", sum);
    return 0;
}
