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

int yylexlinenum;
int yywrap(void)
{
  return (1);
}

%}
%%
"//".*[\n]+     { RegisterComment(CommentListTop, yytext, &yylexlinenum); }
\n[\n]+         { RegisterComment(CommentListTop, yytext, &yylexlinenum); }
\n              { yylexlinenum++; }
"/*"            { // read file until "*/" is detected.
                int ch1, ch2;
                char *buf1, *buf2;
                ch1  = input();
                buf1 = (char *)malloc(sizeof (char) * 4);
                sprintf(buf1, "/*%c", (char)ch1);
                for (;;) {
                  if ((ch2 = input()) == EOF)
                    break;
                  buf2 = buf1;
                  buf1 = (char *)malloc(sizeof (char) * (strlen(buf2) + 2));
                  sprintf(buf1, "%s%c", buf2, (char)ch2);
                  free(buf2);
                  if (ch1 == '*' && ch2 == '/')  break;
                  else              ch1 = ch2;
                }

                for (; ch2 != EOF;) {  // detect LFs
                  ch1 = input();
                  if (ch1 != '\n') {
                    unput(ch1);
                    break;
                  }
                  buf2 = buf1;
                  buf1 = (char *)malloc(sizeof (char) * (strlen(buf2) + 2));
                  sprintf(buf1, "%s\n", buf2);
                  free(buf2);
                }

                RegisterComment(CommentListTop, buf1, &yylexlinenum);
                free(buf1);
              }

`celldefine                                                               {yylval = MallocTcell(T_CELLDEFINE, NULLSTR, yylexlinenum); return(T_CELLDEFINE);}
`define                                                                   {yylval = MallocTcell(T_DEFINE, NULLSTR, yylexlinenum); return(T_DEFINE);}
`else                                                                     {yylval = MallocTcell(T_ELSEDEF, NULLSTR, yylexlinenum); return(T_ELSEDEF);}
`elsif                                                                    {yylval = MallocTcell(T_ELSIFDEF, NULLSTR, yylexlinenum); return(T_ELSIFDEF);}
`endcelldefine                                                            {yylval = MallocTcell(T_ENDCELLDEFINE, NULLSTR, yylexlinenum); return(T_ENDCELLDEFINE);}
`endif                                                                    {yylval = MallocTcell(T_ENDIFDEF, NULLSTR, yylexlinenum); return(T_ENDIFDEF);}
`ifdef|`ifndef                                                            {yylval = MallocTcell(T_IFDEF, NULLSTR, yylexlinenum); return(T_IFDEF);}
`include                                                                  {yylval = MallocTcell(T_INCLUDE, NULLSTR, yylexlinenum); return(T_INCLUDE);}
`resetall                                                                 {yylval = MallocTcell(T_RESETALL, NULLSTR, yylexlinenum); return(T_RESETALL);}
`timescale                                                                {yylval = MallocTcell(T_TIMESCALE, NULLSTR, yylexlinenum); return(T_TIMESCALE);}
`undef                                                                    {yylval = MallocTcell(T_UNDEF, NULLSTR, yylexlinenum); return(T_UNDEF);}

