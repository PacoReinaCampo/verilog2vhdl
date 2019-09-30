%{
////////////////////////////////////////////////////////////////////////////////
//                                            __ _      _     _               //
//                                           / _(_)    | |   | |              //
//                __ _ _   _  ___  ___ _ __ | |_ _  ___| | __| |              //
//               / _` | | | |/ _ \/ _ \ '_ \|  _| |/ _ \ |/ _` |              //
//              | (_| | |_| |  __/  __/ | | | | | |  __/ | (_| |              //
//               \__, |\__,_|\___|\___|_| |_|_| |_|\___|_|\__,_|              //
//                  | |                                                       //
//                  |_|                                                       //
//                                                                            //
//                                                                            //
//              Verilog to VHDL                                               //
//              HDL Translator                                                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////

/* Copyright (c) 2016-2017 by the author(s)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * =============================================================================
 * Author(s):
 *   Francisco Javier Reina Campo <frareicam@gmail.com>
 */

#include "verilog2vhdl.h"
void yyerror(char *s);

%}

%token     T_CELLDEFINE
%token     T_DEFINE
%token     T_ELSEDEF
%token     T_ELSIFDEF
%token     T_ENDCELLDEFINE
%token     T_ENDIFDEF
%token     T_IFDEF
%token     T_INCLUDE
%token     T_RESETALL
%token     T_TIMESCALE
%token     T_UNDEF

%token     T_ALWAYS
%token     T_AND
%token     T_ARROW
%token     T_ASSIGN
%token     T_AUTOMATIC
%token     T_AT
%token     T_BEGIN
%token     T_CASE
%token     T_COLON
%token     T_COMMA
%token     T_DEASSIGN
%token     T_DEFAULT
%token     T_DIV
%token     T_DOT
%token     T_ELSE
%token     T_ELSIF
%token     T_END
%token     T_ENDCASE
%token     T_ENDFUNCTION
%token     T_ENDGENERATE
%token     T_ENDMODULE
%token     T_ENDTASK
%token     T_EQ
%token     T_EXP
%token     T_FOR
%token     T_FORCE
%token     T_FOREVER
%token     T_FORK
%token     T_FUNCTION
%token     T_GATE_AND
%token     T_GATE_BUF
%token     T_GATE_NAND
%token     T_GATE_NOR
%token     T_GATE_NOT
%token     T_GATE_OR
%token     T_GATE_XNOR
%token     T_GATE_XOR
%token     T_GE
%token     T_GENERATE
%token     T_GENERIC
%token     T_GENERIC_ID
%token     T_GT
%token     T_IF
%token     T_INITIAL
%token     T_INOUT
%token     T_INPUT
%token     T_INTEGER
%token     T_JOIN
%token     T_LBRACE
%token     T_LBRAKET
%token     T_LE
%token     T_LOGIC_AND
%token     T_LOGIC_EQ
%token     T_LOGIC_NEQ
%token     T_LOGIC_NOT
%token     T_LOGIC_OR
%token     T_LPARENTESIS
%token     T_LS
%token     T_LSHIFT
%token     T_MINUS
%token     T_MOD
%token     T_MODULE
%token     T_MULT
%token     T_NAND
%token     T_NEGEDGE
%token     T_NOR
%token     T_NOT
%token     T_OR
%token     T_OUTPUT
%token     T_PARAMETER
%token     T_PLUS
%token     T_POSEDGE
%token     T_RBRACE
%token     T_RBRAKET
%token     T_REG
%token     T_REPEAT
%token     T_RPARENTESIS
%token     T_RSHIFT
%token     T_SELECT
%token     T_SEMICOLON
%token     T_SIGNED
%token     T_TASK
%token     T_UNIQUE
%token     T_TIME
%token     T_WHILE
%token     T_WIRE
%token     T_XNOR
%token     T_XOR

%token     T_ID
%token     T_SENTENCE

%token     T_NATDIGIT

%token     T_BINDIGIT
%token     T_OCTDIGIT
%token     T_DECDIGIT
%token     T_HEXDIGIT

%token     T_WIDTH_BINDIGIT
%token     T_WIDTH_OCTDIGIT
%token     T_WIDTH_DECDIGIT
%token     T_WIDTH_HEXDIGIT

%token     T_PARAMETER_BINDIGIT
%token     T_PARAMETER_OCTDIGIT
%token     T_PARAMETER_DECDIGIT
%token     T_PARAMETER_HEXDIGIT

%token     T_GENERIC_BINDIGIT
%token     T_GENERIC_OCTDIGIT
%token     T_GENERIC_DECDIGIT
%token     T_GENERIC_HEXDIGIT

%token     N_ALWAYS_ASYNCRONE_SEQUENCE
%token     N_ALWAYS_BODIES_GENERIC
%token     N_ALWAYS_COMBINATIONAL
%token     N_ALWAYS_SEQUENCE
%token     N_ALWAYS_SYNCRONE_SEQUENCE
%token     N_ALWAYS_UNCONDITIONAL
%token     N_ASSIGN
%token     N_ASSIGN_PARAMETER
%token     N_ASSIGN_SIGNAL
%token     N_ASYNCRST_IF
%token     N_CASE
%token     N_COMPACT_ENTITY
%token     N_COMPLEX_IFDEF_MODULE
%token     N_CONCATENATION
%token     N_CONCURRENCE
%token     N_CONSTANT_PROCESS
%token     N_COPY_SIGNAL
%token     N_DEFINE_DIRECTIVE
%token     N_DELAY_TASKCALL
%token     N_DUMMY
%token     N_FULL_ENTITY
%token     N_EXPRESSION_DOT_LIST
%token     N_EXPRESSION_LIST
%token     N_FOR_ACTUALIZATION
%token     N_FOR_CONDITION_GE
%token     N_FOR_CONDITION_GT
%token     N_FOR_CONDITION_LE
%token     N_FOR_CONDITION_LS
%token     N_FOR_INITIALIZATION
%token     N_FOREVER
%token     N_FORK
%token     N_FUNCTION_CALL
%token     N_FUNCTION_DEFINITION
%token     N_IFDEF_CASE
%token     N_IFDEF_MAP
%token     N_IFDEF_MODULE
%token     N_IFDEF_PORT
%token     N_IFDEF_PROJECT
%token     N_INCLUDE_DIRECTIVE
%token     N_INITIAL
%token     N_MAP_LIST
%token     N_NAME
%token     N_NET_ASSIGN
%token     N_NET_ASSIGN_DELAY
%token     N_NET_DELAY_ASSIGN
%token     N_NULL
%token     N_PARENTESIS
%token     N_PORT_MAP
%token     N_PROCEDURAL_TIME_EXPRESSION
%token     N_PROCEDURAL_TIME_GENERIC
%token     N_RANGE
%token     N_REDUCTION_AND
%token     N_REDUCTION_NAND
%token     N_REDUCTION_NOR
%token     N_REDUCTION_OR
%token     N_REDUCTION_XNOR
%token     N_REDUCTION_XOR
%token     N_REPEAT
%token     N_SENSITIVITY_LIST
%token     N_SENSITIVITY_NEGEDGE_LIST
%token     N_SENSITIVITY_POSEDGE_LIST
%token     N_SIGNAL
%token     N_SIGNAL_LIST
%token     N_SIGNAL_WIDTH
%token     N_TASK_CALL
%token     N_TASK_DEFINITION
%token     N_TIMESCALE_DIRECTIVE
%token     N_VARIABLE_ASSIGN
%token     N_VARIABLE_ASSIGN_DELAY
%token     N_VARIABLE_DELAY_ASSIGN
%token     N_VARIABLE_PROCESS
%token     N_WHILE

%left      T_LOGIC_AND
%left      T_LOGIC_OR
%right     T_LOGIC_NOT
%nonassoc  T_LOGIC_NEQ
%nonassoc  T_LOGIC_EQ
%left      T_AND
%left      T_NAND
%left      T_OR
%left      T_NOR
%left      T_XOR
%left      T_XNOR
%nonassoc  T_GE
%nonassoc  T_GT
%nonassoc  T_LE
%nonassoc  T_LS
%nonassoc  T_EQ
%nonassoc  T_LSHIFT
%nonassoc  T_RSHIFT
%right     T_NOT
%left      T_PLUS
%left      T_MINUS
%left      T_DIV
%left      T_EXP
%left      T_MULT
%left      T_MOD
%left      N_UPLUS
%left      N_UMINUS

%%

top
  : project
    { ParseTreeTop = $1; }
  ;

project
  : module_definitions project
    {
      $$ = $1; SetNext($$,$2);
    }
  | common_compiler_directives project
    {
      $$ = $1; SetNext($$,$2);
    }
  | module_definitions
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | common_compiler_directives
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

module_definitions
  : T_MODULE module_entity T_ENDMODULE
    {  /* T_MODULE info1=entity, info2=body */
      $$ = $1; SetInfo1($$,$2);
      SetLine($$,CellLine($1));
      FreeTcell($3);

      SetSig($$,SigListTop); SigListTop = MakeNewSigList();  /* reset signal list */
      SetCmp($$,ComponentListTop); ComponentListTop = MakeNewComponentList();  /* reset type list */
      /* reset comment list ... unnecessary (common to all modules) */
      /* reset line list ... unnecessary (common to all modules) */
    }
  | T_MODULE module_entity module_items_list T_ENDMODULE
    {  /* T_MODULE info1=entity, info2=body */
      $$ = $1; SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);

      SetSig($$,SigListTop); SigListTop = MakeNewSigList();  /* reset signal list */
      SetCmp($$,ComponentListTop); ComponentListTop = MakeNewComponentList();  /* reset type list */
      /* reset comment list ... unnecessary (common to all modules) */
      /* reset line list ... unnecessary (common to all modules) */
    }
  ;

module_entity
  : T_ID T_LPARENTESIS port_names_top T_RPARENTESIS T_SEMICOLON
    {  /* N_FULL_ENTITY info0=name, info1=list */
      $$ = MallocTcell(N_FULL_ENTITY,(char *)NULL,CellLine($5)); SetInfo0($$,$1); SetInfo1($$,$3);
      FreeTcell($2); FreeTcell($4); FreeTcell($5);
    }
  | T_ID T_LPARENTESIS T_RPARENTESIS T_SEMICOLON
    {  /* N_FULL_ENTITY info0=name, info1=list */
      $$ = MallocTcell(N_FULL_ENTITY,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetInfo1($$,NULLCELL);
      FreeTcell($2); FreeTcell($3); FreeTcell($4);
    }
  | T_ID T_SEMICOLON
    {  /* N_FULL_ENTITY info0=name, info1=list */
      $$ = MallocTcell(N_FULL_ENTITY,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetInfo1($$,NULLCELL);
      FreeTcell($2);
    }
  | T_ID T_GENERIC T_LPARENTESIS compact_data_type_declarations_list T_RPARENTESIS T_LPARENTESIS compact_data_type_declarations_list T_RPARENTESIS T_SEMICOLON
    {  /* N_COMPACT_ENTITY info0=name, info1=list(generic), info2=list(port) */
      $$ = MallocTcell(N_COMPACT_ENTITY,(char *)NULL,CellLine($5)); SetInfo0($$,$1); SetInfo1($$,$4); SetInfo2($$,$7);
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($6); FreeTcell($8); FreeTcell($9);
    }
  | T_ID T_LPARENTESIS compact_data_type_declarations_list T_RPARENTESIS T_SEMICOLON
    {  /* N_COMPACT_ENTITY info0=name, info1=list(generic), info2=list(port) */
      $$ = MallocTcell(N_COMPACT_ENTITY,(char *)NULL,CellLine($5)); SetInfo0($$,$1); SetInfo1($$,NULLCELL); SetInfo2($$,$3);
      FreeTcell($2); FreeTcell($4); FreeTcell($5);
    }
  ;

port_names_top
  : T_IFDEF T_ID port_names_top T_ELSEDEF port_names_top T_ENDIFDEF port_names_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PORT);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5); SetNext($$,$7);
    }
  | T_IFDEF T_ID port_names_top T_ELSEDEF port_names_top T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PORT);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5);
    }
  | T_IFDEF T_ID port_names_top T_ELSEDEF T_ENDIFDEF port_names_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PORT);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetNext($$,$6);
    }
  | T_IFDEF T_ID port_names_top T_ELSEDEF T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PORT);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
    }
  | T_IFDEF T_ID T_ELSEDEF port_names_top T_ENDIFDEF port_names_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PORT);
      SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4); SetNext($$,$6);
    }
  | T_IFDEF T_ID T_ELSEDEF port_names_top T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PORT);
      SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4);
    }
  | T_IFDEF T_ID port_names_top T_ENDIFDEF port_names_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PORT)
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetNext($$,$5);
    }
  | T_IFDEF T_ID port_names_top T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PORT)
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
    }
  | port_names port_names_top
    {
      $$ = $1; SetNext($$,$2);
    }
  | port_names
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

