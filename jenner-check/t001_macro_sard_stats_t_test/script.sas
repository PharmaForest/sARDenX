/* ------------------------------------------------------------------ *
 * sARDenX compatibility bundle: %sard_stats_t_test
 *
 * The macro body below is copied verbatim from
 *   sARDenX/06_macro/sard_stats_t_test.sas
 * The only additions are (1) a small mock ADSL dataset built inline so
 * the bundle is self-contained, and (2) the README usage example as the
 * caller. The README invites substituting a typical ADSL dataset, which
 * is what the DATALINES block below does (TRT01PN two-level group, AGE).
 * ------------------------------------------------------------------ */

data ADSL;
  length USUBJID $12 TRT01P $9 SEX $1;
  input USUBJID $ TRT01PN TRT01P $ AGE SEX $;
datalines;
STUDY-001 1 Placebo 45 M
STUDY-002 1 Placebo 52 F
STUDY-003 1 Placebo 38 M
STUDY-004 1 Placebo 61 F
STUDY-005 1 Placebo 47 M
STUDY-006 1 Placebo 55 F
STUDY-007 1 Placebo 43 M
STUDY-008 1 Placebo 66 F
STUDY-009 1 Placebo 50 M
STUDY-010 1 Placebo 58 F
STUDY-011 1 Placebo 41 M
STUDY-012 1 Placebo 49 F
STUDY-013 1 Placebo 63 M
STUDY-014 1 Placebo 37 F
STUDY-015 1 Placebo 54 M
STUDY-016 2 Active 48 F
STUDY-017 2 Active 59 M
STUDY-018 2 Active 44 F
STUDY-019 2 Active 67 M
STUDY-020 2 Active 51 F
STUDY-021 2 Active 46 M
STUDY-022 2 Active 62 F
STUDY-023 2 Active 39 M
STUDY-024 2 Active 57 F
STUDY-025 2 Active 53 M
STUDY-026 2 Active 42 F
STUDY-027 2 Active 65 M
STUDY-028 2 Active 50 F
STUDY-029 2 Active 60 M
STUDY-030 2 Active 45 F
;
run;

/*** HELP START ***//*

Purpose:
  Performs a two-sample t-test using PROC TTEST and returns ARD-style results.
  The macro outputs group means, confidence intervals, and test statistics
  in a standardized long-format dataset.

Inputs:
  data      - Input dataset.
  class     - Grouping (classification) variable with two levels.
  var       - Numeric analysis variable.
  alpha     - Significance level for confidence intervals (default: 0.05).
  side      - Test type for PROC TTEST:
              2 = two-sided (default),
              L = one-sided lower-tail,
              U/R = one-sided upper-tail.
  h0        - Null hypothesis mean difference (default: 0).
  Welch     - Whether to use Welch/Satterthwaite method:
              Y = Welch t-test (default),
              N = Pooled-variance t-test.

Outputs:
  out       - Output dataset in ARD-style structure with:
              - estimate / conf.low / conf.high for each group mean
              - estimate1 / estimate2 for group-specific means
              - t statistic, degrees of freedom, p-value
              - method, alternative, conf.level, mu, var.equal, paired

Notes:
  - Assumes exactly two groups in &class.
  - One-sided direction depends on the ordering of CLASS levels in PROC TTEST.
  - Intermediate datasets are created in WORK and deleted at the end.

Example:
  %sard_stats_t_test(
    data=ADSL,
    out=sard_stats_t_test,
    class=TRT01PN,
    var=AGE,
    alpha=0.05,
    side=2,
    h0=0,
    Welch=Y
  );

*//*** HELP END ***/

%macro sard_stats_t_test(
  data = ,
  out =sard_stats_t_test,
  class = ,
  var = ,
  alpha = 0.05 ,
  side = 2,
  h0 = 0,
  Welch = Y
);

proc ttest data = &data alpha=&alpha. side=&side. h0=&h0;
 class &class;
 var &var;

ods output Statistics=sard_ttest_Statistics;
ods output TTests=sard_ttest_Ttests;

run;

data sard_ttest_Statistics_1;
length 
stat_name
stat_label $200.
stat 8.
fmt_fun
context
$200.
;
set sard_ttest_Statistics;

/*estimate*/
call missing(of stat_name stat_label stat  fmt_fun context);
%if %upcase(&Welch) ne Y %then %do;
if method = "Pooled" then do;
%end;
%if %upcase(&Welch) = Y %then %do;
if method = "Satterthwaite" then do;
%end;
  stat_name ="estimate";
  stat_label="Group Mean";
  stat = Mean;
  fmt_fun = "1";
  context=class;
  output;
end;

/*conf.low*/
call missing(of stat_name stat_label stat  fmt_fun context);
%if %upcase(&Welch) ne Y %then %do;
if method = "Pooled" then do;
%end;
%if %upcase(&Welch) = Y %then %do;
if method = "Satterthwaite" then do;
%end;
  stat_name ="conf.low";
  stat_label="CI Lower Bound";
  stat = LowerCLMean;
  fmt_fun = "1";
  output;
