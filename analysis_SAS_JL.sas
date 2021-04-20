* read in data;
PROC IMPORT OUT= WORK.df_with_missing
            DATAFILE= "C:\Users\laveryj\Desktop\SPRIS-Project3\df_for_model.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

proc contents data = df_with_missing; run;

* make variable numeric;
data df_with_missing1;
	set df_with_missing (rename=(mem_comp = mem_comp_c));

	* make numeric;
	mem_comp = input(mem_comp_c, 8.3);
run;

* identify completers;
proc sql;
	create table df_with_missing2 as
	select *, count(*) as n_recs
	from df_with_missing1
	where not missing(mem_comp)
	group by subject_id;
quit;

* test for interaction term: not significant, remove;
proc mixed data = df_with_missing2 method = REML;
	class subject_id gender (ref = "F") tx (ref = "Placebo");
	* completers only;
	where n_recs = 3;
	model mem_comp = bl_mem_comp tx day tx*day age gender / s cl;
	random intercept / subject = subject_id;
run;

* run hierarchical model to get difference in means;
* test for different effect of tx over time;
* without tx*day interaction, test for lsmeans diff of tx by day is all the same for each day, which makes sense
b/c the effect of tx wasnt set to change by day; 
proc mixed data = df_with_missing2 method = REML;
	* completers only;
	where n_recs = 3;
	class subject_id gender (ref = "F") tx (ref = "Placebo");
	model mem_comp = bl_mem_comp tx day tx*day age gender / s cl;
	random intercept / subject = subject_id;
	ods trace on;
	ods output Diffs=diffs_missing solutionf = est;
	lsmeans tx / diff cl adjust = tukey;
	lsmeans tx  / at day = 5 diff cl adjust = tukey;
	lsmeans tx / at day = 19 diff cl adjust = tukey;
	lsmeans tx / at day = 90 diff cl adjust = tukey;
run;

* export to R to export to Latex table;
PROC EXPORT DATA= WORK.Diffs_missing
            OUTFILE= "diffs_missing_data_model.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

** on imputed data;
PROC IMPORT OUT= WORK.df_imputed
            DATAFILE= "C:\Users\laveryj\Desktop\SPRIS-Project3\df_imputed.csv" 
            DBMS=CSV REPLACE;
     GETNAMES=YES;
     DATAROW=2; 
RUN;

* test interaction term;
proc mixed data = df_imputed method = REML;
	class subject_id gender (ref = "F") tx (ref = "Placebo");
	model mem_comp = bl_mem_comp tx day tx*day age gender / s cl;
	random intercept / subject = subject_id;
run;

* run hierarchical model to get difference in means;
proc mixed data = df_imputed method = REML;
	class subject_id gender (ref = "F") tx (ref = "Placebo");
	model mem_comp = bl_mem_comp tx day tx*day age gender / s cl;
	random intercept / subject = subject_id;
	ods trace on;
	ods output Diffs=diffs_imputed lsmeans=lsmeans_imputed solutionf = est;
	lsmeans tx / diff cl adjust = tukey;
	lsmeans tx  / at day = 5 diff cl adjust = tukey;
	lsmeans tx / at day = 19 diff cl adjust = tukey;
	lsmeans tx / at day = 90 diff cl adjust = tukey;
run;

* export to R to export to Latex table;
PROC EXPORT DATA= WORK.diffs_imputed 
            OUTFILE= "diffs_imputed_model.csv" 
            DBMS=CSV REPLACE;
     PUTNAMES=YES;
RUN;

* set up lsmeans for graph;
data diffs2;
	set diffs;
	where _tx = "Placebo";
	est_cl = strip(put(Estimate,8.2)) || " (" || strip(put(Lower,8.2)) || ", " || strip(put(Upper,8.2)) || ")";
run;

* create plot;
ods graphics / reset noborder;
proc sgpanel data=diffs2 noautolegend ;
	panelby day / rows = 3;
	scatter y=tx x=Estimate / xerrorupper=Lower xerrorlower=Upper
			markerattrs=(symbol=squarefilled color=cx445694) errorbarattrs=(color=cx445694 thickness=1)
			;
	scatter y=tx x=Estimate;*  / datalabel=print;
	format Estimate 8.1 day 8.;
	refline 0 / axis=x transparency=0.5;
	refline 1 / axis=x;

	*add columns to the right of OR (95% CI), ICC and p-value;
	rowaxistable est_cl / title = 'Mean Difference (95% CI)'
	valueattrs=(color=black size=11) labelattrs=( size=11)
	valuehalign=center VALUEJUSTIFY=center 
	LABELHALIGN=center LABELJUSTIFY=center
	 titlehalign=center titleattrs=(weight=bold)
	/*INDENTWEIGHT= indenter*/ pad=(left=0.2in) ;*location=inside 
	;

	*rowaxistable probt ;*/ 
	valuehalign=center VALUEJUSTIFY=center 
	LABELHALIGN=center LABELJUSTIFY=center
	title = 'differences    ' titlehalign=right titleattrs=(weight=bold)
	/*INDENTWEIGHT= indenter*/ pad=(left=0.3in right=0.2in) location=inside 
	valueattrs=(color=black size=11) labelattrs=( size=11);
	*set up axes;
	colaxis /*offsetmin=0.01 offsetmax=0.05 */ min=-2 max=1.5 display=(nolabel)
	valueattrs=(size=11) offsetmin=0.01
	tickvalueformat=data
	 /*x2axis offsetmax=0.04 display=(noticks nolabel)*/;
	rowaxis /*colorbands=even  colorbandsattrs=(transparency=0.4)*/ 
	type=discrete splitchar='!' fitpolicy=split 
	offsetmin=0.1 offsetmax=0.1 valueattrs=(size=11)
	display=(noticks nolabel) reverse;

	label est_cl="00"x;
run;
