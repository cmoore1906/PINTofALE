pro tekku,id_str,fx,fxerr,texfil=texfil,fxunit=fxunit,trance=trance,$
	trantex=trantex,asku=asku,fxfmt=fxfmt,fxefmt=fxefmt,$
	kamentu=kamentu,lineu=lineu, _extra=e
;+
;procedure	tekku
;	write out a LaTeX file summary of the ID structure
;
;syntax
;	tekku,id_str,fx,fxerr,texfil=texfil,fxunit=fxunit,/trance,/asku,$
;	fxfmt=fxfmt,fxefmt=fxefmt,/kamentu
;
;parameters
;	id_str	[INPUT; required] ID structure from LINEID
;	fx	[INPUT] measured fluxes
;		* if size does not match number of ID components of the
;		  number of IDs, the internally stored values are used
;		* if FX is set to 0, then the output will not contain
;		  any information about fluxes.
;	fxerr	[INPUT] errors on FX
;		* if size does not match FX, first element is assumed
;		  to represent a constant >fractional< error on FX
;		* default is 0.01
;		* if FXERR is explicitly set to 0, then the output will
;		  not report the errors.
;
;keywords
;	texfil	[INPUT] name of file to dump the table to
;		* the ".tex" extension is not needed
;		* if not given, dumps output to screen
;		* if ASKU is set, the default extension is ".txt"
;	fxunit	[INPUT] string representing the units that the fluxes
;		are in, e.g., "ph s$^{-1}$"
;	trance	[INPUT] if set, adds a column to hold transition data
;		(e-configuration and level designation)
;       trantex [INPUT] if set, e-configuration and level designation 
;               are converted to LaTex format so that appropriate 
;               super-scripting and sub-scripting is included. This is set 
;               by default.
;		* explicitly set to zero to turn this off. 
;	asku	[INPUT] if set, writes out a plain text ascii file w/o all
;		the TeX commands
;	fxfmt	[INPUT] FORTRAN-style formatting syntax for writing out
;		fluxes, e.g., "f10.4", "e14.4", etc.
;		* default is "f7.2"
;	fxefmt	[INPUT] as FXFMT, for flux errors
;		* default is FXFMT
;	kamentu	[INPUT] set this keyword to include the scracth pad notes
;		in the table output.  if not set, the comments won't be
;		included.
;	lineu	[INPUT] if set, the input structure is assumed to be a
;		line emissivity structure of the sort generated by RD_LINE()
;		* in this case, the lambda_obs column is not printed out,
;		  and the lambda_pred column is simply labeled as lambda
;	_extra	[JUNK] here only to prevent crashing the program
;
;history
;	vinay kashyap (Dec98)
;	added support for scribbles (VK; Mar99)
;	changed call to INITSTUFF to INICON (VK; 99May)
;	allowed output minus flux+-fluxerr column; also transition info
;	  column (VK; 99Nov)
;	added keyword ASKU (VK; MarMM)
;	added keywords FXFMT and FXEFMT (VK; JunMM)
;	corrected: what if FXFMT/FXEFMT not set (VK NovMM; viz. A.Maggio)
;	added keyword KAMENTU; changed transitions font to "\small";
;	  now reads in flux and fluxerr from ID_STR; Erica asks that
;	  wvls, and flux+error alignments be set to "r" (VK; Apr02)
;	now puts "..." instead of spaces for duplicates (VK; Oct03)
;       added support for TEKHI() via keyword TRANTEX (LL;Nov04) 
;	added keyword LINEU, call to DUMMYID(), changed \nl to \\ (VK; Feb06)
;	changed \documentstyle[apjpt4]{article} to \documentclass[10pt]{article}
;	  (VK; Mar07)
;
;etymology
;	the name comes from kannadization of the "process of TeXing";
;	Kannada, mind you, is a language of southern India, and has
;	absolutely nothing to do with Quebec and surrounding regions.
;-

;	usage
nid=n_tags(id_str)
if nid lt 2 then begin
  print,'Usage: tekku,idstr,flux,fluxerr,texfil=texfil,fxunit=fxunit,$'
  print,'       /trance,/asku,fxfmt=fxfmt,fxefmt=fxefmt,/kamentu,/lineu'
  print,'  dump ID structure information into a LaTeX file'
  return
endif

