;+
;
; SAVE_DIAG, FILENAME  [, /DATA, /KEYWORDS, /VARIABLES, /SYMBOLS ]
;
;  Read and understand the contents of an IDL SAVE file from IDL.
;
;  This is just a toy program at the moment, meant to show that SAVE
;  files can be read and picked apart programmatically.  It's not
;  fully documented since it's just a prototype.  However, with the
;  concepts here, and what we know now about ROUTINE_NAMES(), a
;  full-on clone to SAVE and RESTORE could be developed.
;
;  This program understands and prints IDL variables, but also saved
;  procedures and functions.
;
;  It will crash on structure types.
;
;  FILENAME - name of IDL save file.  IDL 4 and 5 files are
;             recognized.  Probably not compressed though.
;
;  DATA - set this keyword to print (a sample of) the saved data
;         values.
;
;  KEYWORDS - set this keyword to print the keyword arguements to
;             saved procedures or functions
;
;  VARIABLES - set this keyword to print the variables of saved
;              procedures or functions
;
;  SYMBOLS - set this keyword to print the symbol table of saved
;            procedures or functions
;-
; Copyright (C) 2000, Craig Markwardt
; This software is provided as is without any warranty whatsoever.
; Permission to use, copy, modify, and distribute modified or
; unmodified copies is granted, provided this copyright and disclaimer
; are included unchanged.
;-


forward_function save_diag_read_long, save_diag_read_string, $
  save_diag_read_arrdesc, save_diag_read_strdesc, save_diag_read_compldesc, $
  save_diag_read_type, save_diag_make_var

function save_diag_read_long, unit, n
  if n_elements(n) EQ 0 then value = 0L $
  else value = lonarr(floor(n(0)) > 1)
  readu, unit, value
  ieee_to_host, value
  return, value
end

function save_diag_read_string, unit
  ;; STRING_DATA
  ;;   00-03 : LONG - string length in characters
  ;;   04-NN : BYTExN - string characters, padded to next four-byte boundary

  namelen = save_diag_read_long(unit)
  if namelen LE 0 then return, ''
  name = bytarr(long(floor((namelen+3)/4)*4))
  readu, unit, name
  return, string(name(0:namelen-1))
end

function save_diag_read_arrdesc, unit
  ;; ARRAY_DESC
  ;;   LONG - value 08 - array descriptor flag
  ;;   LONG - unknown (value 2)
  ;;   LONG - number of bytes in value
  ;;   LONG - number of elements in value
  ;;   LONG - number of variable dimensions
  ;;   LONG - maximum number of stored dimensions ( = 8 )
  ;;   LONGx8 - dimensions of number
  buff = save_diag_read_long(unit, 16)
  if buff(0) NE 8 then begin
      message, 'ERROR: invalid array descriptor'
      return, 0
  endif

  ndims = buff(4)
  nelt = buff(3)
  dims = buff(8:8+ndims-1)
  vartype = 0

  return, [ndims, dims, vartype, nelt]

end

