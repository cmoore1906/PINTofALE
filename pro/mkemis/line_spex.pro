pro line_spex,z=z,outdir=outdir
;+
;procedure	line_spex
;	IDL procedure that completes the task begun by line_spex.f
;	i.e., it converts the line emissivity info contained in
;	the files in the current directory and reorganizes it in
;	a form that may be read in with RD_LINE.PRO
;
;syntax
;	line_spex,z=z,outdir=outdir
;
;parameters	NONE
;
;keywords
;	Z	[INPUT; default: ALL] element, ionic state (e.g.:'He','Fe XII')
;	outdir	[INPUT; default: emisspex] directory tree under which to
;		store the output files
;
;side-effects
;	deposits (possibly large) files in OUTDIR
;	* ATOM_wvl	wavelengths of all the transitions
;	* ATOM_tem	temperatures
;	* ATOM_##.#	line intensities I(tem,wvl)@logP
;	* ATOM_ion	ionic states corresponding to wvl
;	* ATOM_jon	ionic states that actually *determine* intensities
;	* ATOM_src	source of line information
;			1: SPEX
;	* ATOM_lvl	description of each transition
;	* ATOM_ecn	blank array, for consistency with CHIANTI (and
;			hopefully future implementation)
;
;history
;	vinay kashyap (Jan97)
;	changed N_PRES from 11 to 8 (VK; Jun97)
;	added call to INITSTUFF, added ATOM_jon as output, etc (VK; May99)
;-

;	initialize variables shared with line_spex.f
n_pres=8 & n_temp=81 & d_pres=1. & d_temp=0.05 & lgp_mn=13. & lgt_mn=4.
logT=findgen(n_temp)*d_temp+lgt_mn
line_max=5412L		;actually, not expected to be > (3862+2121+225)

;	first of all, figure out the sizes of the emissivity arrays needed
c_lines=lonarr(line_max) & p_lines=c_lines & n_lines=c_lines
for jp=0,n_pres-1 do begin	;{loop over pressures
  kilroy; was here.
  if jp lt 9 then ext='.0'+string(jp+1,'(i1)') else ext='.'+string(jp+1,'(i2)')
  nlines=wc('plev'+ext) & ii=lonarr(nlines)
    openr,lu_pi,'plev'+ext,/get_lun & readf,lu_pi,ii
    close,lu_pi & free_lun,lu_pi & p_lines(ii-1L)=1
  nlines=wc('clev'+ext) & ii=lonarr(nlines)
    openr,lu_ci,'clev'+ext,/get_lun & readf,lu_ci,ii
    close,lu_ci & free_lun,lu_ci & c_lines(ii-1L)=1
  nlines=wc('nlev'+ext) & ii=lonarr(nlines)
    openr,lu_ni,'nlev'+ext,/get_lun & readf,lu_ni,ii
    close,lu_ni & free_lun,lu_ni & n_lines(ii-1L)=1
endfor				;JP=0,N_PRES-1}
o_p=where(p_lines gt 0,mop)
o_c=where(c_lines gt 0,moc)
o_n=where(n_lines gt 0,mon)
linemax = mop+moc+mon
print,'total number of lines in SPEX output: '+strtrim(linemax,2)