port_names
  : T_ID T_COMMA port_names
    {  /* N_EXPRESSION_LIST info0=signal */
      $$ = MallocTcell(N_EXPRESSION_LIST,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetNext($$,$3);
      SetType($1,N_SIGNAL);
      FreeTcell($2);
    }
  | T_ID T_COMMA
    {  /* N_EXPRESSION_LIST info0=signal */
      $$ = MallocTcell(N_EXPRESSION_LIST,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetNext($$,NULLCELL);
      SetType($1,N_SIGNAL);
    }
  | T_ID
    {  /* N_EXPRESSION_LIST info0=signal */
      $$ = MallocTcell(N_EXPRESSION_LIST,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetNext($$,NULLCELL);
      SetType($1,N_SIGNAL);
    }
  ;

module_items_list
  : module_items module_items_list
    {  /* (module_items will already be a list if module_items == declarations) */
      TREECELL *ptr;
      $$ = $1;
      for (ptr = $1; NextCell(ptr) != NULLCELL; ptr = NextCell(ptr))
        ;
      SetNext(ptr,$2);
    }
  | module_items
    {
      $$ = $1;
    }
  ;

module_items
  : full_data_type_declarations_list
    {
      register TCELLPNT  ptr;
      $$ = $1;
      for (ptr = $$; ptr != NULLCELL; ptr = NextCell(ptr)) {
        Boolean  isinp, isout, issig;
        isinp  = isout  = issig  = False;
        switch (CellType(ptr)) {
        case T_INPUT:
          isinp  = True;
          break;
        case T_OUTPUT:
          isout  = True;
          break;
        case T_INOUT:
          isinp  = True;
          isout  = True;
          break;
        case T_REG:
          issig  = True;
          break;
        case T_WIRE:
          issig  = True;
          break;
        }
        //if (CellType(ptr) != T_PARAMETER && RegisterSignal(SigListTop, ptr, issig, isinp, isout) == False) {
          //fprintfError("Duplicate signal name (VHDL code is case insensitive).", CellLine(ptr));
        //}
      }
    }
  | module_body
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

module_body
  : module_instances
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | primitive_instances
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | generate_blocks
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | fork_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | initial_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | unconditional_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | always_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | forever_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | for_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | if_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | repeat_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | while_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | continuous_assignments
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | procedural_time_controls
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | task_definitions
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | function_definitions
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | define_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | ifdef_module_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | include_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | undef_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

full_data_type_declarations_list
  : full_data_type_declarations full_data_type_declarations_list
    {
      $$ = $1; SetNext($$,$2);
    }
  | full_data_type_declarations
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

compact_data_type_declarations_list
  : compact_data_type_declarations compact_data_type_declarations_list
    {
      $$ = $1; SetNext($$,$2);
    }
  | compact_data_type_declarations
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

full_data_type_declarations
  : port_declarations
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | net_data_types
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | variable_data_types
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | parameter_data_types
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

compact_data_type_declarations
  : compact_port_declarations
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | compact_parameter_data_types
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

port_declarations
  : T_INPUT port_names T_SEMICOLON
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_INPUT range port_names T_SEMICOLON
    {  /* T_INPUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INPUT port_names range T_SEMICOLON
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INPUT range port_names range T_SEMICOLON
    {  /* T_INPUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INPUT T_INTEGER port_names T_SEMICOLON
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INPUT T_INTEGER range port_names T_SEMICOLON
    {  /* T_INPUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INPUT T_INTEGER port_names range T_SEMICOLON
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INPUT T_INTEGER range port_names range T_SEMICOLON
    {  /* T_INPUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_INPUT T_WIRE port_names T_SEMICOLON
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INPUT T_WIRE range port_names T_SEMICOLON
    {  /* T_INPUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INPUT T_WIRE port_names range T_SEMICOLON
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INPUT T_WIRE range port_names range T_SEMICOLON
    {  /* T_INPUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_OUTPUT port_names T_SEMICOLON
    {  /* T_OUTPUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_OUTPUT range port_names T_SEMICOLON
    {  /* T_OUTPUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_OUTPUT port_names range T_SEMICOLON
    {  /* T_OUTPUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_OUTPUT range port_names range T_SEMICOLON
    {  /* T_OUTPUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_OUTPUT T_WIRE port_names T_SEMICOLON
    {  /* T_WIRE info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_OUTPUT T_WIRE range port_names T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_OUTPUT T_WIRE port_names range T_SEMICOLON
    {  /* T_WIRE info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_OUTPUT T_WIRE range port_names range T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_OUTPUT T_REG port_names T_SEMICOLON
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_OUTPUT T_REG range port_names T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_OUTPUT T_REG port_names range T_SEMICOLON
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_OUTPUT T_REG range port_names range T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_INOUT port_names T_SEMICOLON
    {  /* T_INOUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_INOUT range port_names T_SEMICOLON
    {  /* T_INOUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INOUT port_names range T_SEMICOLON
    {  /* T_INOUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INOUT range port_names range T_SEMICOLON
    {  /* T_INOUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  ;

compact_port_declarations
  : T_INPUT port_names
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_INPUT range port_names
    {  /* T_INPUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_INPUT port_names range T_COMMA
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INPUT range port_names range T_COMMA
    {  /* T_INPUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INPUT T_INTEGER port_names
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_INPUT T_INTEGER range port_names
    {  /* T_INPUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_INPUT T_INTEGER port_names range T_COMMA
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INPUT T_INTEGER range port_names range T_COMMA
    {  /* T_INPUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_INPUT T_WIRE port_names
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_INPUT T_WIRE range port_names
    {  /* T_INPUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_INPUT T_WIRE port_names range T_COMMA
    {  /* T_INPUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INPUT T_WIRE range port_names range T_COMMA
    {  /* T_INPUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_OUTPUT port_names
    {  /* T_OUTPUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_OUTPUT range port_names
    {  /* T_OUTPUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_OUTPUT port_names range T_COMMA
    {  /* T_OUTPUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_OUTPUT port_names range
    {  /* T_OUTPUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
    }
  | T_OUTPUT range port_names range T_COMMA
    {  /* T_OUTPUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_OUTPUT T_WIRE port_names
    {  /* T_WIRE info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_OUTPUT T_WIRE range port_names
    {  /* T_WIRE info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_OUTPUT T_WIRE port_names range T_COMMA
    {  /* T_WIRE info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_OUTPUT T_WIRE range port_names range T_COMMA
    {  /* T_WIRE info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_OUTPUT T_REG port_names
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_OUTPUT T_REG range port_names
    {  /* T_REG info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_OUTPUT T_REG port_names range T_COMMA
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_OUTPUT T_REG range port_names range T_COMMA
    {  /* T_REG info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_INOUT port_names
    {  /* T_INOUT info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_INOUT range port_names
    {  /* T_INOUT info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
    }
  | T_INOUT port_names range T_COMMA
    {  /* T_INOUT info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INOUT range port_names range T_COMMA
    {  /* T_INOUT info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  ;

net_data_types
  : T_WIRE port_names T_SEMICOLON
    {  /* T_WIRE info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_WIRE range port_names T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_WIRE port_names range T_SEMICOLON
    {  /* T_WIRE info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_WIRE range port_names range T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_WIRE port_names T_EQ expression_list T_SEMICOLON
    {  /* T_WIRE info0=range(N_NULL), info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,$4);
      SetLine($$,CellLine($5));
      ChkEvalOutput($4, SigListTop);
      FreeTcell($3); FreeTcell($5);
    }
  | T_WIRE range port_names T_EQ expression_list T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,$5);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_WIRE port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_WIRE info0=range(N_NULL), info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3); SetInfo3($$,$5);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_WIRE range port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,$6);
      SetLine($$,CellLine($7));
      ChkEvalOutput($6, SigListTop);
      FreeTcell($5); FreeTcell($7);
    }
  | T_WIRE T_SIGNED port_names T_EQ expression_list T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,$5);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_WIRE T_SIGNED range port_names T_EQ expression_list T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL); SetInfo3($$,$6);
      SetLine($$,CellLine($7));
      ChkEvalOutput($6, SigListTop);
      FreeTcell($5); FreeTcell($7);
    }
  | T_WIRE T_SIGNED port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,$6);
      SetLine($$,CellLine($7));
      ChkEvalOutput($6, SigListTop);
      FreeTcell($5); FreeTcell($7);
    }
  | T_WIRE T_SIGNED range port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_WIRE info0=range, info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5); SetInfo3($$,$7);
      SetLine($$,CellLine($8));
      ChkEvalOutput($7, SigListTop);
      FreeTcell($6); FreeTcell($8);
    }
  ;

variable_data_types
  : T_REG port_names T_SEMICOLON
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_REG range port_names T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_REG port_names range T_SEMICOLON
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_REG range port_names range T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_REG port_names T_EQ expression_list T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,$4);
      SetLine($$,CellLine($5));
      ChkEvalOutput($4, SigListTop);
      FreeTcell($3); FreeTcell($5);
    }
  | T_REG range port_names T_EQ expression_list T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,$5);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_REG port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3); SetInfo3($$,$5);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_REG range port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_CONCURRENCE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,$6);
      SetLine($$,CellLine($7));
      ChkEvalOutput($6, SigListTop);
      FreeTcell($5); FreeTcell($7);
    }
  | T_REG T_SIGNED port_names T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_REG T_SIGNED range port_names T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_REG T_SIGNED port_names range T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_REG T_SIGNED range port_names range T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_REG range port_names range T_COMMA port_names T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,$6);
      SetLine($$,CellLine($1));
      FreeTcell($7);
    }
  | T_INTEGER port_names T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_INTEGER port_names T_EQ expression T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INTEGER range port_names T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INTEGER range port_names T_EQ expression T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_INTEGER port_names range T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INTEGER port_names range T_EQ expression T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3); SetInfo3($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($6);
    }
  | T_INTEGER range port_names range T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INTEGER range port_names range T_EQ expression T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,$6);
      SetLine($$,CellLine($1));
      FreeTcell($7);
    }
  ;

parameter_data_types
  : T_PARAMETER parameter_assign_list T_SEMICOLON
    {  /* T_PARAMETER info0=range(N_NULL), info1=parameter */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_PARAMETER range parameter_assign_list T_SEMICOLON
    {  /* T_PARAMETER info0=range, info1=parameter */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  ;

compact_parameter_data_types
  : T_PARAMETER parameter_assign_list
    {  /* T_PARAMETER info0=range(N_NULL), info1=parameter */
      $$ = $1; SetInfo0($$,NULLCELL); SetInfo1($$,$2);
      SetLine($$,CellLine($1));
    }
  | T_PARAMETER range parameter_assign_list
    {  /* T_PARAMETER info0=range, info1=parameter */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3);
      SetLine($$,CellLine($1));
    }
  ;

parameter_assign_list
  : signal_name_list T_EQ expression T_COMMA parameter_assign_list
    {  /* N_ASSIGN_PARAMETER, info0=name, info1=expression */
      $$ = MallocTcell(N_ASSIGN_PARAMETER,(char *)NULL,CellLine($5)); SetInfo0($$,$1); SetInfo1($$,$3); SetNext($$,$5);
      FreeTcell($2); FreeTcell($4);
    }
  | signal_name_list T_EQ expression T_COMMA
    {  /* N_ASSIGN_PARAMETER, info0=name, info1=expression */
      $$ = MallocTcell(N_ASSIGN_PARAMETER,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetInfo1($$,$3); SetNext($$,NULLCELL);
      FreeTcell($2); FreeTcell($4);
    }
  | signal_name_list T_EQ expression
    {  /* N_ASSIGN_PARAMETER, info0=name, info1=expression */
      $$ = MallocTcell(N_ASSIGN_PARAMETER,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetInfo1($$,$3); SetNext($$,NULLCELL);
      FreeTcell($2);
    }
  ;

range
  : T_LBRAKET expression T_COLON expression T_RBRAKET
    {  /* N_RANGE info0=from, info1=to */
      $$ = $1; SetType($$,N_RANGE); SetInfo0($$,$2); SetInfo1($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($5);
    }
  | T_LBRAKET expression T_COLON expression T_RBRAKET T_LBRAKET expression T_COLON expression T_RBRAKET
    {  /* N_RANGE info0=from, info1=to, info2=from, info3=to */
      $$ = $1; SetType($$,N_RANGE); SetInfo0($$,$2); SetInfo1($$,$4); SetInfo0($$,$7); SetInfo1($$,$9);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($5); FreeTcell($6); FreeTcell($8); FreeTcell($10);
    }
  | T_LBRAKET expression T_COLON expression T_RBRAKET T_LBRAKET expression T_COLON expression T_RBRAKET T_LBRAKET expression T_COLON expression T_RBRAKET
    {  /* N_RANGE info0=from, info1=to, info2=from, info3=to */
      $$ = $1; SetType($$,N_RANGE); SetInfo0($$,$2); SetInfo1($$,$4); SetInfo0($$,$7); SetInfo1($$,$9); SetInfo1($$,$12); SetInfo1($$,$14);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($5); FreeTcell($6); FreeTcell($8); FreeTcell($10); FreeTcell($11); FreeTcell($13); FreeTcell($15);
    }
  | T_LBRAKET expression T_RBRAKET
    {  /* N_RANGE info0=from, info1=to(N_NULL) */
      $$ = $1; SetType($$,N_RANGE); SetInfo0($$,$2); SetInfo1($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  ;

call_delay_function_or_task
  : T_GENERIC number literal
    {  /* N_DELAY_TASKCALL info0=expression, info1=function_or_task */
      $$ = $1; SetType($$,N_DELAY_TASKCALL); SetInfo0($$,$2); SetInfo1($$,$3);
    }
  ;

call_function_or_task
  : signal_name_list T_LPARENTESIS expression_list T_RPARENTESIS
    {
      $$ = $1; SetInfo0($$,$3);
      SetLine($$,CellLine($4));
      FreeTcell($2); FreeTcell($4);
    }
  | signal_name_list T_LPARENTESIS T_RPARENTESIS
    {
      $$ = $1; SetInfo0($$,NULLCELL);
      SetLine($$,CellLine($3));
      FreeTcell($2); FreeTcell($3);
    }
  ;

module_instances
  : T_ID T_GENERIC T_LPARENTESIS map_top T_RPARENTESIS T_ID T_LPARENTESIS map_top T_RPARENTESIS T_SEMICOLON
    {  /* N_PORT_MAP info0=module, info1=label, info2=generic, info3=list */
      $$ = $2; SetType($$,N_PORT_MAP); SetInfo0($$,$1); SetInfo1($$,$6); SetInfo2($$,$4); SetInfo3($$,$8);
      SetLine($$,CellLine($1));
      ConvertExplist2Substlist($4);
      RegisterComponent(ComponentListTop, $$);
      FreeTcell($3); FreeTcell($5); FreeTcell($7); FreeTcell($9); FreeTcell($10);
    }
  | T_ID T_GENERIC T_LPARENTESIS expression_list T_RPARENTESIS T_ID T_LPARENTESIS map_top T_RPARENTESIS T_SEMICOLON
    {  /* N_PORT_MAP info0=module, info1=label, info2=generic, info3=list */
      $$ = $2; SetType($$,N_PORT_MAP); SetInfo0($$,$1); SetInfo1($$,$6); SetInfo2($$,$4); SetInfo3($$,$8);
      SetLine($$,CellLine($1));
      ConvertExplist2Substlist($4);
      RegisterComponent(ComponentListTop, $$);
      FreeTcell($3); FreeTcell($5); FreeTcell($7); FreeTcell($9); FreeTcell($10);
    }
  | T_ID T_ID T_LPARENTESIS map_top T_RPARENTESIS T_SEMICOLON
    {  /* N_PORT_MAP info0=module, info1=label, info2=generic(N_NULL), info3=list */
      $$ = $3; SetType($$,N_PORT_MAP); SetInfo0($$,$1); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,$4);
      SetLine($$,CellLine($1));
      RegisterComponent(ComponentListTop, $$);
      FreeTcell($5); FreeTcell($6);
    }
  | T_ID T_ID T_LPARENTESIS T_RPARENTESIS T_SEMICOLON
    {  /* N_PORT_MAP info0=module, info1=label, info2=generic(N_NULL), info3=list(N_NULL) */
      $$ = $3; SetType($$,N_PORT_MAP); SetInfo0($$,$1); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      RegisterComponent(ComponentListTop, $$);
      FreeTcell($4); FreeTcell($5);
    }
  | T_ID T_GENERIC T_LPARENTESIS expression_list T_RPARENTESIS T_ID T_LPARENTESIS expression_list T_RPARENTESIS T_SEMICOLON
    {  /* N_PORT_MAP info0=module, info1=label, info2=generic, info3=list */
      $$ = $2; SetType($$,N_PORT_MAP); SetInfo0($$,$1); SetInfo1($$,$6); SetInfo2($$,$4); SetInfo3($$,$8);
      SetLine($$,CellLine($1));
      ConvertExplist2Substlist($4);
      ConvertExplist2Substlist($8);
      RegisterComponent(ComponentListTop, $$);
      FreeTcell($3); FreeTcell($5); FreeTcell($7); FreeTcell($9); FreeTcell($10);
    }
  | T_ID T_ID T_LPARENTESIS expression_list T_RPARENTESIS T_SEMICOLON
    {  /* N_PORT_MAP info0=module, info1=label, info2=generic(N_NULL), info3=list */
      $$ = $3; SetType($$,N_PORT_MAP); SetInfo0($$,$1); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,$4);
      SetLine($$,CellLine($1));
      ConvertExplist2Substlist($4);
      RegisterComponent(ComponentListTop, $$);
      FreeTcell($5); FreeTcell($6);
    }
  ;

map_top
  : T_IFDEF T_ID map_top T_ELSEDEF map_top T_ENDIFDEF map_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_MAP);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5); SetNext($$,$7);
    }
  | T_IFDEF T_ID map_top T_ELSEDEF map_top T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_MAP);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5);
    }
  | T_IFDEF T_ID map_top T_ELSEDEF T_ENDIFDEF map_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_MAP);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetNext($$,$6);
    }
  | T_IFDEF T_ID map_top T_ELSEDEF T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_MAP);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
    }
  | T_IFDEF T_ID T_ELSEDEF map_top T_ENDIFDEF map_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_MAP);
      SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4); SetNext($$,$6);
    }
  | T_IFDEF T_ID T_ELSEDEF map_top T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_MAP);
      SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4);
    }
  | T_IFDEF T_ID map_top T_ENDIFDEF map_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_MAP)
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetNext($$,$5);
    }
  | T_IFDEF T_ID map_top T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_MAP)
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
    }
  | map_item T_COMMA map_top
    {
      $$ = $1; SetNext($$,$3);
      FreeTcell($2);
    }
  | map_item T_COMMA
    {
      $$ = $1; SetNext($$,NULLCELL);
      FreeTcell($2);
    }
  | map_item
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

