/*
      mfpl.y

Specifications for the MFPL language, YACC input file.

To create syntax analyzer:

flex mfpl.l
	bison mfpl.y
	g++ mfpl.tab.c -o mfpl_parser
	mfpl_parser < inputFileName
 */

/*
 *	Declaration section.
 */
%{
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <cstring>
#include <stack>
#include "SymbolTable.h"
using namespace std;

#define ARITHMETIC_OP	1  // 0000001
#define ADD_OP 9         // 0001001
#define SUB_OP 17 		   // 0010001
#define MULT_OP 25       // 0011001
#define DIV_OP 33        // 0100001

#define LOGICAL_OP   	2  // 0000010
#define AND_OP 10        // 0001010
#define OR_OP 18         // 0010010

#define RELATIONAL_OP	4  // 0000100  
#define LT_OP 12         // 0001100
#define GT_OP 20         // 0010100
#define LE_OP 28         // 0011100
#define GE_OP 36         // 0100100
#define EQ_OP 44         // 0101100
#define NE_OP 52         // 0110100



int lineNum = 1;

stack<SYMBOL_TABLE> scopeStack;    // stack of scope hashtables

bool isIntCompatible(const int theType);
bool isStrCompatible(const int theType);
bool isIntOrStrCompatible(const int theType);

string convertFromBool(const bool b)
{
	// cout << "DEBUG::" << b << endl;
	return b ? "t" : "nil";
}

bool checkBit(int fullVal, int bit) 
{
	//cout << "RELOPBIT? " << bit << endl;
	bool o = false;
	if (fullVal & (1 << (bit - 1))) 
			o = true;
	return o;
}

void beginScope();
void endScope();
void cleanUp();
TYPE_INFO findEntryInAnyScope(const string theName);

void printRule(const char*, const char*);
int yyerror(const char* s) {
  printf("Line %d: %s\n", lineNum, s);
  cleanUp();
  exit(1);
}

extern "C" {
    int yyparse(void);
    int yylex(void);
    int yywrap() {return 1;}
}

%}

%union {
  char* text;
  int num;
  TYPE_INFO typeInfo;
};

/*
 *	Token declarations
*/
%token  T_LPAREN T_RPAREN 
%token  T_IF T_LETSTAR T_PRINT T_INPUT
%token  T_ADD  T_SUB  T_MULT  T_DIV
%token  T_LT T_GT T_LE T_GE T_EQ T_NE T_AND T_OR T_NOT	 
%token  T_INTCONST T_STRCONST T_T T_NIL T_IDENT T_UNKNOWN

%type	<text> T_IDENT T_STRCONST T_INTCONST
%type <typeInfo> N_EXPR N_PARENTHESIZED_EXPR N_ARITHLOGIC_EXPR  
%type <typeInfo> N_CONST N_IF_EXPR N_PRINT_EXPR N_INPUT_EXPR 
%type <typeInfo> N_LET_EXPR N_EXPR_LIST  
%type <num> N_BIN_OP N_LOG_OP N_REL_OP N_ARITH_OP

/*
 *	Starting point.
 */
%start  N_START

/*
 *	Translation rules.
 */
%%
N_START		: N_EXPR
	 {
			printRule("START", "EXPR");
			printf("\n---- Completed parsing ----\n\n");
			printf("\nValue of the expression is\: ");
			
			if ($1.type == BOOL)
				cout << convertFromBool($1.boolVal);
			else if ($1.type == STR)
			  cout << $1.stringVal;
			else if ($1.type == INT)
			  cout << $1.intVal;
			
			printf("\n");
			//printf("\Type of the expression is> ");
			//cout << $1.type;
			return 0;
			}
			;
N_EXPR		: N_CONST
	{
			printRule("EXPR", "CONST");
			$$.type = $1.type; 
			}
		| T_IDENT
		{
			printRule("EXPR", "IDENT");
		string ident = string($1);
		TYPE_INFO exprTypeInfo = 	findEntryInAnyScope(ident);
		if (exprTypeInfo.type == UNDEFINED) 
		{
		  yyerror("Undefined identifier");
		  return(0);
		}
		$$ = exprTypeInfo; 
			}
		| T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
		{
			printRule("EXPR", "( PARENTHESIZED_EXPR )");
			$$ = $2; 
			}
			;
