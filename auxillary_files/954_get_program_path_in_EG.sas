
options  mautolocdisplay mautosource  spool mprint  nofmterr validvarname=v7 mcompilenote=all source source2;
%macro create_init;
 
	%put %sysfunc(repeat(*,20)) START: macro &sysmacroname.  %sysfunc(datetime(),datetime20.) %sysfunc(repeat(*,20));

	%if "&sysscp"="LIN X64" and "&sysprocessname"="Object Server" %then
		%do;
			%put We are running on Enterprise Guide (local execution host);

			%if %superq(_sasprogramfile) eq %str('') %then
				%do;
					%put %str(E)RROR: >>> The SAS EG not resolved the path, you have to open from >>>;
					%put %str(E)RROR: >>> program folder and click the proram or sever  Please check. >>>;
					%goto exit;
				%end;

			%if %superq(_sasprogramfile) ne %str('') %then
				%do;
%let pathnpgm=%sysfunc(tranwrd(%sysfunc(tranwrd(%sysfunc(dequote(&_sasprogramfile)),\,/)),UserData,userdata));
	                 
					%put >>>  &pathnpgm;

					%if %index(&pathnpgm,use) =0 %then
						%do;
							%put ">>> It is not a proper path and going away from the location.>>> ";

							%Return;
						%end;

					%if %index(&pathnpgm,use) > 0 %then
						%do;
							%if %index(&pathnpgm,cda) > 0 and  %index(&pathnpgm,use) > 0 %then
								%do;
									%put ">>> You have opened the program directly from the location >>> ";
									%let varl= %EVAL(%index(&pathnpgm,%scan(&pathnpgm,-1,/)) -  %eval(%index(&pathnpgm,use)-1));
									%put &varl;
									%let acpath=%SYSFUNC(LOWCASE(%substr(&pathnpgm,%eval(%index(&pathnpgm,use)-1), %EVAL(&VARl-1) )));
									%put the current path is  >>>> &acpath;
								%end;

							%if %index(&pathnpgm,cda) =0 and  %index(&pathnpgm,use) > 0 %then
								%do;
									%put ">>> You have opened the program SAS EG via Server. >>> ";
									%let varl= %EVAL(%index(&pathnpgm,%scan(&pathnpgm,-1,/)) -  %eval(%index(&pathnpgm,use)-1));
									%let acpath=%substr(&pathnpgm,%eval(%index(&pathnpgm,use)-1),%EVAL(&VARl-1));
									%put the current path is  >>>> &acpath;
								%END;

							%sysexec  cd &acpath;
							%Put  >>>>>> assigned via eg >>>>>>>>>>>>>;
						%END;
				%end;

	%exit:
		%end;

	%put %sysfunc(repeat(*,20)) END: macro &sysmacroname.  %sysfunc(datetime(),datetime20.) %sysfunc(repeat(*,20));
%mend create_init;

%create_init;