map_item
  : T_DOT T_ID T_LPARENTESIS expression T_DOT expression T_RPARENTESIS
    {  /* N_MAP_LIST info0=port, info1=expression, info2=expression */
      $$ = $1; SetType($$,N_MAP_LIST); SetInfo0($$,$2); SetInfo1($$,$4); SetInfo2($$,$6);
      SetLine($$,CellLine($7));
      FreeTcell($3); FreeTcell($7);
    }
  | T_DOT T_ID T_LPARENTESIS expression T_RPARENTESIS
    {  /* N_MAP_LIST info0=port, info1=expression */
      $$ = $1; SetType($$,N_MAP_LIST); SetInfo0($$,$2); SetInfo1($$,$4);
      SetLine($$,CellLine($5));
      FreeTcell($3); FreeTcell($5);
    }
  | T_DOT T_ID T_LPARENTESIS T_RPARENTESIS
    {  /* N_MAP_LIST info0=port, info1=expression */
      $$ = $1; SetType($$,N_MAP_LIST); SetInfo0($$,$2); SetInfo1($$,NULLCELL);
      SetLine($$,CellLine($4));
      FreeTcell($3); FreeTcell($4);
    }
  ;

primitive_instances
  : gate_buf T_GENERIC T_LPARENTESIS expression T_RPARENTESIS T_ID T_LPARENTESIS signal_name T_COMMA signal_name T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression, info2=delay */
      $$ = $1; SetType($$,N_VARIABLE_DELAY_ASSIGN); SetInfo0($$,$8); SetInfo1($$,$10); SetInfo2($$,$4);
      SetLine($$,CellLine($7));
      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($6);
      FreeTcell($7); FreeTcell($9); FreeTcell($11); FreeTcell($12);
    }
  | gate_not T_GENERIC T_LPARENTESIS expression T_RPARENTESIS T_ID T_LPARENTESIS signal_name T_COMMA signal_name T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression, info2=delay */
      $$ = $1; SetType($$,N_VARIABLE_DELAY_ASSIGN); SetInfo0($$,$8); SetInfo1($$,$10); SetInfo2($$,$4);
      SetLine($$,CellLine($7));

      // connect all inputs to gate
      SetInfo1($$,MallocTcell(T_NOT,(char *)NULL,CellLine($12)));  // R-val: append new cell
      SetInfo0(CellInfo1($$),$10);

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($6);
      FreeTcell($7); FreeTcell($9); FreeTcell($11); FreeTcell($12);
    }
  | gate_buf T_LPARENTESIS signal_name T_COMMA signal_name T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression */
      $$ = $1; SetType($$,T_ASSIGN); SetInfo0($$,$3); SetInfo1($$,$5);
      SetLine($$,CellLine($7));
      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($7);
    }
  | gate_not T_LPARENTESIS signal_name T_COMMA signal_name T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression */
      $$ = $1; SetType($$,T_ASSIGN); SetInfo0($$,$3);
      SetLine($$,CellLine($7));

      // connect all inputs to gate
      SetInfo1($$,MallocTcell(T_NOT,(char *)NULL,CellLine($7)));  // R-val: append new cell
      SetInfo0(CellInfo1($$),$5);

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($7);
    }
  | gate_buf T_GENERIC T_LPARENTESIS expression T_RPARENTESIS T_ID T_LPARENTESIS signal_name T_COMMA signal_name T_COMMA expression_list T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression, info2=delay */
      register TCELLPNT  src, dist, nextsrc;
      $$ = $1; SetType($$,N_VARIABLE_ASSIGN_DELAY); SetInfo0($$,$8); SetInfo2($$,$4);
      SetLine($$,CellLine($14));

      // connect all inputs to gate
      SetInfo1($$,MallocTcell(T_AND,(char *)NULL,CellLine($14)));  // R-val: append new cell
      SetInfo0(CellInfo1($$),$10);
      for (src = $12, dist = CellInfo1($$); src != NULLCELL; src = nextsrc) {
        nextsrc  = NextCell(src);
        if (NextCell(src) == NULLCELL) {  // last parameter
          SetInfo1(dist,CellInfo0(src));
          FreeTcell(src);          // (N_SIGLIST)
        }
        else {
          SetInfo1(dist,MallocTcell(T_AND,(char *)NULL,CellLine($14)));  // append new cell
          SetInfo0(CellInfo1(dist),CellInfo0(src));
          dist  = CellInfo1(dist);
          FreeTcell(src);          // (N_SIGLIST)
        }
      }

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($6);
      FreeTcell($7); FreeTcell($9); FreeTcell($11); FreeTcell($13); FreeTcell($14);
    }
  | gate_or T_GENERIC T_LPARENTESIS expression T_RPARENTESIS T_ID T_LPARENTESIS signal_name T_COMMA signal_name T_COMMA expression_list T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression, info2=delay */
      register TCELLPNT  src, dist, nextsrc;
      $$ = $1; SetType($$,N_VARIABLE_ASSIGN_DELAY); SetInfo0($$,$8); SetInfo2($$,$4);
      SetLine($$,CellLine($14));

      // connect all inputs to gate
      SetInfo1($$,MallocTcell(T_OR,(char *)NULL,CellLine($14)));  // R-val: append new cell
      SetInfo0(CellInfo1($$),$10);
      for (src = $12, dist = CellInfo1($$); src != NULLCELL; src = nextsrc) {
        nextsrc  = NextCell(src);
        if (NextCell(src) == NULLCELL) {  // last parameter
          SetInfo1(dist,CellInfo0(src));
          FreeTcell(src);          // (N_SIGLIST)
        }
        else {
          SetInfo1(dist,MallocTcell(T_OR,(char *)NULL,CellLine($14)));  // append new cell
          SetInfo0(CellInfo1(dist),CellInfo0(src));
          dist  = CellInfo1(dist);
          FreeTcell(src);          // (N_SIGLIST)
        }
      }

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($6);
      FreeTcell($7); FreeTcell($9); FreeTcell($11); FreeTcell($13); FreeTcell($14);
    }
  | gate_buf T_LPARENTESIS signal_name T_COMMA signal_name T_COMMA expression_list T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression */
      register TCELLPNT  src, dist, nextsrc;
      $$ = $1; SetType($$,T_ASSIGN); SetInfo0($$,$3);
      SetLine($$,CellLine($9));

      // connect all inputs to gate
      SetInfo1($$,MallocTcell(T_AND,(char *)NULL,CellLine($9)));  // R-val: append new cell
      SetInfo0(CellInfo1($$),$5);
      for (src = $7, dist = CellInfo1($$); src != NULLCELL; src = nextsrc) {
        nextsrc  = NextCell(src);
        if (NextCell(src) == NULLCELL) {  // last parameter
          SetInfo1(dist,CellInfo0(src));
          FreeTcell(src);          // (N_SIGLIST)
        }
        else {
          SetInfo1(dist,MallocTcell(T_AND,(char *)NULL,CellLine($9)));  // append new cell
          SetInfo0(CellInfo1(dist),CellInfo0(src));
          dist  = CellInfo1(dist);
          FreeTcell(src);          // (N_SIGLIST)
        }
      }

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($8); FreeTcell($9);
    }
  | gate_and T_LPARENTESIS signal_name T_COMMA signal_name T_COMMA expression_list T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression */
      register TCELLPNT  src, dist, nextsrc;
      $$ = $1; SetType($$,T_ASSIGN); SetInfo0($$,$3);
      SetLine($$,CellLine($9));

      // connect all inputs to gate
      SetInfo1($$,MallocTcell(T_AND,(char *)NULL,CellLine($9)));  // R-val: append new cell
      SetInfo0(CellInfo1($$),$5);
      for (src = $7, dist = CellInfo1($$); src != NULLCELL; src = nextsrc) {
        nextsrc  = NextCell(src);
        if (NextCell(src) == NULLCELL) {  // last parameter
          SetInfo1(dist,CellInfo0(src));
          FreeTcell(src);          // (N_SIGLIST)
        }
        else {
          SetInfo1(dist,MallocTcell(T_AND,(char *)NULL,CellLine($9)));  // append new cell
          SetInfo0(CellInfo1(dist),CellInfo0(src));
          dist  = CellInfo1(dist);
          FreeTcell(src);          // (N_SIGLIST)
        }
      }

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($8); FreeTcell($9);
    }
  | gate_or T_LPARENTESIS signal_name T_COMMA signal_name T_COMMA expression_list T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression */
      register TCELLPNT  src, dist, nextsrc;
      $$ = $1; SetType($$,T_ASSIGN); SetInfo0($$,$3);
      SetLine($$,CellLine($9));

      // connect all inputs to gate
      SetInfo1($$,MallocTcell(T_OR,(char *)NULL,CellLine($9)));  // R-val: append new cell
      SetInfo0(CellInfo1($$),$5);
      for (src = $7, dist = CellInfo1($$); src != NULLCELL; src = nextsrc) {
        nextsrc  = NextCell(src);
        if (NextCell(src) == NULLCELL) {  // last parameter
          SetInfo1(dist,CellInfo0(src));
          FreeTcell(src);          // (N_SIGLIST)
        }
        else {
          SetInfo1(dist,MallocTcell(T_OR,(char *)NULL,CellLine($9)));  // append new cell
          SetInfo0(CellInfo1(dist),CellInfo0(src));
          dist  = CellInfo1(dist);
          FreeTcell(src);          // (N_SIGLIST)
        }
      }

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($8); FreeTcell($9);
    }
  | gate_xor T_LPARENTESIS signal_name T_COMMA signal_name T_COMMA expression_list T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression */
      register TCELLPNT  src, dist, nextsrc;
      $$ = $1; SetType($$,T_ASSIGN); SetInfo0($$,$3);
      SetLine($$,CellLine($9));

      // connect all inputs to gate
      SetInfo1($$,MallocTcell(T_XOR,(char *)NULL,CellLine($9)));  // R-val: append new cell
      SetInfo0(CellInfo1($$),$5);
      for (src = $7, dist = CellInfo1($$); src != NULLCELL; src = nextsrc) {
        nextsrc  = NextCell(src);
        if (NextCell(src) == NULLCELL) {  // last parameter
          SetInfo1(dist,CellInfo0(src));
          FreeTcell(src);          // (N_SIGLIST)
        }
        else {
          SetInfo1(dist,MallocTcell(T_XOR,(char *)NULL,CellLine($9)));  // append new cell
          SetInfo0(CellInfo1(dist),CellInfo0(src));
          dist  = CellInfo1(dist);
          FreeTcell(src);          // (N_SIGLIST)
        }
      }

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($8); FreeTcell($9);
    }
  | gate_nand T_LPARENTESIS signal_name T_COMMA signal_name T_COMMA expression_list T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression */
      register TCELLPNT  src, dist, nextsrc;
      $$ = $1; SetType($$,T_ASSIGN); SetInfo0($$,$3);
      SetLine($$,CellLine($9));

      // connect all inputs to gate
      // R-val: append new cell
      SetInfo1($$,MallocTcell(T_NOT,(char *)NULL,CellLine($9)));
      SetInfo0(CellInfo1($$),MallocTcell(N_PARENTESIS,(char *)NULL,CellLine($9)));
      SetInfo0(CellInfo0(CellInfo1($$)),MallocTcell(T_AND,(char *)NULL,CellLine($9)));

      SetInfo0(CellInfo0(CellInfo0(CellInfo1($$))),$5);
      for (src = $7, dist = CellInfo0(CellInfo0(CellInfo1($$))); src != NULLCELL; src = nextsrc) {
        nextsrc  = NextCell(src);
        if (NextCell(src) == NULLCELL) {  // last parameter
          SetInfo1(dist,CellInfo0(src));
          FreeTcell(src);          // (N_SIGLIST)
        }
        else {
          SetInfo1(dist,MallocTcell(T_AND,(char *)NULL,CellLine($9)));  // append new cell
          SetInfo0(CellInfo1(dist),CellInfo0(src));
          dist  = CellInfo1(dist);
          FreeTcell(src);          // (N_SIGLIST)
        }
      }

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($8); FreeTcell($9);
    }
  | gate_nor T_LPARENTESIS signal_name T_COMMA signal_name T_COMMA expression_list T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression */
      register TCELLPNT  src, dist, nextsrc;
      $$ = $1; SetType($$,T_ASSIGN); SetInfo0($$,$3);
      SetLine($$,CellLine($9));

      // connect all inputs to gate
      // R-val: append new cell
      SetInfo1($$,MallocTcell(T_NOT,(char *)NULL,CellLine($9)));
      SetInfo0(CellInfo1($$),MallocTcell(N_PARENTESIS,(char *)NULL,CellLine($9)));
      SetInfo0(CellInfo0(CellInfo1($$)),MallocTcell(T_OR,(char *)NULL,CellLine($9)));

      SetInfo0(CellInfo0(CellInfo0(CellInfo1($$))),$5);
      for (src = $7, dist = CellInfo0(CellInfo0(CellInfo1($$))); src != NULLCELL; src = nextsrc) {
        nextsrc  = NextCell(src);
        if (NextCell(src) == NULLCELL) {  // last parameter
          SetInfo1(dist,CellInfo0(src));
          FreeTcell(src);          // (N_SIGLIST)
        }
        else {
          SetInfo1(dist,MallocTcell(T_OR,(char *)NULL,CellLine($9)));  // append new cell
          SetInfo0(CellInfo1(dist),CellInfo0(src));
          dist  = CellInfo1(dist);
          FreeTcell(src);          // (N_SIGLIST)
        }
      }

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($8); FreeTcell($9);
    }
  | gate_xnor T_LPARENTESIS signal_name T_COMMA signal_name T_COMMA expression_list T_RPARENTESIS T_SEMICOLON
    {  /* T_ASSIGN info0=signal, info1=expression */
      register TCELLPNT  src, dist, nextsrc;
      $$ = $1; SetType($$,T_ASSIGN); SetInfo0($$,$3);
      SetLine($$,CellLine($9));

      // connect all inputs to gate
      // R-val: append new cell
      SetInfo1($$,MallocTcell(T_NOT,(char *)NULL,CellLine($9)));
      SetInfo0(CellInfo1($$),MallocTcell(N_PARENTESIS,(char *)NULL,CellLine($9)));
      SetInfo0(CellInfo0(CellInfo1($$)),MallocTcell(T_XOR,(char *)NULL,CellLine($9)));

      SetInfo0(CellInfo0(CellInfo0(CellInfo1($$))),$5);
      for (src = $7, dist = CellInfo0(CellInfo0(CellInfo1($$))); src != NULLCELL; src = nextsrc) {
        nextsrc  = NextCell(src);
        if (NextCell(src) == NULLCELL) {  // last parameter
          SetInfo1(dist,CellInfo0(src));
          FreeTcell(src);          // (N_SIGLIST)
        }
        else {
          SetInfo1(dist,MallocTcell(T_XOR,(char *)NULL,CellLine($9)));  // append new cell
          SetInfo0(CellInfo1(dist),CellInfo0(src));
          dist  = CellInfo1(dist);
          FreeTcell(src);          // (N_SIGLIST)
        }
      }

      ChkEvalOutput(CellInfo1($$), SigListTop);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($8); FreeTcell($9);
    }
  ;

