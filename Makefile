CONFIG_MODULE_SIG = n
TARGET_MODULE := fibdrv

obj-m := $(TARGET_MODULE).o
ccflags-y := -std=gnu99 -Wno-declaration-after-statement

KDIR := /lib/modules/$(shell uname -r)/build
PWD := $(shell pwd)

GIT_HOOKS := .git/hooks/applied

all: $(GIT_HOOKS) client

perf: perf_dp perf_dbl plot

perf_dp: all
	$(MAKE) -C $(KDIR) M=$(PWD) modules EXTRA_CFLAGS=-DVER_DP
	$(MAKE) unload
	$(MAKE) load
	sudo dmesg -c
	sudo ./client > out
	dmesg | cut -d ' ' -f 2- > perf_dp.out
	$(MAKE) unload

perf_dbl: all
	$(MAKE) -C $(KDIR) M=$(PWD) modules EXTRA_CFLAGS=-DVER_DBL
	$(MAKE) unload
	$(MAKE) load
	sudo dmesg -c
	sudo ./client > out
	dmesg | cut -d ' ' -f 2- > perf_dbl.out
	$(MAKE) unload

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	$(RM) client out *.png *.out
load:
	sudo insmod $(TARGET_MODULE).ko
unload:
	sudo rmmod $(TARGET_MODULE) || true >/dev/null
plot: all
	gnuplot scripts/plot.gp

client: client.c
	$(CC) -o $@ $^

PRINTF = env printf
PASS_COLOR = \e[32;01m
NO_COLOR = \e[0m
pass = $(PRINTF) "$(PASS_COLOR)$1 Passed [-]$(NO_COLOR)\n"

check: all perf_dp
	$(MAKE) unload
	$(MAKE) load
	sudo dmesg -c
	sudo ./client > out
	$(MAKE) unload
	@diff -u out expected.txt && $(call pass)
