pro get_abs_plot,num

  common GMW_1,dir_name,file,zabs,name,N_Spectra_files,file_index,file1
  common GAP,wav,flux,sig,conti, rwave, mgii_ratio,w_obs_mgii,id_plot_mgii,n_plot_mgii
  COMMON GMW_2, drawID_LEFT,drawID_RIGHT
  COMMON GVP, z,id_plot,n_plot,w_obs
  COMMON MVCE, ew1,ew2,sigew1,sigew2,zabs1,zabs2
  
  mgii_ratio = 2803.5310/2796.3520
  ;;;readcol,file(num),wav,flux,sig,conti

  aa= mrdfits(file(num),1,h)   
  gdpix= where(aa.IVAR GT 0. and   FINITE(aa.IVAR) , cntpix)
  wav = (10.^aa.LOGLAM)(gdpix) & flux = (aa.FLUX)(gdpix) & sig = (SQRT(1d/aa.IVAR))(gdpix) & conti = (aa.MODEL)(gdpix)
   
  rwave= [2796.3520d,2803.5310d, 2852.963108d,2600.1729d]

  w_obs_mgii = (1.0 + zabs(file_index) )* 2796.3520
  id_plot_mgii = where( wav ge (w_obs_mgii - 70.0) and wav le (w_obs_mgii + 70.0), n_plot_mgii )
  
  return
end

pro get_vel_plot,num,rest_wave
  common GMW_1,dir_name,file,zabs,name,N_Spectra_files,file_index,file1
common GAP,wav,flux,sig,conti, rwave, mgii_ratio,w_obs_mgii,id_plot_mgii,n_plot_mgii
COMMON GMW_2, drawID_LEFT,drawID_RIGHT
COMMON GVP, z,id_plot,n_plot,w_obs
COMMON MVCE, ew1,ew2,sigew1,sigew2,zabs1,zabs2

  w_obs = (1.0 + zabs(file_index) ) * rest_wave
  id_plot = where( wav ge (w_obs - 70.0) and wav le (w_obs + 70.0), n_plot )
  if n_plot gt 10 then z = 299792.46*(wav( id_plot) /w_obs - 1)
           
  return
end
PRO mgii_visual_check_event, ev

