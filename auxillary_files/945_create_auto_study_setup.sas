

dm log 'clear';
dm output 'clear';

*============================================================;
*Defining the macros which are used in this program;
*============================================================;

*-----------------------------------------------;
*macro to check for the presence of a folder
and create the folder if it does not exist;
*-----------------------------------------------;

%macro newfolder(newfld);
%local rc fileref;
%let rc=%sysfunc(filename(fileref,&newfld));
%if %sysfunc(fexist(&fileref)) %then %put NOTE:The directory "&newfld" already EXISTED.;
%else %do;
         %sysexec md "&newfld";
         %put NOTE:The directory "&newfld" has been CREATED.;
      %end;
%let rc=%sysfunc(filename(fileref));
%mend newfolder;


*-----------------------------------------------------;
*macro to check for the presence of an external file;
*returns 1 if the file is present/else 0;
*-----------------------------------------------------;

%macro file_exist(file=);
   %if %sysfunc(fileexist("&file.")) %then Y;
   %else N;
%mend file_exist;


*==============================end of section================;


*============================================================;
*Creating the files required for a study setup;
*============================================================;

*------------------------------------------------------;
*define macro variables for root folder,study etc;
*------------------------------------------------------;
%let _study=x1;
%let _parent=%str(D:\Home\dev\);
%let _cfg=%str(C:\Program Files\SASHome2\SASFoundation\9.4\nls\en\);
%let _siddate=01-01-2016;
%let _sasver=sasv94;
%let _sasexe=%str(C:\Program Files\SASHome2\SASFoundation\9.4\sas.exe);


*-----------------------------------------------------;
*create a dataset to hold the standard folder structure;
*-----------------------------------------------------;

data newfolder;
   length newfld $400;
   newfld="&_parent.&_study."; output;
   newfld="&_parent.&_study.\data"; output;
   newfld="&_parent.&_study.\lums"; output;
   newfld="&_parent.&_study.\programs_stat"; output;
   newfld="&_parent.&_study.\replica_programs"; output;
   newfld="&_parent.&_study.\specifications"; output;
   newfld="&_parent.&_study.\data\shared"; output;
   newfld="&_parent.&_study.\data\shared\adam"; output;
   newfld="&_parent.&_study.\data\shared\ads"; output;
   newfld="&_parent.&_study.\data\shared\dict"; output;
   newfld="&_parent.&_study.\data\shared\raw"; output;
   newfld="&_parent.&_study.\data\shared\sdtm"; output;
   newfld="&_parent.&_study.\programs_stat\adam"; output;
   newfld="&_parent.&_study.\programs_stat\ads"; output;
   newfld="&_parent.&_study.\programs_stat\macros"; output;
   newfld="&_parent.&_study.\programs_stat\sdtm"; output;
   newfld="&_parent.&_study.\programs_stat\system_files"; output;
   newfld="&_parent.&_study.\programs_stat\tfl"; output;
   newfld="&_parent.&_study.\programs_stat\tfl_output"; output;
   newfld="&_parent.&_study.\programs_stat\tfl\figures"; output;
   newfld="&_parent.&_study.\programs_stat\tfl\listings"; output;
   newfld="&_parent.&_study.\programs_stat\tfl\tables"; output;
   newfld="&_parent.&_study.\replica_programs\adam"; output;
   newfld="&_parent.&_study.\replica_programs\ads"; output;
   newfld="&_parent.&_study.\replica_programs\macros"; output;
   newfld="&_parent.&_study.\replica_programs\sdtm"; output;
   newfld="&_parent.&_study.\replica_programs\system_files"; output;
   newfld="&_parent.&_study.\replica_programs\tfl"; output;
   newfld="&_parent.&_study.\replica_programs\tfl_output"; output;
   newfld="&_parent.&_study.\replica_programs\tfl\figures"; output;
   newfld="&_parent.&_study.\replica_programs\tfl\listings"; output;
   newfld="&_parent.&_study.\replica_programs\tfl\tables"; output;
   newfld="&_parent.&_study.\specifications\Notes"; output;
   newfld="&_parent.&_study.\specifications\adam"; output;
   newfld="&_parent.&_study.\specifications\sdtm"; output;
   newfld="&_parent.&_study.\specifications\tfl"; output;
run;

options xmin noxwait;

