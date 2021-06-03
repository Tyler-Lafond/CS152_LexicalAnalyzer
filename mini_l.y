%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <set>
	#include <string.h>
	int tempCount = 0;
	int labelCount = 0;
	void yyerror(const char *msg);
	extern int currLine;
	extern int currPos;
	FILE *yyin;
	bool mainFunc = false;
	std::map<std::string, std::string> varTemp;
	std::map<std::string, int> arrSize;
	std::set<std::string> funcs;
	std::string new_temp();
	std::string new_label();
	std::set<std::string> reserved {"NUMBER", "IDENT", "FUNCTION", "BEGIN_PARAMS", "END_PARAMS", "BEGIN_LOCALS", "END_LOCALS", "BEGIN_BODY", "END_BODY", "INTEGER", "ARRAY", "ENUM", "OF", "IF", "THEN", "ENDIF", "ELSE", "WHILE", "DO", "BEGIN_LOOP", "END_LOOP", "CONTINUE", "READ", "WRITE", "AND", "OR", "NOT", "TRUE", "FALSE", "RETURN", "ADD", "SUB", "MULT", "DIV", "MOD", "EQ", "NEQ", "LT", "GT", "LTE", "GTE", "SEMICOLON", "COLON", "COMMA", "L_PAREN", "R_PAREN", "L_SQUARE_BRACKET", "R_SQUARE_BRACKET", "ASSIGN", "function", "funcIdent", "declarations", "declaration", "vars", "var", "expressions", "expression", "ident", "identifiers", "bool_exp", "relation_and_exp", "relation_exp", "comp", "multiplicative_exp", "term", "statement", "statements"};
%}

%union{
	int num_val;
	char* id_val;
	struct S {
		char* code;
	} statement;
	struct E {
		char* place;
		char* code;
		bool arr;
	} expression;
}

%error-verbose
%start prog_start
%token <num_val> NUMBER
%token <id_val> IDENT
%type <expression> function funcIdent declarations declaration vars var expressions expression ident identifiers
%type <expression> bool_exp relation_and_exp relation_exp comp multiplicative_exp term
%type <statement> statement statements
%token FUNCTION BEGIN_PARAMS END_PARAMS BEGIN_LOCALS END_LOCALS BEGIN_BODY END_BODY INTEGER ARRAY ENUM OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE RETURN ADD SUB MULT DIV MOD EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_PAREN R_PAREN L_SQUARE_BRACKET R_SQUARE_BRACKET ASSIGN
%right ASSIGN
%left OR
%left AND
%right NOT
%left LT LTE GT GTE EQ NEQ
%left ADD SUB
%left MULT DIV MOD

%%
prog_start:	{
			if (!mainFunc)
			{
				printf("ERROR: No main function declared.\n");
				exit(0);
			}
		}
		| function prog_start {}
		;

function:	FUNCTION funcIdent SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements END_BODY
		{
			std::string temp = "func ";
			temp.append($2.place);
			temp.append("\n");
			std::string s = $2.place;
			if (s == "main")
			{
				mainFunc = true;
			}
			temp.append($5.code);
			std::string decs = $5.code;
			int decNum = 0;
			while(decs.find(".") != std::string::npos)
			{
				int pos = decs.find(".");
				decs.replace(pos, 1, "=");
				std::string part = ", $" + std::to_string(decNum) + "\n";
				decNum++;
				decs.replace(decs.find("\n", pos), 1, part);
			}
			temp.append(decs);

			temp.append($8.code);
			std::string statements = $11.code;
			if (statements.find("continue") != std::string::npos)
			{
				printf("ERROR: Continue outside loop in function %s\n", $2.place);
				exit(0);
			}
			temp.append(statements);
			temp.append("endfunc\n\n");
			printf(temp.c_str());
		}
		| error {yyerrok; yyclearin;}
		| FUNCTION ident error {yyerrok; yyclearin;}
		| FUNCTION ident SEMICOLON error {yyerrok; yyclearin;}
		| FUNCTION ident SEMICOLON BEGIN_PARAMS declarations error BEGIN_LOCALS {yyerrok; yyclearin;}
		| FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS error {yyerrok; yyclearin;}
		| FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations error {yyerrok; yyclearin;}
		| FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS error {yyerrok; yyclearin;}
		| FUNCTION ident SEMICOLON BEGIN_PARAMS declarations END_PARAMS BEGIN_LOCALS declarations END_LOCALS BEGIN_BODY statements error {yyerrok; yyclearin;}	
		;

