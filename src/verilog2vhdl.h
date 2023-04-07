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
 *   Francisco Javier Reina Campo <pacoreinacampo@queenfield.tech>
 */

#ifndef V2VHD_H

//////////////////////////////////////////////////////////////////////
// Change below if necessary
//////////////////////////////////////////////////////////////////////

//#define WINDOWS
#define UNIX

// signal name prefix/suffix
#define REFOUTSIG_SUFFIX   "_OUTREF"  // reffered output signal
#define UNDERSCORE_PREFIX  "V2V"      // if underscore is used
#define UNDERSCORE_SUFFIX  "V2V"      // if undersocre is used
#define FUNCRET_SUFFIX     "_return"  // function return variable

//////////////////////////////////////////////////////////////////////
// Warning messages
//////////////////////////////////////////////////////////////////////

#define  WARN_0_CMPDEC    "0\0Please modify the following component declaration manually."
#define  WARN_1_STDLGC    "1\0Please change the following 'std_logic_vector' to 'std_logic', if necessary."
#define  WARN_2_FUNCRET   "2\0Please write signal width of the following return-variable, manually."
#define  WARN_3_PROCPAR   "3\0Please insert a word 'signal' into the above I/O decralations, if necessary."
#define  WARN_4_TYPEDEF   "4\0Please write a new array-type definition for the following signal, manually."
#define  WARN_5_SIGWIDTH  "5\0Please write a signal width part in the following sentence, manually."
#define  WARN_6_BLKSUBST  "6\0Please replace the above non-blocking substitution ('<=') to blocking one (':='), if necessary."
#define  WARN_7_SHIFT     "7\0Please modify the following shift operation, if necessary. (Some VHDL tools don't support srl/sll.)"
#define  WARN_8_REDUCT    "8\0Please convert the following reduction operation, manually."
#define  WARN_9_CONCAT    "9\0Please convert the following concatination, manually. (Possibly 'others' statement can be used.)"

//////////////////////////////////////////////////////////////////////
// Type/Constant declarations
//////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include <math.h>

#define TITLE "verilog2vhdl - QueenField\n"

typedef enum {
  True, False
} Boolean;

#define NULLSTR (char *)NULL

// TOKEN cell
typedef struct _tree_cell {
  int    linenum;    // line number in source code
  int    typ;        // token type
  char  *str;        // ID/digit value
  int    *siglist;   // signal list
  int    *complist;  // type list
  struct _tree_cell  *next;
  struct _tree_cell  *info0;
  struct _tree_cell  *info1;
  struct _tree_cell  *info2;
  struct _tree_cell  *info3;
  struct _tree_cell  *info4;
  struct _tree_cell  *info5;
} TREECELL;

typedef TREECELL  *TCELLPNT;

#define  NULLCELL      (TREECELL *)NULL
#define  CellLine(x)   ((x)->linenum)
#define  CellType(x)   ((x)->typ)
#define  CellStr(x)    ((x)->str)
#define  NextCell(x)   ((x)->next)
#define  CellInfo0(x)  ((x)->info0)
#define  CellInfo1(x)  ((x)->info1)
#define  CellInfo2(x)  ((x)->info2)
#define  CellInfo3(x)  ((x)->info3)
#define  CellInfo4(x)  ((x)->info4)
#define  CellInfo5(x)  ((x)->info5)
#define  CellSig(x)    ((SIGLIST *)((x)->siglist))
#define  CellCmp(x)    ((COMPONENTLIST *)((x)->complist))

#define  SetType(d,s)   (d)->typ      = (s);
#define  SetLine(d,s)   (d)->linenum  = (s);
#define  SetNext(d,s)   (d)->next     = (s);
#define  SetInfo0(d,s)  (d)->info0    = (s);
#define  SetInfo1(d,s)  (d)->info1    = (s);
#define  SetInfo2(d,s)  (d)->info2    = (s);
#define  SetInfo3(d,s)  (d)->info3    = (s);
#define  SetInfo4(d,s)  (d)->info4    = (s);
#define  SetInfo5(d,s)  (d)->info5    = (s);
#define  SetSig(d,s)    (d)->siglist  = (int *)(s);
#define  SetCmp(d,c)    (d)->complist = (int *)(c);

// Signal list
typedef struct _signal_list  {
  char      *str;     // signal name
  TCELLPNT  typ;      // signal type (width,dir)
  Boolean   issig;    // internal reg/wire or I/O port
  Boolean   isinp;    // input flag
  Boolean   isout;    // output flag
  Boolean   refer;    // if this signal is referred in module or not
  struct _signal_list  *next;
} SIGLIST;