function save_diag_read_strdesc, unit
  ;; STRUCT_DESCR
  ;;   LONG - START_TOKEN - value 9
  ;;   STRING_DATA - name of struct (or 0 if anonymous)
  ;;   LONG - value 0
  ;;   LONG - N_TAGS - number of structure tags
  ;;   LONG - total "length" in bytes, but nothing meaningful
  ;;   TAG_DESCRxN_TAGS - TAG_TABLE - description of each tag
  ;;   STRING_DATAxN_TAGS - TAG_NAMES - name of each tag
  ;;   <x>_DESCRxN_COMPLEX_TAGS - descriptors for each "complex" tag

  start_token = save_diag_read_long(unit)
  if start_token NE 9 then begin
      message, 'ERROR: invalid structure descriptor'
      return, 0
  endif
  struct_name = save_diag_read_string(unit)
  buff = save_diag_read_long(unit, 3)

  n_tags = buff(1)
  if n_tags LE 0 then begin
      message, 'ERROR: number of structure tags was LE 0'
      return, 0
  endif
  tag_table = save_diag_read_long(unit, 3*n_tags)
  tag_table = reform(tag_table, 3, n_tags, /overwrite)
  tag_names1 = strarr(n_tags)
  for i = 0L, n_tags-1 do begin
      tag_names1(i) = save_diag_read_string(unit)
  endfor

  ssz = lonarr(4,n_tags)
  for i = 0L, n_tags-1 do begin
      if tag_table(2,i) NE 0 then begin
          sz = save_diag_read_arrdesc(unit)
      endif else begin
          sz = [0L, 0, 1L]
      endelse
      sz(sz(0)+1) = tag_table(1,i)
      ssz(0,i) = sz
  endfor

  for i = 0L, n_tags-1 do begin
      sz = reform(ssz(*,i))
      if (tag_table(2,i) AND '20'x) NE 0 then $
        tp = save_diag_read_strdesc(unit) $
      else $
        tp = save_diag_make_var(size=sz)
      
      if (tag_table(2,i) AND '14'x) NE 0 then begin
          ndims = sz(0)
          nelt = sz(ndims+2)
          dims = sz(1:ndims)
          tp = replicate(tp, nelt)
          tp = reform(tp, dims, /overwrite)
      endif

      if n_elements(ss) EQ 0 then $
        ss = create_struct(tag_names1(i), tp) $
      else $
        ss = create_struct(ss, tag_names1(i), tp)
  endfor
  if struct_name NE '' then ss = create_struct(ss, name=struct_name)
  
  return, ss
end

function save_diag_read_type, unit, template=template
  ;; SCALAR_TYPE
  ;;   00-03 : LONG - variable type (IDL type code)
  ;;   04-07 : LONG - value 0

  ;; ARRAY_TYPE
  ;;   00-03 : LONG - variable type (IDL type code)
  ;;   04-07 : LONG - values 0x14 (or 0x34 for struct)
  ;;   ARRAY_DESC
  ;;   STRUCT_DESC (if a structure)
  vartype = save_diag_read_long(unit)

  arrtype = save_diag_read_long(unit)
  ;; Scalar
  if arrtype(0) EQ 0 then return, [0L, vartype, 1] 

  ;; Complex array type
  struct = (arrtype(0) AND '20'x) NE 0
  if arrtype(0) NE 0 then begin
      sz = save_diag_read_arrdesc(unit)
      if keyword_set(struct) then $
        template = save_diag_read_strdesc(unit)
  endif
  sz(sz(0)+1) = vartype

  return, sz
end

function save_diag_make_var, size=size, status=status, template=template
  status = 0
  sz = size
  expr = ''
  forward_function complex, dcomplex, uint, ulong, long64, ulong64
  case sz(sz(0)+1) of 
      ;; 0 - undefined
      1:  data = byte(0)
      2:  data = fix(0)
      3:  data = long(0)
      4:  data = 0.
      5:  data = 0D
      6:  data = complex(0,0)
      7:  data = ''
      8:  data = template
      9:  data = dcomplex(0,0)
      ;; 10 - pointer
      ;; 11 - object
      12: data = uint(0)
      13: data = ulong(0)
      14: data = long64(0)
      15: data = ulong64(0)
      else: return, 0
  end
  status = 1
  return, data
end

pro save_diag_read_version, unit, data
  ;; VERSION_STAMP
  ;;   00-03 : LONG - Major version number
  ;;   STRING_DATA - Host architecture ( = !version.arch )
  ;;   STRING_DATA - Host OS ( = !version.os )
  ;;   STRING_DATA - IDL release ( = !version.release )

  major_version = save_diag_read_long(unit)
  arch = save_diag_read_string(unit)
  os = save_diag_read_string(unit)
  release = save_diag_read_string(unit)

  data = {arch:arch, os:os, release:release, major_release:major_version}
end

function save_diag_read_struct, unit, template
  tn = tag_names(template)
  nt = n_elements(tn)
  data = template
  for i = 0, nt-1 do begin
      sz = size(data.(i))
      save_diag_read_data, unit, d, sz, template=data.(i)(0)
      data.(i)(*) = d(*)
  endfor
  return, data
end