;	verify input
if keyword_set(lineu) then idstr=dummyid(id_str) else idstr=id_str
ok='ok' & tagid=tag_names(idstr)
if tagid(0) eq 'LINE_INT' and not keyword_set(lineu) then begin
  message,'Input appears to be an emissivity structure',/informational
  lineu=1 & idstr=dummyid(id_str)
endif
if tagid(0) ne 'WVL' then ok='ID Structure not in right format' else $
 if tagid(0) eq 'WVL_COMMENT' then ok='ID Structure contains no data' else $
  if tagid(0) eq 'Z' then ok='ID structure appears to have been stripped'
if ok ne 'ok' then begin
  message,ok,/info & return
endif

;	how many components?  how many IDs?  which wavelengths?
obswvl=idstr.WVL & nwvl=n_elements(obswvl)
wvl=abs(idstr.(1).WVL) & for i=1L,nwvl-1L do wvl=[wvl,abs(idstr.(i+1).WVL)]
mwvl=n_elements(wvl)

;	check fluxes
nfx=n_elements(fx) & write_flux=1
if nfx eq 1 then begin
  if fx(0) eq 0 then write_flux=0
endif
if write_flux eq 0 then message,'Output will not contain fluxes',/info
flux=idstr.(1).FLUX & for i=1L,nwvl-1L do flux=[flux,idstr.(i+1).FLUX]
if nfx eq mwvl then flux=fx
if nfx eq nwvl then begin
  k=0L
  for i=0L,nwvl-1L do begin
    flx=idstr.(i+1).FLUX & mw=n_elements(flx) & tflx=total(flx)
    if tflx eq 0 then tflx=float(mw)
    rflx=flx/tflx
    flx=rflx*fx(i)
    flux(k:k+mw-1L)=flx
    k=k+mw
  endfor
endif

;	check flux errors
nfxe=n_elements(fxerr)
if write_flux eq 1 and nfxe eq 1 then begin
  if fxerr(0) eq 0 then write_fluxe=0
endif else write_fluxe=write_flux
fluxerr=idstr.(1).FLUXERR & for i=1L,nwvl-1L do fluxerr=[fluxerr,idstr.(i+1).FLUXERR]
if nfxe eq mwvl then fluxerr=fxerr
if nfxe eq nwvl then begin
  k=0L
  for i=0L,nwvl-1L do begin
    flx=idstr.(i+1).FLUX & mw=n_elements(flx) & tflx=total(flx)
    if tflx eq 0 then tflx=float(mw)
    rflx=flx/tflx
    flxe=rflx*fxerr(i)
    fluxerr(k:k+mw-1L)=flxe
    k=k+mw
  endfor
endif
if nfxe gt 0 and nfxe ne nfx then begin
  fluxerr=flux*fxerr(0)
endif

;	flux units
if not keyword_set(fxunit) then fxunit='ph s$^{-1}$ cm$^{-2}$' else $
	fxunit=strtrim(fxunit,2)

;	flux formats
fmtfx='f7.2' & if keyword_set(fxfmt) then fmtfx=strtrim(fxfmt[0],2)
fmtfxe=fmtfx & if keyword_set(fxefmt) then fmtefx=strtrim(fxefmt[0],2)

