 /*
  *  The scanner definition for COOL.
  */

 /*
  *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
  *  output, so headers and global definitions are placed here to be visible
  * to the code in the file.  Don't remove anything that was here initially
  */
%{

#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <ctype.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */
/*
   The two statements below are here just so this program will compile.
   You may need to change or remove them on your final code.
*/
#define yywrap() 1
#define YY_SKIP_YYWRAP

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int tam_string;
bool invalid;
int comment_nest=0;

%}

/*
* Define names for regular expressions here.
*/

%x STRING COMMENT

%%

\n {curr_lineno++;}

[ \f\t\r\v]+ {}
 
 /*
  *  Nested comments
  */

"--".* {}

"(*" {
	BEGIN COMMENT;
	comment_nest++;
}

<COMMENT>"(*" {
	comment_nest++;
}

<COMMENT>"*)" {
	comment_nest--;
	if(comment_nest==0){
		BEGIN 0;
	}
}

<COMMENT><<EOF>> {
	fatal_error("EOF in comment\n");
}

"*)" {
	strcpy(cool_yylval.error_msg,"Unmatched *)");
	return(ERROR);
}

<COMMENT>\n {curr_lineno++;}
<COMMENT>. {}

 /*
  *  The single-character operators.
  */

"{"	{return '{';}
"}"	{return '}';}
"("	{return '(';}
")"	{return ')';}
"~"	{return '~';}
","	{return ',';}
";"	{return ';';}
":"	{return ':';}
"+"	{return '+';}
"-"	{return '-';}
"*"	{return '*';}
"/"	{return '/';}
"%"	{return '%';}
"."	{return '.';}
"<"	{return '<';}
"="	{return '=';}
"@"	{return '@';}

 /*
  *  The multiple-character operators.
  */
"=>" {return (DARROW);}
"<-" {return (ASSIGN);}
"<=" {return (LE);}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

(?i:CLASS)    {return(CLASS);}      
(?i:ELSE)     {return(ELSE);}       
(?i:FI)       {return(FI);}         
(?i:IF)       {return(IF);}         
(?i:IN)       {return(IN);}         
(?i:INHERITS) {return(INHERITS);}   
(?i:LET)      {return(LET);}        
(?i:LOOP)     {return(LOOP);}       
(?i:POOL)     {return(POOL);}       
(?i:THEN)     {return(THEN);}       
(?i:WHILE)    {return(WHILE);}      
(?i:CASE)     {return(CASE);}       
(?i:ESAC)     {return(ESAC);}       
(?i:OF)       {return(OF);}         
(?i:NEW)      {return(NEW);}        
(?i:NOT)      {return(NOT);}        
(?i:ISVOID)   {return(ISVOID);}

[0-9]+ { 
	cool_yylval.symbol=inttable.add_string(yytext); 
	return(INT_CONST);
}

t[rR][uU][eE] { 
	cool_yylval.boolean = 1;
	return (BOOL_CONST);
}
f[aA][lL][sS][eE] { 
	cool_yylval.boolean = 0;
	return (BOOL_CONST);
}

[A-Za-z][A-Za-z0-9_]* {
	cool_yylval.symbol=idtable.add_string(yytext);
	return islower(yytext[0])? OBJECTID: TYPEID;
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

"\"" {
	tam_string=0;
	invalid=false;
	BEGIN STRING;
}

<STRING>"\"" { 
	if(invalid){
		strcpy(cool_yylval.error_msg,"String contains null character");
		BEGIN 0;
		return(ERROR);
	}
	string_buf[tam_string]='\0';
	cool_yylval.symbol=stringtable.add_string(string_buf);
	BEGIN 0;
	return(STR_CONST);
}

<STRING>\\. {
	if (tam_string>=MAX_STR_CONST-1){
		strcpy(cool_yylval.error_msg,"String constant too long");
		BEGIN 0;
		return (ERROR);
	}

	if(yytext[1]=='\n'){
		curr_lineno++;
	}
	else if(yytext[1]=='0'){
		invalid=true;
	}
	else{
		char c;
		switch(yytext[1]){
			case '\"': c='\"'; break;
			case '\\': c='\\'; break;
			case 'b' : c='\b'; break;
			case 't' : c='\t'; break;
			case 'n' : c='\n'; break;
			case 'f' : c='\f'; break;
			default  : c=yytext[1];
		}

		string_buf[tam_string]=c;
		tam_string++;
	}
}

<STRING>. { 
	if (tam_string>=MAX_STR_CONST-1) {
		strcpy(cool_yylval.error_msg,"String constant too long");
		BEGIN 0;
		return(ERROR);
	} 
	string_buf[tam_string]=yytext[0]; 
	tam_string++;
}

<STRING>\n {
	curr_lineno++;
	strcpy(cool_yylval.error_msg,"Unterminated string constant");
	BEGIN 0;
	return(ERROR);
}

<STRING><<EOF>>	{
	fatal_error("EOF in string constant\n");
}

 /* Unknown char */
. {
	strcpy(cool_yylval.error_msg,yytext); 
	return(ERROR); 
}
%%
