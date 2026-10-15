function fig = pv_filas_visualizador(visible)
% PV_FILAS_VISUALIZADOR Visualizador didáctico sin toolboxes adicionales.
% pv_filas_visualizador; Este negativo / Oeste positivo.
if nargin<1, visible='on'; end
fig=uifigure('Name','Tecnología e Instalaciones Fotovoltaicas: Geometría Solar.','Position',[60 40 1500 950],'Visible',visible);
outer=uigridlayout(fig,[2 1]); outer.RowHeight={70,'1x'};
header=uigridlayout(outer,[1 2]);header.ColumnWidth={220,'1x'};
logo=uiimage(header,'ImageSource',fullfile(fileparts(fileparts(mfilename('fullpath'))),'assets','usal.png'),'ScaleMethod','fit');
uilabel(header,'Text',{'Escuela Técnica Superior de Ingeniería Industrial. Área de Tecnología Electrónica', ...
    'Tecnología e Instalaciones Fotovoltaicas: Geometría Solar.'},'FontSize',18,'FontWeight','bold');
layout=uigridlayout(outer,[1 2]); layout.ColumnWidth={320,'1x'};
controls=uigridlayout(layout,[20 2]); controls.ColumnWidth={155,'1x'};controls.Scrollable='on';
controls.RowSpacing=5;
controls.RowHeight=[repmat({30},1,14),{40,35,55,115,'1x',25}];
lat=number('Latitud (° N)',40,[-65 65]);
lon=number('Longitud (° E)',-5,[-180 180]);
uilabel(controls,'Text','Emplazamiento');locationName=uieditfield(controls,'text','Value','Punto seleccionado','Tag','locationName');
mapButton=uibutton(controls,'Text','Seleccionar en mapa…','Tag','selectLocation','ButtonPushedFcn',@selectLocation);mapButton.Layout.Column=[1 2];
alpha=number('Acimut (°)',0,[-90 90]);
beta=number('Inclinación (°)',30,[0 45]);
W=number('Longitud fila (m)',10,[.1 1000]);
L=number('Anchura inclinada (m)',2,[.1 100]);
n=number('Número de filas',5,[1 30]); n.RoundFractionalValues='on';
h=number('Borde inferior (m)',.3,[0 20]);
uilabel(controls,'Text','Fecha'); date=uidatepicker(controls,'Value',datetime(year(datetime('today')),12,21),'DisplayFormat','dd/MM/yy');
hourlabel=uilabel(controls,'Text','Hora solar'); hour=uieditfield(controls,'numeric','Value',12,'Limits',[0 24]);
apply=uibutton(controls,'Text','Actualizar','ButtonPushedFcn',@rebuild); apply.Layout.Column=[1 2];
play=uibutton(controls,'Text','Animar día','ButtonPushedFcn',@animate); play.Layout.Column=[1 2];
slider=uislider(controls,'Limits',[0 24],'Value',12,'MajorTicks',[0 6 12 18 24]); slider.Layout.Column=[1 2];
uilabel(controls,'Text','Separación automática'); uilabel(controls,'Text','Invierno ±1,5 h');
status=uilabel(controls,'Text','','WordWrap','on'); status.Layout.Column=[1 2];
summary=uilabel(controls,'Text','','WordWrap','on'); summary.Layout.Column=[1 2];
note=uilabel(controls,'Text','Terreno horizontal. Hora civil: Europe/Madrid (incluye horario de verano). La fecha cambia las sombras; el paso se diseña para el solsticio de invierno.','WordWrap','on'); note.Layout.Column=[1 2];
key=uilabel(controls,'Text','Azul oscuro: incidencia posterior · rojo: sombra','FontSize',10,'WordWrap','on'); key.Layout.Column=[1 2];
views=uigridlayout(layout,[2 2]); views.RowHeight={'2.4x','1x'};
ax3=uiaxes(views); ax2=uiaxes(views);
bottom=uigridlayout(views,[1 2]);bottom.Layout.Row=2;bottom.Layout.Column=[1 2];
bottom.ColumnWidth={'1x',150};bottom.Padding=[0 0 0 0];
daily=uiaxes(bottom);
timepanel=uigridlayout(bottom,[6 1]);timepanel.RowHeight={25,30,25,30,65,'1x'};timepanel.Padding=[0 0 0 0];
uilabel(timepanel,'Text','Referencia horaria:');
mode=uidropdown(timepanel,'Items',{'Hora solar','Hora civil'},'Value','Hora solar','Tag','referenciaHoraria');
uilabel(timepanel,'Text','Huso civil:');
zone=uieditfield(timepanel,'text','Value','Europe/Madrid','Tag','husoCivil');
uilabel(timepanel,'Text','Ángulo con el plano: positivo frontal, negativo posterior. ≤ 0°: 100% sin Sol frontal.','WordWrap','on','FontSize',11);
cached=[]; params=[]; busy=false; running=false; currentMode='Hora solar';
mode.ValueChangedFcn=@switchmode;zone.ValueChangedFcn=@rebuild;
slider.ValueChangingFcn=@(~,e) showhour(e.Value);
slider.ValueChangedFcn=@(~,~) showhour(slider.Value);
hour.ValueChangedFcn=@(~,~) showhour(hour.Value);
for c=[lat lon alpha beta W L n h], c.ValueChangedFcn=@rebuild; end
lat.ValueChangedFcn=@coordinatesChanged;lon.ValueChangedFcn=@coordinatesChanged;
date.ValueChangedFcn=@rebuild;
fig.CloseRequestFcn=@closeapp;
rebuild();

    function field=number(label,value,limits)
        uilabel(controls,'Text',label); field=uieditfield(controls,'numeric','Value',value,'Limits',limits);
    end
    function rebuild(varargin)
        if busy, return; end
        running=false; play.Text='Animar día'; busy=true;
        cleanup=onCleanup(@() release());
        try
            params=struct('lat',lat.Value,'lon',lon.Value,'alpha',alpha.Value,'beta',beta.Value, ...
                'W',W.Value,'L',L.Value,'n',n.Value,'h',h.Value);
            status.Text='Calculando evolución diaria…'; drawnow;
            cached=pv_filas_modelo(params,date.Value,tosolar(0:.25:24));
            cla(daily,'reset');yyaxis(daily,'left');
            curves=plot(daily,0:.25:24,100*cached.fraccion,'LineWidth',1.2);
            colors=lines(params.n);
            for j=1:params.n,curves(j).Color=colors(j,:);curves(j).Marker='none';curves(j).LineStyle='-';end
            xlabel(daily,mode.Value); ylabel(daily,'Superficie sombreada (%)');hourlabel.Text=mode.Value;
            title(daily,'Evolución diaria por fila'); grid(daily,'on'); ylim(daily,[0 100]); xlim(daily,[0 24]);
            yyaxis(daily,'right');hold(daily,'on');
            inc=plot(daily,0:.25:24,cached.incidencia,'--','Color',[.6 .15 .65],'LineWidth',1.6,'Tag','incidencia');
            hold(daily,'off');
            ylabel(daily,'Ángulo con el plano (°)');ylim(daily,[-90 90]);yticks(daily,-90:30:90);
            yline(daily,0,':','Color',[.6 .15 .65],'HandleVisibility','off');
            daily.YAxis(2).Color=[.6 .15 .65];
            yyaxis(daily,'left');daily.YAxis(1).Color=[.2 .2 .2];
            ylabel(daily,'Superficie sombreada (%)');ylim(daily,[0 100]);yticks(daily,0:20:100);
            xlabel(daily,mode.Value);xlim(daily,[0 24]);xticks(daily,0:3:24);
            daily.Visible='on';grid(daily,'on');
            legend(daily,[curves;inc],[compose('Fila %d',(1:params.n)');"Incidencia"],'Location','northoutside','Orientation','horizontal');
            summary.Text=sprintf('Hueco d = %.2f m\nPaso P = %.2f m\nProyección b = %.2f m\nBorde alto = %.2f m\nLCR = %.1f %%\nConjunto: %.2f × %.2f m', ...
                cached.d,cached.P,cached.b,params.h+cached.H,100*cached.LCR,params.W,(params.n-1)*cached.P+cached.b);
            showhour(hour.Value);
        catch err
            cached=[]; status.Text=err.message; cla(ax3);cla(ax2);cla(daily);summary.Text='';
        end
    end
    function release(), busy=false; end
    function coordinatesChanged(varargin),locationName.Value='Punto personalizado';rebuild();end
    function selectLocation(varargin)
        if busy,return;end
        running=false;play.Text='Animar día';
        [newLat,newLon,ok,name]=seleccionar_ubicacion(lat.Value,lon.Value,Nombre=string(locationName.Value),LatitudeLimits=[-65 65]);
        if ok && isvalid(fig),lat.Value=newLat;lon.Value=newLon;locationName.Value=name;rebuild();end
    end
    function showhour(t)
        if isempty(cached), return; end
        hour.Value=t; slider.Value=t;
        solar=tosolar(t);m=pv_filas_modelo(params,date.Value,solar);
        cla(ax3);cla(ax2); hold(ax3,'on');hold(ax2,'on');
        extent=(params.n-1)*m.P+m.b; margin=max(3,params.L);
        patch(ax3,[-margin extent+margin extent+margin -margin], ...
            [-params.W/2-margin -params.W/2-margin params.W/2+margin params.W/2+margin], ...
            [0 0 0 0],[.92 .91 .84],'EdgeColor','none');
        for j=1:params.n
            if m.alt>0
                g=m.suelo{1,j};
                plot(ax2,g,'FaceColor',[.3 .3 .3],'FaceAlpha',.22,'EdgeColor','none');
                [gx,gy]=boundary(g); patch(ax3,gx,gy,zeros(size(gx)),[.3 .3 .3],'FaceAlpha',.22,'EdgeColor','none');
            end
            v=m.vertices{j};
            color=[.2 .55 .85];if m.posterior,color=[.06 .16 .34];end
            patch(ax3,v(:,1),v(:,2),v(:,3),color,'FaceAlpha',.95);
            patch(ax2,v(:,1),v(:,2),color,'FaceAlpha',.95);
            if m.alt>0 && ~m.posterior && ~isempty(m.sombras{1,j}.Vertices)
                [u,y]=boundary(m.sombras{1,j});
                x=(j-1)*m.P+u*cosd(params.beta); z=params.h+u*sind(params.beta);
                patch(ax3,x,y,z+1e-4,[.85 .15 .1],'EdgeColor','none','FaceAlpha',.9);
                patch(ax2,x,y,[.85 .15 .1],'EdgeColor','none','FaceAlpha',.9);
            end
            text(ax2,(j-1)*m.P+m.b/2,0,sprintf('%d',j),'HorizontalAlignment','center');
        end
        sunPoint=[];
        if m.alt>0
            s=m.sun*max(3*params.L,.4*params.W); origin=[extent/2,0,params.h+m.H];sunPoint=origin+s;
            quiver3(ax3,origin(1),origin(2),origin(3),s(1),s(2),s(3),0,'Color',[1 .75 0],'LineWidth',2.5,'Tag','sunRay');
            plot3(ax3,sunPoint(1),sunPoint(2),sunPoint(3),'o','MarkerSize',15,'MarkerFaceColor',[1 .85 0],'MarkerEdgeColor',[1 .65 0],'Tag','sunDisc');
            status.Text=sprintf('%02d:%02d · %s\nAltura solar: %.1f° · acimut: %.1f°\nSombreado conjunto: %.1f %%',floor(t),floor(60*mod(t,1)),mode.Value,m.alt,m.az,100*mean(m.fraccion));
        else
            status.Text=sprintf('%.2f h · %s · Sol bajo el horizonte',t,mode.Value);
        end
        for a=[ax3 ax2]
            axis(a,'equal');grid(a,'on');xlim(a,[-margin extent+margin]);ylim(a,[-params.W/2-margin params.W/2+margin]);
            xlabel(a,'Perpendicular a filas (m)');ylabel(a,'A lo largo de filas (m)');
        end
        zlim(ax3,[0 max(1,params.h+m.H+params.L)]);zlabel(ax3,'Altura (m)');view(ax3,[-40 25]);
        if ~isempty(sunPoint)
            xlim(ax3,[min(-margin,sunPoint(1)-margin/2),max(extent+margin,sunPoint(1)+margin/2)]);
            ylim(ax3,[min(-params.W/2-margin,sunPoint(2)-margin/2),max(params.W/2+margin,sunPoint(2)+margin/2)]);
            zlim(ax3,[0 max([1,params.h+m.H+params.L,sunPoint(3)+margin/2])]);
        end
        compass(ax3,true,extent,margin);compass(ax2,false,extent,margin);
        if m.alt>0
            face='frontal';if m.posterior,face='posterior';end
            title(ax3,{sprintf('Vista 3D · acimut módulos %.0f°',params.alpha),sprintf('Ángulo con el plano: %.1f° · %s',m.incidencia,face)});
        else
            title(ax3,'Vista 3D · Sol bajo el horizonte');
        end
        view(ax2,2);ax2.CameraUpVector=[0 1 0];camroll(ax2,90);
        title(ax2,'Planta · rojo: sombra sobre módulos');
        yyaxis(daily,'left');
        delete(findall(daily,'Tag','hora')); line(daily,[t t],[0 100],'Color',[.85 .15 .1],'LineStyle','--','Tag','hora','HandleVisibility','off');
        hold(ax3,'off');hold(ax2,'off');drawnow limitrate;
    end
    function solar=tosolar(t)
        if strcmp(mode.Value,'Hora civil')
            solar=pv_hora_solar(date.Value,lon.Value,t,'civilToSolar',zone.Value);
        else
            solar=t;
        end
    end
    function switchmode(varargin)
        t=hour.Value;
        try
            if strcmp(currentMode,'Hora civil')
                t=pv_hora_solar(date.Value,lon.Value,t,'civilToSolar',zone.Value);
            end
            if strcmp(mode.Value,'Hora civil')
                t=pv_hora_solar(date.Value,lon.Value,t,'solarToCivil',zone.Value);
            end
            hour.Value=mod(t,24);currentMode=mode.Value;rebuild();
        catch err
            mode.Value=currentMode;status.Text=err.message;
        end
    end
    function compass(a,is3,extent,margin)
        center=[extent+margin*.45,params.W/2+margin*.45];r=margin*.32;
        if is3,center=[-margin*.45,-params.W/2-margin*.45];end
        theta=linspace(0,2*pi,65);
        if is3,plot3(a,center(1)+r*cos(theta),center(2)+r*sin(theta),.03+zeros(size(theta)),'Color',[.3 .3 .3]);
        else,plot(a,center(1)+r*cos(theta),center(2)+r*sin(theta),'Color',[.3 .3 .3]);end
        angles=[0 90 180 -90]; labels={'S','O','N','E'};
        for q=1:4
            delta=angles(q)-params.alpha;
            dx=-cosd(delta)*r;dy=sind(delta)*r;color=[.2 .2 .2];
            if q==1,color=[.85 .1 .1];end
            if is3
                quiver3(a,center(1),center(2),.03,dx,dy,0,0,'Color',color,'LineWidth',1.7,'MaxHeadSize',.6);
                text(a,center(1)+1.3*dx,center(2)+1.3*dy,.03,labels{q},'Color',color,'FontWeight','bold','HorizontalAlignment','center');
            else
                quiver(a,center(1),center(2),dx,dy,0,'Color',color,'LineWidth',1.7,'MaxHeadSize',.6);
                text(a,center(1)+1.3*dx,center(2)+1.3*dy,labels{q},'Color',color,'FontWeight','bold','HorizontalAlignment','center');
            end
        end
    end
    function animate(varargin)
        if running, running=false;play.Text='Animar día';return; end
        if isempty(cached),return;end
        running=true;play.Text='Detener';
        times=0:.25:24; times=times(cached.alt>0);
        for t=times
            if ~isvalid(fig)||~running,break;end
            showhour(t);pause(.12);
        end
        running=false;if isvalid(fig),play.Text='Animar día';end
    end
    function closeapp(varargin),running=false;delete(fig);end
end
