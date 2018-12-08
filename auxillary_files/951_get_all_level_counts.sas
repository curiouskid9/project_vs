%gen_init_001;

proc format;
   value $lbnrind(default=8)
   "NORMAL"="NORMAL"
   "ABNORMAL"="ABNORMAL"
   "LOW"="LOW"
   "HIGH"="HIGH";
run;

data adlb01;
   set adam.adlbh;
   where trta ne "" and paramcd=:"H";
   if mod(_n_,10)=1 then lbnrind="";
run;

data adsl01;
   set adam.adsl;
   where saffl="Y";
run;

proc sort data=adlb01;
   by paramcd param trtan trta avisitn avisit;
run;


%macro csg_get_counts_all_by_levels(indsn=
                     ,byvar=%str( )
                     ,keycountvar=
                     ,macid=_csg_gc_
                     );

%*--------------------------------------------------------------;
%*get the list of parameters of the this macro;
%*process the macro variables as needed;
%*--------------------------------------------------------------;

data _csg_gc_localmacvars;
   set sashelp.vmacro;
   where scope = "&sysmacroname";
   name=upcase(name);
   if name="BYVAR" then do;
      value=compbl(value);
      value=catx(" ","_CSGBYVAR",value);
      call symputx("_byvarlist",value,'L');
      call symputx("_byvarlistsql",translate(strip(value),',',' '),'L');
      call symputx("_byvarcount",countw(value),'L');
   end;
   if name="KEYCOUNTVAR" then do;
      value=compbl(value);
      if missing(value) then value="_CSGCOUNTVAR";
      call symputx("_csgcountvar",value);
      call symputx("_csgcountvarsql",translate(strip(value),',',' '));
   end;
run;

%*-----------------------------------------------------------;
%*check the overall count of by and count variables;
%*-----------------------------------------------------------;

data &macid.check01;
   fulllist=cats("&_byvarlistsql.",",","&_csgcountvarsql.");
   listcount=countw(fulllist,",");
   call symputx( "_bycountvarsql", fulllist,'L');
   call symputx( "_bycountvarcount", listcount,'L');
run;


%*-------------------------------------------------;
%*Create a copy of the input dataset;
%*create some temporary variables as well to 
  enble smooth processing of the macro;
%*-------------------------------------------------;

data &macid.&indsn.;
   set &indsn.;

   _csgbyvar=1;%*if no by variables are passed to the macro this will become the default;
   _csgcountvar=1;%*if count variable is missing then this dummy variable will be used;
   _csgdummynum=1;%*to use as a dummy numeric variable;
   _csdummychar="CSG";%*to use as a dummy character variable;
run;


data &macid.check02;
   length var level $1000;
   var="&_bycountvarsql.";
   do i= 1 to &_bycountvarcount.;
      level=catx(" ",level,scan(var,i,','));
      output;
   end;
run;

proc sort data=&macid.check02;
   by descending i;
run;


%macro run_freq(_bylevel=,level=);

proc sort data=&macid.&indsn;
   by &_bylevel.;
run;

proc freq data=&macid.&indsn noprint;
   by &_bylevel.;
   tables _csgdummynum/ out=&macid.counts01_level_&level.(drop=_csgdummynum percent);
run;

%if %eval(&level) lt &_bycountvarcount. %then %do;
   
   data &macid.counts01_final;
      merge &macid.counts01_final 
            &macid.counts01_level_&level.(rename=(count=level&level.));
      by &_bylevel.;
      label level&level.="&_bylevel.";
   run; 
%end;
%else %do;
data &macid.counts01_final;
   set &macid.counts01_level_&level.;
run;
%end;

%mend run_freq;

data _null_;
   set &macid.check02;
   var=cats('%run_freq(_bylevel=',level,',level=',i,');');
   call execute(var);
run;

%mend;



options mprint sgen spool;
%csg_get_counts_all_by_levels(indsn=adlb01,byvar=paramcd param avisitn avisit ,keycountvar=lbnrind);
options nomprint nosgen nospool;

%gen_term_001;