pro save_diag_read_data, unit, data, sz, template=template, start=start
  ;; VAR_DATA
  ;;   LONG - START_DATA TOKEN - value 7
  ;;   for bytes - consecutive bytes
  ;;   for (u)ints - upcast to type long 
  ;;   for (u)longs - consecutive longs
  ;;   for pointers - consecutive longs, indices into saved heap data
  ;;   for strings - consecutive STRING_DATA's
  if keyword_set(start) then begin
      start_token = save_diag_read_long(unit)
      if start_token NE 7 then begin
          message, 'ERROR: corrupted data', /info
          return
      endif
  endif
  tp = sz(sz(0)+1)
  if (tp EQ 11) then return
  nelt = sz(sz(0)+2)
  if (tp EQ 10) then sz(sz(0)+1) = 3  ;; Pointer type -> LONG

  if (tp EQ 8) then begin   ;; Structure type
      data = replicate(template, nelt)
;      print, 'in - nelt = ', nelt
      for i = 0L, nelt-1 do begin
          data(i) = save_diag_read_struct(unit, template)
      endfor
;      print, 'out - nelt = ', nelt
      data = reform(data, sz(1:sz(0)), /overwrite)
      return
  endif

  if sz(0) EQ 0 then begin  ;; Scalar type
      status = 0
      data = save_diag_make_var(size=sz, status=status)
      if status EQ 0 then return
  endif else begin          ;; Array type
      data = make_array(size=sz)
  endelse

  if tp EQ 7 then begin     ;; String type
      for i = 0L, nelt-1 do begin
          dummy = save_diag_read_long(unit)
          data(i) = save_diag_read_string(unit)
      endfor
      return
  endif
  indata = data
  if (tp EQ 2) then indata = long(data)
  if (tp EQ 12) then indata = ulong(data)
  if (tp EQ 6) OR (tp EQ 9) then nelt = nelt * 2
  if (tp EQ 6) then indata = fltarr(nelt)
  if (tp EQ 9) then indata = dblarr(nelt)
  readu, unit, indata
  ieee_to_host, indata
  if (tp EQ 6) OR (tp EQ 9) then begin
      if (tp EQ 6) then data(0) = complex(temporary(indata),0,nelt/2)
      if (tp EQ 9) then data(0) = dcomplex(temporary(indata),0,nelt/2)
  endif else begin
      data(0) = temporary(indata)
  endelse

  return
end

pro save_diag_read_sym, unit, sym, vals

  ;; SYM_ENTRY
  ;;  STRING_DATA - symbol name
  ;;  LONG - common number (index into common list, 0 for local)
  ;;  LONG - index (?)
  ;;  LONG - sequential index in namespace (?)
  sym = save_diag_read_string(unit)
  vals = save_diag_read_long(unit, 3)

  return
end


pro save_diag_print_binary, bbuffer
  ;; Print binary data in a pleasing format
  n = n_elements(bbuffer)
  buffer = long(bbuffer, 0, n/4)
  ieee_to_host, buffer
  n = n / 4
  for i = 0L, n-1 do begin
      if (i MOD 4) EQ 0 then begin
          line = [bbuffer(i*4:(i+1)*4-1)]
          print, '        ', format='(A,$)'
      endif else begin
          line = [line, bbuffer(i*4:(i+1)*4-1)]
      endelse
      print, buffer(i), format='(Z8.8," ",$)'
      if ((i+1) MOD 4) EQ 0 OR i EQ n-1 then begin
          nleft = (4 - ((i+1) MOD 4)) MOD 4
          if nleft GT 0 then line = [line, bytarr(4*nleft)]
          for j = 0, nleft-1 do print, '         ', format='(A,$)'
          line = (line AND '7f'xb) < '7e'xb
          wh = where(line LT 32b, ct)
          if ct GT 0 then line(wh) = byte('.')
          print, '    >'+string(line)+'<'
      endif
  endfor
  
  return
end