common GMW_1,dir_name,file,zabs,name,N_Spectra_files,file_index,file1
common GAP,wav,flux,sig,conti, rwave, mgii_ratio,w_obs_mgii,id_plot_mgii,n_plot_mgii
COMMON GMW_2, drawID_LEFT,drawID_RIGHT
COMMON GVP, z,id_plot,n_plot,w_obs
COMMON MVCE, ew1,ew2,sigew1,sigew2,zabs1,zabs2

  widget_control,ev.id,get_uvalue=uvalue

  CASE uvalue OF
     'Next':  $
       begin
         ;print,'Next button pressed...'
         If file_index LE N_Spectra_files - 2 Then Begin
           file_index = file_index + 1
         Endif  Else Begin
           ans = Dialog_Message('No More Spectra File...')
           RETURN
         Endelse
         get_abs_plot,file_index

        if n_plot_mgii gt 10 then begin
          title=string(file_index)+': '+name(file_index)+' '+'zabs= '+string(zabs(file_index))
          plot,wav(id_plot_mgii),flux(id_plot_mgii)/conti(id_plot_mgii),title=title
          oplot,wav(id_plot_mgii)*mgii_ratio,flux(id_plot_mgii)/conti(id_plot_mgii),color=2
          oplot,[(1.0+zabs(file_index))*rwave(1) -0.0005,(1.0+zabs(file_index))*rwave(1)+0.0005],[-10.,10.],color=4,thick=2,linestyle=2
          ;oplot,[civ-0.0005,civ+0.0005],[-1000.,1000.],color=2,thick=4,linestyle=2
          ;oplot,[siv-0.0005,siv+0.0005],[-1000.,1000.],color=2,thick=4,linestyle=2
         endif
         ; Draw plot in RIGHT window         
         
         WSET, drawID_RIGHT
          !P.Multi = [0, 1, 4]
           get_vel_plot,slect_index,rwave(0)
          if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.80, 0.95, 0.98] $
          else vline,w_obs
          vline,0
          get_vel_plot,slect_index,rwave(1)
           if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.55, 0.95, 0.75] $
           else vline,w_obs
           get_vel_plot,slect_index,rwave(2)
           vline,0
           if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.30, 0.95, 0.50] $
           else vline,0
           vline,0
          get_vel_plot,slect_index,rwave(3)
          if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.05, 0.95, 0.25] $
          else vline,0
          vline,0
          !P.Multi = 0
       
         WSET, drawID_LEFT
         
         ;; endif else begin
      ;;    printf,2,fit_dr5(file_index),fit_dr12(file_index),zemi(file_index),name(file_index),f='(A,2x,A,f17.3,2x,A)'
      ;;    print,'Redshift too small for '+name(file_index)
      ;; endelse
         
        end
     'Back': begin
       ;print,'back button pressed...'
         If file_index GE 1 Then Begin
           file_index = file_index - 1
         Endif  Else Begin
           ans = Dialog_Message('At beginning of Spectra Files...')
           RETURN
         Endelse

         get_abs_plot,file_index
         if n_plot_mgii gt 10 then begin
            title=string(file_index)+': '+name(file_index)+' '+'zabs= '+string(zabs(file_index))
            plot,wav(id_plot_mgii),flux(id_plot_mgii)/conti(id_plot_mgii),title=title
           
          oplot,wav(id_plot_mgii)*mgii_ratio,flux(id_plot_mgii)/conti(id_plot_mgii),color=2
          oplot,[(1.0+zabs(file_index))*rwave(1) -0.0005,(1.0+zabs(file_index))*rwave(1)+0.0005],[-10.,10.],color=4,thick=2,linestyle=2
          
          ;oplot,[siv-0.0005,siv+0.0005],[-1000.,1000.],color=2,thick=4,linestyle=2
         endif
         ; Draw plot in RIGHT window         
         
         WSET, drawID_RIGHT   
           !P.Multi = [0, 1, 4]
           get_vel_plot,slect_index,rwave(0)
          if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.80, 0.95, 0.98] $
          else vline,w_obs
          vline,0
          get_vel_plot,slect_index,rwave(1)
           if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.55, 0.95, 0.75] $
           else vline,w_obs
           get_vel_plot,slect_index,rwave(2)
           vline,0
           if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.30, 0.95, 0.50] $
           else vline,0
           vline,0
          get_vel_plot,slect_index,rwave(3)
          if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.05, 0.95, 0.25] $
          else vline,0
          vline,0
          !P.Multi = 0
          
         ;  plot some stuff in RIGHT window...  
                                ;
         WSET, drawID_LEFT
         
        ;;  endif else begin
      ;;    printf,2,fit_dr5(file_index),fit_dr12(file_index),zemi(file_index),name(file_index),f='(A,2x,A,f17.3,2x,A)'
      ;;    print,'Redshift too small for '+name(file_index)
      ;; endelse
         
      end

     'Get_EW': begin
             
         id_plot_mgii_zoom = where( wav ge (w_obs_mgii - 50.0) and wav le (w_obs_mgii + 50.0))
            title=string(file_index)+': '+name(file_index)+' '+'zabs= '+string(zabs(file_index))
            plot,wav(id_plot_mgii_zoom),flux(id_plot_mgii_zoom)/conti(id_plot_mgii_zoom),title=title
           ; oplot,wav(id_plot_mgii_zoom)*mgii_ratio,flux(id_plot_mgii_zoom)/conti(id_plot_mgii_zoom),color=2
            vline,[(1.0+zabs(file_index))*rwave(0)],color=4,thick=2,linestyle=2
             
            cursor,x1,y1
            print,'x1,y1',x1,y1
            wait,1
            cursor,x2,y2
            print,'x2,y2',x2,y2
            wait,1
            idx_ok= Where(wav gt x1 and wav lt x2, cnt_idx)
            if cnt_idx gt 0 then mn = min(flux(idx_ok),min_idx) else stop 
            if n_elements(min_idx) gt 1 then cent = wav(idx_ok(median(min_idx))) $
            else cent = wav(idx_ok(min_idx))
            zabs1 = cent/rwave(0)-1.0

            dwv = wav - shift(wav,1)
            mn = min(abs(wav-x1),ilhs)
            mn = min(abs(wav-x2),irhs)

            ew1 = total( (1.-flux[ilhs:irhs]/conti[ilhs:irhs]) $
                              *dwv[ilhs:irhs]) / (1.+zabs1)

            sigew1 = sqrt(total( (sig[ilhs:irhs]/conti[ilhs:irhs] $
                                       *dwv[ilhs:irhs])^2)) $
                    / (1.+zabs1)
            ;wait,1

            ;; ======== for line 2=============
            title=string(file_index)+': '+name(file_index)+' '+'zabs= '+string(zabs(file_index))
            plot,wav(id_plot_mgii_zoom),flux(id_plot_mgii_zoom)/conti(id_plot_mgii_zoom),title=title
            ;oplot,wav(id_plot_mgii_zoom)*mgii_ratio,flux(id_plot_mgii_zoom)/conti(id_plot_mgii_zoom),color=2
            vline,[(1.0+zabs(file_index))*rwave(1)],color=4,thick=2,linestyle=2
            cursor,x1,y1
            print,'x1,y1',x1,y1
            wait,1
            cursor,x2,y2
            print,'x2,y2',x2,y2
            wait,1
            idx_ok= Where(wav gt x1 and wav lt x2, cnt_idx)
            if cnt_idx gt 0 then mn = min(flux(idx_ok),min_idx) else stop 
            if n_elements(min_idx) gt 1 then cent = wav(idx_ok(median(min_idx))) $
            else cent = wav(idx_ok(min_idx))

            zabs2 = cent/rwave(1)-1.0

            dwv = wav - shift(wav,1)
            mn = min(abs(wav-x1),ilhs)
            mn = min(abs(wav-x2),irhs)

            ew2 = total( (1.-flux[ilhs:irhs]/conti[ilhs:irhs]) $
                              *dwv[ilhs:irhs]) / (1.+zabs2)

            sigew2 = sqrt(total( (sig[ilhs:irhs]/conti[ilhs:irhs] $
                                       *dwv[ilhs:irhs])^2)) $
                          / (1.+zabs2)
       
 

          print,zabs1,zabs2,ew1,sigew1,ew2,sigew2
            
          ;wait,1
          title=string(file_index)+': '+name(file_index)+' '+'zabs= '+string(zabs(file_index))
          plot,wav(id_plot_mgii),flux(id_plot_mgii)/conti(id_plot_mgii),title=title
          oplot,wav(id_plot_mgii)*mgii_ratio,flux(id_plot_mgii)/conti(id_plot_mgii),color=2
          oplot,[(1.0+zabs(file_index))*rwave(1) -0.0005,(1.0+zabs(file_index))*rwave(1)+0.0005],[-10.,10.],color=4,thick=2,linestyle=2
        end

     'Save':    begin

              ew_file_name = dir_name(file_index)+'ewzabs_wc_'+name(file_index)+'.dat'

              ;ew_file_name = dir_name(file_index)+'ewzabs_'+file1(file_index)
              
               ;; openw,5,ew_file_name,/append
               ;; printf,5,'#qso_name       z_abs    ew_1    ew_err1   ew_2    ew_err3  ew_1/ew_3'
               ;; printf,5, format='(a18,1x,f7.5,2x,f7.4,2x,f7.4,2x,f7.4,2x,f7.4,2x,f7.4)',$
               ;;                          name(file_index),(zabs1+zabs2)/2.0,ew1,sigew1, $
               ;;        ew2,sigew2,ew1/ew2
               ;; close,5

         test = FILE_test(ew_file_name)

            if test eq 0 then begin
               openw,5,ew_file_name,/append
               printf,5,'#qso_name       z_abs    ew_1    ew_err1   ew_2    ew_err3  ew_1/ew_3'
                printf,5, format='(a20,1x,f10.3,2x,f10.3,2x,f10.3,2x,f10.3,2x,f10.3,2x,f10.3)',$
                                        name(file_index),(zabs1+zabs2)/2.0,ew1,sigew1, $
                       ew2,sigew2,ew1/ew2
                close,5
            endif else begin
            openw,5,ew_file_name ,/append
            printf,5, format='(a20,1x,f10.3,2x,f10.3,2x,f10.3,2x,f10.3,2x,f10.3,2x,f10.3)',$
                                        name(file_index),(zabs1+zabs2)/2.0,ew1,sigew1, $
                      ew2,sigew2,ew1/ew2
            close,5
            endelse
             ;;  printf,1,fit_dr5(file_index),fit_dr12(file_index),zemi(file_index),name(file_index),f='(A,2x,A,f17.3,2x,A)'
            ;; print,'Saving file '+string(file_index)+', For source
            ;; '+name(file_index)
            print,'Absrober: '+string((zabs1+zabs2)/2.0)+' got saved in file: '+ ew_file_name
       end
        
    'Done': $
      begin
       ans = Dialog_Message('EXIT PROGRAM : Are you sure?')
       print,'Upto source'+string(file_index)+' code has been run' 
       close,1,2,5
         if STRUPCASE(ans) EQ 'OK' Then  WIDGET_CONTROL, ev.TOP, /DESTROY
      end

  ENDCASE