declarations:	declaration SEMICOLON declarations
		{
			std::string temp;
			temp.append($1.code);
			temp.append($3.code);
			$$.code = strdup(temp.c_str());
			$$.place = strdup("");
		}
		|
		{
			$$.code = strdup("");
			$$.place = strdup("");
		}
		| declaration error declarations {yyerrok; yyclearin;}
		;

declaration:	identifiers COLON INTEGER
		{
			int left = 0;
			int right = 0;
			std::string parse($1.place);
			std::string temp;
			bool ex = false;
			while(!ex)
			{
				right = parse.find("|", left);
				temp.append(". ");
				if (right == std::string::npos)
				{
					std::string ident = parse.substr(left, right);
					if (reserved.find(ident) != reserved.end())
					{
						printf("ERROR: Identifier %s's name is a reserved word.\n", ident.c_str());
						exit(0);
					}
					if (funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end())
					{
						printf("ERROR: Identifier %s is previously declared.\n", ident.c_str());
						exit(0);
					}
					else
					{
						varTemp[ident] = ident;
						arrSize[ident] = 1;
					}
					temp.append(ident);
					ex = true;
				}
				else
				{
					std::string ident = parse.substr(left, right-left);
					if (reserved.find(ident) != reserved.end())
					{
						printf("ERROR: Identifier %s's name is a reserved word.\n", ident.c_str());
						exit(0);
					}
					if (funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end())
					{
						printf("ERROR: Identifier %s is previously declared.\n", ident.c_str());
						exit(0);
					}
					else
					{
						varTemp[ident] = ident;
						arrSize[ident] = 1;
					}
					temp.append(ident);
					left = right+1;
				}
				temp.append("\n");
			}
			$$.code = strdup(temp.c_str());
			$$.place = strdup("");
		}
		| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF INTEGER
		{
			size_t left = 0;
			size_t right = 0;
			std::string parse($1.place);
			std::string temp;
			bool ex = false;
			while (!ex)
			{
				right = parse.find("|", left);
				temp.append(".[] ");
				if (right == std::string::npos)
				{
					std::string ident = parse.substr(left, right);
					if (reserved.find(ident) != reserved.end())
					{
						printf("ERROR: Identifier %s's name is a reserved word.\n", ident.c_str());
						exit(0);
					}
					if (funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end())
					{
						printf("ERROR: Identifier %s is previously declared.\n", ident.c_str());
						exit(0);
					}
					else
					{
						if ($5 <= 0)
						{
							printf("ERROR: Declaring array ident %s of size <= 0.\n", ident.c_str());
							exit(0);
						}
						varTemp[ident] = ident;
						arrSize[ident] = $5;
					}
					temp.append(ident);
					ex = true;
				}
				else
				{
					std::string ident = parse.substr(left, right-left);
					if (reserved.find(ident) != reserved.end())
					{
						printf("ERROR: Identifier %s's name is a reserved word.\n", ident.c_str());
						exit(0);
					}
					if (funcs.find(ident) != funcs.end() || varTemp.find(ident) != varTemp.end())
					{
						printf("ERROR: Identifier %s is previously declared.\n", ident.c_str());
						exit(0);
					}
					else
					{
						if ($5 <= 0)
						{
							printf("ERROR: Declaring array ident %s of size <= 0.\n", ident.c_str());
							exit(0);
						}
						varTemp[ident] = ident;
						arrSize[ident] = $5;
					}
					temp.append(ident);
					ex = true;
				}
			}
		}
		| identifiers COLON ENUM L_PAREN identifiers R_PAREN { printf("declaration -> identifiers COLON ENUM L_PAREN identifiers R_PAREN\n"); }
		| identifiers error ARRAY {yyerrok; yyclearin;}
		| identifiers error ENUM {yyerrok; yyclearin;}
		| identifiers COLON error {yyerrok; yyclearin;}
		| identifiers COLON ARRAY error {yyerrok; yyclearin;}
		| identifiers COLON ARRAY L_SQUARE_BRACKET error {yyerrok; yyclearin;}
		| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER error {yyerrok; yyclearin;}
		| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET error {yyerrok; yyclearin;}
		| identifiers COLON ARRAY L_SQUARE_BRACKET NUMBER R_SQUARE_BRACKET OF error {yyerrok; yyclearin;}
		| identifiers COLON ENUM error {yyerrok; yyclearin;}
		| identifiers COLON ENUM L_PAREN error {yyerrok; yyclearin;}
		| identifiers COLON ENUM L_PAREN identifiers error {yyerrok; yyclearin;}
		;