gate_buf
  : T_GATE_BUF T_ID
    {
      $$  = $1;
      FreeTcell($2);
    }
  | T_GATE_BUF
    {
      $$  = $1;
    }
  ;

gate_not
  : T_GATE_NOT T_ID
    {
      $$  = $1;
      FreeTcell($2);
    }
  | T_GATE_NOT
    {
      $$  = $1;
    }
  ;

gate_and
  : T_GATE_AND T_ID
    {
      $$  = $1;
      FreeTcell($2);
    }
  | T_GATE_AND
    {
      $$  = $1;
    }
  ;

gate_or
  : T_GATE_OR T_ID
    {
      $$  = $1;
      FreeTcell($2);
    }
  | T_GATE_OR
    {
      $$  = $1;
    }
  ;

gate_xor
  : T_GATE_XOR T_ID
    {
      $$  = $1;
      FreeTcell($2);
    }
  | T_GATE_XOR
    {
      $$  = $1;
    }
  ;

gate_nand
  : T_GATE_NAND T_ID
    {
      $$  = $1;
      FreeTcell($2);
    }
  | T_GATE_NAND
    {
      $$  = $1;
    }
  ;

gate_nor
  : T_GATE_NOR T_ID
    {
      $$  = $1;
      FreeTcell($2);
    }
  | T_GATE_NOR
    {
      $$  = $1;
    }
  ;

gate_xnor
  : T_GATE_XNOR T_ID
    {
      $$  = $1;
      FreeTcell($2);
    }
  | T_GATE_XNOR
    {
      $$  = $1;
    }
  ;

generate_blocks
  : T_GENERATE always_body T_ENDGENERATE
    {  /* T_GENERATE info0=body */
      $$ = $1; SetInfo0($$,$2);
      SetLine($$,CellLine($1));
    }

  | T_GENERATE full_data_type_declarations_list always_body T_ENDGENERATE
    {  /* T_GENERATE info0=body */
      $$ = $1; SetInfo0($$,$3);
      SetLine($$,CellLine($1));
    }
  | T_GENERATE always_bodies T_ENDGENERATE
    {  /* T_GENERATE info0=body */
      $$ = $1; SetInfo0($$,$2);
      SetLine($$,CellLine($1));
    }
  | T_GENERATE full_data_type_declarations_list always_bodies T_ENDGENERATE
    {  /* T_GENERATE info0=body */
      $$ = $1; SetInfo0($$,$3);
      SetLine($$,CellLine($1));
    }
  ;

fork_part
  : T_FORK always_bodies_generic T_JOIN
    {  /* N_FORK info0=body */
      $$ = $1; SetType($$,N_FORK); SetInfo0($$,$2);
      SetLine($$,CellLine($1));
    }
  ;

initial_part
  : T_INITIAL always_body_generic
    {  /* N_INITIAL info0=body */
      $$ = $1; SetType($$,N_INITIAL); SetInfo0($$,$2);
      SetLine($$,CellLine($1));
    }
  ;