N_CONST		: T_INTCONST
	 {
			printRule("CONST", "INTCONST");
		  $$.type = INT;
			$$.intVal = atoi($1); 
			}
		| T_STRCONST
			{
			printRule("CONST", "STRCONST");
		  $$.type = STR;
			$$.stringVal = $1;
			}
		| T_T
		{
			printRule("CONST", "t");
		  $$.type = BOOL;
			$$.boolVal = 1;
			}
		| T_NIL
		{
			printRule("CONST", "nil");
			$$.type = BOOL; 
			$$.boolVal = 0;
			}
			;
N_PARENTHESIZED_EXPR	: N_ARITHLOGIC_EXPR 
		     {
				printRule("PARENTHESIZED_EXPR",
				"ARITHLOGIC_EXPR");
				$$.type = $1.type; 
				}
		      | N_IF_EXPR 
				{
				printRule("PARENTHESIZED_EXPR", "IF_EXPR");
				$$ = $1;
				}
		      | N_LET_EXPR 
				{
				printRule("PARENTHESIZED_EXPR", 
				"LET_EXPR");
				$$.type = $1.type; 
				}
		      | N_PRINT_EXPR 
				{
				printRule("PARENTHESIZED_EXPR", 
					    "PRINT_EXPR");
				$$.type = $1.type; 
				}
		      | N_INPUT_EXPR 
				{
				printRule("PARENTHESIZED_EXPR",
					    "INPUT_EXPR");
				$$ = $1; 
				}
		     | N_EXPR_LIST 
				{
				printRule("PARENTHESIZED_EXPR",
					  "EXPR_LIST");
				$$ = $1;
				
				}
				;
N_ARITHLOGIC_EXPR	: N_UN_OP N_EXPR
		  {
				printRule("ARITHLOGIC_EXPR", 
					  "UN_OP EXPR");
		      $$.type = BOOL; 
					// if ($2.boolVal == 0 && $2.type == BOOL)
					//   $$.
					$$.boolVal = ($2.boolVal == 0 && $2.type == BOOL);
				}
				| N_BIN_OP N_EXPR N_EXPR
				{
					printRule("ARITHLOGIC_EXPR", "BIN_OP EXPR EXPR");
		      $$.type = BOOL;

		      if (checkBit($1,ARITHMETIC_OP))
					{
							$$.type = INT;
							if (!isIntCompatible($2.type)) 
							{
								yyerror("Arg 1 must be integer");
								return(0);
							}
							if (!isIntCompatible($3.type)) 
							{
								yyerror("Arg 2 must be integer");
								return(0);
							}
							switch($1)
							{
								case ADD_OP:
									$$.intVal = $2.intVal + $3.intVal;
									break;
								case MULT_OP:
									$$.intVal = $2.intVal * $3.intVal;
									break;
								case SUB_OP:
									$$.intVal = $2.intVal - $3.intVal;
									break;
								case DIV_OP:
								  if ($3.intVal == 0)
									{
										yyerror("Attempted division by zero");
									  return(0);
									}
									$$.intVal = $2.intVal / $3.intVal;
									break;
							}
					}
					else if ($1 & RELATIONAL_OP)
				  {
						if (!isIntOrStrCompatible($2.type)) 
						{
							yyerror("Arg 1 must be integer or string");
							return(0);
						}
						if (!isIntOrStrCompatible($3.type)) 
						{
							yyerror("Arg 2 must be integer or string");
							return(0);
						}
						if (isIntCompatible($2.type) &&
								!isIntCompatible($3.type)) 
						{
							yyerror("Arg 2 must be integer");
							return(0);
						}
						else if (isStrCompatible($2.type) && !isStrCompatible($3.type)) 
						{
							yyerror("Arg 2 must be string");
							return(0);
						}
						

						switch($1)
						{
							case EQ_OP:
								if (isStrCompatible($2.type))
								{			  
									$$.boolVal = string($2.stringVal) == string($3.stringVal);
								}
								else
									$$.boolVal = $2.intVal == $3.intVal;
								break;
							case LT_OP:
								if (isStrCompatible($2.type))
								{
									$$.boolVal = string($2.stringVal) <= string($3.stringVal);
								}
								else
									$$.boolVal = $2.intVal < $3.intVal;
								break;
							case LE_OP:
								if (isStrCompatible($2.type))
								{
									$$.boolVal = string($2.stringVal) <= string($3.stringVal);
								}
								else
									$$.boolVal = $2.intVal <= $3.intVal;
								break;
							case GT_OP:
								if (isStrCompatible($2.type))
								{
									$$.boolVal = string($2.stringVal) > string($3.stringVal);
								}
								else
									$$.boolVal = $2.intVal > $3.intVal;
								break;
							case GE_OP:
								if (isStrCompatible($2.type))
								{
									$$.boolVal = string($2.stringVal) >= string($3.stringVal);
								}
								else
									$$.boolVal = $2.intVal >= $3.intVal;
								break;
							case NE_OP:
								if (isStrCompatible($2.type))
								{
									$$.boolVal = string($2.stringVal) != string($3.stringVal);
								}
								else
									$$.boolVal = $2.intVal != $3.intVal;
								break;
						}
					}
					else if (checkBit($1, LOGICAL_OP))
					{
						bool l = !($2.type == BOOL && !($2.boolVal));
						bool r = !($3.type == BOOL && !($3.boolVal));
						$$.boolVal = ($1 == AND_OP) ? l && r : l || r; 
					}
				}
			;