pro save_diag_read_func, unit, len, header, bbuffer, $
                         symbols=symbols, keywords=keywords, commons=commons

  ;; FUNCTION
  ;;   STRING_DATA - pro/function name
  ;;   LONG - LENGTH - length of body (what units?)
  ;;   LONG - N_VARS - number of local variables
  ;;   LONG - N_ARGS - number of positional+keyword arguments
  ;;   LONG - FLAGS - bit 0:function, bit 1:keywords, bit 4:_EXTRA
  ;;   LONG - ??
  ;;   LONG - N_COMMONS - number of commons
  ;;   LONG - N_SYMS - number of symbols in symbol table
  ;;   LONG - ?? - 1 or 3
  ;;   COMMON_TAB - COMMON_ENTRYxN_COMMONS
  ;;   ARG_TAB - [0xN_PARS, STRING_DATAxN_KEYS]  (positional vs keyword parms)
  ;;   SYM_TAB - SYM_ENTRYxN_SYMS - array of symbols

  ;; COMMON_ENTRY
  ;;   STRING_DATA - NAME - name of common
  ;;   LONG - N_ELT - number of variables in common

  point_lun, -unit, pos0
  funcname = save_diag_read_string(unit)

  catch, catcherror
  if catcherror NE 0 then begin
      catch, /cancel
      goto, FINISH
  endif

  length = save_diag_read_long(unit)
  n_vars = save_diag_read_long(unit)
  n_args = save_diag_read_long(unit)
  flags = save_diag_read_long(unit)
  dummy = save_diag_read_long(unit)
  n_commons = save_diag_read_long(unit)
  n_syms = save_diag_read_long(unit)
  dummy = save_diag_read_long(unit)

  if (flags AND '01'xb) NE 0 then type = 'FUNCTION' else type = 'PRO'
  if (flags AND '02'xb) NE 0 then has_keywords = 1 else has_keywords = 0
  if (flags AND '08'xb) NE 0 then extra = 1 else extra = 0
  
  n_pars = 0L
  n_keys = 0L
  keywords = 0L &  dummy = temporary(keywords)
  commons  = 0L &  dummy = temporary(commons)
  if n_syms GT 0 then begin
      for i = 0L, n_args-1 do begin
          key = save_diag_read_string(unit)
          if key NE '' then begin
              if n_elements(keywords) EQ 0 then keywords = [key] $
              else keywords = [keywords, key]
          endif              
      endfor

      if n_commons GT 0 then begin
          commons = replicate({name:'', size:0L}, n_commons)
          for i = 0L, n_commons-1 do begin
              commons(i).name = save_diag_read_string(unit)
              commons(i).size = save_diag_read_long(unit)
          endfor
      endif

      symbols = replicate({symname:'', values:lonarr(3)}, n_syms)
      for i = 0L, n_syms-1 do begin
          save_diag_read_sym, unit, sym, vals
          if sym NE '' then begin
              symbols(i).symname = sym
              symbols(i).values = vals
          endif
      endfor
  endif

  FINISH:
  n_keys = n_elements(keywords)
  n_pars = n_args - n_keys
  header = {name: funcname, type: type, length: length, flags: flags, $
            n_vars: n_vars, n_args: n_args, n_pars: n_pars, n_keys: n_keys, $
            n_syms: n_syms, has_keywords: has_keywords, extra: extra, $
            n_commons: n_commons }

;  point_lun, unit, pos0
;  bbuffer = bytarr(len-4*4)
  
  point_lun, -unit, pos1
  len1 = len - (pos1-pos0) - 4*4
  bbuffer = bytarr(len1)

  readu, unit, bbuffer
end