unconditional_part
  : T_ALWAYS T_AT T_LPARENTESIS T_MULT T_RPARENTESIS always_body_generic
    {  /* N_ALWAYS_UNCONDITIONAL info0=body */
      $$ = $1; SetType($$,N_ALWAYS_UNCONDITIONAL); SetInfo0($$,$6);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5);
    }
  | T_ALWAYS T_AT T_MULT always_body_generic
    {  /* N_ALWAYS_UNCONDITIONAL info0=body */
      $$ = $1; SetType($$,N_ALWAYS_UNCONDITIONAL); SetInfo0($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($2);
    }
  | T_ALWAYS T_BEGIN always_bodies T_END
    {  /* N_ALWAYS_UNCONDITIONAL info0=body */
      $$ = $1; SetType($$,N_ALWAYS_UNCONDITIONAL); SetInfo0($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($4);
    }
  | T_ALWAYS T_BEGIN always_body T_END
    {  /* N_ALWAYS_UNCONDITIONAL info0=body */
      $$ = $1; SetType($$,N_ALWAYS_UNCONDITIONAL); SetInfo0($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($4);
    }
  ;

always_part
  : T_ALWAYS T_AT T_LPARENTESIS sensitivity_list_combinational T_RPARENTESIS T_BEGIN T_COLON T_ID variable_process_types_list always_bodies T_END
    {  /* N_ALWAYS_COMBINATIONAL info0=sensitivity, info1=body */
      $$ = $1; SetType($$,N_ALWAYS_COMBINATIONAL); SetInfo0($$,$4); SetInfo1($$,$10); SetInfo3($$,$9);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($6); FreeTcell($11);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_list_combinational T_RPARENTESIS T_BEGIN T_COLON T_ID variable_process_types_list always_body T_END
    {  /* N_ALWAYS_COMBINATIONAL info0=sensitivity, info1=body */
      $$ = $1; SetType($$,N_ALWAYS_COMBINATIONAL); SetInfo0($$,$4); SetInfo1($$,$10); SetInfo3($$,$9);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($6); FreeTcell($11);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_list_combinational T_RPARENTESIS T_COLON T_ID variable_process_types_list always_body
    {  /* N_ALWAYS_COMBINATIONAL info0=sensitivity, info1=body */
      $$ = $1; SetType($$,N_ALWAYS_COMBINATIONAL); SetInfo0($$,$4); SetInfo1($$,$9); SetInfo3($$,$8);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_list_combinational T_RPARENTESIS always_body_generic
    {  /* N_ALWAYS_COMBINATIONAL info0=sensitivity, info1=body */
      $$ = $1; SetType($$,N_ALWAYS_COMBINATIONAL); SetInfo0($$,$4); SetInfo1($$,$6);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_item_sequential T_RPARENTESIS always_body_generic
    {  /* N_ALWAYS_SYNCRONE_SEQUENCE info0=sensitivity, info1=body */
      $$ = $1; SetType($$,N_ALWAYS_SYNCRONE_SEQUENCE); SetInfo0($$,$4); SetInfo1($$,$6);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_item_sequential T_GATE_OR sensitivity_item_sequential T_RPARENTESIS T_BEGIN T_COLON T_ID variable_process_types_list always_bodies T_END
    {  /* N_ALWAYS_ASYNCRONE_SEQUENCE info0=sensitivity, info1=body, info2=sensitivity(reset) */
      $$ = $1; SetType($$,N_ALWAYS_ASYNCRONE_SEQUENCE); SetInfo1($$,$12); SetInfo3($$,$11);
      if (UsedSignalinIfCond($12,CellInfo0($4)) == False && UsedSignalinIfCond($12,CellInfo0($6)) == True) {
        SetInfo0($$,$4);  // clk
        SetInfo2($$,$6);  // reset
      }
      else if (UsedSignalinIfCond($12,CellInfo0($4)) == True && UsedSignalinIfCond($12,CellInfo0($6)) == False) {
        SetInfo0($$,$6);  // clk
        SetInfo2($$,$4);  // reset
      }
      else {
        yyerror("$Can not determine clock signal.");
      }

      if (CellType($12) == T_IF) {
        CellType($12) = N_ASYNCRST_IF;
        if (CellInfo2($12) != NULLCELL && CellType(CellInfo2($12)) == T_ELSIF)
          CellType(CellInfo2($12)) = T_IF;
      }
      else {
        yyerror("$Unsupported type of description for async reset.");
      }

      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($7); FreeTcell($8); FreeTcell($13);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_item_sequential T_GATE_OR sensitivity_item_sequential T_RPARENTESIS T_BEGIN T_COLON T_ID variable_process_types_list always_body T_END
    {  /* N_ALWAYS_ASYNCRONE_SEQUENCE info0=sensitivity, info1=body, info2=sensitivity(reset) */
      $$ = $1; SetType($$,N_ALWAYS_ASYNCRONE_SEQUENCE); SetInfo1($$,$12); SetInfo3($$,$11);
      if (UsedSignalinIfCond($12,CellInfo0($4)) == False && UsedSignalinIfCond($12,CellInfo0($6)) == True) {
        SetInfo0($$,$4);  // clk
        SetInfo2($$,$6);  // reset
      }
      else if (UsedSignalinIfCond($12,CellInfo0($4)) == True && UsedSignalinIfCond($12,CellInfo0($6)) == False) {
        SetInfo0($$,$6);  // clk
        SetInfo2($$,$4);  // reset
      }
      else {
        yyerror("$Can not determine clock signal.");
      }

      if (CellType($12) == T_IF) {
        CellType($12) = N_ASYNCRST_IF;
        if (CellInfo2($12) != NULLCELL && CellType(CellInfo2($12)) == T_ELSIF)
          CellType(CellInfo2($12)) = T_IF;
      }
      else {
        yyerror("$Unsupported type of description for async reset.");
      }

      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($7); FreeTcell($8); FreeTcell($13);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_item_sequential T_GATE_OR sensitivity_item_sequential T_RPARENTESIS T_COLON T_ID variable_process_types_list always_body
    {  /* N_ALWAYS_ASYNCRONE_SEQUENCE info0=sensitivity, info1=body, info2=sensitivity(reset) */
      $$ = $1; SetType($$,N_ALWAYS_ASYNCRONE_SEQUENCE); SetInfo1($$,$11); SetInfo3($$,$10);
      if (UsedSignalinIfCond($11,CellInfo0($4)) == False && UsedSignalinIfCond($11,CellInfo0($6)) == True) {
        SetInfo0($$,$4);  // clk
        SetInfo2($$,$6);  // reset
      }
      else if (UsedSignalinIfCond($11,CellInfo0($4)) == True && UsedSignalinIfCond($11,CellInfo0($6)) == False) {
        SetInfo0($$,$6);  // clk
        SetInfo2($$,$4);  // reset
      }
      else {
        yyerror("$Can not determine clock signal.");
      }

      if (CellType($11) == T_IF) {
        CellType($11) = N_ASYNCRST_IF;
        if (CellInfo2($11) != NULLCELL && CellType(CellInfo2($11)) == T_ELSIF)
          CellType(CellInfo2($11)) = T_IF;
      }
      else {
        yyerror("$Unsupported type of description for async reset.");
      }

      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($7);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_item_sequential T_GATE_OR sensitivity_item_sequential T_RPARENTESIS always_body_generic
    {  /* N_ALWAYS_ASYNCRONE_SEQUENCE info0=sensitivity, info1=body, info2=sensitivity(reset) */
      $$ = $1; SetType($$,N_ALWAYS_ASYNCRONE_SEQUENCE); SetInfo1($$,$8);
      if (CellType($8) == T_IF) {
        if (UsedSignalinIfCond($8,CellInfo0($4)) == False && UsedSignalinIfCond($8,CellInfo0($6)) == True) {
          SetInfo0($$,$4);  // clk
          SetInfo2($$,$6);  // reset
        }
        else if (UsedSignalinIfCond($8,CellInfo0($4)) == True && UsedSignalinIfCond($8,CellInfo0($6)) == False) {
          SetInfo0($$,$6);  // clk
          SetInfo2($$,$4);  // reset
        }
        else {
          SetInfo0($$,$4);   // clk
          SetInfo2($$,$6);  // reset
        }
  
        if (CellType($8) == T_IF) {
          CellType($8) = N_ASYNCRST_IF;
          if (CellInfo2($8) != NULLCELL && CellType(CellInfo2($8)) == T_ELSIF)
            CellType(CellInfo2($8)) = T_IF;
        }
        else {
          yyerror("$Unsupported type of description for async reset.");
        }
      }
      else {
        SetInfo0($$,$4);   // clk
        SetInfo2($$,$6);  // reset
      }

      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($7);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_item_sequential T_COMMA sensitivity_item_sequential T_RPARENTESIS T_BEGIN T_COLON T_ID variable_process_types_list always_bodies T_END
    {  /* N_ALWAYS_ASYNCRONE_SEQUENCE info0=sensitivity, info1=body, info2=sensitivity(reset) */
      $$ = $1; SetType($$,N_ALWAYS_ASYNCRONE_SEQUENCE); SetInfo1($$,$12); SetInfo3($$,$11);
      if (UsedSignalinIfCond($12,CellInfo0($4)) == False && UsedSignalinIfCond($12,CellInfo0($6)) == True) {
        SetInfo0($$,$4);  // clk
        SetInfo2($$,$6);  // reset
      }
      else if (UsedSignalinIfCond($12,CellInfo0($4)) == True && UsedSignalinIfCond($12,CellInfo0($6)) == False) {
        SetInfo0($$,$6);  // clk
        SetInfo2($$,$4);  // reset
      }
      else {
        yyerror("$Can not determine clock signal.");
      }

      if (CellType($12) == T_IF) {
        CellType($12) = N_ASYNCRST_IF;
        if (CellInfo2($12) != NULLCELL && CellType(CellInfo2($12)) == T_ELSIF)
          CellType(CellInfo2($12)) = T_IF;
      }
      else {
        yyerror("$Unsupported type of description for async reset.");
      }

      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($7); FreeTcell($8); FreeTcell($13);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_item_sequential T_COMMA sensitivity_item_sequential T_RPARENTESIS T_BEGIN T_COLON T_ID variable_process_types_list always_body T_END
    {  /* N_ALWAYS_ASYNCRONE_SEQUENCE info0=sensitivity, info1=body, info2=sensitivity(reset) */
      $$ = $1; SetType($$,N_ALWAYS_ASYNCRONE_SEQUENCE); SetInfo1($$,$12); SetInfo3($$,$11);
      if (UsedSignalinIfCond($12,CellInfo0($4)) == False && UsedSignalinIfCond($12,CellInfo0($6)) == True) {
        SetInfo0($$,$4);  // clk
        SetInfo2($$,$6);  // reset
      }
      else if (UsedSignalinIfCond($12,CellInfo0($4)) == True && UsedSignalinIfCond($12,CellInfo0($6)) == False) {
        SetInfo0($$,$6);  // clk
        SetInfo2($$,$4);  // reset
      }
      else {
        yyerror("$Can not determine clock signal.");
      }

      if (CellType($12) == T_IF) {
        CellType($12) = N_ASYNCRST_IF;
        if (CellInfo2($12) != NULLCELL && CellType(CellInfo2($12)) == T_ELSIF)
          CellType(CellInfo2($12)) = T_IF;
      }
      else {
        yyerror("$Unsupported type of description for async reset.");
      }

      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($7); FreeTcell($8); FreeTcell($13);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_item_sequential T_COMMA sensitivity_item_sequential T_RPARENTESIS T_COLON T_ID variable_process_types_list always_body
    {  /* N_ALWAYS_ASYNCRONE_SEQUENCE info0=sensitivity, info1=body, info2=sensitivity(reset) */
      $$ = $1; SetType($$,N_ALWAYS_ASYNCRONE_SEQUENCE); SetInfo1($$,$11); SetInfo3($$,$10);
      if (UsedSignalinIfCond($11,CellInfo0($4)) == False && UsedSignalinIfCond($11,CellInfo0($6)) == True) {
        SetInfo0($$,$4);  // clk
        SetInfo2($$,$6);  // reset
      }
      else if (UsedSignalinIfCond($11,CellInfo0($4)) == True && UsedSignalinIfCond($11,CellInfo0($6)) == False) {
        SetInfo0($$,$6);  // clk
        SetInfo2($$,$4);  // reset
      }
      else {
        yyerror("$Can not determine clock signal.");
      }

      if (CellType($11) == T_IF) {
        CellType($11) = N_ASYNCRST_IF;
        if (CellInfo2($11) != NULLCELL && CellType(CellInfo2($11)) == T_ELSIF)
          CellType(CellInfo2($11)) = T_IF;
      }
      else {
        yyerror("$Unsupported type of description for async reset.");
      }

      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($7);
    }
  | T_ALWAYS T_AT T_LPARENTESIS sensitivity_item_sequential T_COMMA sensitivity_item_sequential T_RPARENTESIS always_body_generic
    {  /* N_ALWAYS_ASYNCRONE_SEQUENCE info0=sensitivity, info1=body, info2=sensitivity(reset) */
      $$ = $1; SetType($$,N_ALWAYS_ASYNCRONE_SEQUENCE); SetInfo1($$,$8);
      if (CellType($8) == T_IF) {
        if (UsedSignalinIfCond($8,CellInfo0($4)) == False && UsedSignalinIfCond($8,CellInfo0($6)) == True) {
          SetInfo0($$,$4);  // clk
          SetInfo2($$,$6);  // reset
        }
        else if (UsedSignalinIfCond($8,CellInfo0($4)) == True && UsedSignalinIfCond($8,CellInfo0($6)) == False) {
          SetInfo0($$,$6);  // clk
          SetInfo2($$,$4);  // reset
        }
        else {
          SetInfo0($$,$4);   // clk
          SetInfo2($$,$6);  // reset
        }
  
        if (CellType($8) == T_IF) {
          CellType($8) = N_ASYNCRST_IF;
          if (CellInfo2($8) != NULLCELL && CellType(CellInfo2($8)) == T_ELSIF)
            CellType(CellInfo2($8)) = T_IF;
        }
        else {
          yyerror("$Unsupported type of description for async reset.");
        }
      }
      else {
        SetInfo0($$,$4);   // clk
        SetInfo2($$,$6);  // reset
      }

      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($5); FreeTcell($7);
    }
  ;

variable_process_types_list
  : variable_process_types variable_process_types_list
    {
      $$ = $1; SetNext($$,$2);
    }
  | variable_process_types
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

variable_process_types
  : T_REG port_names T_SEMICOLON
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetType($$,N_VARIABLE_PROCESS); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_REG port_names T_EQ expression_list T_SEMICOLON
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_VARIABLE_PROCESS); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($5);
    }
  | T_REG range port_names T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetType($$,N_VARIABLE_PROCESS); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_REG range port_names T_EQ expression_list T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_VARIABLE_PROCESS); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,$5);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_REG port_names range T_SEMICOLON
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetType($$,N_VARIABLE_PROCESS); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_REG port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_REG info0=range(N_NULL), info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_VARIABLE_PROCESS); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3); SetInfo3($$,$5);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_REG range port_names range T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range) */
      $$ = $1; SetType($$,N_VARIABLE_PROCESS); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_REG range port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_REG info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_VARIABLE_PROCESS); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,$6);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($5); FreeTcell($7);
    }
  | T_INTEGER port_names T_SEMICOLON
    {  /* T_INTEGER info0=range(N_NULL), info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetType($$,N_CONSTANT_PROCESS); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_INTEGER port_names T_EQ expression_list T_SEMICOLON
    {  /* T_INTEGER info0=range(N_NULL), info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_CONSTANT_PROCESS); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($5);
    }
  | T_INTEGER range port_names T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range)(N_NULL) */
      $$ = $1; SetType($$,N_CONSTANT_PROCESS); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INTEGER range port_names T_EQ expression_list T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range)(N_NULL), info3=expression */
      $$ = $1; SetType($$,N_CONSTANT_PROCESS); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,$5);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_INTEGER port_names range T_SEMICOLON
    {  /* T_INTEGER info0=range(N_NULL), info1=name, info2=array(range) */
      $$ = $1; SetType($$,N_CONSTANT_PROCESS); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($4);
    }
  | T_INTEGER port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_INTEGER info0=range(N_NULL), info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_CONSTANT_PROCESS); SetInfo0($$,NULLCELL); SetInfo1($$,$2); SetInfo2($$,$3); SetInfo3($$,$5);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_INTEGER range port_names range T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range) */
      $$ = $1; SetType($$,N_CONSTANT_PROCESS); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($5);
    }
  | T_INTEGER range port_names range T_EQ expression_list T_SEMICOLON
    {  /* T_INTEGER info0=range, info1=name, info2=array(range), info3=expression */
      $$ = $1; SetType($$,N_CONSTANT_PROCESS); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4); SetInfo3($$,$6);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($5); FreeTcell($7);
    }
  ;

