pro init_param, param
;common psfstuff,param,psfsig,psfpix,obpix
   param = { $
          p:        dblarr(15,121),       $
          wid:      1d,                   $
          oldwid:   1d,                   $
          x:        fillarr(.25d,-15d,15d),  $
          plotpsf:  0,                    $
          set:      0,                    $
          coeff:    dblarr(15,15),        $
          powarr:   dblarr(15,121),       $
          normarr:  dblarr(15,121),       $
          zarr:     dblarr(15,121)        $
        }
end
