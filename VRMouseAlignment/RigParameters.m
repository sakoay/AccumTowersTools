classdef RigParameters

  properties (Constant)
    
    % general setup
    rig                 = '' % rig name for record keeping
    savepath            = 'C:\Data\headplateRef\' % where headplate refrences will be saved
    webcam_name         = 'Live! Cam Sync HD VF0770'
    
    % extra cam settings can be inserted here too, but are cam-specific,
    % eg:
    % Zoom
    % Focus
    
    % image registration
    ytolerance       = 0.1; % tolerance of image registration in mm, translation y 
    xtolerance       = 0.1; % tolerance of image registration in mm, translation x 
    atolerance       = 0.5; % tolerance of image registration in deg, rotation 
    percentTolerance = 1;   % tolerance of image registration in percentage, overall
    pxlPerMM         = 100; % change this for adequate scale (only relevant if using image reg)
    
  end
  
end
