* read in data;
/*PROC IMPORT OUT= WORK.df_imputed*/
/*            DATAFILE= "C:\Users\laveryj\Desktop\SPRIS-Project3\data_pmm.csv" */
/*            DBMS=CSV REPLACE;*/
/*     GETNAMES=YES;*/
/*     DATAROW=2; */
/*RUN;*/

* run hierarchical model;
/*proc glimmix data = df_imputed method = RMPL;*/
/*	class subject_id gender (ref = "F") tx (ref = "Placebo");*/
/*	model mem_comp = tx day age gender / s;*/
/*	random intercept / subject = subject_id;*/
/*run;*/

* run hierarchical model to get difference in means;
* test for different effect of tx over time;
proc mixed data = df_imputed method = REML;
	class subject_id gender (ref = "F") tx (ref = "Placebo");
	model mem_comp = tx day tx*day age gender / s cl;
	random intercept / subject = subject_id;
	ods trace on;
	ods output Diffs=diffs solutionf = est;
	lsmeans tx  / at day = 5 diff cl;
	lsmeans tx / at day = 19 diff cl;
	lsmeans tx / at day = 90 diff cl;
run;

* run hierarchical model to get difference in means;
proc mixed data = df_imputed method = REML;
	class subject_id gender (ref = "F") tx (ref = "Placebo");
	model mem_comp = tx day age gender / s cl;
	random intercept / subject = subject_id;
	ods trace on;
	ods output Diffs=diffs solutionf = est;
	lsmeans tx  / at day = 5 diff cl;
	lsmeans tx / at day = 19 diff cl;
	lsmeans tx / at day = 90 diff cl;
run;

* export to R to export to Latex table;
PROC EXPORT DATA= WORK.EST 
            OUTFILE= "imputed_model_results.csv" 
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