sensitivity_list
  : T_POSEDGE expression_worm T_GATE_OR sensitivity_list
    {  /* T_POSEDGE info0=signal */
      $$ = MallocTcell(N_SENSITIVITY_POSEDGE_LIST,(char *)NULL,CellLine($2)); SetInfo0($$,$2); SetNext($$,$4);
    }
  | T_NEGEDGE expression_worm T_GATE_OR sensitivity_list
    {  /* T_NEGEDGE info0=signal */
      $$ = MallocTcell(N_SENSITIVITY_NEGEDGE_LIST,(char *)NULL,CellLine($2)); SetInfo0($$,$2); SetNext($$,$4);
    }
  | expression T_GATE_OR sensitivity_list
    {  /* N_SENSITIVITY_LIST info0=signal */
      $$ = MallocTcell(N_SENSITIVITY_LIST,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetInfo0($$,$1); SetNext($$,$3);
    }
  | T_POSEDGE expression_worm
    {  /* T_POSEDGE info0=signal */
      $$ = MallocTcell(N_SENSITIVITY_POSEDGE_LIST,(char *)NULL,CellLine($2)); SetInfo0($$,$2); SetNext($$,NULLCELL);
    }
  | T_NEGEDGE expression_worm
    {  /* T_NEGEDGE info0=signal */
      $$ = MallocTcell(N_SENSITIVITY_NEGEDGE_LIST,(char *)NULL,CellLine($2)); SetInfo0($$,$2); SetNext($$,NULLCELL);
    }
  | expression
    {  /* N_SENSITIVITY_LIST info0=signal */
      $$ = MallocTcell(N_SENSITIVITY_LIST,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetNext($$,NULLCELL);
    }
  ;

sensitivity_list_combinational
  : sensitivity_item_combinational T_GATE_OR sensitivity_list_combinational
    {
      $$ = $1; SetNext($$,$3);
      FreeTcell($2);
    }
  | sensitivity_item_combinational
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

sensitivity_item_combinational
  : expression_worm
    {  /* N_SENSITIVITY_LIST info0=signal */
      $$ = MallocTcell(N_SENSITIVITY_LIST,(char *)NULL,CellLine($1)); SetInfo0($$,$1);
    }
  ;

sensitivity_item_sequential
  : T_POSEDGE expression
    {  /* T_POSEDGE info0=signal */
      $$ = $1; SetInfo0($$,$2);
    }
  | T_NEGEDGE expression
    {  /* T_NEGEDGE info0=signal */
      $$ = $1; SetInfo0($$,$2);
    }
  ;

always_bodies_generic
  : always_body_generic always_bodies_generic
    {  /* N_ALWAYS_BODIES_GENERIC info0=body */
      $$ = MallocTcell(N_ALWAYS_BODIES_GENERIC,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetInfo0($$,$1); SetNext($$,$2);
    }
  | always_body_generic
    {
      $$ = MallocTcell(N_ALWAYS_BODIES_GENERIC,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetNext($$,NULLCELL);
    }
  ;

always_body_generic
  : T_BEGIN T_COLON T_ID always_bodies T_END
    {
      $$ = $4;
      FreeTcell($1); FreeTcell($2); FreeTcell($5);
    }
  | T_BEGIN T_BEGIN always_bodies T_END T_END
    {
      $$ = $3;
      FreeTcell($1); FreeTcell($2); FreeTcell($4); FreeTcell($5);
    }
  | T_BEGIN always_bodies T_END
    {
      $$ = $2;
      FreeTcell($1); FreeTcell($3);
    }
  | T_BEGIN T_COLON T_ID always_body T_END
    {
      $$ = $4;
      FreeTcell($1); FreeTcell($2); FreeTcell($5);
    }
  | T_BEGIN T_BEGIN always_body T_END T_END
    {
      $$ = $3;
      FreeTcell($1); FreeTcell($2); FreeTcell($4); FreeTcell($5);
    }
  | T_BEGIN always_body T_END
    {
      $$ = $2;
      FreeTcell($1); FreeTcell($3);
    }
  | always_body
    {
      $$ = $1;
    }
  ;

always_bodies
  : always_body always_bodies
    {
      $$ = $1; SetNext($$,$2);
    }
  | unconditional_part always_bodies
    {
      $$ = $1; SetNext($$,$2);
    }
  | always_body always_body
    {
      $$ = $1; SetNext($$,$2); SetNext($2,NULLCELL);
    }
  | unconditional_part
    {
      $$ = $1;
    }
  ;

always_body
  : module_instances
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | initial_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | always_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | ifdef_module_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | generate_blocks
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | fork_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | case_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | if_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | forever_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | for_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | repeat_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | while_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | continuous_assignments
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | procedural_time_controls
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | include_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  | undef_part
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

case_part
  : T_CASE literal case_top T_ENDCASE
    {  /* T_CASE info0=expression, info1=item */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($4);
    }
  | T_UNIQUE T_CASE literal case_top T_ENDCASE
    {  /* T_CASE info0=expression, info1=item */
      $$ = $2; SetInfo0($$,$3); SetInfo1($$,$4);
      SetLine($$,CellLine($2));
      ChkEvalOutput($3, SigListTop);
      FreeTcell($5);
    }
  ;

case_top
  : T_IFDEF T_ID case_top T_ELSEDEF case_top T_ENDIFDEF case_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_CASE);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5); SetNext($$,$7);
    }
  | T_IFDEF T_ID case_top T_ELSEDEF case_top T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_CASE);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5);
    }
  | T_IFDEF T_ID case_top T_ELSEDEF T_ENDIFDEF case_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_CASE);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetNext($$,$6);
    }
  | T_IFDEF T_ID case_top T_ELSEDEF T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_CASE);
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
    }
  | T_IFDEF T_ID T_ELSEDEF case_top T_ENDIFDEF case_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_CASE);
      SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4); SetNext($$,$6);
    }
  | T_IFDEF T_ID T_ELSEDEF case_top T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_CASE);
      SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4);
    }
  | T_IFDEF T_ID case_top T_ENDIFDEF case_top
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_CASE)
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetNext($$,$5);
    }
  | T_IFDEF T_ID case_top T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_CASE)
      SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
    }
  | case_item case_top
    {
      $$ = $1; SetNext($$,$2);
    }
  | case_item
    {
      $$ = $1; SetNext($$,NULLCELL);
    }
  ;

case_item
  : expression_list T_COLON always_body_generic
    {  /* N_CASE info0=condition, info1=body */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($1));
    }
  | expression_list T_COLON T_SEMICOLON
    {  /* N_CASE info0=condition, info1=body */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,NULLCELL);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | T_DEFAULT T_BEGIN always_bodies T_END
    {  /* N_CASE info0=condition, info1=body */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($1));
    }
  | T_DEFAULT T_BEGIN always_body T_END
    {  /* N_CASE info0=condition, info1=body */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($1));
    }
  | T_DEFAULT T_COLON T_BEGIN always_body T_BEGIN always_body T_END T_END
    {  /* N_CASE info0=condition, info1=body */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($5);
    }
  | T_DEFAULT T_COLON always_body_generic
    {  /* N_CASE info0=condition, info1=body */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($1));
    }
  | expression_list T_COLON T_BEGIN T_END
    {  /* N_CASE info0=condition, info1=body(N_NULL) */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,MallocTcell(N_NULL,NULLSTR,CellLine($4)));
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($4);
    }
  | expression_list T_COLON
    {  /* N_CASE info0=condition, info1=body(N_NULL) */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,MallocTcell(N_NULL,NULLSTR,CellLine($2)));
      SetLine($$,CellLine($1));
    }
  | T_DEFAULT T_COLON T_BEGIN T_END
    {  /* N_CASE info0=condition, info1=body(N_NULL) */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,MallocTcell(N_NULL,NULLSTR,CellLine($4)));
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($4);
    }
  | T_DEFAULT T_COLON T_SEMICOLON
    {  /* N_CASE info0=condition, info1=body(N_NULL) */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,MallocTcell(N_NULL,NULLSTR,CellLine($2)));
      SetLine($$,CellLine($1));
    }
  | T_DEFAULT T_COLON
    {  /* N_CASE info0=condition, info1=body(N_NULL) */
      $$ = $2; SetType($$,N_CASE); SetInfo0($$,$1); SetInfo1($$,MallocTcell(N_NULL,NULLSTR,CellLine($2)));
      SetLine($$,CellLine($1));
    }
  ;

if_part
  : T_IF expression T_BEGIN always_body T_BEGIN T_COLON T_ID variable_process_types_list always_body T_END T_END else_part
    {  /* T_IF info0=condition, info1=then, info2=else */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$9); SetInfo2($$,$12); SetInfo3($$,$8);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($5); FreeTcell($10); FreeTcell($11);
      if (CellType($12) == T_IF)
        CellType($12) = T_ELSIF;
    }
  | T_IF expression T_BEGIN T_COLON T_ID variable_process_types_list always_bodies T_END else_part
    {  /* T_IF info0=condition, info1=then, info2=else */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$7); SetInfo2($$,$9); SetInfo3($$,$6);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($8);
      if (CellType($9) == T_IF)
        CellType($9) = T_ELSIF;
    }
  | T_IF expression T_BEGIN T_COLON T_ID variable_process_types_list always_body T_END else_part
    {  /* T_IF info0=condition, info1=then, info2=else */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$7); SetInfo2($$,$9); SetInfo3($$,$6);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($8);
      if (CellType($9) == T_IF)
        CellType($9) = T_ELSIF;
    }
  | T_IF expression T_COLON T_ID variable_process_types_list always_body else_part
    {  /* T_IF info0=condition, info1=then, info2=else */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$6); SetInfo2($$,$7); SetInfo3($$,$5);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      if (CellType($7) == T_IF)
        CellType($7) = T_ELSIF;
    }
  | T_IF expression always_body_generic else_part
    {  /* T_IF info0=condition, info1=then, info2=else */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      if (CellType($4) == T_IF)
        CellType($4) = T_ELSIF;
    }
  | T_IF expression always_body_generic
    {  /* T_IF info0=condition, info1=then, info2=else(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
    }
  | T_IF expression T_BEGIN T_END else_part
    {  /* T_IF info0=condition, info1=then(N_NULL), info2=else */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,MallocTcell(N_NULL,NULLSTR,CellLine($4))); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($4);
      if (CellType($5) == T_IF)
        CellType($5) = T_ELSIF;
    }
  | T_IF expression else_part
    {  /* T_IF info0=condition, info1=then(N_NULL), info2=else */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,MallocTcell(N_NULL,NULLSTR,CellLine($2))); SetInfo2($$,$3);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      if (CellType($3) == T_IF)
        CellType($3) = T_ELSIF;
    }
  | T_IF expression T_BEGIN T_END
    {  /* T_IF info0=condition, info1=then(N_NULL), info2=else(N_NULL) */
      $$ = $1; SetInfo0($$,$2); SetInfo1($$,MallocTcell(N_NULL,NULLSTR,CellLine($4))); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($4);
    }
  ;

else_part
  : T_ELSE T_BEGIN T_COLON T_ID variable_process_types_list always_body T_END
    {  
      $$ = $6;
      SetLine($$,CellLine($1));
      FreeTcell($1); FreeTcell($2); FreeTcell($7);
    }
  | T_ELSE always_body_generic
    {  
      $$ = $2;
      FreeTcell($1);
    }
  | T_ELSE T_BEGIN T_END
    {  
      $$ = MallocTcell(N_NULL,NULLSTR,CellLine($1));
      FreeTcell($1); FreeTcell($2); FreeTcell($3);
    }
  | T_ELSE T_SEMICOLON
    {  
      $$ = MallocTcell(N_NULL,NULLSTR,CellLine($1));
      FreeTcell($1); FreeTcell($2);
    }
  ;

forever_part
  : T_FOREVER always_body_generic
    {  /* T_FOREVER info0=body */
      $$ = $1; SetType($$,N_FOREVER); SetInfo0($$,$2);
      SetLine($$,CellLine($1));
    }
  ;

for_part
  : T_FOR T_LPARENTESIS for_initialization T_SEMICOLON for_condition T_SEMICOLON for_actualization T_RPARENTESIS always_body_generic
    {  /* T_FOR info0=initialization, info1=condition, info2=actualization, info3=body */
      $$ = $1; SetInfo0($$,$3); SetInfo1($$,$5); SetInfo2($$,$7); SetInfo3($$,$9);
      FreeTcell($2); FreeTcell($4); FreeTcell($6); FreeTcell($8);
    }
  ;

