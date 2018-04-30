;***** CARLSTRETCH*******************************************
pro carlstretch, r, g, b, low, high, gamma
;like IDL's 'stretch', but does color independently.
common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
nc = !d.table_size      ;# of colors entries in device

; STRETCH THE COLOR TABLE...
if (high eq low) then return                ; Nonsense...
slope = 1. / (float(high) - float(low))     ; Range of 0 to 1.
intercept = -slope * float(low)
p = findgen(nc) * slope + intercept > 0.0
p = long(nc * (p^gamma)) < 255

; WHAT IF ANY ARE ZERO ???

if (r ne 0) then r_curr = r_orig[p]
if (g ne 0) then g_curr = g_orig[p]
if (b ne 0) then b_curr = b_orig[p]

; LOAD THE STRETCHED COLOR TABLE...
tvlct, r_curr, g_curr, b_curr

end; carlstretch

;***** TDIDDLE *******************************************
pro tdiddle, channels, lo, hi, gamma
;DIDDLES GAMMA AND STRETCH OF IMAGES IN 3 CHANNELS INDEPENDENTLY OR IN ALL.
;WHICH COLOR DEPENDS ON COLORS. R, G, B OR ANY COMBINATION.

; COLORS = STRING, 'G', 'R', 'B' OR ANY COMBO...

; BEGIN WITH THE INPUT STRETCH PARAMETERS: LO, HI, GAMMA,
; IF THEY HAVE BEEN ENTERED. OTHERWISE, USE THE DEFAULT VALUES.

; ONLY USEFUL FOR 24-BIT DIRECTCOLOR VISUAL...
device, get_visual_name=visual, get_decomposed=decomposed
if (visual ne 'DirectColor') then begin
    message, 'Application only runs on 24-bit DirectColor display!', /INFO
    return
endif
if (decomposed eq 0l) then begin
    message, 'Color decomposition must be turned on!', /INFO
    return
endif

; GET THE IDL COLOR COMMON BLOCK...
common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

; WHICH COLORS DO WE WANT TO DIDDLE...
if (N_params() eq 0) then channels='rgb'
channels = strupcase(channels)
r = (strpos(channels,'R') ne -1)*255l
g = (strpos(channels,'G') ne -1)*255l
b = (strpos(channels,'B') ne -1)*255l
colorout = r + 256l*( g + 256l*b)

; MAKE SURE A COLOR TABLE HAS BEEN LOADED...
if (N_elements(r_curr) eq 0) then loadct, 0

; THEN THE OTHER PARAMETERS...
if (N_elements(lo) eq 0) then lo = 0
lo = float(lo)/255.
if (N_elements(hi) eq 0) then hi = 255
hi = float(hi)/255.
if (N_elements(gamma) eq 0) then gamma = 1.0
gamma = 0.5*(1. + alog10(gamma))

; THE INITIAL PARAMETERS...
lo = byte(lo * 255)
hi = byte(hi * 255)
gamma = 0.1*(100.^gamma)

; STRETCH THE COLOR TABLE OVER INITIAL RANGE...
carlstretch, r, g, b, lo, hi, gamma

; SAVE THE ORIGINAL WINDOW NUMBER SO THAT WE GO BACK TO IT UPON RETURN...
windownr = !d.window
print & print, 'Original window: '+strtrim(windownr,2) & print

; DEFINE THE DIDDLE WINDOW AND THE PIXMAP...
device, get_screen_size=screen
window, xsize=400, ysize=100, xpos=0.01*screen[0], ypos=0.05*screen[1], $
  /free, retain=2, title='Color & Gamma Control'
didwin = !d.window
window, xsize=400, ysize=100, /free, /pixmap
pixwin = !d.window

; PLOT THE AXES IN THE PIXMAP...
plot, [1,1], xrange=[0,1], yrange=[0,1], /nodata, $
  xstyle=4, ystyle=1, position=[.05, .15, .95, .85], $
  color=colorout, ytickformat='(A1)', ticklen=0
axis, xaxis=0, /xs, xr=[0,255], charsize=0.7, ticklen=0.1, co=colorout
axis, xaxis=1, /xs, xr=[0.1,10], charsize=0.7, ticklen=0.1, /xlog, co=colorout

; OUTPUT VALUES...
xyouts, .15, .5, lo, /normal, charsize=1.5, color=colorout
xyouts, .83, .5, hi, /normal, charsize=1.5, color=colorout, align=1
xyouts, .5, .5, string(gamma, format='(f5.2)'), /normal, $
  charsize=1.5, align=0.5, color=colorout

; OUTPUT DIRECTIONS AND STARTING VALUES...
print, 'LEFT button controls MIN, MID button GAMMA, RIGHT button MAX'
print, 'the horizontal position of the cursor gives the value '
print, 'hit ANY key to QUIT' & print
print, 'Color Channels: '+channels & print
print, '','LOW','HIGH','GAMMA', format='(A10,2A5,A10)'
print, 'STARTING: ', lo, hi, gamma, format='(A10,2I5,F10.5)'

beginagn:

; STORE THE ORIGINAL VALUES...
lo_old = lo
hi_old = hi
gamma_old = gamma

; GO BACK TO THE WINDOW AND CHECK FOR MOUSE ACTIVITY...
wset, didwin
;wshow, didwin
cursor, xx, yy, /nowait, /data
xx = (0. > xx) < 1.0

; WHICH MOUSE BUTTON WAS CLICKED...
clicked = 1B
case !mouse.button of
    1 : lo = byte(xx * 255) < hi ; DON'T GO ABOVE THE HIGH...
    4 : hi = byte(xx * 255) > lo ; DON'T GO BELOW THE LOW...
    2 : gamma = 0.1*(100.^xx)
 else : clicked=0B ; YOU CLICKED MULTIPLE OR NO BUTTONS...
endcase

; GO BACK TO THE PIXMAP...
wset, pixwin

; ONLY UPDATE THE DISPLAY IF A CHANGE WAS MADE...
if clicked then begin

    ; ERASE THE OLD VALUES...
    xyouts, .15, .5, lo_old, /normal, charsize=1.5, color=0
    xyouts, .83, .5, hi_old, /normal, charsize=1.5, color=0, align=1
    xyouts, .5, .5, string(gamma_old, format='(f5.2)'), /normal, $
      align=0.5, charsize=1.5, color=0

    ; STRETCH THE COLOR TABLE OVER THE NEW VALUES...
    carlstretch, r, g, b, lo, hi, gamma

    ; OUTPUT THE NEW VALUES...
    xyouts, .15, .5, lo, /normal, charsize=1.5, color=colorout
    xyouts, .83, .5, hi, /normal, charsize=1.5, color=colorout, align=1
    xyouts, .5, .5, string(gamma, format='(f5.2)'), /normal, charsize=1.5, $
      align=0.5, color=colorout
endif

; DUMP THE PIXMAP IMAGE ON THE WINDOW...
wset, didwin
device, copy=[0,0,!d.x_vsize,!d.y_vsize,0,0,pixwin]

; SLOW IT DOWN A BIT...
wait, 0.02
wset, pixwin

; CHECK TO SEE IF WE SHOULD QUIT...
if (get_kbrd(0) eq '') $
  then goto, beginagn $
  else begin
    print, 'ENDING: ', lo, hi, gamma, format='(A10,2I5,F10.5)'

    ; GO BACK TO ORIGNAL WINDOW...
    wset, windownr
    print & print, 'Returning to window: '+strtrim(windownr,2) & print

    ; DELETE THE DIDDLE WINDOW AND THE PIXMAP...
    wdelete, didwin, pixwin
  endelse 

end; tdiddle








