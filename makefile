ZEPHYR=ext/zephyr
SHELL=/bin/bash
NETLIST_DEPENDENCIES=$(shell find hardware/scala -type f)
.ONESHELL:
ROOT=$(shell pwd)

clean:
	rm -rf ext/zephyr/samples/synchronization/vexriscv_*
	rm -rf ext/zephyr/samples/philosophers/vexriscv_*
	make -C software/bootloader/up5kPerf clean
	make -C software/bootloader/up5kArea clean
	make -C software/bootloader/igloo2Perf clean
	make -C software/dhrystone/igloo2Perf clean
	make -C software/dhrystone/up5kPerf clean
	make -C software/dhrystone/up5kArea clean
	make -C software/emulation/area clean
	make -C test/up5kPerf clean
	make -C test/up5kArea clean
	make -C test/igloo2Perf clean


.PHONY: software/bootloader
software/bootloader:
	source ${ZEPHYR}/zephyr-env.sh
	make -C software/bootloader/up5kPerf all
	make -C software/bootloader/up5kArea all
	make -C software/bootloader/igloo2Perf all

.PHONY: software/bootloader
software/emulation:
	source ${ZEPHYR}/zephyr-env.sh
	make -C software/emulation/area all

${ZEPHYR}/samples/%/zephyr/zephyr.bin:
	cd ${ZEPHYR}
	source zephyr-env.sh
	rm -rf samples/$(*)
	mkdir samples/$(*)
	cd samples/$(*)
	cmake -DBOARD=$(lastword $(subst /, ,$(*))) ..
	make -j


.PHONY: software/dhrystone/up5kPerf/build/dhrystone.bin
software/dhrystone/up5kPerf/build/dhrystone.bin:
	source ${ZEPHYR}/zephyr-env.sh
	make -C software/dhrystone/up5kPerf

.PHONY: software/dhrystone/igloo2Perf/build/dhrystone.bin
software/dhrystone/igloo2Perf/build/dhrystone.bin:
	source ${ZEPHYR}/zephyr-env.sh
	make -C software/dhrystone/igloo2Perf


.PHONY: software/dhrystone/up5kArea/build/dhrystone.bin
software/dhrystone/up5kArea/build/dhrystone.bin:
	source ${ZEPHYR}/zephyr-env.sh
	make -C software/dhrystone/up5kArea



hardware/netlist/%.v: ${NETLIST_DEPENDENCIES}
	sbt "run-main riscvSoftcoreContest.$(subst hardware/netlist/,,$(subst .v,,$@))"


up5kPerf_sim_compliance_rv32i:  software/bootloader
	make -C ext/riscv-compliance variant RISCV_TARGET=vexriscv_contest RISCV_DEVICE=up5kPerf RISCV_ISA=rv32i

up5kPerf_sim_compliance_rv32im: software/bootloader
	make -C ext/riscv-compliance variant RISCV_TARGET=vexriscv_contest RISCV_DEVICE=up5kPerf RISCV_ISA=rv32im

up5kPerf_sim_dhrystone: software/dhrystone/up5kPerf/build/dhrystone.bin software/bootloader
	make -C test/up5kPerf run ARGS='--iramBin ${ROOT}/software/dhrystone/up5kPerf/build/dhrystone.bin --bootloader ${ROOT}/software/bootloader/up5kPerf/noFlash.bin'

up5kPerf_sim_synchronization: ext/zephyr/samples/synchronization/vexriscv_contest_up5kperf_evn/zephyr/zephyr.bin software/bootloader
	make -C test/up5kPerf run ARGS='--iramBin ${ROOT}/ext/zephyr/samples/synchronization/vexriscv_contest_up5kperf_evn/zephyr/zephyr.bin --bootloader ${ROOT}/software/bootloader/up5kPerf/noFlash.bin'

up5kPerf_sim_philosophers: ext/zephyr/samples/philosophers/vexriscv_contest_up5kperf_evn/zephyr/zephyr.bin software/bootloader
	make -C test/up5kPerf run ARGS='--iramBin ${ROOT}/ext/zephyr/samples/philosophers/vexriscv_contest_up5kperf_evn/zephyr/zephyr.bin --bootloader ${ROOT}/software/bootloader/up5kPerf/noFlash.bin'


up5kPerf_evn_prog_icecube2:
	iceprog -o 0x00000 hardware/synthesis/up5kPerfEvn/icecube2/icecube2_Implmnt/sbt/outputs/bitmap/Up5kPerfEvn_bitmap.bin

up5kPerf_evn_prog_bootloader: software/bootloader
	iceprog -o 0x20000 software/bootloader/up5kPerf/copyFlash.bin

up5kPerf_evn_prog_dhrystone: software/dhrystone/up5kPerf/build/dhrystone.bin
	iceprog -o 0x30000 software/dhrystone/up5kPerf/build/dhrystone.bin

up5kPerf_evn_prog_all_dhrystone: up5kPerf_evn_prog_icecube2 up5kPerf_evn_prog_bootloader up5kPerf_evn_prog_dhrystone

up5kPerf_evn_prog_syncronization: ext/zephyr/samples/synchronization/vexriscv_contest_up5kperf_evn/zephyr/zephyr.bin
	iceprog -o 0x30000 ext/zephyr/samples/synchronization/vexriscv_contest_up5kperf_evn/zephyr/zephyr.bin

up5kPerf_evn_prog_philosophers: ext/zephyr/samples/philosophers/vexriscv_contest_up5kperf_evn/zephyr/zephyr.bin
	iceprog -o 0x30000 ext/zephyr/samples/philosophers/vexriscv_contest_up5kperf_evn/zephyr/zephyr.bin




