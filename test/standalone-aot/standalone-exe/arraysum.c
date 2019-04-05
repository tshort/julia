#include <stdio.h> 
#include <julia.h> 

extern long arraysum(long);
extern void init_lib(void);
extern void jl_init(void);

int main()
{
   jl_init();
   init_lib();
   printf("arraysum: %ld\n", arraysum(5));
   jl_atexit_hook(0);
   return 0;
}