;	check output file
szf=size(texfil) & nszf=n_elements(szf) & utex=-1L
if szf(nszf-2) eq 7 then begin
  i=strpos(texfil(0),'.tex',1)		;handle the ".tex" extension
  if i lt 0 then begin
    if keyword_set(asku) then filnam=texfil(0)+'.txt' else $
	filnam=texfil(0)+'.tex'
  endif else filnam=texfil(0)
  message,'Writing to file: '+filnam,/info
  openw,utex,strtrim(filnam,2),/get_lun		;{open for I/O
endif

;	TeX or ASCII?
asci=0		;by default, make TeX file
if utex eq -1 then asci=1	;no file name, print to screen
if keyword_set(asku) then asci=1	;explicitly asked for ascii

;       Tex or ASCII for level designations and e-configurations?
trancetex=1
if n_elements(trantex) gt 0 then begin
  if trantex[0] eq 0 then trancetex=0
endif

;	initialize header and footer
lll='rrll' & if keyword_set(lineu) then lll='rll'
if keyword_set(write_flux) then lll=lll+'r'
if keyword_set(trance) then lll=lll+'l'
if keyword_set(kamentu) then lll=lll+'l'
if not keyword_set(asci) then begin	;(header for TeX file
  hdr=['',$
  '\documentclass[10pt]{article}',$
  '%\usepackage{apjpt4}',$
  '\begin{document}',$
  '%\setcounter{table}{1}',$
  '\pagestyle{empty}',$
  '',$
  '\begin{deluxetable}{'+lll+'}',$
  '\tablecaption{Identifications and Fluxes for Spectral Lines Used in this Analysis}',$
  '\tablehead{']
  if keyword_set(lineu) then hdr=[hdr, '\colhead{$\lambda$} &'] else $
	hdr=[hdr,$
  	'\colhead{$\lambda_{\rm obs}$} & ',$
  	'\colhead{$\lambda_{\rm pred}$} &']
  hdr=[hdr,$
  '\colhead{Ion} & ',$
  '\colhead{$\log T_{\rm max}$}' ]
  if keyword_set(write_flux) then begin
    if keyword_set(write_fluxe) then $
      hdr=[hdr, ' & \colhead{Flux $\pm$ Error} ' ] else $
      hdr=[hdr, ' & \colhead{Flux} ' ]
  endif
  if keyword_set(trance) then hdr=[hdr, ' & \colhead{Transition}']
  if keyword_set(kamentu) then hdr=[hdr, ' & \colhead{Comments}']
  hdr=[hdr,' \\',$
  '\colhead{(\AA )} &']
  if not keyword_set(lineu) then hdr=[hdr, '\colhead{(\AA )} &']
  hdr=[hdr,$
  '\colhead{} &',$
  '\colhead{(K)}' ]
  if keyword_set(write_flux) then hdr=[hdr, ' & \colhead{['+fxunit+']} ' ]
  if keyword_set(trance) then hdr=[hdr, ' & \colhead{} ']
  if keyword_set(kamentu) then hdr=[hdr,' & \colhead{} ']
  hdr=[hdr, '}',$
  '',$
  '\startdata',$
  '' ] & nhdr=n_elements(hdr)
  ;	table data goes here
  ;	WVL(obs) & WVL(ID) & Z ION & Tmax & Flux +- Fluxerr & Comments
  ftr=['',$
  '\enddata',$
  '\end{deluxetable}',$
  '\end{document}',$
  ''] & nftr=n_elements(ftr)
endif else begin			;)(header for ASCII/rdb file
  hdr=['',$
  '#	Identifications and Fluxes for Spectral Lines Used in this Analysis']
  if keyword_set(lineu) then hdr=[hdr, '#	lambda'] else $
	hdr=[hdr,$
  	'#	lambda_obs [AA]',$
  	'#	lambda_pred [AA]']
  hdr=[hdr,$
  '#	Ion',$
  '#	logT_max [K]' ]
  if keyword_set(write_flux) then begin
    if keyword_set(write_fluxe) then $
      hdr=[hdr, '#	Flux+-Error ['+fxunit+']'] else $
      hdr=[hdr, '#	Flux ['+fxunit+' ]']
  endif
  if keyword_set(trance) then hdr=[hdr, '#	Transition']
  if keyword_set(kamentu) then hdr=[hdr, '#	Comments']
  hdr=[hdr,''] & nhdr=n_elements(hdr)
  ;	table data goes here
  ;	WVL(obs) & WVL(ID) & Z ION & Tmax & Flux +- Fluxerr & Comments
  rdbhdr1='obs_WVL	id_WVL	Z	ION	Tmax	'
  rdbhdr2='N	N	S	S	N	'
  if keyword_set(lineu) then begin
    rdbhdr1='WVL	Z	ION	Tmax	'
    rdbhdr2='N	S	S	N	'
  endif
  if keyword_set(write_flux) then begin
    if keyword_set(write_fluxe) then begin
      rdbhdr1=rdbhdr1+'Flux	FluxErr	'
      rdbhdr2=rdbhdr2+'N	N	'
    endif else begin
      rdbhdr1=rdbhdr1+'Flux	'
      rdbhdr2=rdbhdr2+'N	'
    endelse
  endif
  if keyword_set(trance) then begin
    rdbhdr1=rdbhdr1+'	Transition	'
    rdbhdr2=rdbhdr2+'	S	'
  endif
  if keyword_set(kamentu) then begin
    rdbhdr1=rdbhdr1+'Comments'
    rdbhdr2=rdbhdr2+'S'
  endif
  ftr=['',$]
  ''] & nftr=n_elements(ftr)
endelse					;headers)

