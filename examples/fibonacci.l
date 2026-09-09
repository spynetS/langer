package main;

extern printf(fmt: string, d: double);

func main(): int {
  let n : int = 100;
  let i : int;

  let t1 : double = 0
  let t2 : double = 1
  let nextTerm : double = 0
  i = 1
  while i <= n {
      printf("%f\n", t1)
      nextTerm = t1+t2
      t1=t2
      t2=nextTerm;
      i = i + 1;
  }

  return 0;
}
