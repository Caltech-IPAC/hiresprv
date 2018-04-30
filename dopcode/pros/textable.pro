;
;+
; NAME:
;       TEXTABLE
; PURPOSE:
;       Returns a translation table from TeX to IDL.
; CATEGORY:
;       text/strings
; CALLING SEQUENCE:
;       table = textable()
; INPUTS:
;       None
; KEYWORD PARAMETERS:
;       /POSTSCRIPT -- If set, return postscript translation
;                      table rather than vector fonts table.
;                      Default is translations for vector
;                      fonts.
;       /HELP       -- Print help and exit.
; OUTPUTS:
;       table -- a 2D text array.  table(0,*) contains          out
;                the words to be translated away, table(1,*)
;                contains the words to translate them to.   
; COMMON BLOCKS:
; SIDE EFFECTS:
; NOTES:
;       To find out what TeX sequences are available, look at
;       table(0,*).
; EXAMPLE:
; LIBRARY FUNCTIONS CALLED:
;        
; MODIFICATION HISTORY:
;       $Id: textable.pro,v 1.4 1996/05/09 00:22:17 mcraig Exp $
;       $Log: textable.pro,v $
;       Revision 1.4  1996/05/09 00:22:17  mcraig
;       Added command to return to previous font after switching to Greek or
;       symbol font.
;
;       Revision 1.3  1996/02/08 19:49:35  mcraig
;       Removed control sequence \perp because the postscript code for it is '^'.
;
;       Revision 1.2  1996/02/08 18:53:38  mcraig
;       Added translations for PostScript fonts, and added several new TeX
;       control sequences.
;
;       Revision 1.1  1996/01/31 18:47:37  mcraig
;       Initial revision
;
; RELEASE:
;       $Name: test4 $
;
; COPYRIGHT:
;  This software is Copyright (C) 1996 by Matthew Craig.  It may be freely
;  used, copied and redistributed, as long as there is no fee charged
;  for it and this copyright notice is kept in each copy made.  It may also be
;  modified, but if modified it may not be distributed further unless
;  the name of the routine is changed and it is made clear that I did
;  not make the modifications.  This software is provided as is, without any
;  warranties, expressed or implied.  
;-
;
FUNCTION textable, POSTSCRIPT=ps, VECTOR=vec,  HELP=Help

; Return to caller if error.
    On_error, 2

; Print help if necessary.
    IF keyword_set(Help)  THEN BEGIN
        offset = '   '
        print, offset+'Returns a translation table from TeX to IDL.'
        print, offset+'table = textable()'
        print, offset+'Keywords:'
        print, offset+offset+'/POSTSCRIPT -- If set, return postscript translation'
        print, offset+offset+'               table rather than vector fonts table.'
        print, offset+offset+'               Default is translations for vector'
        print, offset+offset+'               fonts.'
        print, offset+offset+'/HELP       -- Print help and exit.'
        print, offset+'Outputs:'
        print, offset+offset+'table -- a 2D text array.  table(0,*) contains          out'
        print, offset+offset+'         the words to be translated away, table(1,*)'
        print, offset+offset+'         contains the words to translate them to.'
        print, offset+'Notes:'
        print, offset+offset+'To find out what TeX sequences are available, look at'
        print, offset+offset+'table(0,*).'
    ENDIF 

    VECFONT=1                   ; index of vector font in translation table
    PSFONT=2			; index of postscript font in trans table
    IF keyword_set(ps) THEN FontSelection=PSFONT ELSE FontSelection=VECFONT

;  Set IDL font sequence needed to switch to Greek letters.
    GreekFont = strarr(3)
    GreekFont(VECFONT) = '!7'
    GreekFont(PSFONT) = '!M'

;  Set IDL font sequence needed to switch to special symbol font.
    SymbolFont = strarr(3)
    SymbolFont(VECFONT) = '!M'
    SymbolFont(PSFONT) = '!M'

;  Set IDL font sequence needed to switch back to initial font.
    PreviousFont = strarr(3)
    PreviousFont(VECFONT) = '!X'
    PreviousFont(PSFONT) = '!X'

;lowercase Greek 
;;        TeX SEQUENCE       VECTOR       POSTSCRIPT
    LowercaseGreek = [$
	[ '\alpha',     	'a'     ,     'a'     ],$
	[ '\beta',      	'b'     ,     'b'     ],$
	[ '\gamma',     	'c'     ,     'g'     ],$
	[ '\delta',     	'd'     ,     'd'     ],$
	[ '\epsilon',   	'e'     ,     'e'     ],$
	[ '\zeta',      	'f'     ,     'z'     ],$
	[ '\eta', 		'g'	,     'h'     ],$
	[ '\theta', 		'h'	,     'q'     ],$
	[ '\iota', 		'i'	,     'i'     ],$
	[ '\kappa', 		'j'	,     'k'     ],$
	[ '\lambda', 		'k'	,     'l'     ],$
	[ '\mu', 		'l'	,     'm'     ],$
	[ '\nu', 		'm'	,     'n'     ],$
	[ '\xi', 		'n'	,  '!S !Rx'   ],$
	[ '\pi', 		'p'	,     'p'     ],$
	[ '\rho', 		'q'	,     'r'     ],$
	[ '\sigma', 		'r'	,     's'     ],$
	[ '\tau', 		's'	,     't'     ],$
	[ '\upsilon', 		't'	,     'u'     ],$
	[ '\phi', 		'u'	,     'f'     ],$
	[ '\chi', 		'v'	,     'c'     ],$
	[ '\psi', 		'w'	,     'y'     ],$
	[ '\omega', 		'x'	,     'w'     ],$
	[ '\varpi', 		'p'	,     'v'     ],$
	[ '\varepsilon', 	'e'     ,     'e'     ],$
	[ '\varphi', 		'u'	,     'j'     ]$
	                     ]
