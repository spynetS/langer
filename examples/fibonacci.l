package main;

func printf(fmt: string, d: double): void;

func main(): int {
  n : int = 100;
  i : int;

  t1 : double = 0
  t2 : double = 1
  nextTerm : double = 0
  i = 1
  // while i <= n {
       printf("%f\n", t1)
       nextTerm = t1+t2
       t1=t2
       t2=nextTerm;
       i = i + 1;
  // }

  return 0;
}
