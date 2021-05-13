%{
	#include "y.tab.h"
	int currLine = 1;
	int currPos = 1;
%}

DIGIT [0-9]
ID [a-zA-Z]|[a-zA-Z][a-zA-Z0-9_]*[a-zA-Z0-9]
COMMENT ##.*
E_ID_1 [0-9_][a-zA-Z0-9_]*
E_ID_2 [a-zA-Z][a-zA-Z0-9_]*[_]

%%


"function"	{currPos += yyleng; return FUNCTION;}
"beginparams"	{currPos += yyleng; return BEGIN_PARAMS;}
"endparams"	{currPos += yyleng; return END_PARAMS;}
"beginlocals"	{currPos += yyleng; return BEGIN_LOCALS;}
"endlocals"	{currPos += yyleng; return END_LOCALS;}
"beginbody"	{currPos += yyleng; return BEGIN_BODY;}
"endbody"	{currPos += yyleng; return END_BODY;}
"integer"	{currPos += yyleng; return INTEGER;}
"array"	{currPos += yyleng; return ARRAY;}
"enum"	{currPos += yyleng; return ENUM;}
"of"	{currPos += yyleng; return OF;}
"if"	{currPos += yyleng; return IF;}
"then"	{currPos += yyleng; return THEN;}
"endif"	{currPos += yyleng; return ENDIF;}
"else"	{currPos += yyleng; return ELSE;}
"while"	{currPos += yyleng; return WHILE;}
"do"	{currPos += yyleng; return DO;}
"beginloop"	{currPos += yyleng; return BEGINLOOP;}
"endloop"	{currPos += yyleng; return ENDLOOP;}
"continue"	{currPos += yyleng; return CONTINUE;}
"read"	{currPos += yyleng; return READ;}
"write"	{currPos += yyleng; return WRITE;}
"and"	{currPos += yyleng; return AND;}
"or"	{currPos += yyleng; return OR;}
"not"	{currPos += yyleng; return NOT;}
"true"	{currPos += yyleng; return TRUE;}
"false"	{currPos += yyleng; return FALSE;}
"return"	{currPos += yyleng; return RETURN;}

"+"	{currPos += yyleng; return ADD;}
"-"	{currPos += yyleng; return SUB;}
"*"	{currPos += yyleng; return MULT;}
"/"	{currPos += yyleng; return DIV;}
"%"	{currPos += yyleng; return MOD;}

"=="	{currPos += yyleng; return EQ;}
"<>"	{currPos += yyleng; return NEQ;}
"<"	{currPos += yyleng; return LT;}
">"	{currPos += yyleng; return GT;}
"<="	{currPos += yyleng; return LTE;}
">="	{currPos += yyleng; return GTE;}

(\.{DIGIT}+)|({DIGIT}+(\.{DIGIT}*)?([eE][+-]?[0-9]+)?)	{currPos += yyleng; yylval.num_val = atof(yytext); return NUMBER;}
{ID}	{currPos += yyleng; yylval.id_val = yytext; return IDENT;}
{COMMENT}	{currLine++; currPos = 1;}

";"	{currPos += yyleng; return SEMICOLON;}
":"	{currPos += yyleng; return COLON;}
","	{currPos += yyleng; return COMMA;}
"("	{currPos += yyleng; return L_PAREN;}
")"	{currPos += yyleng; return R_PAREN;}
"["	{currPos += yyleng; return L_SQUARE_BRACKET;}
"]"	{currPos += yyleng; return R_SQUARE_BRACKET;}
":="	{currPos += yyleng; return ASSIGN;}

"\n"	{currLine++; currPos = 1;}
[ ]+	{currPos += yyleng;}
[\t]+	{currPos += 4;}

{E_ID_1}	{printf("Error at line %d, column %d: identifier \"%s\" must begin with a letter\n", currLine, currPos, yytext); exit(0);}

{E_ID_2}	{printf("Error at line %d, column %d: identifier \"%s\" cannot end with an underscore\n", currLine, currPos, yytext); exit(0);}

.	{printf("Error at line %d, column %d: unrecognized symbol \"%s\"\n", currLine, currPos, yytext); exit(0);}

%%