end;

/*conf.high*/
call missing(of stat_name stat_label stat  fmt_fun context);
%if %upcase(&Welch) ne Y %then %do;
if method = "Pooled" then do;
%end;
%if %upcase(&Welch) = Y %then %do;
if method = "Satterthwaite" then do;
%end;
  stat_name ="conf.high";
  stat_label="CI Upper Bound";
  stat = UpperCLMean;
  fmt_fun = "1";
  output;
end;

/*estimate1*/
call missing(of stat_name stat_label stat  fmt_fun context);
if _N_ = 1 then do;
  stat_name ="estimate1";
  stat_label="Group 1 Mean";
  stat = Mean;
  fmt_fun = "1";
  context =cats("&class.=",class);
  output;
end;
/*estimate2*/
call missing(of stat_name stat_label stat  fmt_fun context);
if _N_ = 2 then do;
  stat_name ="estimate2";
  stat_label="Group 2 Mean";
  stat = Mean;
  fmt_fun = "1";
  context =cats("&class.=",class);
  output;
end;


run;


data sard_ttest_TTests_1;
length 
stat_name
stat_label $200.
stat 8.
fmt_fun
context
$200.
;
set sard_ttest_Ttests;
%if %upcase(&Welch) = Y %then %do;
  where method ="Satterthwaite";
%end;
%else %do;
  where method ="Pooled";
%end;

/*statistic*/
call missing(of stat_name stat_label stat  fmt_fun context);
stat_name=cats("statistic");
stat_label=cats("t Statistic");
stat = tValue;
fmt_fun = cats(1);
output;

/*parameter*/
call missing(of stat_name stat_label stat  fmt_fun context);
stat_name=cats("parameter");
stat_label=cats("Degrees of Freedom");
stat = DF;
fmt_fun = cats(1);
output;

/*Probt*/
call missing(of stat_name stat_label stat  fmt_fun context);
stat_name=cats("p.value");
stat_label=cats("p-value");
stat = Probt;
fmt_fun = cats(1);
output;

/*method*/
call missing(of stat_name stat_label stat  fmt_fun context);
stat_name=cats("method");
stat_label=cats("method");
select(method);
 when("Pooled") do;
     stat=1;
     fmt_fun=catx(":",stat,"Two Sample t-test");
     context="Pooled";
 end;
 when("Satterthwaite") do;
     stat=2;
     fmt_fun=catx(":",stat,"Welch Two Sample t-test");
     context="Satterthwaite";
 end;
end;
sas_raw_stat=cats(method);
output;

/*alternative*/
call missing(of stat_name stat_label stat  fmt_fun context);
stat_name=cats("alternative");
stat_label=cats("alternative");
if "%upcase(&side)" = "2" then do; 
  stat =2;
  fmt_fun  = "2:two.sided";
end;
else do;
 stat=1;
 fmt_fun = "1:one.sided (&side.)";
end;
output;

/*conf.level*/
call missing(of stat_name stat_label stat  fmt_fun context);
stat_name=cats("conf.level");
stat_label=cats("CI Confidence Level");
stat = 1 - &alpha.;
fmt_fun = cats(1);
output;

/*H0 Mean*/
call missing(of stat_name stat_label stat  fmt_fun context);
stat_name=cats("mu");
stat_label=cats("H0 Mean");
stat = &h0.;
fmt_fun = cats(1);
output;

/*	var.equal*/
call missing(of stat_name stat_label stat  fmt_fun context);
stat_name=cats("var.equal");
stat_label=cats("Equal Variances");
select(method);
 when("Pooled") do;
     stat=1;
     fmt_fun=catx(":",stat,"Y");
 end;
 when("Satterthwaite") do;
     stat=0;
     fmt_fun=catx(":",stat,"N");
 end;
end;
output;

/*paired*/
call missing(of stat_name stat_label stat  fmt_fun context);
stat_name=cats("paired");
stat_label=cats("Paired t-test");
stat=0;
fmt_fun=catx(":",stat,"N");
output;

run;

data &out.;
length 
group1
variable
context
stat_name
stat_label
$200.
stat
8.
fmt_fun
Additional_Notes_in_SAS $200.
;
set
  sard_ttest_statistics_1(rename=(context=Additional_Notes_in_SAS))
  sard_ttest_ttests_1(rename=(context=Additional_Notes_in_SAS))
;
context="stats_t_test";
group1="%upcase(&class)";
variable="%upcase(&var)";
keep group1--Additional_Notes_in_SAS ;
run;

proc delete data =sard_ttest_statistics;
run;
proc delete data =sard_ttest_statistics_1;
run;
proc delete data =sard_ttest_ttests;
run;
proc delete data =sard_ttest_ttests_1;
run;


%mend;

/* caller: README usage example, run against the mock ADSL above */
%sard_stats_t_test(
  data=ADSL,
  out=ard_ttest,
  class=TRT01PN,
  var=AGE,
  alpha=0.05,
  side=2,
  h0=0,
  Welch=Y
);

proc print data=ard_ttest noobs; run;
