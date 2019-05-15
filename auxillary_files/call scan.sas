data test;
sent="This is a sentence for testing";
length current $100;
l_sent=length(sent);
do i=1 to countw(sent);
   call scan (sent,i,pos,len," ");
   if i gt 1 then cumlen+len+1;
   else cumlen+len;
   current=catx(' ',current,scan(sent,i,' '));
   remain=substrn(sent,cumlen+2);
   output;
end;

run;