;	... and "invert" the locations, i.e., provide a way to go from
;	line number to serial location
plin=lonarr(line_max)-1L & for i=0L,mop-1L do plin(o_p(i))=i
clin=lonarr(line_max)-1L & for i=0L,moc-1L do clin(o_c(i))=i+mop
nlin=lonarr(line_max)-1L & for i=0L,mon-1L do nlin(o_n(i))=i+mop+moc
;	in other words, Xlin(lin#-1) is the location number

;	initialize
fx=fltarr(n_temp,linemax)
wvl=fltarr(line_max) & zz=lonarr(line_max) & ion=zz & jon=zz
labl=strarr(line_max)
initstuff,atom

;	check inputs
if keyword_set(z) then atom=[strtrim(z,2)]		;element defined
nz=n_elements(atom)
;
if not keyword_set(outdir) then outdir='emisspex'	;where to dump output
wfil='wvl' & tfil='tem' & ifil='ion' & sfil='src' & lfil='lvl' & efil='ecn'
jfil='jon'
;
;if OUTDIR doesn't exist, create it
;	clearly, this bit works only on UNIX
spawn,'csh -c "if \!( -e ' + outdir +' ) mkdir '+outdir+'"'

for ip=0,n_pres-1 do begin				;{pressure loop
  logp=lgp_mn+ip*d_pres
  if logp le 0 or logp ge 10 then ffil=string(logp,'(f4.1)') else $
	ffil='0'+string(logp,'(f3.1)')
  if ip lt 9 then ext='.0'+string(ip+1,'(i1)') else ext='.'+string(ip+1,'(i2)')
  ;
  if ip eq 0 then begin
    openr,lu_w,'wavl'+ext,/get_lun
    openr,lu_z,'atno'+ext,/get_lun
    openr,lu_i,'ions'+ext,/get_lun
    openr,lu_d,'desc'+ext,/get_lun
  endif
  openr,lu_pp,'pprs'+ext,/get_lun
  openr,lu_pf,'pflx'+ext,/get_lun
  openr,lu_pl,'plev'+ext,/get_lun
  openr,lu_cp,'cprs'+ext,/get_lun
  openr,lu_cf,'cflx'+ext,/get_lun
  openr,lu_cl,'clev'+ext,/get_lun
  openr,lu_np,'nprs'+ext,/get_lun
  openr,lu_nf,'nflx'+ext,/get_lun
  openr,lu_nl,'nlev'+ext,/get_lun
  ;
  if ip eq 0 then begin
    readf,lu_w,wvl & readf,lu_d,labl & readf,lu_z,zz & readf,lu_i,ion
    wvl=[wvl(o_p),wvl(o_c),wvl(o_n)]
    labl=[labl(o_p)+' (II)',$
	labl(o_c)+' (EX)',$
	labl(o_n)+' (Recomb)']
    zz=[zz(o_p),zz(o_c),zz(o_n)]
    jon=[ion(o_p)-1L,ion(o_c),ion(o_n)+1L]
    ion=[ion(o_p),ion(o_c),ion(o_n)]
  endif
  ;
  for it=0,n_temp-1 do begin				;{temperature loop
    kilroy; was here.
    ;
    readf,lu_pp,nlines & em=dblarr(nlines) & id=lonarr(nlines)
    readf,lu_pf,em & readf,lu_pl,id & ol=plin(id-1L) & fx(it,ol)=em
    ;
    readf,lu_cp,nlines & em=dblarr(nlines) & id=lonarr(nlines)
    readf,lu_cf,em & readf,lu_cl,id & ol=clin(id-1L) & fx(it,ol)=em
    ;
    readf,lu_np,nlines & em=dblarr(nlines) & id=lonarr(nlines)
    readf,lu_nf,em & readf,lu_nl,id & ol=nlin(id-1L) & fx(it,ol)=em
  endfor						;temperature loop}

  if ip eq 0 then begin
    close,lu_w & free_lun,lu_w
    close,lu_z & free_lun,lu_z
    close,lu_i & free_lun,lu_i
    close,lu_d & free_lun,lu_d
  endif
  close,lu_pp & free_lun,lu_pp
  close,lu_pf & free_lun,lu_pf
  close,lu_pl & free_lun,lu_pl
  close,lu_cp & free_lun,lu_cp
  close,lu_cf & free_lun,lu_cf
  close,lu_cl & free_lun,lu_cl
  close,lu_np & free_lun,lu_np
  close,lu_nf & free_lun,lu_nf
  close,lu_nl & free_lun,lu_nl

  ;{	output loop
  for iz=0,nz-1 do begin				;{for each element
    message,'	working on '+atom(iz),/info
    symb2zion,atom(iz),kz,kion
    oo=where(zz eq kz) & if kion gt 0 then oo=where(zz eq kz and ion eq kion)
    if oo(0) ne -1 then begin				;(
      moo=n_elements(oo)
      fpre=strcompress(atom(iz),/remove_all)		;file prefixes
      message,'	writing to '+outdir+'/'+fpre+'_*',/info
      ;	open files
      if ip eq 0 then begin
        openw,uw,outdir+'/'+fpre+'_'+wfil,/get_lun	;wavelengths
        openw,ut,outdir+'/'+fpre+'_'+tfil,/get_lun	;temperatures
        openw,ui,outdir+'/'+fpre+'_'+ifil,/get_lun	;ionic state
        openw,uj,outdir+'/'+fpre+'_'+jfil,/get_lun	;"true" ionic state
        openw,us,outdir+'/'+fpre+'_'+sfil,/get_lun	;data source
        ;		outdir+'/'+fpre+'_'+lfil	;transitions
        ;		outdir+'/'+fpre+'_'+efil	;e-configs (blank)
      endif
      openw,uf,outdir+'/'+fpre+'_'+ffil,/get_lun	;intensities
      ;	write
      if ip eq 0 then begin
        writeu,uw,moo,wvl(oo)
        writeu,ut,n_elements(logT),logT
        writeu,ui,moo,long(ion(oo))
        writeu,uj,moo,long(jon(oo))
        writeu,us,moo,0*oo+1L
        tmp_trans=strarr(2,moo) & tmp_trans(1,*)=labl(oo)
        tmp_econf=strarr(2,moo)
        save,file=outdir+'/'+fpre+'_'+lfil,tmp_trans
        save,file=outdir+'/'+fpre+'_'+efil,tmp_econf
      endif
      writeu,uf,n_elements(logT),moo,double(fx(*,oo))
      ;	close files
      if ip eq 0 then begin
        close,uw & free_lun,uw
        close,ut & free_lun,ut
        close,ui & free_lun,ui
        close,uj & free_lun,uj
        close,us & free_lun,us
      endif
      close,uf & free_lun,uf
    endif						;)
  endfor						;iz=0,nz-1}

  ;	output loop}

endfor							;pressure loop}

return
end