for_initialization
  : T_ID T_EQ expression
    {  /* N_FOR_INITIALIZATION, info0=name, info1=expression */
      $$ = MallocTcell(N_FOR_INITIALIZATION,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetInfo1($$,$3);
      FreeTcell($2);
    }
  | T_LPARENTESIS for_initialization T_RPARENTESIS
    {
      $$ = $2;
      FreeTcell($1); FreeTcell($3);
    }
  ;

for_actualization
  : T_ID T_EQ expression
    {  /* N_FOR_ACTUALIZATION, info0=name, info1=expression */
      $$ = MallocTcell(N_FOR_ACTUALIZATION,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetInfo1($$,$3);
      FreeTcell($2);
    }
  | T_LPARENTESIS for_actualization T_RPARENTESIS
    {
      $$ = $2;
      FreeTcell($1); FreeTcell($3);
    }
  ;

for_condition
  : T_ID T_GE expression
    {  /* N_FOR_CONDITION_GE, info0=name, info1=expression */
      $$ = MallocTcell(N_FOR_CONDITION_GE,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetInfo1($$,$3);
      FreeTcell($2);
    }
  | T_ID T_GT expression
    {  /* N_FOR_CONDITION_GT, info0=name, info1=expression */
      $$ = MallocTcell(N_FOR_CONDITION_GT,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetInfo1($$,$3);
      FreeTcell($2);
    }
  | T_ID T_LE expression
    {  /* N_FOR_CONDITION_LE, info0=name, info1=expression */
      $$ = MallocTcell(N_FOR_CONDITION_LE,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetInfo1($$,$3);
      FreeTcell($2);
    }
  | T_ID T_LS expression
    {  /* N_FOR_CONDITION_LS, info0=name, info1=expression */
      $$ = MallocTcell(N_FOR_CONDITION_LS,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetInfo1($$,$3);
      FreeTcell($2);
    }
  | T_LPARENTESIS for_condition T_RPARENTESIS
    {
      $$ = $2;
      FreeTcell($1); FreeTcell($3);
    }
  ;

repeat_part
  : T_REPEAT T_LPARENTESIS expression T_RPARENTESIS always_body_generic
    {  /* T_REPEAT info0=condition, info1=body */
      $$ = $1; SetType($$,N_REPEAT); SetInfo0($$,$3); SetInfo1($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($4);
    }
  ;

while_part
  : T_WHILE T_LPARENTESIS expression T_RPARENTESIS always_body_generic
    {  /* T_WHILE info0=condition, info1=body */
      $$ = $1; SetType($$,N_WHILE); SetInfo0($$,$3); SetInfo1($$,$5);
      FreeTcell($2); FreeTcell($4);
    }
  ;

continuous_assignments // SIGNAL = NET OR VARIABLE
  : expression_worm T_EQ T_GENERIC expression literal T_SEMICOLON
    {  /* N_VARIABLE_DELAY_ASSIGN info0=signal, info1=expression, info2=signal */
      $$ = $2; SetType($$,N_VARIABLE_DELAY_ASSIGN); SetInfo0($$,$1); SetInfo1($$,$5); SetInfo2($$,$4);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($6);
    }
  | expression_worm T_EQ T_GENERIC_ID T_ID expression T_SEMICOLON
    {  /* N_VARIABLE_DELAY_ASSIGN info0=signal, info1=expression, info2=signal */
      $$ = $2; SetType($$,N_VARIABLE_DELAY_ASSIGN); SetInfo0($$,$1); SetInfo1($$,$5); SetInfo2($$,$4);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($6);
    }
  | expression_worm T_EQ expression literal T_SEMICOLON
    {  /* N_VARIABLE_DELAY_ASSIGN info0=signal, info1=expression, info2=signal */
      $$ = $2; SetType($$,N_VARIABLE_DELAY_ASSIGN); SetInfo0($$,$1); SetInfo1($$,$4); SetInfo2($$,$3);
      SetLine($$,CellLine($5));
      ChkEvalOutput($4, SigListTop);
      FreeTcell($5);
    }
  | expression_worm T_GE T_GENERIC_ID T_ID expression T_SEMICOLON
    {  /* N_NET_DELAY_ASSIGN info0=signal, info1=expression, info2=signal */
      $$ = $2; SetType($$,N_NET_DELAY_ASSIGN); SetInfo0($$,$1); SetInfo1($$,$5); SetInfo2($$,$4);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($6);
    }
  | expression_worm T_GE T_GENERIC expression literal T_SEMICOLON
    {  /* N_NET_DELAY_ASSIGN info0=signal, info1=expression, info2=signal */
      $$ = $2; SetType($$,N_NET_DELAY_ASSIGN); SetInfo0($$,$1); SetInfo1($$,$5); SetInfo2($$,$4);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($6);
    }
  | expression_worm T_GE expression literal T_SEMICOLON
    {  /* N_NET_DELAY_ASSIGN info0=signal, info1=expression, info2=signal */
      $$ = $2; SetType($$,N_NET_DELAY_ASSIGN); SetInfo0($$,$1); SetInfo1($$,$4); SetInfo2($$,$3);
      SetLine($$,CellLine($5));
      ChkEvalOutput($4, SigListTop);
      FreeTcell($5);
    }
  | expression_worm T_EQ expression_list T_SEMICOLON
    {  /* N_VARIABLE_ASSIGN info0=signal, info1=expression */
      $$ = $2; SetType($$,N_VARIABLE_ASSIGN); SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($4));
      ChkEvalOutput($3, SigListTop);
      FreeTcell($4);
    }
  | expression_worm T_GE expression_list T_SEMICOLON
    {  /* N_NET_ASSIGN info0=signal, info1=expression */
      $$ = $2; SetType($$,N_NET_ASSIGN); SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($4));
      ChkEvalOutput($3, SigListTop);
      FreeTcell($4);
    }
  | T_GENERIC_ID T_ID signal_name T_EQ expression_list T_SEMICOLON
    {  /* N_VARIABLE_ASSIGN_DELAY info0=signal, info1=expression, info2=expression */
      $$ = $4; SetType($$,N_VARIABLE_ASSIGN_DELAY); SetInfo0($$,$3); SetInfo1($$,$5); SetInfo2($$,$2);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($6);
    }
  | T_GENERIC_ID T_ID signal_name T_GE expression_list T_SEMICOLON
    {  /* N_NET_ASSIGN_DELAY info0=signal, info1=expression, info2=expression */
      $$ = $4; SetType($$,N_NET_ASSIGN_DELAY); SetInfo0($$,$3); SetInfo1($$,$5); SetInfo2($$,$2);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($6);
    }
  | T_GENERIC number signal_name T_EQ expression_list T_SEMICOLON
    {  /* N_VARIABLE_ASSIGN_DELAY info0=signal, info1=expression, info2=expression */
      $$ = $4; SetType($$,N_VARIABLE_ASSIGN_DELAY); SetInfo0($$,$3); SetInfo1($$,$5); SetInfo2($$,$2);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($6);
    }
  | T_GENERIC number signal_name T_GE expression_list T_SEMICOLON
    {  /* N_NET_ASSIGN_DELAY info0=signal, info1=expression, info2=expression */
      $$ = $4; SetType($$,N_NET_ASSIGN_DELAY); SetInfo0($$,$3); SetInfo1($$,$5); SetInfo2($$,$2);
      SetLine($$,CellLine($6));
      ChkEvalOutput($5, SigListTop);
      FreeTcell($6);
    }
  | T_ASSIGN T_GENERIC number signal_name T_EQ expression_list T_SEMICOLON
    {  /* N_VARIABLE_ASSIGN_DELAY info0=signal, info1=expression, info2=expression */
      $$ = $5; SetType($$,N_VARIABLE_ASSIGN_DELAY); SetInfo0($$,$4); SetInfo1($$,$6); SetInfo2($$,$3);
      SetLine($$,CellLine($7));
      ChkEvalOutput($6, SigListTop);
      FreeTcell($7);
    }
  | T_ASSIGN T_GENERIC number signal_name T_GE expression_list T_SEMICOLON
    {  /* N_NET_ASSIGN_DELAY info0=signal, info1=expression, info2=expression */
      $$ = $5; SetType($$,N_NET_ASSIGN_DELAY); SetInfo0($$,$4); SetInfo1($$,$6); SetInfo2($$,$3);
      SetLine($$,CellLine($7));
      ChkEvalOutput($6, SigListTop);
      FreeTcell($7);
    }
  | T_DEASSIGN expression_worm T_SEMICOLON
    {  /* N_VARIABLE_ASSIGN info0=signal, info1=expression */
      $$ = $1; SetType($$,N_VARIABLE_ASSIGN); SetInfo0($$,$2); SetInfo1($$,NULLCELL);
      SetLine($$,CellLine($3));
      FreeTcell($3);
    }

  | T_FORCE expression_worm T_EQ expression_list T_SEMICOLON
    {  /* N_VARIABLE_ASSIGN info0=signal, info1=expression */
      $$ = $3; SetType($$,N_VARIABLE_ASSIGN); SetInfo0($$,$2); SetInfo1($$,$4);
      SetLine($$,CellLine($5));
      ChkEvalOutput($4, SigListTop);
      FreeTcell($5);
    }

  | T_FORCE expression_worm T_GE expression_list T_SEMICOLON
    {  /* N_NET_ASSIGN info0=signal, info1=expression */
      $$ = $3; SetType($$,N_NET_ASSIGN); SetInfo0($$,$2); SetInfo1($$,$4);
      SetLine($$,CellLine($5));
      ChkEvalOutput($4, SigListTop);
      FreeTcell($5);
    }
  | T_ASSIGN T_LPARENTESIS T_ID T_COMMA T_ID T_RPARENTESIS signal_assign_list T_SEMICOLON
    {  /* T_ASSIGN info0=signal_assign_list */
      $$ = $1; SetType($$,N_ASSIGN); SetInfo0($$,$7);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($3); FreeTcell($4); FreeTcell($5); FreeTcell($6);
      FreeTcell($8);
    }
  | T_ASSIGN signal_assign_list T_SEMICOLON
    {  /* T_ASSIGN info0=signal_assign_list */
      $$ = $1; SetType($$,N_ASSIGN); SetInfo0($$,$2);
      SetLine($$,CellLine($1));
      FreeTcell($3);
    }
  | call_function_or_task T_SEMICOLON
    {  /* N_TASK_CALL info0=list */
      $$ = $1; SetType($$,N_TASK_CALL); SetNext($$,NULLCELL);
    }
  | call_delay_function_or_task T_SEMICOLON
    {  /* N_DELAY_TASKCALL */
      $$ = $1; SetType($$,N_DELAY_TASKCALL); SetNext($$,NULLCELL);
    }
  | signal_name_list T_SEMICOLON
    {  /* T_ID */
      $$ = MallocTcell(N_NAME,(char *)NULL,CellLine($1)); SetInfo0($$,$1);
    }
  | T_ARROW T_ID T_SEMICOLON
    {  /* T_ID */
      $$ = MallocTcell(N_NAME,(char *)NULL,CellLine($2)); SetInfo0($$,$2);
    }
  ;

signal_assign_list
  : expression_worm T_EQ expression T_COMMA signal_assign_list
    {  /* N_ASSIGN_SIGNAL, info0=name, info1=expression */
      $$ = MallocTcell(N_ASSIGN_SIGNAL,(char *)NULL,CellLine($5)); SetInfo0($$,$1); SetInfo1($$,$3); SetNext($$,$5);
      FreeTcell($2); FreeTcell($4);
    }
  | expression_worm T_EQ expression
    {  /* N_ASSIGN_SIGNAL, info0=name, info1=expression */
      $$ = MallocTcell(N_ASSIGN_SIGNAL,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetInfo1($$,$3); SetNext($$,NULLCELL);
      FreeTcell($2);
    }
  ;

procedural_time_controls
  : T_GENERIC expression T_SEMICOLON
    {  /* T_GENERIC info0=expression */
      $$ = $1; SetType($$,N_PROCEDURAL_TIME_GENERIC); SetInfo0($$,$2);
    }
  | T_GENERIC expression always_body_generic
    {  /* T_GENERIC info0=expression, info1=body */
      $$ = $1; SetType($$,N_PROCEDURAL_TIME_GENERIC); SetInfo0($$,$2); SetInfo1($$,$3);
    }
  | T_AT T_LPARENTESIS sensitivity_list T_RPARENTESIS T_SEMICOLON
    {  /* T_AT info0=sensitivity */
      $$ = $1; SetType($$,N_PROCEDURAL_TIME_EXPRESSION); SetInfo0($$,$3);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($4);
    }
  | T_AT T_LPARENTESIS sensitivity_list T_RPARENTESIS always_body_generic
    {  /* T_AT info0=sensitivity, info1=body */
      $$ = $1; SetType($$,N_PROCEDURAL_TIME_EXPRESSION); SetInfo0($$,$3); SetInfo1($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($2); FreeTcell($4);
    }
  ;

task_definitions
  : T_TASK T_ID T_SEMICOLON always_body_generic T_ENDTASK
    {  /* N_TASK_DEFINITION info0=name, info1=declarations(N_NULL), info2=body */
      $$ = $1; SetType($$,N_TASK_DEFINITION); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($5);
    }
  | T_TASK T_ID T_SEMICOLON full_data_type_declarations_list always_body_generic T_ENDTASK
    {  /* N_TASK_DEFINITION info0=name, info1=declarations, info2=body */
      $$ = $1; SetType($$,N_TASK_DEFINITION); SetInfo0($$,$2); SetInfo1($$,$4); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($6);
    }
  ;

function_definitions
  : T_FUNCTION range T_ID T_SEMICOLON full_data_type_declarations_list always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range, info2=declarations, info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$3); SetInfo1($$,$2); SetInfo2($$,$5); SetInfo3($$,$6);
      SetLine($$,CellLine($1));
      FreeTcell($4); FreeTcell($7);
    }
  | T_FUNCTION T_ID T_SEMICOLON full_data_type_declarations_list always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range(N_NULL), info2=declarations, info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4); SetInfo3($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($6);
    }
  | T_FUNCTION range T_ID T_SEMICOLON always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range, info2=declarations(N_NULL), info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$3); SetInfo1($$,$2); SetInfo2($$,NULLCELL); SetInfo3($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($4); FreeTcell($6);
    }
  | T_FUNCTION T_ID T_SEMICOLON always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range(N_NULL), info2=declarations(N_NULL), info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,NULLCELL); SetInfo3($$,$4);
      SetLine($$,CellLine($1));
      FreeTcell($3); FreeTcell($5);
    }
  | T_FUNCTION T_AUTOMATIC range T_ID T_SEMICOLON full_data_type_declarations_list always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range, info2=declarations, info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$4); SetInfo1($$,$3); SetInfo2($$,$6); SetInfo3($$,$7);
      SetLine($$,CellLine($1));
      FreeTcell($5); FreeTcell($8);
    }
  | T_FUNCTION T_AUTOMATIC T_ID T_SEMICOLON full_data_type_declarations_list always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range(N_NULL), info2=declarations, info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$3); SetInfo1($$,NULLCELL); SetInfo2($$,$5); SetInfo3($$,$7);
      SetLine($$,CellLine($1));
      FreeTcell($4); FreeTcell($7);
    }
  | T_FUNCTION T_AUTOMATIC range T_ID T_SEMICOLON always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range, info2=declarations(N_NULL), info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$4); SetInfo1($$,$3); SetInfo2($$,NULLCELL); SetInfo3($$,$6);
      SetLine($$,CellLine($1));
      FreeTcell($5); FreeTcell($7);
    }
  | T_FUNCTION T_AUTOMATIC T_ID T_SEMICOLON always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range(N_NULL), info2=declarations(N_NULL), info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$3); SetInfo1($$,NULLCELL); SetInfo2($$,NULLCELL); SetInfo3($$,$5);
      SetLine($$,CellLine($1));
      FreeTcell($4); FreeTcell($6);
    }
  | T_FUNCTION T_AUTOMATIC T_INTEGER T_ID T_SEMICOLON full_data_type_declarations_list always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range(N_NULL), info2=declarations, info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$4); SetInfo1($$,$6); SetInfo2($$,NULLCELL); SetInfo3($$,$7);
      SetLine($$,CellLine($1));
      FreeTcell($5); FreeTcell($8);
    }
  | T_FUNCTION T_AUTOMATIC T_INTEGER T_ID T_SEMICOLON always_bodies_generic T_ENDFUNCTION
    {  /* N_FUNCTION_DEFINITION info0=name, info1=out range(N_NULL), info2=declarations(N_NULL), info3=body */
      $$ = $1; SetType($$,N_FUNCTION_DEFINITION); SetInfo0($$,$4); SetInfo1($$,NULLCELL); SetInfo2($$,NULLCELL); SetInfo3($$,$6);
      SetLine($$,CellLine($1));
      FreeTcell($5); FreeTcell($7);
    }
  ;