;Uppercase Greek -- 
;;        TeX SEQUENCE        VECTOR          POSTSCRIPT
    UppercaseGreek = [$
	[ '\Gamma', 		'C'   ,	        'G'         ],$
	[ '\Delta', 		'D'   ,	        'D'         ],$
	[ '\Theta', 		'H'   ,	        'Q'         ],$
	[ '\Lambda', 		'K'   ,	        'L'         ],$
	[ '\Xi', 		'N'   ,      '!S !RX'       ],$
	[ '\Pi', 		'P'   ,	        'P'         ],$
	[ '\Sigma', 		'R'   ,	        'S'         ],$
	[ '\Upsilon', 		'T'   ,  string(byte(161))  ],$
	[ '\Phi', 		'U'   ,	        'F'         ],$
	[ '\Psi', 		'W'   ,	        'Y'         ],$
	[ '\Omega', 		'X'   ,	        'W'         ]$
			   ]
;Special symbols -- 
;  NOTES -- You must leave \infty before \in in the translatation
;           table to avoid having the \in part of \infty translated
;           away. 
;           
;           DO NOT blindly add the control sequence \perp.  Its
;           PostScript code is '^', which leads to thing being
;           interpreted as superscripts which shouldn't be.
;
;;        TeX SEQUENCE        VECTOR          POSTSCRIPT
    Symbols = [$
	[ '\aleph', 		'@'   ,	 string(byte(192))  ],$
	[ '\ast', 		'*'   ,	        '*'         ],$
	[ '\cap', 		'3'   ,	 string(byte(199))  ],$
	[ '\cdot', 		'.'   ,	 string(byte(215))  ],$
	[ '\cup', 		'1'   ,	 string(byte(200))  ],$
	[ '\exists', 		'E'   ,	        '$'         ],$
	[ '\infty', 		'$'   ,	 string(byte(165))  ],$
	[ '\in', 		'e'   ,	 string(byte(206))  ],$
	[ '\equiv', 		':'   ,	 string(byte(186))  ],$
	[ '\pm', 		'+'   ,	 string(byte(177))  ],$
	[ '\div', 		'/'   ,	 string(byte(184))  ],$
	[ '\subset', 		'0'   ,	 string(byte(204))  ],$
	[ '\superset', 		'2'   ,	 string(byte(201))  ],$
	[ '\leftarrow', 	'4'   ,	 string(byte(172))  ],$
	[ '\downarrow', 	'5'   ,	 string(byte(175))  ],$
	[ '\rightarrow', 	'6'   ,	 string(byte(174))  ],$
	[ '\uparrow', 		'7'   ,	 string(byte(173))  ],$
	[ '\neq', 		'='   ,	 string(byte(185))  ],$
	[ '\propto', 		'?'   ,	 string(byte(181))  ],$
	[ '\sim', 		'A'   ,	 string(byte(126))  ],$
	[ '\partial', 		'D'   ,	 string(byte(182))  ],$
	[ '\nabla', 		'G'   ,	 string(byte(209))  ],$
	[ '\angle', 		'a'   ,	 string(byte(208))  ],$
	[ '\times', 		'X'   ,	 string(byte(180))  ],$
	[ '\geq', 		'b'   ,	 string(byte(179))  ],$
	[ '\leq', 		'l'   ,	 string(byte(163))  ],$
	[ "\'", 		"'"   ,	 string(byte(162))  ],$
	[ '\prime', 		"'"   ,	 string(byte(162))  ]$
	                  ]
    LowercaseGreek(1,*) = $
      GreekFont(FontSelection) $
      + LowercaseGreek(FontSelection,*) $
      + PreviousFont(FontSelection)
    UppercaseGreek(1,*) = $
      GreekFont(FontSelection) +$
      UppercaseGreek(FontSelection,*) $
      + PreviousFont(FontSelection)
    Symbols(1,*) = $
      SymbolFont(FontSelection) $
      + Symbols(FontSelection,*) $
      + PreviousFont(FontSelection)

    TranslationTable = [[LowercaseGreek],[UppercaseGreek],[Symbols]]
    return,TranslationTable(0:1,*)

END 

