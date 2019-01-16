
build/Main.smc: Main.asm Main.link include/*.asm include/*.inc
	if [ ! -d "build" ]; then mkdir build; fi
	wla-65816 -v -o build/Main.obj Main.asm
	wlalink -v -r Main.link build/Main.smc

.PHONY: clean
clean:
	rm -r build