expression_list
  : expression T_COMMA expression_list
    {  /* N_EXPRESSION_LIST info0=expression */
      $$ = MallocTcell(N_EXPRESSION_LIST,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetNext($$,$3);
      FreeTcell($2);
    }
  | expression T_DOT expression_list
    {  /* N_EXPRESSION_DOT_LIST info0=expression */
      $$ = MallocTcell(N_EXPRESSION_DOT_LIST,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetNext($$,$3);
      FreeTcell($2);
    }
  | expression
    {  /* N_EXPRESSION_LIST info0=expression */
      $$ = MallocTcell(N_EXPRESSION_LIST,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetNext($$,NULLCELL);
    }
  ;

expression
  : expression T_LOGIC_OR expression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | condexpression
    {
      $$ = $1;
    }
  ;

condexpression
  : expression T_SELECT expression T_COLON expression
    {  /* T_SELECT info0=condition, info1=then, info2=else */
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3); SetInfo2($$,$5);
      ConvertParen2Dummy($$);
      SetLine($$,CellLine($5));
      FreeTcell($4);
    }
  | logicandexpression
    {
      $$ = $1;
    }
  ;

logicandexpression
  : logicandexpression T_LOGIC_AND logicandexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | orexpression
    {
      $$ = $1;
    }
  ;

orexpression
  : orexpression T_OR orexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | andexpression
    {
      $$ = $1;
    }
  ;

andexpression
  : andexpression T_AND andexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | andexpression T_NAND andexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | andexpression T_XOR andexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | andexpression T_XNOR andexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | eqexpression
    {
      $$ = $1;
    }
  ;

eqexpression
  : eqexpression T_LOGIC_EQ eqexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | eqexpression T_LOGIC_NEQ eqexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | compexpression
    {
      $$ = $1;
    }
  ;

compexpression
  : compexpression T_GE compexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | compexpression T_LE compexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | compexpression T_GT compexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | compexpression T_LS compexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | shiftexpression
    {
      $$ = $1;
    }
  ;

shiftexpression
  : shiftexpression T_RSHIFT shiftexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | shiftexpression T_LSHIFT shiftexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | addexpression
    {
      $$ = $1;
    }
  ;

addexpression
  : addexpression T_PLUS addexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | addexpression T_MINUS addexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | T_MINUS T_DECDIGIT  %prec N_UMINUS
    {
      char  *newstr;
      $$ = $2; FreeTcell($1);
      newstr = (char *)malloc(sizeof (char) * (strlen(CellStr($2)) + 2));
      sprintf(newstr, "-%s", CellStr($2));
      free(CellStr($2));
      CellStr($2) = newstr;
    }
  | T_PLUS T_DECDIGIT    %prec N_UPLUS
    {
      $$ = $2; FreeTcell($1);
    }
  | multexpression
    {
      $$ = $1;
    }
  ;

multexpression
  : multexpression T_MULT multexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | multexpression T_DIV multexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | multexpression T_EXP multexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | multexpression T_MOD multexpression
    {
      $$ = $2; SetInfo0($$,$1); SetInfo1($$,$3);
      SetLine($$,CellLine($3));
    }
  | notexpression
    {
      $$ = $1;
    }
  ;

notexpression
  : T_NOT literal
    {
      $$ = $1; SetInfo0($$,$2);
      SetLine($$,CellLine($2));
    }
  | T_LOGIC_NOT literal
    {
      $$ = $1; SetInfo0($$,$2);
      SetLine($$,CellLine($2));
    }
  | T_AND literal
    {  /* N_REDUCTION_AND info0=expression */
      $$ = $1; SetType($$,N_REDUCTION_AND); SetInfo0($$,$2);
      SetLine($$,CellLine($2));
    }
  | T_OR literal
    {  /* N_REDUCTION_OR info0=expression */
      $$ = $1; SetType($$,N_REDUCTION_OR); SetInfo0($$,$2);
      SetLine($$,CellLine($2));
    }
  | T_XOR literal
    {  /* N_REDUCTION_XOR info0=expression */
      $$ = $1; SetType($$,N_REDUCTION_XOR); SetInfo0($$,$2);
      SetLine($$,CellLine($2));
    }
  | T_NAND literal
    {  /* N_REDUCTION_NAND info0=expression */
      $$ = $1; SetType($$,N_REDUCTION_NAND); SetInfo0($$,$2);
      SetLine($$,CellLine($2));
    }
  | T_NOR literal
    {  /* N_REDUCTION_NOR info0=expression */
      $$ = $1; SetType($$,N_REDUCTION_NOR); SetInfo0($$,$2);
      SetLine($$,CellLine($2));
    }
  | T_XNOR literal
    {  /* N_REDUCTION_XNOR info0=expression */
      $$ = $1; SetType($$,N_REDUCTION_XNOR); SetInfo0($$,$2);
      SetLine($$,CellLine($2));
    }
  | literal
    {
      $$ = $1;
    }
  ;

literal
  : sentence
    {
      $$ = $1;
    }
  | common_function_or_task
    {
      $$ = $1;
    }
  | number
    {
      $$ = $1;
    }
  | expression_worm
    {
      $$ = $1;
    }
  ;

common_function_or_task
  : T_TIME
    {  /* T_TIME */
      $$ = $1;
    }
  ;

sentence
  : T_SENTENCE
    {  /* N_SIGNAL */
      $$ = $1; SetType($$,N_SIGNAL);
    }
  ;

number
  : T_NATDIGIT
    {
      $$ = $1;
    }
  | T_BINDIGIT
    {
      $$ = $1;
    }
  | T_OCTDIGIT
    {
      $$ = $1;
    }
  | T_DECDIGIT
    {
      $$ = $1;
    }
  | T_HEXDIGIT
    {
      $$ = $1;
    }
  | T_WIDTH_BINDIGIT
    {
      $$ = $1;
    }
  | T_WIDTH_OCTDIGIT
    {
      $$ = $1;
    }
  | T_WIDTH_DECDIGIT
    {
      $$ = $1;
    }
  | T_WIDTH_HEXDIGIT
    {
      $$ = $1;
    }
  | T_PARAMETER_BINDIGIT
    {
      $$ = $1;
    }
  | T_PARAMETER_OCTDIGIT
    {
      $$ = $1;
    }
  | T_PARAMETER_DECDIGIT
    {
      $$ = $1;
    }
  | T_PARAMETER_HEXDIGIT
    {
      $$ = $1;
    }
  | T_GENERIC_BINDIGIT
    {
      $$ = $1;
    }
  | T_GENERIC_OCTDIGIT
    {
      $$ = $1;
    }
  | T_GENERIC_DECDIGIT
    {
      $$ = $1;
    }
  | T_GENERIC_HEXDIGIT
    {
      $$ = $1;
    }
  ;

expression_worm
  : signal_name_list
    {
      $$ = $1;
    }
  | T_LBRACE expression_list T_RBRACE
    {  /* N_CONCATENATION info0=list */
      $$ = $1; SetType($$,N_CONCATENATION); SetInfo0($$,$2);
      SetLine($$,CellLine($3));
      FreeTcell($3);
    }
  | T_LBRACE expression T_LBRACE expression_list T_RBRACE T_RBRACE
    {  /* N_COPY_SIGNAL info0=copy times, info1=expression */
      $$ = $1; SetType($$,N_COPY_SIGNAL); SetInfo0($$,$2); SetInfo1($$,$4);
      SetLine($$,CellLine($6));
      FreeTcell($3); FreeTcell($5); FreeTcell($6);
    }
  | T_LBRACE expression signal_name T_RBRACE
    {  /* N_COPY_SIGNAL info0=copy times, info1=expression */
      $$ = $1; SetType($$,N_COPY_SIGNAL); SetInfo0($$,$2); SetInfo1($$,$3);
      SetLine($$,CellLine($4));
      FreeTcell($4);
    }
  | T_LPARENTESIS expression T_RPARENTESIS
    {  /* N_PARENTESIS info0=expression */
      $$ = $1; SetType($$,N_PARENTESIS); SetInfo0($$,$2);
      SetLine($$,CellLine($3));
      FreeTcell($3);
    }
  | call_function_or_task
    {  /* N_FUNCTION_CALL info0=list */
      $$ = $1; SetType($$,N_FUNCTION_CALL);
    }
  ;

signal_name_list
  : signal_name T_DOT signal_name_list
    {  /* N_EXPRESSION_DOT_LIST info0=signal */
      $$ = MallocTcell(N_EXPRESSION_DOT_LIST,(char *)NULL,CellLine($3)); SetInfo0($$,$1); SetNext($$,$3);
      FreeTcell($2);
    }
  | signal_name
    {  /* N_EXPRESSION_DOT_LIST info0=signal */
      $$ = MallocTcell(N_EXPRESSION_DOT_LIST,(char *)NULL,CellLine($1)); SetInfo0($$,$1); SetNext($$,NULLCELL);
    }
  ;

signal_name
  : T_ID
    {  /* N_SIGNAL */
      $$ = $1; SetType($$,N_SIGNAL);
    }
  | T_ID range
    {  /* N_SIGNAL_WIDTH info0=range */
      $$ = $1; SetType($$,N_SIGNAL_WIDTH); SetInfo0($$,$2);
      SetLine($$,CellLine($2));
    }
  | T_ID range range
    {  /* N_SIGNAL_WIDTH info0=range, info1=range */
      $$ = $1; SetType($$,N_SIGNAL_WIDTH); SetInfo0($$,$2); SetInfo1($$,$3);
      SetLine($$,CellLine($2));
    }
  ;

common_compiler_directives
  : timescale_part
    {
      $$ = $1;
    }
  | define_part
    {
      $$ = $1;
    }
  | undef_part
    {
      $$ = $1;
    }
  | ifdef_project_part
    {
      $$ = $1;
    }
  | include_part
    {
      $$ = $1;
    }
  | celldefine_part
    {
      $$ = $1;
    }
  | endcelldefine_part
    {
      $$ = $1;
    }
  ;

timescale_part
  : T_TIMESCALE T_NATDIGIT T_ID T_DIV T_NATDIGIT T_ID
    {  /* T_TIMESCALE */
      $$ = $1; SetType($$,N_TIMESCALE_DIRECTIVE);
    }
  ;

define_part
  : T_DEFINE T_ID expression T_COLON expression
    {  /* T_DEFINE info0=name, info1=expression, info2=expression */
      $$ = $1; SetType($$,N_DEFINE_DIRECTIVE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
    }
  | T_DEFINE T_ID expression
    {  /* T_DEFINE info0=name, info1=expression, info2=expression(N_NULL) */
      $$ = $1; SetType($$,N_DEFINE_DIRECTIVE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
    }
  | T_DEFINE T_ID
    {  /* T_DEFINE info0=name, info1=expression(N_NULL), info2=expression(N_NULL) */
      $$ = $1; SetType($$,N_DEFINE_DIRECTIVE); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
    }
  ;

undef_part
  : T_UNDEF T_ID
    {  /* T_UNDEF info0=name, info1=expression(N_NULL), info2=expression(N_NULL) */
      $$ = $1; SetType($$,N_DEFINE_DIRECTIVE); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
    }
  ;

ifdef_project_part
  : T_IFDEF T_ID project T_ELSEDEF project T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PROJECT); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_IFDEF T_ID project T_ELSEDEF T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_PROJECT); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($4); FreeTcell($5);
    }
  | T_IFDEF T_ID T_ELSEDEF project T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body(N_NULL), info2=else */
      $$ = $1; SetType($$,N_IFDEF_PROJECT); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($5);
    }
  | T_IFDEF T_ID T_ELSEDEF T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body(N_NULL), info2=else */
      $$ = $1; SetType($$,N_IFDEF_PROJECT); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($4);
    }
  | T_IFDEF T_ID project T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else(N_NULL) */
      $$ = $1; SetType($$,N_IFDEF_PROJECT); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($4);
    }
  | T_IFDEF T_ID T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body(N_NULL), info2=else(N_NULL) */
      $$ = $1; SetType($$,N_IFDEF_PROJECT); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3);
    }
  ;

ifdef_module_part
  : T_IFDEF T_ID module_items_list T_ELSIFDEF T_ID module_items_list T_ELSEDEF module_items_list T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=name, info3=else, info4=else */
      $$ = $1; SetType($$,N_COMPLEX_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5); SetInfo3($$,$6); SetInfo4($$,$8);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($4); FreeTcell($7); FreeTcell($9);
    }
  | T_IFDEF T_ID T_ELSIFDEF T_ID module_items_list T_ELSEDEF module_items_list T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=name, info3=else, info4=else */
      $$ = $1; SetType($$,N_COMPLEX_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4); SetInfo3($$,$5); SetInfo4($$,$7);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($6); FreeTcell($8);
    }
  | T_IFDEF T_ID T_ELSIFDEF T_ID T_ELSEDEF module_items_list T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=name, info3=else, info4=else */
      $$ = $1; SetType($$,N_COMPLEX_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4); SetInfo3($$,NULLCELL); SetInfo4($$,$6);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($5); FreeTcell($7);
    }
  | T_IFDEF T_ID T_ELSIFDEF T_ID module_items_list T_ELSEDEF T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=name, info3=else, info4=else */
      $$ = $1; SetType($$,N_COMPLEX_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4); SetInfo3($$,$5); SetInfo4($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($6); FreeTcell($7);
    }
  | T_IFDEF T_ID module_items_list T_ELSEDEF module_items_list T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else */
      $$ = $1; SetType($$,N_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,$5);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($4); FreeTcell($6);
    }
  | T_IFDEF T_ID T_ELSEDEF module_items_list T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body(N_NULL), info2=else */
      $$ = $1; SetType($$,N_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,$4);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($5);
    }
  | T_IFDEF T_ID module_items_list T_ELSEDEF T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body(N_NULL), info2=else */
      $$ = $1; SetType($$,N_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($4); FreeTcell($5);
    }
  | T_IFDEF T_ID T_ELSEDEF T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body(N_NULL), info2=else */
      $$ = $1; SetType($$,N_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3); FreeTcell($4);
    }
  | T_IFDEF T_ID module_items_list T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body, info2=else(N_NULL) */
      $$ = $1; SetType($$,N_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,$3); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($4);
    }
  | T_IFDEF T_ID T_ENDIFDEF
    {  /* T_IFDEF info0=name, info1=body(N_NULL), info2=else(N_NULL) */
      $$ = $1; SetType($$,N_IFDEF_MODULE); SetInfo0($$,$2); SetInfo1($$,NULLCELL); SetInfo2($$,NULLCELL);
      SetLine($$,CellLine($1));
      ChkEvalOutput($2, SigListTop);
      FreeTcell($3);
    }
  ;

include_part
  : T_INCLUDE T_SENTENCE
    {  /* T_INCLUDE info0=name */
      $$ = $1; SetType($$,N_INCLUDE_DIRECTIVE); SetInfo0($$,$2);
    }
  ;

celldefine_part
  : T_CELLDEFINE
    {  /* T_CELLDEFINE */
      $$ = $1;
    }
  ;

endcelldefine_part
  : T_ENDCELLDEFINE
    {  /* T_ENDCELLDEFINE */
      $$ = $1;
    }
  ;

%%

void fprintfError(char *s, int line)  // (unuse yylexlinenum for line number)
{
  ParseError = True;
  fprintf(stderr, "ERROR: in line %d, %s\n", line, s);
}

void yyerror(char *s)
{
  ParseError = True;
  if (*s == '$')
    fprintf(stderr, "ERROR: in line %d, %s\n", yylexlinenum, s + 1);
  else
    fprintf(stderr, "ERROR: parse error in line %d\n", yylexlinenum);
    return;
}
// end of file
