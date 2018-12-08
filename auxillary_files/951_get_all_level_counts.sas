%gen_init_001;


data adlb01;
   set adam.adlbh;
   where trta ne "";
run;

proc sort data=adlb01;
   by paramcd param trtan trta avisitn avisit;
run;


%macro csg_get_counts_all_by_levels(indsn=adlb01
                     ,byvar=%str(paramcd param trtan trta avisitn avisit)
                     ,keycountvar=lbnrind
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
      call symputx("_byvarcount",countw(value),'L');
   end;
run;


%*-------------------------------------------------;
%*Create a copy of the input dataset;
%*create some temporary variables as well to 
  enble smooth processing of the macro;
%*-------------------------------------------------;

data &macid.&indsn.01;
   set &indsn.;

   _csgbyvar=1;%*if no by variables are passed to the macro this will become the default;
run;

proc sort data=&macid.&indsn.01;
   by &_byvarlist.;
run;


proc freq data= &macid.&indsn.01    noprint   ;
   by &_byvarlist.;
   tables    &keycountvar.             /list missing out=counts01;
run;

%mend;

options mprint sgen spool;
%csg_get_counts_all_by_levels(byvar=paramcd trta);
options nomprint nosgen nospool;

%gen_term_001;

