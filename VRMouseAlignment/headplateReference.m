function headplateReference

global obj

%% start GUI and draw buttons
drawGUIfig; % nested function at the bottom

%% start webcam
obj                  = createWebcamObj(obj);
obj.savepathroot     = RigParameters.savepath;
obj.reg              = RigParameters;
obj.headplateOutline = [];

end

%% camera on/off
function camON_callback(~,event)
global obj

if get(obj.camON,'Value') == true 
  
  % create video input
  if ~isfield(obj,'vid'); obj = createWebcamObj(obj); end
  
  % go into video data acquisition loop
  try
      camLoop;
  catch 
      delete(obj.vid)
      obj = createWebcamObj(obj);
      camLoop;
  end
  
end
end

%% subject
% select mouse
function subjList_callback(~,event)

global obj 

obj.mouseID  = get(obj.subjList,'String');
obj.savepath = sprintf('%s%s\\',obj.savepathroot,obj.mouseID);

% create directory for animal if necessary
if isempty(dir(obj.savepath))
  mkdir(obj.savepath);
end

% load reference image
if ~isempty(dir(sprintf('%s%s_refIm.mat',obj.savepath,obj.mouseID)))
  load(sprintf('%s%s_refIm',obj.savepath,obj.mouseID),'frame')
  obj.refIm  = frame;
else
  warndlg('reference image not found')
end

% load headplate outline
if ~isempty(dir(sprintf('%s%s_headplate.mat',obj.savepath,obj.mouseID)))
  load(sprintf('%s%s_headplate.mat',obj.savepath,obj.mouseID),'headplateContour')
  obj.headplateOutline = headplateContour;
else
  warndlg('headplate outline not found')
end

end

%% save frame
function grabFrame_callback(~,event)
global obj 
if get(obj.grab,'Value') == true
  
  set(obj.camON,'Value',false);
  drawnow();
  camON_callback([],1);
  
  
  uin = questdlg('save as reference image?'); % save?
  switch uin
    case 'Yes'
      thisfn = sprintf('%s%s_refIm',obj.savepath,obj.mouseID);
      obj.refIm = obj.camData;
      
      % save as refIM and also with a date for recordkeeping
      frame = obj.camData; 
      save(thisfn,'frame')
      imwrite(frame,sprintf('%s.tif',thisfn),'tif')
      
      % reset im registration
      obj.imTform = [];
      
    case 'No'
      thisls = dir(sprintf('%s%s_frameGrab*',obj.savepath,obj.fn));
      if isempty(thisls)
        thisfn = sprintf('%s%s_frameGrab',obj.savepath,obj.fn);
      else
        thisfn = sprintf('%s%s_frameGrab-%d',obj.savepath,obj.fn,length(thisls));
      end
      obj.currIm = obj.camData;
      
      frame = obj.camData; 
      save(thisfn,'frame')
      imwrite(frame,sprintf('%s.tif',thisfn),'tif')
    case 'Cancel'
      close(f1)
  end
  
%   set(f1,'visible','on','position',[20 20 obj.vidRes]);
%   close(f1)
%   fprintf('image saved to %s\n',thisfn)
  
  % prompt to register
  if strcmpi(uin,'No')
    uin3 = questdlg('register to reference image?');
    if strcmpi(uin3,'Yes')
      set(obj.registerIm,'Value',true)
      registerIm_callback([],1);
      set(obj.registerIm,'Value',false)
    end
  end
  plotHeadplateOutline(obj.camfig);
end
end

%% draw headplate outline
function drawHeadplate_callback(~,event)
global obj 

if get(obj.drawHeadplate,'Value') == true
  % manually draw headplate
  drawHeadplate(obj.savepath,obj.mouseID)
  
  % plot it
  plotHeadplateOutline(obj.camfig);
end

end

%% 
% register iamge
function registerIm_callback(~,event)
global obj 

if get(obj.registerIm,'Value') == true
  
  if isempty(obj.currIm)
%     thisdir = pwd;
%     cd(obj.savepath)
%     thisfn = uigetfile('*.tif','select image');
%     frame = imread(thisfn);
%     cd(thisdir)
    obj.currIm  = obj.camData; 
  end
  
  set(obj.statusTxt,'String','performing Im regsitration...')
  drawnow()
  
  [regMsg,obj.okFlag] = registerImage(obj.refIm,obj.currIm,false);
  wd = warndlg(regMsg,'Registration output');
end

end

%% reset
function reset_callback(~,event)
global obj 
if get(obj.resetgui,'Value') == true
  delete(obj.vid)
  close(obj.fig); clear
  headplateReference;
end
end

%% quit GUI
function quitgui_callback(~,event)
global obj 
if get(obj.quitgui,'Value') == true
  delete(obj.vid)
  close(obj.fig); clear
end
end

%% set directory for file saving
function cd_callback(~,event)
global obj 
if event == true || get(obj.sdir,'Value') == true
  obj.savepathroot = uigetdir(pwd,'Pick a directory');
end
end

%% image acquisition loop
function camLoop
warning off

global obj

stopL   = false; 
% ii      = 1;
vidRate = 20;