always                                                                    {yylval = MallocTcell(T_ALWAYS, NULLSTR, yylexlinenum); return(T_ALWAYS);}
and                                                                       {yylval = MallocTcell(T_GATE_AND, NULLSTR, yylexlinenum); return(T_GATE_AND);}
assign                                                                    {yylval = MallocTcell(T_ASSIGN, NULLSTR, yylexlinenum); return(T_ASSIGN);}
automatic                                                                 {yylval = MallocTcell(T_AUTOMATIC, NULLSTR, yylexlinenum); return(T_AUTOMATIC);}
begin                                                                     {yylval = MallocTcell(T_BEGIN, NULLSTR, yylexlinenum); return(T_BEGIN);}
buf|bufif1                                                                {yylval = MallocTcell(T_GATE_BUF, NULLSTR, yylexlinenum); return(T_GATE_BUF);}
case|casex|casez                                                          {yylval = MallocTcell(T_CASE, NULLSTR, yylexlinenum); return(T_CASE);}
default                                                                   {yylval = MallocTcell(T_DEFAULT, NULLSTR, yylexlinenum); return(T_DEFAULT);}
else                                                                      {yylval = MallocTcell(T_ELSE, NULLSTR, yylexlinenum); return(T_ELSE);}
end                                                                       {yylval = MallocTcell(T_END, NULLSTR, yylexlinenum); return(T_END);}
endcase                                                                   {yylval = MallocTcell(T_ENDCASE, NULLSTR, yylexlinenum); return(T_ENDCASE);}
endfunction                                                               {yylval = MallocTcell(T_ENDFUNCTION, NULLSTR, yylexlinenum); return(T_ENDFUNCTION);}
endgenerate                                                               {yylval = MallocTcell(T_ENDGENERATE, NULLSTR, yylexlinenum); return(T_ENDGENERATE);}
endmodule                                                                 {yylval = MallocTcell(T_ENDMODULE, NULLSTR, yylexlinenum); return(T_ENDMODULE);}
endtask                                                                   {yylval = MallocTcell(T_ENDTASK, NULLSTR, yylexlinenum); return(T_ENDTASK);}
deassign|disable|release                                                  {yylval = MallocTcell(T_DEASSIGN, NULLSTR, yylexlinenum); return(T_DEASSIGN);}
for                                                                       {yylval = MallocTcell(T_FOR, NULLSTR, yylexlinenum); return(T_FOR);}
force                                                                     {yylval = MallocTcell(T_FORCE, NULLSTR, yylexlinenum); return(T_FORCE);}
fork                                                                      {yylval = MallocTcell(T_FORK, NULLSTR, yylexlinenum); return(T_FORK);}
forever                                                                   {yylval = MallocTcell(T_FOREVER, NULLSTR, yylexlinenum); return(T_FOREVER);}
function                                                                  {yylval = MallocTcell(T_FUNCTION, NULLSTR, yylexlinenum); return(T_FUNCTION);}
generate                                                                  {yylval = MallocTcell(T_GENERATE, NULLSTR, yylexlinenum); return(T_GENERATE);}
if                                                                        {yylval = MallocTcell(T_IF, NULLSTR, yylexlinenum); return(T_IF);}
initial|always_comb                                                       {yylval = MallocTcell(T_INITIAL, NULLSTR, yylexlinenum); return(T_INITIAL);}
inout                                                                     {yylval = MallocTcell(T_INOUT, NULLSTR, yylexlinenum); return(T_INOUT);}
input                                                                     {yylval = MallocTcell(T_INPUT, NULLSTR, yylexlinenum); return(T_INPUT);}
integer|time|real|realtime                                                {yylval = MallocTcell(T_INTEGER, NULLSTR, yylexlinenum); return(T_INTEGER);}
join                                                                      {yylval = MallocTcell(T_JOIN, NULLSTR, yylexlinenum); return(T_JOIN);}
module                                                                    {yylval = MallocTcell(T_MODULE, NULLSTR, yylexlinenum); return(T_MODULE);}
nand                                                                      {yylval = MallocTcell(T_GATE_NAND, NULLSTR, yylexlinenum); return(T_GATE_NAND);}
negedge                                                                   {yylval = MallocTcell(T_NEGEDGE, NULLSTR, yylexlinenum); return(T_NEGEDGE);}
nor                                                                       {yylval = MallocTcell(T_GATE_NOR, NULLSTR, yylexlinenum); return(T_GATE_NOR);}
not                                                                       {yylval = MallocTcell(T_GATE_NOT, NULLSTR, yylexlinenum); return(T_GATE_NOT);}
or                                                                        {yylval = MallocTcell(T_GATE_OR, NULLSTR, yylexlinenum); return(T_GATE_OR);}
output                                                                    {yylval = MallocTcell(T_OUTPUT, NULLSTR, yylexlinenum); return(T_OUTPUT);}
parameter|defparam|localparam|specparam                                   {yylval = MallocTcell(T_PARAMETER, NULLSTR, yylexlinenum); return(T_PARAMETER);}
posedge                                                                   {yylval = MallocTcell(T_POSEDGE, NULLSTR, yylexlinenum); return(T_POSEDGE);}
reg|genvar|event                                                          {yylval = MallocTcell(T_REG, NULLSTR, yylexlinenum); return(T_REG);}
repeat                                                                    {yylval = MallocTcell(T_REPEAT, NULLSTR, yylexlinenum); return(T_REPEAT);}
signed                                                                    {yylval = MallocTcell(T_SIGNED, NULLSTR, yylexlinenum); return(T_SIGNED);}
task                                                                      {yylval = MallocTcell(T_TASK, NULLSTR, yylexlinenum); return(T_TASK);}
unique                                                                    {yylval = MallocTcell(T_UNIQUE, NULLSTR, yylexlinenum); return(T_UNIQUE);}
while                                                                     {yylval = MallocTcell(T_WHILE, NULLSTR, yylexlinenum); return(T_WHILE);}
wire|logic|bit|wor|wand|supply0|supply1|tri0|tri1|tri|trior|triand|trireg {yylval = MallocTcell(T_WIRE, NULLSTR, yylexlinenum); return(T_WIRE);}
xnor                                                                      {yylval = MallocTcell(T_GATE_XNOR, NULLSTR, yylexlinenum); return(T_GATE_XNOR);}
xor                                                                       {yylval = MallocTcell(T_GATE_XOR, NULLSTR, yylexlinenum); return(T_GATE_XOR);}

