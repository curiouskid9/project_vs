*-------------------------------------------------------------------------------*;
* Macro variable for defining project area. Not required is program is executed *;
* from a standard Biostatistics project area.                                   *;
*-------------------------------------------------------------------------------*;
%let Root=%str();

*-------------------------------------------------------------------------------*;
* Read in all file in the specified user-defined macro area. This dataset will  *;
* be used to determine what programs are read-in and scanned through for macro  *;
* definitions.                                                                  *;
*-------------------------------------------------------------------------------*;
%macro drive(dir,outDSet);
  %local filrf rc did memcnt name i;

  /* Assigns a fileref to the directory and opens the directory */
  %let rc=%sysfunc(filename(filrf,&dir));
  %let did=%sysfunc(dopen(&filrf));

  /* Make sure directory can be open */
  %if &did eq 0 %then %do;
   %put Directory &dir cannot be open or does not exist;
   %return;
  %end;

   /* Loops through entire directory */
   %do i = 1 %to %sysfunc(dnum(&did));

     /* Retrieve name of each file */
     %let name=%qsysfunc(dread(&did,&i));
      data _filenames;
        length filepath $1000.;
        filepath="&dir\&name.";
      run;
      proc append base=&outDSet. data=_filenames;
      run; quit;

     /* If directory name call macro again */
      %if %qscan(&name,2,.) = %then %do;
/*         %drive(&dir\%unquote(&name),&outDSet.) */
      %end;

   %end;

  /* Closes the directory and clear the fileref */
  %let rc=%sysfunc(dclose(&did));
  %let rc=%sysfunc(filename(filrf));

%mend drive;
%let source=%sysfunc(getoption(source));
%let notes=%sysfunc(getoption(notes));
*-------------------------------------------------------------------------------*;
* Assume that user-defined macros are stored in only one area. If not, then     *;
* extra DRIVE macro calls are required and these extra datasets will need to be *;
* added to the following DATA step.                                             *;
*-------------------------------------------------------------------------------*;
options nosource nonotes;
%drive(%str(&Root.util),Production_macros) ;
options &source. &notes.;
*-------------------------------------------------------------------------------*;
* Select only *.SAS programs for consideration as user-defined macros.          *;
*-------------------------------------------------------------------------------*;
data user_defined_macros;
  set 
    Production_macros (in=in_prod)
   ;
  if kscan(kupcase(filepath),-1,'.') in ('SAS' 'INC');
run;
*-------------------------------------------------------------------------------*;
* Read in each user-defined macro into a dataset and scan through to find macro *;
* definition program lines. There could be more than one macro definition in a  *;
* program.                                                                      *;
*-------------------------------------------------------------------------------*;
%macro SelectMacroDefinitions (sasFile);
*-------------------------------------------------------------------------------*;
* Each SAS program is included using a FILEREF and INFILE statemnent.           *;
*-------------------------------------------------------------------------------*;
  filename sasFile "&sasFile.";
  data _checkfile (keep=MacroName);
    infile sasFile lrecl=1000 truncover end=eof;
    length sasFile $1000. MacroName $50.;
    sasFile="&sasFile.";
    input @1 line $1000.;
*-------------------------------------------------------------------------------*;
* Flag when a MACRO definition is identified.                                   *;
*-------------------------------------------------------------------------------*;
    if kcompress(kupcase(line)) eq: '%MACRO' then do;
      _flag=1;
      MacroName=kupcase(kscan(line,2,' ;('));
    end;
    if _flag eq 1;
  run;
  filename sasFile;

  proc append base=MacrosDefined data=_checkfile;
  run; quit;

  proc sort data=MacrosDefined nodupkey;
    by MacroName;
  run;
%mend SelectMacroDefinitions;

options nosource nonotes;
data _null_;
  set user_defined_macros;
  call execute(cat('%SelectMacroDefinitions(',filepath,');'));
run;
options &source. &notes.;
*-------------------------------------------------------------------------------*;
* Find all the required output programs [TLF] for consideration as to whether   *;
* user-defined macros are used in these programs.                               *;
* Add additional areas as required.                                             *;
*-------------------------------------------------------------------------------*;
options nosource nonotes;
%drive(%str(&Root.report\pgm_saf\HAQ),Tables) ;
/*%drive(%str(&Root.production\listings),Listings) ;*/
/*%drive(%str(&Root.production\figures),Figures) ;*/
options &source. &notes.;

data file_and_pathnames;
  set 
    Tables (in=in_tables)
/*    Listings (in=in_listings)*/
/*    Figures (in=in_figures)*/
  ;
  length ProgType $15.;
  if in_tables then ProgType='Table';
/*  if in_listings then ProgType='Listing';*/
/*  if in_figures then ProgType='Figure';*/
  if kscan(kupcase(filepath),-1,'.') in ('SAS' 'INC');
run;

data file_and_pathnames;
  set work.file_and_pathnames end=eof;
  id=_n_;
  if eof then call symputx ('N_Files',_n_,'G');
run;
%put Number of Programs to Check = &N_Files.;
*-------------------------------------------------------------------------------*;
* Read in each program and the list of macros to check whether the program has  *;
* used any of these macros.                                                     *;
*-------------------------------------------------------------------------------*;
%macro FindMacroInvocations (sasFile, ProgType);
  %put SASFILE=&sasFile.;
  filename sasFile "&sasFile.";
  data _checkfile;
    infile sasFile lrecl=1000 truncover end=eof;
    length sasFile $1000. ProgType $15. MacroName $50.;
    sasFile="&sasFile.";
    ProgType="&ProgType.";

    input @1 line $1000.;
*-------------------------------------------------------------------------------*;
* Flag when a there is a possible macro invocation.                             *;
*-------------------------------------------------------------------------------*;
    if kcompress(line) eq: '%' then do;
      _macro_flag=1;
      MacroName=kupcase(kscan(line,1,' ;(%'));
    end;
  run;
  filename sasFile;

  data _macro_lines (keep=sasFile ProgType MacroName);
    if 0 then set work._checkfile work.MacrosDefined; *** Sets up the PDV ***;

    if _n_ eq 1 then do; *** Only need to declare hash tables once ***;
      declare hash usermac(dataset:'work.MacrosDefined',hashexp:8); *** HASHEXP can be increased to have more memory available ***;
      usermac.defineKey('MacroName'); *** Key variables ***;
      usermac.defineDone(); *** Completes the initialisation of hash object ***;
    end; *** End of hash table declaration ***;
  
    set work._checkfile (where=(_macro_flag eq 1)); *** Base dataset ***;

*** The return code is set to zero when the keys match ***;
*** This is an INNER JOIN. For LEFT JOINS a different bit of code is required ***;
    if usermac.find() eq 0 then output; *** As all key variables are the same we do not need to define what keys to match on ***;
  run;

  proc append base=MacrosUsed data=_macro_lines;
  run; quit;
%mend FindMacroInvocations;

options nosource nonotes;
data _null_;
  set file_and_pathnames;
  call execute(cat('%FindMacroInvocations(',filepath,',',progtype,');'));
run;
options &source. &notes.;
*-------------------------------------------------------------------------------*;
* Print out list of programs with user-define macros used in each program.      *;
*-------------------------------------------------------------------------------*;
proc print data=work.MacrosUsed width=min heading=horizontal;
run;