axes(obj.camfig)
% start(obj.vid)

% timing here is not strictly enforced, roughly 20 Hz
while ~ stopL
    tic;
    
    % get cam data 
    delay(0.001);
    dataRead    = snapshot(obj.vid);
    obj.camData = dataRead(:,:,:,end);
    if isempty(dataRead); continue; else clear dataRead; end
    
    % plot
    plotHeadplateOutline(obj.camfig)
    
    % check for other stuff in gui and roughly enforce timing
    drawnow()
    if get(obj.camON,'Value') == false; stopL = true; end
    if toc < 1/vidRate; delay(1/vidRate-toc); end
end

delete(obj.vid);

warning on

end

%% plot outline of headplate
function plotHeadplateOutline(fh)

global obj

if nargin < 1
    fh = [];
end
if isempty(fh)
axes(obj.camfig); % focus
cla
end

imshow(obj.camData); %colormap gray;  
set(gca,'xtick',[],'ytick',[]);

% headplate
if ~isempty(obj.headplateOutline)
  hold(obj.camfig,'on')
  [y,x] = find(obj.headplateOutline==1);
  plot(x,y,'y.')
  axis image;
end
end

%% create cam object 
function obj = createWebcamObj(obj)

if isprop(RigParameters,'webcam_name')
  obj.vid                 = webcam(RigParameters.webcam_name);
else
  obj.vid                 = webcam;
end
obj.vidRes(1)             = str2double(obj.vid.Resolution(1:3));
obj.vidRes(2)             = str2double(obj.vid.Resolution(5:7));
obj.hImage                = image(zeros(obj.vidRes(1),obj.vidRes(2),3),'Parent',obj.camfig);
set(obj.camfig,'visible','on'); axis off

if isprop(RigParameters,'webcam_zoom')
  set(obj.vid,'Zoom',RigParameters.webcam_zoom)
end
if isprop(RigParameters,'webcam_focus')
  set(obj.vid,'Focus',RigParameters.webcam_focus)
end

end

%% draw headlate outline
function drawHeadplate(impath,mouseID)

refpath = dir([impath '*refIm.mat']);
load([impath refpath.name],'frame')

fh = figure;
imshow(frame)
headplate        = roipoly;
headplateContour = bwperim(headplate);
close(fh)

save([impath mouseID '_headplate.mat'],'headplateContour','headplate')
end

%% delay (more precise than pause)
function t = delay(seconds)
% function pause the program
% seconds = delay time in seconds
tic; t=0;
while t < seconds
    t=toc;
end
end

%% register image
function [msg,okFlag,offset,tform] = registerImage(ref,im,subImFlag)

if nargin < 3
    subImFlag = false;
end

global obj

%% flip
im  = fliplr(im);
ref = fliplr(ref);

%% normalize images
im  = im-mean(mean(im))./std(std(double(im)));
ref = ref-mean(mean(ref))./std(std(double(ref)));

%% use only relevant subregion?
if subImFlag
    f3 = figure;
    imshow(im); title('select subregion')
    %warndlg('please select sub-region for registration')
    r = getrect(f3);
    im  = im(r(2):r(2)+r(4),r(1):r(1)+r(3));
    ref = ref(r(2):r(2)+r(4),r(1):r(1)+r(3));
    close(f3)
end

%% use rigid transformation to go from current image im to reference image
[optimizer,metric] = imregconfig('multimodal');
regim = imregister(im,ref,'rigid',optimizer,metric);
tform = imregtform(im,ref,'rigid',optimizer,metric);

offset.angle   = rad2deg(asin(tform.T(2,1)));
offset.xtransl = tform.T(3,1)/obj.reg.pxlPerMM;
offset.ytransl = tform.T(3,2)/obj.reg.pxlPerMM;
offset.percent = 100*sum(regim(:)==0)/numel(regim(:)); % % black pixels in registerd image

%% decide whether it's good enough and output message
if    (abs(offset.angle)   <= obj.reg.atolerance          ...
    && abs(offset.xtransl) <= obj.reg.xtolerance          ...
    && abs(offset.ytransl) <= obj.reg.ytolerance          ...
    && offset.percent      <= obj.reg.percentTolerance)   ...
    || offset.percent      <= obj.reg.percentTolerance/2
  
  msg    = sprintf('Good alignment!, %1.1f%% off',offset.percent);
  okFlag = true;

else
  
  okFlag = false;
  
  if abs(offset.angle) <= obj.reg.atolerance
    angtxt = 'angle is good';
  else
    if offset.angle < 0
      angtxt = sprintf('rotate %1.1f deg clockwise',abs(offset.angle));
    else
      angtxt = sprintf('rotate %1.1f deg counterclockwise',abs(offset.angle));
    end
  end
  if abs(offset.xtransl) <= obj.reg.xtolerance
    xtxt = 'x is good';
  else
    if offset.xtransl > 0
      xtxt = sprintf('move %1.2f mm to the left',abs(offset.xtransl));
    else
      xtxt = sprintf('move %1.2f mm to the right',abs(offset.xtransl));
    end
  end
  if abs(offset.ytransl) <= obj.reg.ytolerance
    ytxt = 'y is good';
  else
    if offset.xtransl > 0
      ytxt = sprintf('move %1.2f mm forward',abs(offset.ytransl));
    else
      ytxt = sprintf('move %1.2f mm back',abs(offset.ytransl));
    end
  end
  
  msg = sprintf('Bad alignment: %1.1f%% off\n%s, %s, %s', offset.percent, angtxt, xtxt, ytxt);
  
