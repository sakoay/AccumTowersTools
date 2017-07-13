%% Rig specific constants.
classdef RigParameters

  properties (Constant)
    
    arduinoPort         = 'COM10'           % Arduino port as seen in the Windows Device Manager
%     sensorDotsPerRev    = 23101/10                            % For one sensor
    sensorDotsPerRev    = RigParameters.sensorCalibration()   % For two or more sensors
    ballCircumference   = 63.8              % in cm
    
  end
  
  methods (Static, Access = protected)

    function dotsPerRev = sensorCalibration()
      % This function stores the measured number of sensor dots per ball revolution, as obtained
      % using the calibrateBall script, which can be different for each sensor in a 2-sensor setup.
      % The sensors are identified by the MovementSensor enumeration. For example, 23101 dots were
      % measured for the FrontVelocity sensor after 10 revolutions of a 63.8cm circumference ball; 
      % this leads to a registered dotsPerRev of 23101/10.
      
      dotsPerRev        = nan(1, MovementSensor.count());
      dotsPerRev(MovementSensor.FrontVelocity)  = 23101/10;
      dotsPerRev(MovementSensor.BottomVelocity) = 24358/10;
      dotsPerRev(MovementSensor.BottomPosition) = dotsPerRev(MovementSensor.BottomVelocity);
      
      if any(isnan(dotsPerRev))
        error('RigParameters:sensorCalibration', 'Some sensor calibration data was not specified, please correct this.');
      end
    end
    
  end
  
end
