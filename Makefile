PROFILE ?= Jorvik
ADCF := config/profiles/gnat_$(shell echo $(PROFILE) | tr A-Z a-z).adc

profile:
	@cp $(ADCF) gnat.adc && echo "Using profile $(PROFILE)"

prove:
	gnatprove -P server_starter.gpr --mode=all --level=2 -j0 --report=all

clean:
	rm -rf obj bin gnatprove gnatprove.out
