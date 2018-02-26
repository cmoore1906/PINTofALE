function libmodel_f,x,a,pder,type=type,verbose=verbose, _extra=e
;+
;procedure	libmodel_f
;	function written to be compatible with MPFIT, and is
;	identical in all respects to LIBMODEL, except that this
;	is a function and not a procedure.
;	returns F(X;A) and computes dF/dA for a library of model functions.
;
;syntax
;	f=libmodel_f(x,a,pder,type=type,verbose=verbose,$
;	missing=missing,/norm,/fwhm,betap=betap,angle=angle,vrot=vrot,$
;	Xo=Xo,pbreak=pbreak,NH=NH,wvlar=wvlar,effar=effar,exptime=exptime,$
;	dellam=dellam,X0=X0)
;
;parameters
;	x	[INPUT; required] points at which to generate models
;	a	[INPUT; required] array of parameter values
;		* should match the number expected from TYPE.
;		* no checks are made to verify that the user is not shooting
;		  hirself in the foot.
;	pder	[OUTPUT; optional] partial derivatives for each parameter
;
;keywords
;	type	[INPUT; required] string array denoting the model functions
;		to be called.
;		* this should rightly be a parameter, because it is
;		  a very necessary part of the program.  however, most
;		  fitting functions do not allow that degree of flexibility
;		  and so we are forced to use this hack.
;	verbose	[INPUT; default=0] controls chatter
;
;	_extra	[INPUT] pass defined keywords to subroutines
;		MK_GAUSS: MISSING, FWHM, NORM
;		MK_LORENTZ: BETAP, MISSING, NORM
;		MK_SLANT: ANGLE, BETAP, MISSING, NORM
;		MK_ROGAUSS: VROT, FWHM, NORM, MISSING
;		MK_POWLAM: XO,PBREAK,NH,WVLAR,EFFAR,EXPTIME,DELLAM
;		MK_POLY1D: X0
;
;subroutines
;	MK_GAUSS
;	MK_LORENTZ
;	MK_SLANT
;	MK_ROGAUSS
;	MK_POWLAM
;	MK_POLY1D
;
;history
;	vinay kashyap (Oct02; converted from LIBMODEL)
;-

;	usage
ok='ok' & np=n_params(0) & nx=n_elements(x) & na=n_elements(a)
nt=n_elements(type)
if np lt 3 then ok='Insufficient parameters' else $
 if nx eq 0 then ok='X is undefined' else $
  if na eq 0 then ok='A is undefined' else $
   if nt eq 0 then ok='TYPE is required'
if ok ne 'ok' then begin
  print,'Usage: f=libmodel(x,a,pder,type=type,verbose=verbose,$'
  print,'       missing=missing,/norm,/fwhm,betap=betap,angle=angle,$'
  print,'       vrot=vrot,Xo=Xo,pbreak=pbreak,NH=NH,wvlar=wvlar,$'
  print,'       effar=effar,exptime=exptime,dellam=dellam,X0=X0)'
  print,'  evaluate F and partial(F)/partial(A) at X for parameters A'
  print,'  TYPE may be any of:'
  print,'  	Gaussian (g; gauss; Gauss; etc -- 3 parameters)'
  print,'  	Lorentzian (l; lorentz; Lorentzian; etc -- 3 parameters)'
  print,'  	Beta-profile (b; beta=value; Beta:value; etc -- 4 parameters)'
  print,'  	asymmetric beta (s; slant=angle,beta; slant:angle,beta; etc -- 5 parameters)'
  print,'  	rotation broadened Gaussian (r; rot=value; etc -- 4 parameters)'
  print,'  	power-law (pw; pw=break; pw@break; etc -- 4 parameters)'
  print,'  	polynomial (po=N; poly:N; polynomial=N; etc -- N parameters)'
  if np ne 0 then message,ok,/info
  return,-1L
endif

;	verbosity
vv=0 & if keyword_set(verbose) then vv=long(verbose[0])>1

;	output
f=fltarr(nx) & pder=fltarr(nx,na)