identifiers:	ident
		{
			$$.code = strdup("");
			$$.place = strdup($1.place);
		}
		| ident COMMA identifiers
		{
			std::string temp;
			temp.append($1.place);
			temp.append("|");
			temp.append($3.place);
			$$.code = strdup("");
			$$.place = strdup(temp.c_str());
		}
		| ident error identifiers {yyerrok; yyclearin;}
		;

funcIdent:	IDENT
		{
			if (funcs.find($1) != funcs.end())
			{
				printf("ERROR: Function name %s is already declared.\n", $1);
				exit(0);
			}
			else
			{
				funcs.insert($1);
			}
			$$.code = strdup("");
			$$.place = strdup($1);
		}

ident:	IDENT
	{
		$$.code = strdup("");
		$$.place = strdup($1);
	}

statements:	statement SEMICOLON statements
		{
			std::string temp;
			temp.append($1.code);
			temp.append($3.code);
			$$.code = strdup(temp.c_str());
		}
		|
		{
			$$.code = strdup("");
			$$.place = strdup("");
		}
		| statement error {yyerrok; yyclearin;}
		;

statement:	var ASSIGN expression
		{
			std::string temp;
			temp.append($1.code);
			temp.append($3.code);
			std::string middle = $3.place;
			if ($1.arr)
			{
				temp += "[]= ";
			}
			else
			{
				temp += "= ";
			}
			temp.append($1.place);
			temp.append(", ");
			temp.append(middle);
			temp += "\n";
			$$.code = strdup(temp.c_str());
		}
		| IF bool_exp THEN statements ENDIF
		{
			std::string iS = new_label();
			std::string tS = new_label();
			std::string temp;
			temp.append($2.code);
			temp += "?:= " + iS + ", " + $2.place + "\n";
			temp += ":= " + tS + "\n";
			temp += ": " + iS + "\n";
			temp.append($4.code);
			temp += ": " + tS + "\n";
			$$.code = strdup(temp.c_str());
		}
		| IF bool_exp THEN statements ELSE statements ENDIF
		{
			std::string iS = new_label();
			std::string tS = new_label();
			std::string temp;
			temp.append($2.code);
			temp += "?:= " + iS + ", " + $2.place + "\n";
			temp.append($6.code);
			temp += ":= " + tS + "\n";
			temp += ": " + iS + "\n";
			temp.append($4.code);
			temp += ": " + tS + "\n";
			$$.code = strdup(temp.c_str());
		}
		| WHILE bool_exp BEGINLOOP statements ENDLOOP
		{
			std::string temp;
			std::string cond = new_label();
			std::string body = new_label();
			std::string endOfLoop = new_label();
			std::string code = $4.code;
			size_t pos = code.find("continue");
			while (pos != std::string::npos)
			{
				code.replace(pos, 8, ":= " + cond);
				pos = code.find("continue");
			}
			temp.append(": ");
			temp += cond + "\n";
			temp.append($2.code);
			temp += "?:= " + body + ", ";
			temp.append($2.place);
			temp.append("\n");
			temp += ":= " + endOfLoop + "\n";
			temp += ": " + body + "\n";
			temp.append(code);
			temp += ":= " + cond + "\n";
			temp += ": " + endOfLoop + "\n";
			$$.code = strdup(temp.c_str());
		}
		| DO BEGINLOOP statements ENDLOOP WHILE bool_exp
		{
			std::string temp;
			std::string doStart = new_label();
			std::string cond = new_label();
			std::string code = $3.code;
			size_t pos = code.find("continue");
			while (pos != std::string::npos)
			{
				code.replace(pos, 8, ":= " + cond);
				pos = code.find("continue");
			}
			temp.append(": ");
			temp += doStart + "\n";
			temp.append(code);
			temp += ": " + cond + "\n";
			temp.append($6.code);
			temp += "?:= " + doStart + ", ";
			temp.append($6.place);
			temp.append("\n");
			$$.code = strdup(temp.c_str());
		}
		| READ vars
		{
			std::string temp;
			temp.append($2.code);
			temp.append(". ");
			size_t pos = temp.find("|", 0);
			while (pos != std::string::npos)
			{
				temp.replace(pos, 1, "<");
				pos = temp.find("|", pos);
			}
			$$.code = strdup(temp.c_str());
		}
		| WRITE vars
		{
			std::string temp;
			temp.append($2.code);
			temp.append(". ");
			size_t pos = temp.find("|", 0);
			while (pos != std::string::npos)
			{
				temp.replace(pos, 1, ">");
				pos = temp.find("|", pos);
			}
			$$.code = strdup(temp.c_str());
		}
		| CONTINUE
		{
			$$.code = strdup("continue\n"); 
		}
		| RETURN expression
		{
			std::string temp;
			temp.append($2.code);
			temp.append("ret ");
			temp.append($2.place);
			temp.append("\n");
			$$.code = strdup(temp.c_str());
		}
		| IF bool_exp error statements ENDIF {yyerrok; yyclearin;}
		| IF bool_exp error statements ELSE statements ENDIF {yyerrok; yyclearin;}
		| IF bool_exp THEN statements error {yyerrok; yyclearin;}
		| IF bool_exp THEN statements error statements ENDIF{yyerrok; yyclearin;}
		| IF bool_exp THEN statements ELSE statements error {yyerrok; yyclearin;}
		| WHILE bool_exp error {yyerrok; yyclearin;}
		| WHILE bool_exp BEGINLOOP statements error {yyerrok; yyclearin;}
		| DO error {yyerrok; yyclearin;}
		| DO BEGINLOOP statements error {yyerrok; yyclearin;}
		| DO BEGINLOOP statements ENDLOOP error {yyerrok; yyclearin;}
		;

