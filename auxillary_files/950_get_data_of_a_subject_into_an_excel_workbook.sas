*get data for a subject from all sdtm and adam datasets;

*identify the datasets with the variable USUBJID present in it;

proc sql;
	create table datasets as
		select distinct libname,memname
		from dictionary.columns
		where upcase(name) in ("USUBJID") 
	and ((upcase(libname) in ("SDTM" "ADAM") ;
quit;


%macro ck_subset_subject_data(libname=,memname=);

data work.&memname;
	set &libname..&memname. ;
	&where.;
run;


ods tagsets.excelxp options (sheet_name="&memname" absolute_column_width="8" autofit_height="yes");
options ls=max;

proc print data=&memname noobs label
	style(DATA)={rules=all frame=box font_face=arial font_size=8pt background=white borderwidth=0.5pt just=l}
	style(HEADER)={rules=all frame=box font_face=arial font_size=8pt background=white borderwidth=0.5pt };
run;

%mend;

ods tagsets.excelxp file="./subject_data.xls"
	options(autofilter='all' );


data _null_;
	set datasets;
	x=cats('%',"ck_subset_subject_data(libname=",libname,",","memname=",memname,");");
	call execute(x);
run;

ods tagsets.excelxp close;

