package main;

extern func printf(fmt: *byte, d: double): void;

func main(): int {
  n : int = 100;
  i : int = 1;

  t1 := 1.0
  t2 := 1.0
  nextTerm :f64= 0.0
  while (i <= n) {
       printf("%f\n", t1)
       nextTerm = t1+t2
       t1=t2
       t2=nextTerm;
       i = i + 1;
  }

  return 0;
}