$time|$stime|$realtime                                                    {yylval = MallocTcell(T_TIME, NULLSTR, yylexlinenum); return(T_TIME);}
"!="|"!=="                                                                {yylval = MallocTcell(T_LOGIC_NEQ, NULLSTR, yylexlinenum); return(T_LOGIC_NEQ);}
!                                                                         {yylval = MallocTcell(T_LOGIC_NOT, NULLSTR, yylexlinenum); return(T_LOGIC_NOT);}
"&&"                                                                      {yylval = MallocTcell(T_LOGIC_AND, NULLSTR, yylexlinenum); return(T_LOGIC_AND);}
&                                                                         {yylval = MallocTcell(T_AND, NULLSTR, yylexlinenum); return(T_AND);}
"~&"                                                                      {yylval = MallocTcell(T_NAND, NULLSTR, yylexlinenum); return(T_NAND);}
"||"                                                                      {yylval = MallocTcell(T_LOGIC_OR, NULLSTR, yylexlinenum); return(T_LOGIC_OR);}
"|"                                                                       {yylval = MallocTcell(T_OR, NULLSTR, yylexlinenum); return(T_OR);}
"~|"                                                                      {yylval = MallocTcell(T_NOR, NULLSTR, yylexlinenum); return(T_NOR);}
~                                                                         {yylval = MallocTcell(T_NOT, NULLSTR, yylexlinenum); return(T_NOT);}
"^"                                                                       {yylval = MallocTcell(T_XOR, NULLSTR, yylexlinenum); return(T_XOR);}
"~^"                                                                      {yylval = MallocTcell(T_XNOR, NULLSTR, yylexlinenum); return(T_XNOR);}
"<<"|"<<<"                                                                {yylval = MallocTcell(T_LSHIFT, NULLSTR, yylexlinenum); return(T_LSHIFT);}
"<="                                                                      {yylval = MallocTcell(T_GE, NULLSTR, yylexlinenum); return(T_GE);}
"<"                                                                       {yylval = MallocTcell(T_GT, NULLSTR, yylexlinenum); return(T_GT);}
">>"|">>>"                                                                {yylval = MallocTcell(T_RSHIFT, NULLSTR, yylexlinenum); return(T_RSHIFT);}
">="                                                                      {yylval = MallocTcell(T_LE, NULLSTR, yylexlinenum); return(T_LE);}
">"                                                                       {yylval = MallocTcell(T_LS, NULLSTR, yylexlinenum); return(T_LS);}
"=="|"==="                                                                {yylval = MallocTcell(T_LOGIC_EQ, NULLSTR, yylexlinenum); return(T_LOGIC_EQ);}
=                                                                         {yylval = MallocTcell(T_EQ, NULLSTR, yylexlinenum); return(T_EQ);}
"+"|"+:"                                                                  {yylval = MallocTcell(T_PLUS, NULLSTR, yylexlinenum); return(T_PLUS);}
"-"|"-:"                                                                  {yylval = MallocTcell(T_MINUS, NULLSTR, yylexlinenum); return(T_MINUS);}
"/"                                                                       {yylval = MallocTcell(T_DIV, NULLSTR, yylexlinenum); return(T_DIV);}
"**"                                                                      {yylval = MallocTcell(T_EXP, NULLSTR, yylexlinenum); return(T_EXP);}
"*"                                                                       {yylval = MallocTcell(T_MULT, NULLSTR, yylexlinenum); return(T_MULT);}
"%"                                                                       {yylval = MallocTcell(T_MOD, NULLSTR, yylexlinenum); return(T_MOD);}
"("                                                                       {yylval = MallocTcell(T_LPARENTESIS, NULLSTR, yylexlinenum); return(T_LPARENTESIS);}
")"                                                                       {yylval = MallocTcell(T_RPARENTESIS, NULLSTR, yylexlinenum); return(T_RPARENTESIS);}
"["                                                                       {yylval = MallocTcell(T_LBRAKET, NULLSTR, yylexlinenum); return(T_LBRAKET);}
"]"                                                                       {yylval = MallocTcell(T_RBRAKET, NULLSTR, yylexlinenum); return(T_RBRAKET);}
"{"                                                                       {yylval = MallocTcell(T_LBRACE, NULLSTR, yylexlinenum); return(T_LBRACE);}
"}"                                                                       {yylval = MallocTcell(T_RBRACE, NULLSTR, yylexlinenum); return(T_RBRACE);}
;                                                                         {yylval = MallocTcell(T_SEMICOLON, NULLSTR, yylexlinenum); return(T_SEMICOLON);}
:                                                                         {yylval = MallocTcell(T_COLON, NULLSTR, yylexlinenum); return(T_COLON);}
,                                                                         {yylval = MallocTcell(T_COMMA, NULLSTR, yylexlinenum); return(T_COMMA);}
"."                                                                       {yylval = MallocTcell(T_DOT, NULLSTR, yylexlinenum); return(T_DOT);}
"?"                                                                       {yylval = MallocTcell(T_SELECT, NULLSTR, yylexlinenum); return(T_SELECT);}
"@"                                                                       {yylval = MallocTcell(T_AT, NULLSTR, yylexlinenum); return(T_AT);}
#                                                                         {yylval = MallocTcell(T_GENERIC, NULLSTR, yylexlinenum); return(T_GENERIC);}
#`                                                                        {yylval = MallocTcell(T_GENERIC_ID, NULLSTR, yylexlinenum); return(T_GENERIC_ID);}
->                                                                        {yylval = MallocTcell(T_ARROW, NULLSTR, yylexlinenum); return(T_ARROW);}

