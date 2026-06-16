;;; calling sequence: c = qso_continuum_fit(loglam, flux , error) ;;
                  ;where loglam is log of wavelength axis.
;
;  Another Feeble attempt to fit all QSO continuum robustly,
;   without prior knowledge of redshift or absorption properties
;
;
;  BUGS:  Large sky residuals are assumed to be emission lines with extra
;          absorption.  Need better masking of skylines (with bright sky?)
;
 
function qso_continuum_fit, loglam, flux, invvar, range=range, model1=model1, model2=model2, model3=model3,  mask=mask, firstpass=firstpass

    if (size(flux))[0] NE 1 then begin
         print, 'just 1d arrays for now'
         return,0
    endif

    firstpass = 30
    smoothscale  = 61           ;11
    weightsmooth = 25
    firstupper = 10.0
    firstlower = 2.0
    firstneighbor = fix(smoothscale / 2)
    bkptdist = 10000.

    npix = (size(loglam,/dimen))[0]

    mask = invvar LE 0
    tempivar = invvar
;    good = where(tempivar GT 0)
;    if good[0] NE -1 then $
;      tempivar[good] = 1.0/(tempivar[good] + flux[good]^2/400.0)
    maxiter = 50                ;20


    for iiter=1,maxiter do begin
      weight = (flux > 0)^2 * tempivar + 1.0
      weight = smooth(weight^1.2, weightsmooth)
      maxbkptdist = (total(weight) / 50.0)  
      minbkptdist = (total(weight) / 170.0)  
      tmpbkptdist = (bkptdist < maxbkptdist) > minbkptdist
      weight = weight / tmpbkptdist
      sumweight = weight 
      for i=1,npix-1 do sumweight[i] = sumweight[i-1] + weight[i]

      bkpt = loglam[uniq(long(sumweight))]
     ; help,bkpt

      firstset = bspline_iterfit(loglam, flux, invvar=tempivar, bkpt=bkpt, $
              /groupbadpix, maxrej=1, maxiter=20, upper=10., lower=firstlower, yfit=yfit1)

      diff = (flux-yfit1) * sqrt(tempivar)
      diffsmooth = smooth(diff,smoothscale) * sqrt(smoothscale)
    
      worst = min(diffsmooth,pl) 

      diffmask = diffsmooth LT -1.0 * firstlower   
      smoothmask = smooth(diffmask*smoothscale, smoothscale) GT 0

      firstmask = smoothmask AND (diffsmooth*diff GT firstlower^2)

      if total(firstmask) EQ 0 then break
      mask = mask OR (firstmask GT 0)   

      recoverdiff = (flux-yfit1) * sqrt(invvar)
      recover = where(recoverdiff GT -0.5 * firstlower)
      if recover[0] NE -1 then mask[recover] = 0
      tempivar = invvar * (mask EQ 0)     
                                ; wplot, loglam, flux, /xs, /nodata
                                ; wplot, loglam, flux
                                ;woplot, loglam, flux*(mask EQ 0)
                                ;woplot, loglam, yfit1, color=2,thick=2
                                ;woplot, bkpt, bkpt*0-1,ps=1
      
      print, worst, pl
;
;  What about edge effects (May 9, 2002)?
;    
 
    endfor
    

    secondpass = 5           ; 20
    secondset = bspline_iterfit(loglam, yfit1, invvar=tempivar, everyn=secondpass, $
                                yfit=yfit2,nord=4,upper=8.,lower=1)

    thirdpass = 10              ; 20
    thirdset = bspline_iterfit(loglam, yfit2, invvar=tempivar, everyn=thirdpass, $
                               yfit=yfit3,nord=7,upper=8.,lower=2)
    ;; forthpass = 5          ; 20
    ;; forthset = bspline_iterfit(loglam, yfit3, invvar=tempivar, everyn=forthpass, $
    ;;    yfit=yfit4,nord=7,upper=8.,lower=3)

    model1 = yfit1
    model2 = yfit2
    model3 = yfit3
                                ;stop
    ;woplot, loglam, yfit2,color=4,thick=2
                                ;woplot, loglam, yfit3,color=5,thick=2
                                ; woplot, loglam, yfit4,color=6,thick=2
    return,yfit2
 end