data _null_;
     set newfolder;
     call execute('%newfolder('||newfld||');');
run;

options noxmin xwait;


*--------------------------------------------------------------;
*config file creation;
*--------------------------------------------------------------;

title;
footnote;
options nonumber nodate;


*----------------------------------------------------------;
*use the standard config file;
*create compound level config file;
*use sas installation location from a macro variable;
*SAS will not have write permission to original config file
location, so save the study level config file in lums folder
of the respective study;
*----------------------------------------------------------;

%macro create_config;

%if %file_exist(file=%str(&_parent.&_study.\lums\sasv9_&_study..cfg))=N %then %do;

data _null_;
   put '*----------------------------------------------;';
   put '*creating study level config file....;';
   put '*----------------------------------------------;';
run;

data _null_;
   infile "&_cfg.sasv9.cfg" end=last ;
   input ;
   file "&_parent.&_study.\lums\sasv9_&_study..cfg" ;
   put _infile_;
   if last then do;
      put ///;

      put "-awstitle 'This is &_study.'";
      put "-awsdef 0 0 100 100";
      put "-autoexec &_parent.&_study.\lums\autoexec.sas";
      put "-SET MYSASFILES '&_parent.&_study.' ";
      put "-SASINITIALFOLDER '&_parent.&_study.\programs_stat\'";
      put "-SASUSER '&_parent.&_study.'";
   end;
run;
%end;

%else %do;
   data _null_;
      put '*----------------------------------------------;';
      put '*config file already exists;';
      put '*----------------------------------------------;';
   run;
%end;

%mend create_config;

%create_config;


*----------------------------------------------------------;
*create autoexec.sas file;
*----------------------------------------------------------;

%macro create_autoexec;

%if %file_exist(file=%str(&_parent.&_study.\lums\autoexec.sas))=N %then %do;

data _null_;
   put '*----------------------------------------------;';
   put '*creating study level autoexec file....;';
   put '*----------------------------------------------;';
run;


data _null_;
file "&_parent.&_study.\lums\autoexec.sas";

put '%let root=' "&_parent.&_study.\;" ;
put '%let prog_loc=' "&_parent.&_study.\replica_programs\system_files;";
put '%let study=' "&_study.;";

put //;

put "options mautosource sasautos=(" '"' '&root.\lums' '"' ', sasautos);';

put //;

put '%macro closevts  /* The cmd option makes the macro available to dms */ / cmd; ';
put '  %local i; ';
put '  %do i=1 %to 20;';
put '    next "viewtable:"; end; ';
put '  %end; ';
put '%mend;';

put /;
put "dm " '"' 'keydef F12 ' "'" '%NRSTR(%closevts);' "'" '";';
put /;
put '%assignlibs;';
run;

%end;

%else %do;
   data _null_;
      put '*----------------------------------------------;';
      put '*autoexec file already exists;';
      put '*----------------------------------------------;';
   run;
%end;



%mend create_autoexec;

%create_autoexec;

*----------------------------------------------------------;
*create assignlibs program;
*----------------------------------------------------------;



%macro create_assignlibs;

%if %file_exist(file=%str(&_parent.&_study.\lums\assignlibs.sas))=N %then %do;

data _null_;
   put '*----------------------------------------------;';
   put '*creating study level assignlibs file....;';
   put '*----------------------------------------------;';
run;


data _null_;
   file "&_parent.&_study.\lums\assignlibs.sas";
   put '%macro assignlibs;';
   put /;
   put "libname raw '&_parent.&_study.\data\shared\raw' access=readonly;";
   put "libname sdtm '&_parent.&_study.\data\shared\sdtm' access=readonly;";
   put "libname adam '&_parent.&_study.\data\shared\adam' access=readonly;";
   put "libname tfl '&_parent.&_study.\programs_stat\system_files' access=readonly;";

   put /;

   put "libname raww '&_parent.&_study.\data\shared\raw' ;";
   put "libname sdtmw '&_parent.&_study.\data\shared\sdtm';";
   put "libname adamw '&_parent.&_study.\data\shared\adam'; ";
   put "libname tflw '&_parent.&_study.\programs_stat\system_files';";

   put /;

   put '%mend assignlibs;';

   put //;
   put '%assignlibs;';

run;

%end;

%else %do;
   data _null_;
      put '*----------------------------------------------;';
      put '*assignlibs file already exists;';
      put '*----------------------------------------------;';
   run;
