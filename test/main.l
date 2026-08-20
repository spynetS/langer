extern malloc(int size) : int;
extern printf(string fmt, int size) : int;
extern loop (int str, int index, int size) : void;
extern sprintf(int ptr, string format, string name);


func loop (int str, int index, int size) : void {
  printf("%c ", str[index]);
  if index < size {
      loop(str, index+1, size)
    }
}


func main(): int {
  let age: int  = malloc(256);
  
  sprintf(age, "%s", "Alfred")
  
  loop(age, 0, 4);

  return 0;
}
