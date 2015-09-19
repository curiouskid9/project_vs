
%macro gen_stop_001;
%put you are in gen_stop_001 macro;
proc printto;
run;

options xmin noxwait noxsync;
x  CHDIR "&root.\programs_stat\tfl_output\" & "&_x_x_output_name..lst" ;

%mend gen_stop_001;