;	other initializations
atom=1 & rom=1 & inicon,atom=atom,roman=rom
atom=['Unknown',atom] & rom=['',rom]
fldsep=' & '		;TeX table field separator
if keyword_set(asci) then fldsep='	'
kcom=0L			;comment number

;	print out to file
if utex gt 0 then for i=0L,nhdr-1L do printf,utex,hdr(i)	;header
k=0L
for i=0L,nwvl-1L do begin			;{for each component
  tmpid=idstr.(i+1) & tagnam=tag_names(tmpid)
  wvl=tmpid.WVL & mw=n_elements(wvl)
  zz=tmpid.Z & jon=tmpid.ION
  labl=tmpid.LABL
  ot=where(tagnam eq 'LOGT',mot)
  if mot gt 0 then logT=tmpid.(ot(0)) else logT=findgen(81)*0.05+4.
  nT=n_elements(logT)
  oe=where(tagnam eq 'EMIS',moe)
  if moe gt 0 then emis=tmpid.(oe(0)) else emis=fltarr(nT,mw)
  oy=where(tagnam eq 'NOTES',moy)
  if not keyword_set(kamentu) then moy=0	;no comments, please
  if moy gt 0 then begin
    scratch=tmpid.(oy(0))
    if not keyword_set(kcom) then comm=[scratch] else comm=[comm,scratch]
    kcom=kcom+1L
  endif else scratch=''
  for j=0L,mw-1L do begin			;{for each ID
    if not keyword_set(asci) then begin
      nodat='\nodata'
      if j eq 0 then c1=string(obswvl(i),'(f10.3)')+fldsep else c1=nodat+fldsep
      if keyword_set(lineu) then c1=''
      c1 = c1+string(abs(wvl(j)),'(f10.3)')+fldsep+$
	atom(zz(j))+'	'+rom(jon(j))
    endif else begin
      ;nodat=strjoin(replicate(' ',strlen(strtrim(obswvl(i),2))))
      slen=strlen(strtrim(obswvl(i),2))-3 > 1
      nodat='...'+strjoin(replicate(' ',slen))
      if j eq 0 then c1=strtrim(obswvl(i),2)+fldsep else c1=nodat+fldsep
      if keyword_set(lineu) then c1=''
      c1 = c1+strtrim(abs(wvl(j)),2)+fldsep+$
	atom(zz(j))+fldsep+rom(jon(j))
    endelse
    ;
    ;	Tmax
    emax=max(emis(*,j),min=emin,imx) & Tmax=logT(imx)
    if emin eq emax then begin
      c1=c1+'	'+fldsep+nodat
    endif else begin
      c1=c1+'	'+fldsep+string(Tmax,'(f4.2)')
    endelse
    ;
    ;	flux
    if keyword_set(write_flux) then begin	;(write flux column
      fxk=abs(flux(k))
      if not keyword_set(asci) then begin
	cfx=fldsep+'	$'+string(fxk,'('+fmtfx+')')
	if not keyword_set(fxfmt) then begin
          if fxk ge 1e4 then begin
            tmp=alog10(fxk) & itmp=fix(tmp) & ftmp=tmp-itmp
            cfx=fldsep+'	$'+string(10.^ftmp,'(f5.2)')+$
	    ' \times 10^{'+strtrim(itmp,2)+'}'
          endif
          if fxk gt 0 and fxk lt 0.01 then begin
            tmp=alog10(fxk) & itmp=fix(tmp-1) & ftmp=tmp-itmp
            cfx=fldsep+'	$'+string(10.^ftmp,'(f5.2)')+$
	      ' \times 10^{'+strtrim(itmp,2)+'}'
          endif
	endif
      endif else cfx=fldsep+strtrim(fxk,2)
      c1=c1+cfx
      ;
      ;	fluxerr
      if keyword_set(write_fluxe) then begin	;(write flux errors
        fxk=fluxerr(k)
	if not keyword_set(asci) then begin
          if fxk ne -1 then cfx=' \pm '+string(abs(fxk),'('+fmtfxe+')') else cfx=''
          fxk=abs(fluxerr(k))
	  if not keyword_set(fxefmt) then begin
            if fxk ge 1e4 then begin
              tmp=alog10(abs(fxk)) & itmp=fix(tmp) & ftmp=tmp-itmp
              cfx=' \pm '+string(10.^ftmp,'(g5.2)')+$
		' \times 10^{'+strtrim(itmp,2)+'}'
            endif
            if fxk gt 0 and fxk lt 0.01 then begin
              tmp=alog10(abs(fxk)) & itmp=fix(tmp-1) & ftmp=tmp-itmp
              cfx=' \pm '+string(10.^ftmp,'(g5.2)')+$
		' \times 10^{'+strtrim(itmp,2)+'}'
            endif
	  endif
	endif else begin
	  if fxk ne -1 then cfx=fldsep+strtrim(abs(fxk),2) else cfx=' '
	endelse
        c1=c1+cfx
      endif					;WRITE_FLUXE)
      if not keyword_set(asci) then c1=c1+'$'
    endif					;WRITE_FLUX)
    ;
    ;	level designations
    if keyword_set(trance) then begin		;(write level designations
      nlabl=n_elements(labl)
      c1=c1+fldsep
      if nlabl eq 2L*mw then begin
	ch1=strtrim(labl(0,j),2) & ch2=strtrim(labl(1,j),2)        
     	if not keyword_set(asci) then begin
    	    if ch1 eq '()' then ch1='' & if ch2 eq '()' then ch2=''
            if keyword_set(trancetex) then begin 
               if ch1 ne '' then ch1 = tekhi(ch1)
               if ch2 ne '' then ch2 = tekhi(ch2) 
            endif 
	    if ch1 ne '' and ch2 ne '' then ch='{\small '+ch2+' $\rightarrow$ '+ch1+'}'
	    if ch1 eq '' and ch2 ne '' then ch='{\small '+ch2+'}'
	    if ch1 ne '' and ch2 eq '' then ch='{\small '+ch1+'}'
	    if ch1 eq '' and ch2 eq '' then ch=' \hfil '
            chhh=ch
            if not keyword_set(trancetex) then begin 
	      chh=str_sep(ch,'_') & nchh=n_elements(chh)
	      chhh=chh(0)
	      for ich=1,nchh-1 do chhh=chhh+'\_'+chh(ich)
            endif
	endif else begin
	  if ch1 eq '()' then ch1='' & if ch2 eq '()' then ch2=''
	  if ch1 ne '' and ch2 ne '' then ch=ch2+' -> '+ch1
	  if ch1 eq '' and ch2 ne '' then ch=ch2
	  if ch1 ne '' and ch2 eq '' then ch=ch1
	  if ch1 eq '' and ch2 eq '' then ch=' '
	  chhh=ch
	endelse
	c1=c1+chhh
      endif else begin
	if keyword_set(asci) then c1=c1+' ' else c1=c1+' \hfil '
      endelse
    endif					;TRANCE)
    ;
    ;	comment
    if scratch ne '' then begin
      c1=c1+fldsep+' ('+strtrim(kcom,2)+')'
    endif
    ;
    if not keyword_set(asci) then c1=c1+' \\'
    printf,utex,c1
    ;
    k=k+1L
  endfor					;J=0,MW-1}
endfor						;I=0,NWVL-1}

;	print comments
if not keyword_set(asci) then begin
  if utex gt 0 and kcom gt 0 then printf,utex,'\multicolumn{6}{l}{NOTES:-} \\'
  for i=0L,kcom-1L do begin
    c1='\multicolumn{6}{l}{'+strtrim(i+1,2)+'.\ '+comm(i)+'} \\'
    if utex le 0 then c1=strtrim(i+1,2)+':-- '+comm(i)
    printf,utex,c1
  endfor
endif else begin
  if kcom gt 0 then printf,utex,'#NOTES:-'
  for i=0L,kcom-1L do printf,utex,'#'+strtrim(i+1,2)+':-- '+comm(i)
endelse

;	print footer
if utex gt 0 then for i=0L,nftr-1L do printf,utex,ftr(i)

if szf(nszf-2) eq 7 then begin
  close,utex & free_lun,utex			;close I/O}
endif

return
end