[A-Za-z_][A-Za-z0-9_"$"]*                                                 {yylval = MallocTcell(T_ID, yytext, yylexlinenum); return(T_ID);}
"\""[^\n]*"\""                                                            {yylval = MallocTcell(T_SENTENCE, yytext, yylexlinenum); return(T_SENTENCE);}

[0-9.]+                                                                   {yylval = MallocTcell(T_NATDIGIT, yytext, yylexlinenum); return(T_NATDIGIT);}

'b[0-1XxZz?_]+                                                            {yylval = MallocTcell(T_BINDIGIT, yytext, yylexlinenum); return(T_BINDIGIT);}
'o[0-7]+                                                                  {yylval = MallocTcell(T_OCTDIGIT, yytext, yylexlinenum); return(T_OCTDIGIT);}
'd[0-9]+                                                                  {yylval = MallocTcell(T_DECDIGIT, yytext, yylexlinenum); return(T_DECDIGIT);}
'h[A-Fa-fXxZz0-9?_]+                                                      {yylval = MallocTcell(T_HEXDIGIT, yytext, yylexlinenum); return(T_HEXDIGIT);}

[0-9]+'b[0-1XxZz?_]+                                                      {yylval = MallocTcell(T_WIDTH_BINDIGIT, yytext, yylexlinenum); return(T_WIDTH_BINDIGIT);}
[0-9]+'o[0-7_]+                                                           {yylval = MallocTcell(T_WIDTH_OCTDIGIT, yytext, yylexlinenum); return(T_WIDTH_OCTDIGIT);}
[0-9]+'d[0-9_]+                                                           {yylval = MallocTcell(T_WIDTH_DECDIGIT, yytext, yylexlinenum); return(T_WIDTH_DECDIGIT);}
[0-9]+'h[A-Fa-fXxZz0-9?_]+                                                {yylval = MallocTcell(T_WIDTH_HEXDIGIT, yytext, yylexlinenum); return(T_WIDTH_HEXDIGIT);}

[A-Za-z_][A-Za-z0-9_"$"]+'b[0-1XxZz?_]+                                   {yylval = MallocTcell(T_PARAMETER_BINDIGIT, yytext, yylexlinenum); return(T_PARAMETER_BINDIGIT);}
[A-Za-z_][A-Za-z0-9_"$"]+'o[0-7_]+                                        {yylval = MallocTcell(T_PARAMETER_OCTDIGIT, yytext, yylexlinenum); return(T_PARAMETER_OCTDIGIT);}
[A-Za-z_][A-Za-z0-9_"$"]+'d[0-9_]+                                        {yylval = MallocTcell(T_PARAMETER_DECDIGIT, yytext, yylexlinenum); return(T_PARAMETER_DECDIGIT);}
[A-Za-z_][A-Za-z0-9_"$"]+'h[A-Fa-fXxZz0-9?_]+                             {yylval = MallocTcell(T_PARAMETER_HEXDIGIT, yytext, yylexlinenum); return(T_PARAMETER_HEXDIGIT);}

[0-9]+'b`[A-Za-z_][A-Za-z0-9_"$"]+                                        {yylval = MallocTcell(T_GENERIC_BINDIGIT, yytext, yylexlinenum); return(T_GENERIC_BINDIGIT);}
[0-9]+'o`[A-Za-z_][A-Za-z0-9_"$"]+                                        {yylval = MallocTcell(T_GENERIC_OCTDIGIT, yytext, yylexlinenum); return(T_GENERIC_OCTDIGIT);}
[0-9]+'d`[A-Za-z_][A-Za-z0-9_"$"]+                                        {yylval = MallocTcell(T_GENERIC_DECDIGIT, yytext, yylexlinenum); return(T_GENERIC_DECDIGIT);}
[0-9]+'h`[A-Za-z_][A-Za-z0-9_"$"]+                                        {yylval = MallocTcell(T_GENERIC_HEXDIGIT, yytext, yylexlinenum); return(T_GENERIC_HEXDIGIT);}

%%
// end of file