END

PRO mgii_visual_check

 
common GMW_1,dir_name,file,zabs,name,N_Spectra_files,file_index,file1
common GAP,wav,flux,sig,conti, rwave, mgii_ratio,w_obs_mgii,id_plot_mgii,n_plot_mgii
COMMON GMW_2, drawID_LEFT,drawID_RIGHT
COMMON GVP, z,id_plot,n_plot,w_obs
COMMON MVCE, ew1,ew2,sigew1,sigew2,zabs1,zabs2

  close,/all
  
  ;cd,'f:\idl\sapna\'
  
  ;spawn,'rm -rf interesting_sources.txt'
 ; spawn,'rm -rf bad_sources.txt'
  
 ; openw,1,'interesting_sources.txt' ,/append
 ; openw,2,'bad_sources.txt' ,/append
  

  readcol,'Mgii_result.txt',dir_name,file1,zabs,name,f='(A,A,f,A)' ,skipline=1  ;;;,numline=195
  
  file_index = 0
  N_Spectra_files = N_Elements(file1)

  file = dir_name+file1
  ; MUST DO THIS IF YOU WANT CORRECT 24bit COLOR!!
    device,DECOMP=0
 
  base = WIDGET_BASE(/row,TITLE="Sapna's doublet-finder Plotting GUI")
  base1  = WIDGET_BASE(base,/row)

  Left_Column_base = WIDGET_BASE(base1,/column)
  draw_left = WIDGET_DRAW(Left_Column_base, XSIZE=1000, YSIZE=600)
  
  Button_base = widget_BASE(Left_Column_base,/ROW, XSIZE=500, YSIZE=60)
  back_id = widget_button(Button_base,Value='Back',Uvalue = 'Back',/frame,xsize=120)
  Next_id = widget_button(Button_base,Value='Next',Uvalue = 'Next',/frame,xsize=120)
  save_id = widget_button(Button_base,Value='Save',Uvalue = 'Save',/frame,xsize=120)
  Done_id = widget_button(Button_base,Value='Done',Uvalue = 'Done',/frame,xsize=120)
  Get_EW_id = widget_button(Button_base,Value='Get_EW',Uvalue = 'Get_EW',/frame,xsize=120)
  
  Left_Column_base = WIDGET_BASE(base1,/column )
  draw_right = WIDGET_DRAW(Left_Column_base, XSIZE=200, YSIZE=600)
  
  
  WIDGET_CONTROL, base, /REALIZE
  WIDGET_CONTROL, draw_left, GET_VALUE=drawID_LEFT
  WIDGET_CONTROL, draw_right, GET_VALUE=drawID_RIGHT
 
 ; display graphics in LEFT window
  
  WSET,drawID_LEFT
  !P.position=[0.1,0.1,0.9,0.9]

  get_abs_plot,file_index
  
   w_obs_mgii = (1.0 + zabs(file_index) )* 2796.3520
   id_plot_mgii = where( wav ge (w_obs_mgii - 70.0) and wav le (w_obs_mgii + 70.0), n_plot_mgii )

   if n_plot_mgii gt 10 then begin
          title=string(file_index)+': '+name(file_index)+' '+'zabs= '+string(zabs(file_index))
          plot,wav(id_plot_mgii),flux(id_plot_mgii)/conti(id_plot_mgii),title=title
          oplot,wav(id_plot_mgii)*mgii_ratio,flux(id_plot_mgii)/conti(id_plot_mgii),color=2
          oplot,[(1.0+zabs(file_index))*rwave(1) -0.0005,(1.0+zabs(file_index))*rwave(1)+0.0005],[-10.,10.],color=4,thick=2,linestyle=2
          
         ; oplot,[civ-0.0005,civ+0.0005],[-1000.,1000.],color=2,thick=4,linestyle=2
         ; oplot,[siv-0.0005,siv+0.0005],[-1000.,1000.],color=2,thick=4,linestyle=2
          endif
         
           WSET, drawID_RIGHT

            !P.Multi = [0, 1, 4]
           get_vel_plot,slect_index,rwave(0)
          if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.80, 0.95, 0.98] $
          else vline,w_obs
          vline,0
          get_vel_plot,slect_index,rwave(1)
           if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.55, 0.95, 0.75] $
           else vline,w_obs
           get_vel_plot,slect_index,rwave(2)
           vline,0
           if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.30, 0.95, 0.50] $
           else vline,0
           vline,0
          get_vel_plot,slect_index,rwave(3)
          if n_plot gt 10 then plot,z,flux(id_plot)/conti(id_plot),xrange=[-1000,1000],yrange=[0.0,1.2],Position=[0.10, 0.05, 0.95, 0.25] $
          else vline,0
          vline,0
          !P.Multi = 0
          
         
         WSET, drawID_LEFT
         
  XMANAGER, 'mgii_visual_check', base, /NO_BLOCK
 
END

