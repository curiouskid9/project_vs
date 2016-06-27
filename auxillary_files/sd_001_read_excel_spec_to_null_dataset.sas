

libname xls excel "D:\Home\dev\master_files\copied\Lilly_sdtm\Spec\I7W-MC-JQBA_SDTM_SST1.xls" ;

libname anil "D:\Home\dev\master_files\copied\Lilly_sdtm\Spec";

data anil.ae_spec;
	set xls."ae$"n;
run;

libname xls;