#define  NULLSIG        (SIGLIST *)NULL
#define  SigStr(x)      ((x)->str)
#define  SigType(x)     ((x)->typ)
#define  SigIsSig(x)    ((x)->issig)
#define  SigIsInp(x)    ((x)->isinp)
#define  SigIsOut(x)    ((x)->isout)
#define  SigRefer(x)    ((x)->refer)
#define  NextSig(x)     ((x)->next)

// Component list
typedef struct _component_list  {
  char      *str;  // component name
  TCELLPNT  tree;  // poiter to portmap body
  struct _component_list  *next;
} COMPONENTLIST;

#define  NULLCMP       (COMPONENTLIST *)NULL
#define  CmpStr(x)     ((x)->str)
#define  CmpTree(x)    ((x)->tree)
#define  NextCmp(x)    ((x)->next)

// Comment list
typedef struct _comment_list {
  int      linenum;  // comment line number
  char     *str;     // string
  Boolean  printed;  // flag to indicate the comment is already printed or not
  struct _comment_list  *next;
} COMMENTLIST;

#define  CommentLine(x)  ((x)->linenum)
#define  CommentStr(x)   ((x)->str)
#define  CommentPrn(x)   ((x)->printed)
#define  NextComment(x)  ((x)->next)

// (for PASS2) Output line list
typedef struct _line_list {
  char     *str;     // line string
  char     typ;      // region code
  Boolean  printed;  // flag to indicate the line is already printed or not
  struct _line_list  *next;
} LINELIST;

#define  LineStr(x)    ((x)->str)
#define  LineType(x)   ((x)->typ)
#define  LinePrn(x)    ((x)->printed)
#define  NextLine(x)   ((x)->next)

#define  REGION_MARK  "$$$$$$$$$$$$$$$$$$$$\n"
#define  REGION_HEAD  'H'
#define  REGION_IO    'I'
#define  REGION_SEP   'S'
#define  REGION_DEF   'D'
#define  REGION_BODY  'B'

//////////////////////////////////////////////////////////////////////
// variable/function declarations
//////////////////////////////////////////////////////////////////////

// for lex
extern FILE     *yyin, *yyout;
extern int      yylex();
extern void     yyrestart(FILE *);
extern int      yylex_linenum;

// for parser
#define YYSTYPE TCELLPNT
#include "verilogparse.tab.h"  // this sentence must be after the above definition of YYSTYPE
extern int      yyparse();
extern int      yylexlinenum;
extern void     yyerror(char *);

// for debug
#define YYDEBUG 0

// global variables
extern int            Sysid;              // system internal counter value
extern COMMENTLIST    *CommentListTop;    // comment list
extern SIGLIST        *SigListTop;        // signal list
extern COMPONENTLIST  *ComponentListTop;  // component list
extern LINELIST       *LineListTop;       // output line list
extern TCELLPNT       ParseTreeTop;       // parse tree
extern Boolean        ParseError;         // parse flag

// prototype
extern TCELLPNT  MallocTcell(int, char *, int);
extern TCELLPNT  CopyTcell(TCELLPNT);
extern TCELLPNT  CopyTree(TCELLPNT);
extern void      FreeTcell(TCELLPNT);
extern void      FreeTree(TCELLPNT);

extern SIGLIST        *MakeNewSigList(void);
extern void           FreeSigList(SIGLIST *);
extern Boolean        RegisterSignal(SIGLIST *, TCELLPNT, Boolean, Boolean, Boolean);
extern SIGLIST        *SearchSignal(SIGLIST *, char *);
extern COMPONENTLIST  *MakeNewComponentList(void);
extern void           FreeComponentList(COMPONENTLIST *);
extern void           RegisterComponent(COMPONENTLIST *, TCELLPNT);
extern COMMENTLIST    *MakeNewCommentList(void);
extern void           FreeCommentList(COMMENTLIST *);
extern void           RegisterComment(COMMENTLIST *, char *, int *);
extern LINELIST       *MakeNewLineList(void);
extern void           FreeLineList(LINELIST *);
extern void           RegisterLine(LINELIST *, char *, char);

extern Boolean   IsOutput(SIGLIST *, char *);
extern void      ConvertCondexp2If(TCELLPNT, int, TCELLPNT);
extern void      ConvertParen2Dummy(TCELLPNT);
extern Boolean   UsedSignalinIfCond(TCELLPNT, TCELLPNT);
extern void      ConvertExplist2Substlist(TCELLPNT top);
extern int       EvalExpWidth(TCELLPNT);
extern Boolean   EvalExpValue(TCELLPNT, int *);
extern void      ChkEvalOutput(TCELLPNT, SIGLIST *);

extern Boolean   fprintfLine(FILE *, LINELIST *, char);
extern void      fprintfError(char *, int);

#define V2VHD_H
#endif

// end of file
