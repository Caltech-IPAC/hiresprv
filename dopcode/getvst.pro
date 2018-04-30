pro getvst, name, cf3
file = '~/vstkeck/vst'+name+'.dat'
if check_file(file) then restore,file else print,file+' not found.'
end