bool_exp:	relation_and_exp
		{
			$$.code = strdup.("");
			$$.place = strdup($1.place);
		}
		| relation_and_exp OR bool_exp
		{
			std::string temp;
			std::string dst = new_temp();
			temp.append($1.code);
			temp.append($3.code);
			temp += ". " + dst + "\n" + "|| " + dst + ", " + $1.place + ", " + $3.place + "\n";
			$$.code = strdup(temp.c_str());
			$$.place = strdup(dst.c_str());
		}
		| relation_and_exp error {yyerrok; yyclearin;}
		;

relation_and_exp:	relation_exp
			{
				$$.code = strdup("");
				$$.place = strdup($1.place);
			}
			| relation_exp AND relation_and_exp
			{
				std::string temp;
				std::string dst = new_temp();
				temp.append($1.code);
				temp.append($3.code);
				temp += ". " + dst + "\n" + "&& " + dst + ", " + $1.place + ", " + $3.place + "\n";
				$$.code = strdup(temp.c_str());
				$$.place = strdup(dst.c_str());
			}
			| relation_exp error {yyerrok; yyclearin;}
			;

relation_exp:	NOT expression comp expression
		{
			std::string dst = new_temp();
			std::string inv = new_temp();
			std::string temp;
			temp.append($1.code);
			temp.append($3.code);
			temp += ". " + dst + "\n" + $2.place + dst + ", " + $1.place + ", " + $3.place + "\n" + ". " + inv + "\n" + "! " + inv + ", " + dst + "\n";
			$$.code = strdup(temp.c_str());
			$$.place = strdup(inv.c_str());
		}
		| expression comp expression
		{
			std::string dst = new_temp();
			std::string temp;
			temp.append($1.code);
			temp.append($3.code);
			temp += ". " + dst + "\n" + $2.place + dst + ", " + $1.place + ", " + $3.place + "\n";
			$$.code = strdup(temp.c_str());
			$$.place = strdup(dst.c_str());
		}
		| NOT TRUE
		{
			std::string temp;
			temp.append("0");
			$$.code = strdup("");
			$$.place = strdup(temp.c_str());
		}
		| TRUE
		{
			std::string temp;
			temp.append("1");
			$$.code = strdup("");
			$$.place = strdup(temp.c_str());
		}
		| NOT FALSE
		{
			std::string temp;
			temp.append("1");
			$$.code = strdup("");
			$$.place = strdup(temp.c_str());
		}
		| FALSE
		{
			std::string temp;
			temp.append("0");
			$$.code = strdup("");
			$$.place = strdup(temp.c_str());
		}
		| NOT L_PAREN bool_exp R_PAREN
		{
			std::string temp;
			std::string dst = new_temp();
			temp.append($3.code);
			temp += ". " + dst + "\n" + "! " + dst + ", " + $3.place + "\n";
			$$.code = strdup(temp.c_str());
			$$.place = (dst.c_str());
		}
		| L_PAREN bool_exp R_PAREN
		{
			$$.code = ("");
			$$.place = ($2.place);
		}
		| NOT error {yyerrok; yyclearin;}
		| NOT expression error expression {yyerrok; yyclearin;}
		| expression error expression {yyerrok; yyclearin;}
		| L_PAREN bool_exp error {yyerrok; yyclearin;}
		;