N_IF_EXPR    	: T_IF N_EXPR N_EXPR N_EXPR
	      {
					if ($2.type == BOOL && !($2.boolVal))
					  $$ = $4;
					else
					  $$ = $3;

				printRule("IF_EXPR", "if EXPR EXPR EXPR");
			  //$$.type = $3.type | $4.type; 
			}
			;
N_LET_EXPR      : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN 
		N_EXPR
			{
			printRule("LET_EXPR", 
				    "let* ( ID_EXPR_LIST ) EXPR");
			endScope();
		$$ = $5; 
			}
			;
N_ID_EXPR_LIST  : /* epsilon */
		{
			printRule("ID_EXPR_LIST", "epsilon");
			}
		| N_ID_EXPR_LIST T_LPAREN T_IDENT N_EXPR T_RPAREN 
			{
			printRule("ID_EXPR_LIST", 
			  "ID_EXPR_LIST ( IDENT EXPR )");
			string lexeme = string($3);
		 TYPE_INFO exprTypeInfo = $4;
		//  cout << lexeme << "---------------------" << exprTypeInfo.intVal << endl;
		 printf("___Adding %s to symbol table\n", $3);
		 bool success = scopeStack.top().addEntry
				(SYMBOL_TABLE_ENTRY(lexeme,
									 exprTypeInfo));
		 if (! success) 
		 {
		   yyerror("Multiply defined identifier");
		   return(0);
		 }
			}
			;
N_PRINT_EXPR    : T_PRINT N_EXPR
		{
			printRule("PRINT_EXPR", "print EXPR");
			$$ = $2;
			if ($$.type == BOOL)
				cout << convertFromBool($$.boolVal);
			else if ($$.type == STR)
			  cout << $$.stringVal;
			else if ($$.type == INT)
			  cout << $$.intVal;
			cout << endl;
			}
			;
N_INPUT_EXPR    : T_INPUT
		{
			printRule("INPUT_EXPR", "input");
		  string inp;
			getline(cin, inp);
			cout << "ur mom" << endl;
			if (inp[0] == '+' || inp[0] == '-' || isdigit(inp[0]))
			{
				cout << "omenga" << endl;
				$$.type = INT;
				$$.intVal = atoi(inp.c_str());
			}
			else
			{
				cout << "yeet" << endl;
				$$.type = STR;
				strcpy($$.stringVal, inp.c_str());
			}
			}
			;
