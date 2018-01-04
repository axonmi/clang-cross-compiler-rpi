# clang-cross-compiler-rpi


## Quick start
Run `./generate_sdk.sh -s <SDK_PATH>`. This will generate the clang based cross compiler in that directory. You can test by:

    arm-linux-agnueabihf-clang -o testc test.c -lm
    arm-linux-gnueabihf-clang++ -o testcc test.cc

Then copy the files onto raspberry pi and execute.


## Sysroot directories

On Raspberry PI the following command was used to get the sysroot:

    cp --parents -a /usr/lib/arm-linux-gnueabihf /usr/lib/gcc/arm-linux-gnueabihf  /usr/include /lib/arm-linux-gnueabihf sysroot

## References

http://clang.llvm.org/docs/CrossCompilation.html

https://medium.com/@zw3rk/making-a-raspbian-cross-compilation-sdk-830fe56d75ba