comp:	EQ
	{
		$$.code = strdup("");
		$$.place = strdup("== ");
	}
	| NEQ
	{
		$$.code = strdup("");
		$$.place = strdup("!= ");
	}
	| LT
	{
		$$.code = strdup("");
		$$.place = strdup("< ");
	}
	| GT
	{
		$$.code = strdup("");
		$$.place = strdup("> ");
	}
	| LTE
	{
		$$.code = strdup("");
		$$.place = strdup("<= ");
	}
	| GTE
	{
		$$.code = strdup("");
		$$.place = strdup(">= ");
	}
	;

expressions:	{
			$$.code = strdup("");
			$$.place = strdup("");
		}
		| expression
		{
			$$.code = strdup("");
			$$.place = strdup($1.place);
		}
		| expression COMMA expressions
		{
			std::string temp;
			temp.append($1.place);
			temp.append("|");
			temp.append($3.place);
			$$.code = strdup("");
			$$.place = strdup(temp.c_str());
		}
		| expression error {yyerrok; yyclearin;}
		;

expression:	multiplicative_exp
		{
			$$.code = strdup("");
			$$.place = strdup($1.place);
		}
		| multiplicative_exp ADD expression
		{
			std::string temp;
			std::string dst = new_temp();
			temp.append($1.code);
			temp.append($3.code);
			temp += ". " + dst + "\n" + "+ " + dst + ", " + $1.place + ", " + $3.place + "\n";
			$$.code = strdup(temp.c_str());
			$$.place = strdup(dst.c_str());
		}
		| multiplicative_exp SUB expression
		{
			std::string temp;
			std::string dst = new_temp();
			temp.append($1.code);
			temp.append($3.code);
			temp += ". " + dst + "\n" + "- " + dst + ", " + $1.place + ", " + $3.place + "\n";
			$$.code = strdup(temp.c_str());
			$$.place = strdup(dst.c_str());
		}
		| multiplicative_exp error {yyerrok; yyclearin;}
		;

multiplicative_exp:	term
			{
				$$.code = strdup("");
				$$.place = strdup($1.place);
			}
			| term MULT multiplicative_exp
			{
				std::string temp;
				std::string dst = new_temp();
				temp.append($1.code);
				temp.append($3.code);
				temp += ". " + dst + "\n" + "* " + dst + ", " + $1.place + ", " + $3.place + "\n";
				$$.code = strdup(temp.c_str());
				$$.place = strdup(dst.c_str());
			}
			| term DIV multiplicative_exp
			{
				std::string temp;
				std::string dst = new_temp();
				temp.append($1.code);
				temp.append($3.code);
				temp += ". " + dst + "\n" + "/ " + dst + ", " + $1.place + ", " + $3.place + "\n";
				$$.code = strdup(temp.c_str());
				$$.place = strdup(dst.c_str());
			}
			| term MOD multiplicative_exp
			{
				std::string temp;
				std::string dst = new_temp();
				temp.append($1.code);
				temp.append($3.code);
				temp += ". " + dst + "\n" + "% " + dst + ", " + $1.place + ", " + $3.place + "\n";
				$$.code = strdup(temp.c_str());
				$$.place = strdup(dst.c_str());
			}
			| term error multiplicative_exp {yyerrok; yyclearin;}
			;

