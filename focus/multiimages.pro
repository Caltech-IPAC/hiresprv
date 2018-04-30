PRO MultiImages, multi
IF N_Params() NE 1 THEN multi = [0, 2, 2]
imageFile = Filepath(SubDir=['examples','data'], 'worldelv.dat')
image = BytArr(360, 360)
OpenR, lun, imageFile, /Get_LUN
ReadU, lun, image
Free_Lun, lun
Window, XSize=500, YSize=400
!P.Multi = multi
FOR j=0, multi[1]*multi[2]-1 DO BEGIN
    Plot, Findgen(11), Color=!P.Background
    x1 = !X.Region[0] + 0.05
    x2 = !X.Region[1] - 0.05
    y1 = !Y.Region[0] + 0.05
    y2 = !Y.Region[1] - 0.05
    TVImage, image, Position=[x1, y1, x2, y2]
    Plot, Findgen(11), position=[x1, y1, x2, y2], xticklen=-0.02, $
      yticklen=-0.02, xtitle='latitude', ytitle='longitude', $
      /nodata, /noerase
ENDFOR
END