igloo2Perf_sim_compliance_rv32i: software/bootloader
	make -C ext/riscv-compliance variant RISCV_TARGET=vexriscv_contest RISCV_DEVICE=igloo2Perf RISCV_ISA=rv32i

igloo2Perf_sim_compliance_rv32im: software/bootloader
	make -C ext/riscv-compliance variant RISCV_TARGET=vexriscv_contest RISCV_DEVICE=igloo2Perf RISCV_ISA=rv32im

igloo2Perf_sim_dhrystone: software/dhrystone/igloo2Perf/build/dhrystone.bin software/bootloader
	make -C test/igloo2Perf run ARGS='--iramBin ${ROOT}/software/dhrystone/igloo2Perf/build/dhrystone.bin --bootloader ${ROOT}/software/bootloader/igloo2Perf/noFlash.bin'

igloo2Perf_sim_synchronization: ext/zephyr/samples/synchronization/vexriscv_contest_igloo2perf_creative/zephyr/zephyr.bin software/bootloader
	make -C test/igloo2Perf run ARGS='--iramBin ${ROOT}/ext/zephyr/samples/synchronization/vexriscv_contest_igloo2perf_creative/zephyr/zephyr.bin --bootloader ${ROOT}/software/bootloader/igloo2Perf/noFlash.bin'

igloo2Perf_sim_philosophers: ext/zephyr/samples/philosophers/vexriscv_contest_igloo2perf_creative/zephyr/zephyr.bin software/bootloader
	make -C test/igloo2Perf run ARGS='--iramBin ${ROOT}/ext/zephyr/samples/philosophers/vexriscv_contest_igloo2perf_creative/zephyr/zephyr.bin --bootloader ${ROOT}/software/bootloader/igloo2Perf/noFlash.bin'

igloo2Perf_creative_serial_bootloader: software/bootloader
	python scripts/binToFlash.py software/bootloader/up5kPerf/copyFlash.bin 0x20000 921600 igloo2Perf_creative_serial_bootloader.bin

igloo2Perf_creative_serial_dhrystone: software/dhrystone/igloo2Perf/build/dhrystone.bin
	python scripts/binToFlash.py software/dhrystone/igloo2Perf/build/dhrystone.bin 0x30000 921600 igloo2Perf_creative_serial_dhrystone.bin

igloo2Perf_creative_serial_synchronization: ext/zephyr/samples/synchronization/vexriscv_contest_igloo2perf_creative/zephyr/zephyr.bin
	python scripts/binToFlash.py ext/zephyr/samples/synchronization/vexriscv_contest_igloo2perf_creative/zephyr/zephyr.bin 0x30000 921600 igloo2Perf_creative_serial_synchronization.bin

igloo2Perf_creative_serial_philosophers: ext/zephyr/samples/philosophers/vexriscv_contest_igloo2perf_creative/zephyr/zephyr.bin
	python scripts/binToFlash.py ext/zephyr/samples/philosophers/vexriscv_contest_igloo2perf_creative/zephyr/zephyr.bin 0x30000 921600 igloo2Perf_creative_serial_philosophers.bin


up5kArea_sim_compliance_rv32i: software/bootloader software/emulation
	make -C ext/riscv-compliance variant RISCV_TARGET=vexriscv_contest RISCV_DEVICE=up5kArea RISCV_ISA=rv32i

up5kArea_sim_dhrystone: software/dhrystone/up5kArea/build/dhrystone.bin software/bootloader software/emulation
	make -C test/up5kArea run ARGS='--iramBin ${ROOT}/software/dhrystone/up5kArea/build/dhrystone.bin --bootloader ${ROOT}/software/bootloader/up5kArea/noFlash.bin'

up5kArea_sim_synchronization: ext/zephyr/samples/synchronization/vexriscv_contest_up5karea_evn/zephyr/zephyr.bin software/bootloader software/emulation
	make -C test/up5kArea run ARGS='--iramBin ${ROOT}/ext/zephyr/samples/synchronization/vexriscv_contest_up5karea_evn/zephyr/zephyr.bin --bootloader ${ROOT}/software/bootloader/up5kArea/noFlash.bin'

up5kArea_sim_philosophers: ext/zephyr/samples/philosophers/vexriscv_contest_up5karea_evn/zephyr/zephyr.bin software/bootloader software/emulation
	make -C test/up5kArea run ARGS='--iramBin ${ROOT}/ext/zephyr/samples/philosophers/vexriscv_contest_up5karea_evn/zephyr/zephyr.bin --bootloader ${ROOT}/software/bootloader/up5kArea/noFlash.bin'



play:
	make -C software/emulation/area/ all
	rm -rf tmp.bin
	cat software/emulation/area/emu.bin >> tmp.bin
	dd if=/dev/null of=tmp.bin bs=1 count=0 seek=2048
	cat ext/riscv-compliance/work/I-CSRRW-01.elf.bin >> tmp.bin
	make -C /home/spinalvm/hdl/riscvSoftcoreContest/ext/riscv-compliance/riscv-test-suite/rv32i/../../../../test/up5kArea clean run ARGS='--iramBin ../../tmp.bin --bootloader /home/spinalvm/hdl/riscvSoftcoreContest/ext/riscv-compliance/riscv-test-suite/rv32i/../../../../software/bootloader/up5kArea/noFlash.bin  --timeout 2000000' TRACE=yes
