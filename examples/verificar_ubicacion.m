function verificar_ubicacion
% Tests modal host acceptance/cancellation, bounds, and UI rendering.
root=fileparts(fileparts(mfilename('fullpath')));addpath(fullfile(root,'src'));
drive('accept');[lat,lon,ok,name]=seleccionar_ubicacion(40,-5,Nombre="Original",LatitudeLimits=[-65 65]);
assert(ok&&lat==40.386&&lon==-5.764&&strcmp(name,'Béjar'));
drive('cancel');[lat,lon,ok,name]=seleccionar_ubicacion(40,-5,Nombre="Original");
assert(~ok&&lat==40&&lon==-5&&strcmp(name,'Original'));
drive('invalid');[lat,lon,ok,~]=seleccionar_ubicacion(40,-5,LatitudeLimits=[-65 65]);
assert(~ok&&lat==40&&lon==-5);
disp('UBICACION: aceptación, cancelación y límites verificados');
    function drive(action)
        t=timer('StartDelay',5,'TimerFcn',@(~,~)interact(action),'StopFcn',@(obj,~)delete(obj));start(t);
    end
    function interact(action)
        f=findall(groot,'Tag','locationPicker');h=findall(f,'Tag','locationHTML');
        if strcmp(action,'accept')
            h.Data=struct('type','accept','lat',40.386,'lon',-5.764,'name','Béjar');feval(h.DataChangedFcn,h,[]);
        elseif strcmp(action,'invalid')
            h.Data=struct('type','accept','lat',80,'lon',0,'name','Fuera de límites');feval(h.DataChangedFcn,h,[]);
            assert(strcmp(f.WaitStatus,'waiting'));h.Data=struct('type','cancel');feval(h.DataChangedFcn,h,[]);
        else
            h.Data=struct('type','cancel');feval(h.DataChangedFcn,h,[]);
        end
    end
end