end

%% plot 
f2 = figure; 
subplot(2,3,1); imagesc(ref); axis image; axis off; set(gca,'XDir','reverse'); colormap gray; title('reference')
subplot(2,3,2); imagesc(im); axis image; axis off; set(gca,'XDir','reverse'); colormap gray; title('image')
subplot(2,3,3); imagesc(regim); axis image; axis off; set(gca,'XDir','reverse'); colormap gray; title('registered image')

subplot(2,3,4); imshowpair(ref,im); axis image; set(gca,'XDir','reverse'); title('reference + image')
subplot(2,3,5); imshowpair(ref,regim); axis image; set(gca,'XDir','reverse'); title('reference + reg. image')

end


% =========================================================================
%% DRAW GUI OBJECT
function drawGUIfig

global obj

% create GUI figure
ss = get(groot,'screensize');
ss = ss(3:4);
obj.fig    =   figure    ('Name',               'Headplate reference',     ...
                          'NumberTitle',        'off',                     ...
                          'Position',           round([ss(1)*.18 ss(2)*.26 ss(1)*.64 ss(2)*.48]));
                        

%% cam display
obj.camfig  =   axes      ('units',             'normalized',       ...
                        'position',             [.02 .16 .96 .8],   ...
                        'parent',               obj.fig,            ...
                        'visible',              'off',              ...
                        'xtick',                [],                 ...
                        'ytick',                []);

%% buttons                      
obj.subjtxt   =   uicontrol (obj.fig,                               ...
                        'Style',                'text',             ...
                        'String',               'Mouse ID:',        ...
                        'Units',                'normalized',       ...
                        'Position',             [.02 .025 .12 .07],  ...
                        'horizontalAlignment',  'left',             ...
                        'fontsize',             13,                 ...
                        'fontweight',           'bold');
obj.subjList =   uicontrol (obj.fig,                            ...
                        'Style',                'edit',             ...
                        'Units',                'normalized',       ...
                        'Position',             [.14 .02 .1 .07],  ...
                        'horizontalAlignment',  'left',             ...
                        'fontsize',             13,                 ...
                        'Callback',             @subjList_callback);
obj.quitgui =   uicontrol (obj.fig,                                 ...
                        'String',               'QUIT',             ...
                        'Style',                'pushbutton',       ...
                        'Units',                'normalized',       ...
                        'Position',             [.91 .02 .07 .07],  ...
                        'foregroundColor',      [1 0 0],            ...
                        'Callback',             @quitgui_callback,  ...
                        'fontsize',             13,                 ...
                        'fontweight',           'bold'); 
obj.resetgui   =   uicontrol (obj.fig,                              ...
                        'String',               'RESET',            ...
                        'Style',                'pushbutton',       ...
                        'Units',                'normalized',       ...
                        'Position',             [.84 .02 .07 .07],  ...
                        'Callback',             @reset_callback,    ...
                        'fontsize',             13,                 ...
                        'foregroundColor',      [1 .6 .1],          ...
                        'fontweight',           'bold');
obj.camON   =   uicontrol (obj.fig,                                 ...
                        'String',               'cam ON',           ...
                        'Style',                'togglebutton',     ...
                        'Units',                'normalized',       ...
                        'Position',             [.32 .02 .12 .07],   ...
                        'Callback',              @camON_callback,   ...
                        'fontsize',             13);
obj.grab    =   uicontrol (obj.fig,                                 ...
                        'String',               'grab frame',       ...
                        'Style',                'pushbutton',       ...
                        'Units',                'normalized',       ...
                        'Position',             [.44 .02 .12 .07],   ...
                        'Callback',             @grabFrame_callback,...
                        'fontsize',             13); 
obj.registerIm    =   uicontrol (obj.fig,                           ...
                        'String',               'register',         ...
                        'Style',                'pushbutton',       ...
                        'Units',                'normalized',       ...
                        'Position',             [.56 .02 .12 .07],    ...
                        'Callback',             @registerIm_callback,...
                        'fontsize',             13); 
obj.drawHeadplate =   uicontrol (obj.fig,                           ...
                        'String',               'draw plate' ,      ...
                        'Style',                'pushbutton',       ...
                        'Units',                'normalized',       ...
                        'Position',             [.68 .02 .12 .07],   ...
                        'Callback',             @drawHeadplate_callback,  ...
                        'fontsize',             12);
obj.sdir   =   uicontrol (obj.fig,                                  ...
                        'String',               'set dir',          ...
                        'Style',                'pushbutton',       ...
                        'Units',                'normalized',       ...
                        'Position',             [.25 .02 .07 .07],  ...
                        'Callback',             @cd_callback,       ...
                        'fontsize',             13,                 ...
                        'fontweight',           'bold');
                      
end