pro save_diag, filename0, data=dprint, keywords=kprint, variables=vprint, $
               symbols=sprint, binary_dump=bdump


  if n_elements(filename0) EQ 0 then return
  filename = string(filename0)
  unit = -2L
  get_lun, unit
  openr, unit, filename, error=err

  if err NE 0 then begin
      message = 'ERROR: could not open '+filename
      goto, ERRMSG_OUT
      return
  endif

  signature = bytarr(4)
  ;; SIGNATURE
  ;;   00-01 : BYTEx2 - characters 'SR'
  ;;   02-03 : WORD - size of timestamp header (?)
  ;;   TAGGED_RECORD
  
  readu, unit, signature
  if string(signature(0:1)) NE 'SR' then begin
      free_lun, unit
      message = 'ERROR: '+filename+' is not a recognized IDL save file'
      goto, ERRMSG_OUT
  endif

  typenames = ['UNDEFINED', 'BYTE', 'INTEGER', 'LONG', 'FLOAT', 'DOUBLE', $
               'COMPLEX', 'STRING', 'STRUCTURE', 'DCOMPLEX', 'POINTER', $
               'OBJECT', 'UNSIGNED INTEGER', 'UNSIGNED LONG', $
               'LONG64', 'UNSIGNED LONG64', 'UNKNOWN']
  mkarrfuns = ['', 'BYTARR', 'INTARR', 'LONARR', 'FLTARR', 'DBLARR', $
               'COMPLEXARR', 'STRARR', 'STRUCTARR', 'DCOMPLEXARR', $
               'PTRARR', 'OBJARR', 'UINTARR', 'ULONARR', 'LON64ARR', $
               'ULON64ARR', 'UNKNOWNARR']

  rectype_names = strarr(18)+'UNKNOWN'
  rectype_names(0)  = 'START'
  rectype_names(2)  = 'VARIABLE'
  rectype_names(10) = 'TIMESTAMP'
  rectype_names(12) = 'FUNCTION'
  rectype_names(14) = 'VERSION'
  rectype_names(15) = 'HEAPHEADER'
  rectype_names(16) = 'HEAPDATA'
  rectype_names(6)  = 'ENDMARKER'

  offset = 4L
  print, "'"+filename+"'", format='("Save file ",A0)'
  while 1 do begin

      ;; TAGGED_RECORD
      ;;   00-03 : LONG - Tagged record type
      ;;   04-07 : LONG - File offset of next record (indexed from
      ;;                  file start)
      ;;   08-0F : LONGx2 - unknown (=[0,0]?)
      ;;   TAGGED_DATA
      ;;     - VARIABLE
      ;;     - TIME_STAMP
      ;;     - VERSION_STAMP
      ;;     - HEAPDATA
      ;;     - FUNCTION (function or procedure)
      point_lun, unit, offset
      rechead = lonarr(4)
      readu, unit, rechead
      ieee_to_host, rechead
      
      rectype = rechead(0)
      nextoff = rechead(1)
      print, '--------------------------------------------------------------'
      print, rectype, offset, rectype_names(rectype<17), $
        format='("Record type ",I4," at offset 0x",Z8.8," (",A0,")")'
      
      case rectype of 
          2: begin  ;; VARIABLE
              DO_VARIABLE:
;              if keyword_set(dprint) EQ 0 then goto, BDUMP_OUT
              ;; VARIABLE
              ;;   STRING_DATA - name of variable
              ;;   SCALAR_TYPE or ARRAY_TYPE - type of variable
              ;;   VAR_DATA - binary data of variable
              varname = save_diag_read_string(unit)
              print, "'"+varname+"'", format='("       Name: ",A0)'
              READ_DATA_REC:
              template = 0
              dummy = temporary(template)
              sz = save_diag_read_type(unit, template=template)
              if n_elements(sz) LE 1 then goto, DONE_RECORD
              tp = sz(sz(0)+1)
              print, tp, typenames(tp<15), $
                format='("       Type: ",I0," (",A0,")")'
              ndims = sz(0)
              if ndims EQ 0 then begin
                  print, '  Dimension: SCALAR' 
              endif else begin
                  dims = sz(1:ndims)
                  fmt = '('+strtrim(ndims,2)+'(I0,:,","))'
                  st = '('+string(dims, format=fmt)+')'
                  print, mkarrfuns(tp<15), st, $
                    format='("  Dimension: ",A0,A0)'
              endelse
              if n_elements(template) NE 0 then begin
                  help, /struct, template
              endif
              data = 0
              dummy = temporary(data)
              save_diag_read_data, unit, data, sz, template=template, /start
              if n_elements(data) GT 0 then begin
                  print, 'vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'
                  if n_elements(data) GT 10 then begin
                      sample = inputform(data(0:10))
                      sample = strmid(sample, 0, strlen(sample)-1)+'...]'
                      print, '     ', sample
                  endif else begin
                      inform = inputform(data, status=st)
                      if st EQ 1 then $
                        print, '     ', inform $
                      else $
                        print, '     ', data
                  endelse
              endif
              BDUMP_OUT:
              if keyword_set(bdump) AND (nextoff-offset) - 4*4 GT 0 then begin
                  print, '     vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv'
                  bbuffer = bytarr((nextoff - offset) - 4*4)
                  point_lun, unit, offset+4*4
                  readu, unit, bbuffer
                  save_diag_print_binary, bbuffer
              endif
          end