term:	SUB var { printf("term -> SUB var\n"); }
	| var
	{
		//CHECK THIS OVER AGAIN!!!!!!!
		std::string temp;
		temp.append($1.code);
		if ($1.arr)
		{
			temp.append(".[]| ");
		}
		else
		{
			temp.append(".| ");
		}
		temp.append($1.place);
		temp.append("\n");
		$$.code = strdup(temp.c_str());
		$$.place = strdup("");
	}
	| SUB NUMBER { printf("term -> SUB NUMBER\n"); }
	| NUMBER
	{
		$$.code = strdup("");
		$$.place = ($1)
	}
	| SUB L_PAREN expression R_PAREN { printf("term -> SUB L_PAREN NUMBER R_PAREN\n"); }
	| L_PAREN expression R_PAREN
	{
		$$.code = strdup("");
		$$.place = strdup($2.place);
	}
	| ident L_PAREN expressions R_PAREN { printf("term -> ident L_PAREN expressions R_PAREN\n"); }
	| SUB error expression R_PAREN {yyerrok; yyclearin;}
	| SUB L_PAREN expression error {yyerrok; yyclearin;}
	| L_PAREN expression error {yyerrok; yyclearin;}
	| ident error expressions R_PAREN {yyerrok; yyclearin;}
	| ident L_PAREN expressions error {yyerrok; yyclearin;}
	;

vars:	var 
	{
		std::string temp;
		temp.append($1.code);
		if ($1.arr)
		{
			temp.append(".[]| ");
		}
		else
		{
			temp.append(".| ");
		}
		temp.append($1.place);
		temp.append("\n");
		$$.code = strdup(temp.c_str());
		$$.place = strdup("");
	}
	| var COMMA vars
	{
		std::string temp;
		temp.append($1.code);
		if ($1.arr)
		{
			temp.append(".[]| ");
		}
		else
		{
			temp.append(".| ");
		}
		temp.append($1.place);
		temp.append("\n");
		temp.append($3.code);
		$$.code = strdup(temp.c_str());
		$$.place = strdup("");
	}
	| var error vars {yyerrok; yyclearin;}
	;

var:	ident
	{
		std::string temp;
		$$.code = strdup("");
		std::string ident = $1.place;
		if (funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end())
		{
			printf("ERROR: Identifier %s is not declared.\n", ident.c_str());
			exit(0);
		}
		else if (arrSize[ident] > 1)
		{
			printf("ERROR: No index for array Identifier %s provided.\n", ident.c_str());
			exit(0);
		}
		$$.place = strdup(ident.c_str());
		$$.arr = false;
	}
	| ident L_SQUARE_BRACKET expression R_SQUARE_BRACKET
	{
		std::string temp;
		std::string ident = $1.place;
		if (funcs.find(ident) == funcs.end() && varTemp.find(ident) == varTemp.end())
		{
			printf("ERROR: Identifier %s is not declared.\n", ident.c_str());
			exit(0);
		}
		else if (arrSize[ident] == 1)
		{
			printf("ERROR: Provided index for non-array Identifier %s.\n", ident.c_str());
			exit(0);
		}
		temp.append($1.place);
		temp.append(", ");
		temp.append($3.place);
		$$.code = strdup($3.code);
		$$.place = strdup(temp.c_str());
		$$.arr = true;
	}
	| ident error expression R_SQUARE_BRACKET {yyerrok; yyclearin;}
	| ident L_SQUARE_BRACKET expression error {yyerrok; yyclearin;}
	;

%%

int main(int argc, char **argv) {

	if (argc > 1)
	{
		yyin = fopen(argv[1], "r");
		if ( yyin == NULL)
		{
			printf("Not a valid file name: %s filename\n", argv[0]);
			exit(0);
		}
	}
	yyparse();
	return 0;
}

void yyerror(const char *msg) {
	printf("** Line %d, position %d: %s\n", currLine, currPos, msg);
}

std::string new_temp()
{
	std::string t = "t" + std::to_string(tempCount);
	tempCount++;
	return t;
}

std::string new_label()
{
	std::string l = "L" + std::to_string(labelCount);
	labelCount++;
	return l;
}
