function code = example_ViRMEn_experiment
% example_ViRMEn_experiment   Code for the ViRMEn experiment example_ViRMEn_experiment.
%   code = example_ViRMEn_experiment   Returns handles to the functions that ViRMEn
%   executes during engine initialization, runtime and termination.


% Begin header code - DO NOT EDIT
code.initialization = @initializationCodeFun;
code.runtime = @runtimeCodeFun;
code.termination = @terminationCodeFun;
% End header code - DO NOT EDIT



% --- INITIALIZATION code: executes before the ViRMEn engine starts.
function vr = initializationCodeFun(vr)

% Only one of the following should be used:
vr = initializeArduino_1sensor(vr, 1, 1/2.5);
vr = initializeArduino_2sensors(vr, 1, 1, MovementSensor.BottomVelocity);


% --- RUNTIME code: executes on every iteration of the ViRMEn engine.
function vr = runtimeCodeFun(vr)


% --- TERMINATION code: executes after the ViRMEn engine stops.
function vr = terminationCodeFun(vr)

% This must be run in order to release use of the Arduino COM port
delete(vr.mr);
  