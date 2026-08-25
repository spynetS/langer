extern printf(string str, int val): void;
extern print_str(string s): void;

func greet(string name): void {
    print_str(name);
}

func main(): int {
    string language = "mylang";
    greet(language);
    return 0;
}