N_EXPR_LIST     : N_EXPR N_EXPR_LIST  
		{
			printRule("EXPR_LIST", "EXPR EXPR_LIST");
			$$ = $2;
			}
		| N_EXPR
			{
			printRule("EXPR_LIST", "EXPR");
		  $$ = $1;
			}
			;
N_BIN_OP	     : N_ARITH_OP
	      {
			printRule("BIN_OP", "ARITH_OP");
			$$ = $1;
			}
			|
			N_LOG_OP
			{
			printRule("BIN_OP", "LOG_OP");
			$$ = $1;
			}
			|
			N_REL_OP
			{
			printRule("BIN_OP", "REL_OP");
			$$ = $1;
			}
			;
N_ARITH_OP	     : T_ADD
		{
			printRule("ARITH_OP", "+");
			$$ = ADD_OP;
			}
		| T_SUB
			{
			printRule("ARITH_OP", "-");
			$$ = SUB_OP;
			}
			| T_MULT
			{
			printRule("ARITH_OP", "*");
			$$ = MULT_OP;
			}
			| T_DIV
			{
			printRule("ARITH_OP", "/");
			$$ = DIV_OP;
			}
			;
N_REL_OP	     : T_LT
	      {
			printRule("REL_OP", "<");
			$$ = LT_OP;
			}	
			| T_GT
			{
			printRule("REL_OP", ">");
			$$ = GT_OP;
			}	
			| T_LE
			{
			printRule("REL_OP", "<=");
			$$ = LE_OP;
			}	
			| T_GE
			{
			printRule("REL_OP", ">=");
			$$ = GE_OP;
			}	
			| T_EQ
			{
			printRule("REL_OP", "=");
			$$ = EQ_OP;
			}	
			| T_NE
			{
			printRule("REL_OP", "/=");
			$$ = NE_OP;
			}
			;	
N_LOG_OP	     : T_AND
	    {
			printRule("LOG_OP", "and");
			$$ = AND_OP;
			}	
			| T_OR
			{
			printRule("LOG_OP", "or");
			$$ = OR_OP;
			}
			;
N_UN_OP	     : T_NOT
	     {
			printRule("UN_OP", "not");
			}
			;
%%

#include "lex.yy.c"
extern FILE *yyin;

bool isIntCompatible(const int theType) 
{
  return((theType == INT) || (theType == INT_OR_STR) ||
	 (theType == INT_OR_BOOL) || 
	 (theType == INT_OR_STR_OR_BOOL));
}

bool isStrCompatible(const int theType) 
{
  return((theType == STR) || (theType == INT_OR_STR) ||
	 (theType == STR_OR_BOOL) || 
	 (theType == INT_OR_STR_OR_BOOL));
}

bool isIntOrStrCompatible(const int theType) 
{
  return(isStrCompatible(theType) || isIntCompatible(theType));
}

void printRule(const char* lhs, const char* rhs) 
{
  printf("%s -> %s\n", lhs, rhs);
  return;
}

void beginScope() {
  scopeStack.push(SYMBOL_TABLE());
  printf("\n___Entering new scope...\n\n");
}

void endScope() {
  scopeStack.pop();
  printf("\n___Exiting scope...\n\n");
}

TYPE_INFO findEntryInAnyScope(const string theName) 
{
  TYPE_INFO info = {UNDEFINED};
  if (scopeStack.empty( )) return(info);
  info = scopeStack.top().findEntry(theName);
  if (info.type != UNDEFINED)
    return(info);
  else { // check in "next higher" scope
	   SYMBOL_TABLE symbolTable = scopeStack.top( );
	   scopeStack.pop( );
	   info = findEntryInAnyScope(theName);
	   scopeStack.push(symbolTable); // restore the stack
	   return(info);
  }
}

void cleanUp() 
{
  if (scopeStack.empty()) 
    return;
  else {
	scopeStack.pop();
	cleanUp();
  }
}

int main(int argc, char** argv)
{
	if (argc < 2) 
	{
		printf("You must specify a file in the command line!\n");
		exit(1);
	}
	yyin = fopen(argv[1], "r");
	do 
	{
		yyparse();
	} while (!feof(yyin));
	cleanUp();
  return 0;
}