;	call each model function in sequence
k0=-1L & k1=0L	;parameter count
for i=0L,nt-1L do begin			;{stepping through the TYPEs
  cc=strtrim(type[i],2) & c1=strlowcase(strmid(cc,0,1))
  case c1 of				;{usually enough to tell

    'g': begin			;{Gaussian
      npar=3	;number of parameters (pos,wdt,hgt)
      k0=k0+1L & k1=k0+npar-1L
      if na-1L lt k1 then begin
	message,'insufficient parameters specified for MK_GAUSS()',/info
	return,-1L
      endif
      pos=a[k0] & wdt=a[k0+1] & hgt=a[k0+2]
      if np lt 3 then mm=mk_gauss(x,pos,wdt,hgt, _extra=e) else $
	mm=mk_gauss(x,pos,wdt,hgt,pd, _extra=e)
    end				;Gaussian}

    'l': begin			;{Lorentzian
      npar=3	;number of parameters (pos,wdt,hgt)
      k0=k0+1L & k1=k0+npar-1L
      if na-1L lt k1 then begin
	message,'insufficient parameters specified for MK_LORENTZ()',/info
	return,-1L
      endif
      pos=a[k0] & wdt=a[k0+1] & hgt=a[k0+2]
      if np lt 3 then mm=mk_lorentz(x,pos,wdt,hgt, _extra=e) else $
	mm=mk_lorentz(x,pos,wdt,hgt,pd, _extra=e)
    end				;Lorentzian}

    'b': begin			;{modified beta-profile
      npar=4	;number of parameters (pos,wdt,hgt,betap)
      c=str_sep(cc,'=')                     & nc=n_elements(c)
      if nc eq 1 then c=str_sep(cc,' ')     & nc=n_elements(c)
      if nc eq 1 then c=str_sep(cc,'	')  & nc=n_elements(c)
      if nc eq 1 then c=str_sep(cc,':')     & nc=n_elements(c)
      if nc gt 1 then begin
	betap=float(c[1]) & npar=3	;because BETAP is fixed
      endif else betap=1.	;the default
      k0=k0+1L & k1=k0+npar-1L
      if na-1L lt k1 then begin
	message,'insufficient parameters specified for MK_LORENTZ()',/info
	return,-1L
      endif
      pos=a[k0] & wdt=a[k0+1] & hgt=a[k0+2] & if npar eq 4 then betap=a[k0+3]
      if np lt 3 then mm=mk_lorentz(x,pos,wdt,hgt,betap=betap,_extra=e) else $
	mm=mk_lorentz(x,pos,wdt,hgt,pd,betap=betap, _extra=e)
    end				;modified beta-profile}

    's': begin			;{asymmetrical beta-profile
      npar=5	;number of parameters (pos,wdt,hgt,betap,angle)
      c=str_sep(cc,'=')                     & nc=n_elements(c)
      if nc eq 1 then c=str_sep(cc,' ')     & nc=n_elements(c)
      if nc eq 1 then c=str_sep(cc,'	')  & nc=n_elements(c)
      if nc eq 1 then c=str_sep(cc,':')     & nc=n_elements(c)
      if nc gt 1 then begin
	cb=str_sep(c[1],',') & ncb=n_elements(cb)
	if ncb eq 1 then cb=str_sep(c[1],' ') & ncb=n_elements(cb)
	if ncb eq 1 then cb=str_sep(c[1],'	') & ncb=n_elements(cb)
	if strtrim(cb[0],2) ne '' then begin
	  angle=float(cb[0]) & npar=4	;because ANGLE is fixed
	endif else angle=0.
	if ncb gt 1 then begin
	  if strtrim(cb[1],2) ne '' then betap=float(cb[1])
	  npar=npar-1	;because BETAP is also fixed
	endif else betap=1.
      endif
      k0=k0+1L & k1=k0+npar-1L
      if na-1L lt k1 then begin
	message,'insufficient parameters specified for MK_SLANT()',/info
	return,-1L
      endif
      pos=a[k0] & wdt=a[k0+1] & hgt=a[k0+2]
      if npar eq 4 then angle=a[k0+3]
      if npar eq 5 then betap=a[k0+4]
      if np lt 3 then $
	mm=mk_slant(x,pos,wdt,hgt,angle=angle,betap=betap, _extra=e) else $
	mm=mk_slant(x,pos,wdt,hgt,pd,angle=angle,betap=betap, _extra=e)
    end				;asymmetrical beta-profile}

    'r': begin			;{Rotationally convolved Gaussian
      npar=4	;number of parameters (pos,wdt,hgt,vrot)
      c=str_sep(cc,'=')                     & nc=n_elements(c)
      if nc eq 1 then c=str_sep(cc,' ')     & nc=n_elements(c)
      if nc eq 1 then c=str_sep(cc,'	')  & nc=n_elements(c)
      if nc eq 1 then c=str_sep(cc,':')     & nc=n_elements(c)
      if nc gt 1 then begin
	vrot=float(c[1]) & npar=3	;because VROT is fixed
      endif else vrot=0.	;the default
      k0=k0+1L & k1=k0+npar-1L
      if na-1L lt k1 then begin
	message,'insufficient parameters specified for MK_ROGAUSS()',/info
	return,-1L
      endif
      pos=a[k0] & wdt=a[k0+1] & hgt=a[k0+2] & if npar eq 4 then vrot=a[k0+3]
      if np lt 3 then mm=mk_rogauss(x,pos,wdt,hgt,vrot=vrot,_extra=e) else $
	mm=mk_rogauss(x,pos,wdt,hgt,pd,vrot=vrot, _extra=e)
    end				;Rotationally convolved Gaussian}

    'p': begin			;{polynomial or power-law
      mtyp='unknown'
      if strpos(cc,'pl') ge 0 or strpos(cc,'power') ge 0 or $
	 strpos(cc,'pw') ge 0 or strpos(cc,'pe') ge 0 then mtyp='power-law'
      if strpos(cc,'po') ge 0 or strpos(cc,'poly') ge 0 then mtyp='polynomial'
      case mtyp of
	'power-law': begin		;{power-law
	  message,cc+': sorry, not implemented yet',/info
	  npar=4	;number of parameters (gamma1,gamma2,norm,pbreak)
          c=str_sep(cc,'=')                         & nc=n_elements(c)
          if nc eq 1 then c=str_sep(cc,' ')         & nc=n_elements(c)
          if nc eq 1 then c=str_sep(cc,'	')  & nc=n_elements(c)
          if nc eq 1 then c=str_sep(cc,':')         & nc=n_elements(c)
          if nc eq 1 then c=str_sep(cc,'@')         & nc=n_elements(c)
	  if nc gt 1 then begin
	    pbreak=float(c[1]) & npar=3	;because PBREAK is fixed
	  endif else pbreak=1.	;the default
	  k0=k0+1L & k1=k0+npar-1L
	  if na-1L lt k1 then begin
	    message,'insufficient parameters specified for MK_POWLAM()',/info
	    return,-1L
	  endif
	  c2=strmid(cc,0,2) & ptyp='pw'
	  if c2 ne 'pw' and c2 ne 'pe' then begin
	    message,'Power-law form not understood.  using PL[w]',/info
	    ptyp='pw'
	  endif
	  if ptyp eq 'pw' then begin
	    pa1=a[k0] & pa2=a[k0+1] & pn=a[k0+2]
	    if npar eq 4 then pbreak=a[k0+3]
	    if np lt 3 then $
		mm=mk_powlam(x,pa1,pa2,pn,pbreak=pbreak,_extra=e) else $
		mm=mk_powlam(x,pa1,pa2,pn,pd,pbreak=pbreak,_extra=e)
	  endif else begin
	    message,'PL(E) not implemented yet, sorry'
	    mm=0.*x & if np ge 4 then pd=fltarr(nx,npar)
	  endelse
	end				;power-law}
	'polynomial': begin
          c=str_sep(cc,'=')                         & nc=n_elements(c)
          if nc eq 1 then c=str_sep(cc,' ')         & nc=n_elements(c)
          if nc eq 1 then c=str_sep(cc,'	')  & nc=n_elements(c)
          if nc eq 1 then c=str_sep(cc,':')         & nc=n_elements(c)
          if nc gt 1 then begin
	    npar=long(c[1])
	    k0=k0+1L & k1=k0+npar-1L
	    if na-1L lt k1 then begin
	      message,'insufficient parameters specified for '+$
		'MK_POLY1D()',/info
	    endif
	    aa=a[k0:k1]
	    if np lt 3 then mm=mk_poly1d(x,aa, _extra=e) else $
		mm=mk_poly1d(x,aa,pd, _extra=e)
	  endif else begin
	    ;no other way to know!
	    message,cc+': unknown number of coefficients for MK_POLY1D()',/info
	  endelse
	end
        else: message,cc+': model type not understood',/info
      endcase
    end				;polynomial or power-law}

    else: message,cc+': model type not understood',/info

  endcase				;case C1}

  f=f+mm
  if np eq 4 then for j=0,npar-1 do pder[*,k0+j]=pd[*,j]
  k0=k1 & k1=k1+1L
endfor					;I=0,NT-1}

return,f
end