;;        3: goto, DO_VARIABLE ;; SYSTEM_VARIABLE
          1: begin ;; COMMON_BLOCK
              ncomm = save_diag_read_long(unit)
              commname = save_diag_read_string(unit)
              for i = 0, ncomm-1 do $
                print, save_diag_read_string(unit)+' ('+commname+')'
          end
          10: begin 
              ;; TIME_STAMP
              ;;   00-400 : BYTEx400 - empty (?) legacy area
              ;;   STRING_DATA - save date (as a string)
              ;;   STRING_DATA - user name
              ;;   STRING_DATA - hostname
              buffer = bytarr('400'x)
              readu, unit, buffer
              save_date = save_diag_read_string(unit)
              save_user = save_diag_read_string(unit)
              save_host = save_diag_read_string(unit)
              print, inputform(save_date), $
                format='("       Date: ",A0)'
              print, inputform(save_user), $
                format='("   Username: ",A0)'
              print, inputform(save_host), $
                format='("   Hostname: ",A0)'
          end
          12: begin
              ;; FUNCTION

              len = nextoff-offset
              save_diag_read_func, unit, len, header, bbuffer, $
                symbols=symbols, keywords=keywords, commons=commons

              print, inputform(header.name), $
                format='("       Name: ",A0)'
              print, header.length, format='("     Length: ",A0)'
              print, header.type, $
                format='("       Type: ",A0," ",$)'
              if header.has_keywords then $
                print, 'KEYWORDS ', format='(A0,$)'
              if header.extra then $
                print, '_EXTRA ', format='(A,$)'
              if (header.flags AND (NOT '1B'xb)) NE 0 then $
                print, (header.flags AND (NOT '1B'xb)), $
                format='("FLAGS(0x",Z2.2,") ",$)'
              print, ''
              print, header.n_args, header.n_pars, header.n_keys, $
                format=('("  Arguments: ",I3,"  (",I0," Positional + ",'+ $
                        'I0," Keyword)")')
              if keyword_set(kprint) AND header.n_keys GT 0 then $
                print,    '   Keywords: '+inputform(keywords)
              if header.n_commons GT 0 then begin
                  print, '    Commons: '
                  for j = 0L, header.n_commons-1 do $
                    print, commons(j), $
                    format='("       ",A15,I10," elements")'
              endif
              print, header.n_vars, header.n_syms, $
                format= '(" Local Vars: ",I3,"      Symbols: ",I3)'
              if keyword_set(sprint) AND header.n_syms GT 0 then begin
                  for j = 0L, header.n_syms-1 do begin
                      print, symbols(j), format='("       ",A15,3(I10))'
                  endfor
              endif

              if keyword_set(bdump) then save_diag_print_binary, bbuffer
;              if keyword_set(bdump) then goto, BDUMP_OUT
          end
          14: begin
              ;; VERSION_STAMP
              save_diag_read_version, unit, data
              print, inputform(data.arch), $
                format='("       Arch: ",A0)'
              print, inputform(data.os), $
                format='("         OS: ",A0)'
              print, inputform(data.release), $
               format='("    Release: ",A0)'
              print, data.major_release, $
               format='(" Major Rel.: ",A0)'
          end
          15: begin
              ;; 15 - HEAPHEADER
              if keyword_set(bdump) then goto, BDUMP_OUT
          end
          16: begin  ;; HEAPDATA
              ;; HEAPDATA
              ;;   00-03 : LONG - HEAP_INDEX - index of heap variable
              ;;   04-07 : LONG - unknown ( = 2 ? )
              ;;   SCALAR_TYPE or ARRAY_TYPE - type of variable
              ;;   VAR_DATA - binary data of variable
              index = lonarr(2)
              readu, unit, index
              ieee_to_host, index
              print, index(0), $
                format='(" Heap Index: ",I0)'
              goto, READ_DATA_REC
          end
          ;; ANYTHING ELSE
          else: if keyword_set(bdump) then goto, BDUMP_OUT
      endcase
      DONE_RECORD:
      
      if nextoff EQ 0 then goto, DONE_FILE
      offset = nextoff
  endwhile
  
  DONE_FILE:
  free_lun, unit
  return
  
  ERRMSG_OUT:
  message, message, /info
  return
end