%end;



%mend create_assignlibs;

%create_assignlibs;


*-----------------------------------------------------;
*create bat file;
*-----------------------------------------------------;


%macro create_batfile;

%if %file_exist(file=%str(&_parent.&_study.\Open_&_sasver..bat))=N %then %do;

data _null_;
   put '*----------------------------------------------;';
   put '*creating study level batfile....;';
   put '*----------------------------------------------;';
run;


data _null_;
   file "&_parent.&_study.\Open_&_sasver..bat";

put 'echo %date% > ' "&_parent.&_study.\timelog_&_sasver..txt";
put "date &_siddate.";
put 'ping -n 1 127.0.0.1 > NUL 2>&1';
put 'Start /b "My SAS program "   ' '"' "&_sasexe." '" ' '-config '  '"' "&_parent.&_study.\lums\sasv9_&_study..cfg" '"';
put 'ping -n 20 127.0.0.1 > NUL 2>&1';

put "date =< &_parent.&_study.\timelog_&_sasver..txt";
put "echo.";
put 'del ' '"' "&_parent.&_study.\timelog_&_sasver..txt" '"';
put "exit";

run;

%end;

%else %do;
   data _null_;
      put '*----------------------------------------------;';
      put '*batfile file already exists;';
      put '*----------------------------------------------;';
   run;
%end;



%mend create_batfile;

%create_batfile;





*-----------------------------------------------------;
*create gen_init file;
*-----------------------------------------------------;


%macro create_geninit;

%if %file_exist(file=%str(&_parent.&_study.\lums\gen_init_001.sas))=N %then %do;

data _null_;
   put '*----------------------------------------------;';
   put '*creating study level geninit....;';
   put '*----------------------------------------------;';
run;


data _null_;
   file "&_parent.&_study.\lums\gen_init_001.sas";

put '%macro gen_init_001;';
put '%put you are in gen_init_001 macro;';
put 'options nofmterr;';
put /;

put "dm log 'clear';";
put "dm output 'clear';";
put "dm log 'preview';";
put /;

put "proc datasets library=work mt=data kill nolist;";
put "quit;";
put /;

put "options ps=48 ls=153;";
put /;

put '%macro closevts  / cmd; ';
  put '%local i; ';
  put '%do i=1 %to 20;';
    put 'next "viewtable:"; end; ';
  put '%end;'; 
put '%mend;';
put /;

put "dm " '"' 'keydef F12 ' "'" '%NRSTR(%closevts);' "'" '";';
put /;

put '%assignlibs;';
put '%global _x_x_output_name;';
put /;
put '%mend gen_init_001;';
put /;
put '%let prog_name= %sysfunc(substr(%sysget(SAS_EXECFILENAME),1,%length(%sysget(SAS_EXECFILENAME))-4));';
put 'ods graphics on/path="&root.\programs_stat\tfl_output\figures";';
put /;
run;

%end;

%else %do;
   data _null_;
      put '*----------------------------------------------;';
      put '*geninit file already exists;';
      put '*----------------------------------------------;';
   run;
%end;



%mend create_geninit;

%create_geninit;




*-----------------------------------------------------;
*create gen_term file;
*-----------------------------------------------------;


%macro create_genterm;

%if %file_exist(file=%str(&_parent.&_study.\lums\gen_term_001.sas))=N %then %do;

data _null_;
   put '*----------------------------------------------;';
   put '*creating study level genterm....;';
   put '*----------------------------------------------;';
run;


data _null_;
   file "&_parent.&_study.\lums\gen_term_001.sas";

put '%macro gen_term_001;';

put '  %put you are in gen_term_001 macro;';
put '  %ut_saslogcheck;';

put '%mend gen_term_001;';

run;

%end;

%else %do;
   data _null_;
      put '*----------------------------------------------;';
      put '*genterm file already exists;';
      put '*----------------------------------------------;';
   run;
%end;

%mend create_genterm;

%create_genterm;

*------------------------------------------------------------;
*copy log check macro;
*------------------------------------------------------------;
options xmin noxwait xsync;
%sysexec copy /Y "d:\home\dev\compound1\lums\ut_saslogcheck.sas" "&_parent.&_study.\lums\ut_saslogcheck.sas";
options noxmin xwait noxsync;

*===============================end of section====================;
