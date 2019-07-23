% Brick Interface to Lego Minstorms EV3 brick
%
% Methods::
% brick              Constructor, establishes communications
% delete             Destructor, closes connection
% send               Send data to the brick
% receive            Receive data from the brick
% makenos            Convert Text to code.
% 
% uiReadVBatt        Returns battery level as a voltage
% uiReadLBatt        Returns battery level as a percentage
%
% playTone           Plays a tone at a volume with a frequency and duration
% beep               Plays a beep tone with volume and duration
% playThreeTone      Plays three tones one after the other
%
% inputDeviceGetName Return the device name at a layer and NO
% inputDeviceSymbol  Return the symbol for the device at a layer, NO and mode
% inputDeviceClrAll  Clear all the sensor data at a layer
% inputReadSI        Reads a connected sensor at a layer, NO, type and mode in SI units
% plotSensor         Plots a sensor readings over time
% displayColor       Displays the color from a color sensor
%
% outputStop         Stops motor at a layer, NOS and brake
% outputStopAll      Stops all the motors
% outputPower        Sets motor output power at a layer, NOS and speed
% outputStart        Starts motor at a layer, NOS and speed
% outputTest         Return the state of the motor at a layer and NOS
% outputStepSpeed    Moves a motor to set position with layer, NOS, speed, ramp up angle, constant angle, ramp down angle and brake
% outputClrCount     Clears a motor tachometer at a  layer and NOS
% outputGetCount     Returns the tachometer at a layer and NOS
%
% drawTest           Shows the drawing capabilities of the brick
%
% getBrickName       Return the name of the brick
% setBrickName       Set the name of the brick
%
% mailBoxWrite       Write a mailbox message from the brick to another device
%
% fileUpload         Upload a file to the brick
% fileDownload       Download a file from the brick
% listFiles          List files on the brick from a directory  
% createDir          Create a directory on the brick
% deleteFile         Delete a file from the brick
% writeMailBox       Write a mailbox message to the brick
% readMailBox        Read a mailbox message sent from the brick
%
% threeToneByteCode  Generate the bytecode for the playThreeTone function 
%
% Example::
%           b = Brick('ioType','usb')
%           b = Brick('ioType','wifi','wfAddr','192.168.1.104','wfPort',5555,'wfSN','0016533dbaf5')
%           b = Brick('ioType','bt','serPort','/dev/rfcomm0')



classdef Brick < handle
    
    properties
        % connection handle
        conn;
        % debug input
        debug;
        % IO connection type
        ioType;
        % bluetooth brick device name
        btDevice;
        % bluetooth brick communication channel
        btChannel;
        % wifi brick IP address
        wfAddr;
        % wifi brick TCP port
        wfPort; 
        % brick serial number
        wfSN; 
        % bluetooth serial port
        serPort;
        % Communication State (0 - no expected response, 1 - expected
        % response)
        commState;
    end

    methods
        function brick = Brick(varargin) 
             % Brick.Brick Create a Brick object
             %
             % b = Brick(OPTIONS) is an object that represents a connection
             % interface to a Lego Mindstorms EV3 brick.
             %
             % Options::
             %  'debug',D       Debug level, show communications packet
             %  'ioType',P      IO connection type, either usb, wifi or bt
             %  'btDevice',bt   Bluetooth brick device name
             %  'btChannel',cl  Bluetooth connection channel
             %  'wfAddr',wa     Wifi brick IP address
             %  'wfPort',pr     Wifi brick TCP port, default 5555
             %  'wfSN',sn       Wifi brick serial number (found under Brick info on the brick OR through sniffing the UDP packets the brick emits on port 3015)
             %  'serPort',SP    Serial port connection
             %
             % Notes::
             % - Can connect through: usbBrickIO, wfBrickIO, btBrickIO or
             % instrBrickIO.
             % - For usbBrickIO:
             %      b = Brick('ioType','usb')
             % - For wfBrickIO:
             %      b = Brick('ioType','wifi','wfAddr','192.168.1.104','wfPort',5555,'wfSN','0016533dbaf5')
             % - For btBrickIO:
             %      b = Brick('ioType','bt','serPort','/dev/rfcomm0')
             % - For instrBrickIO (wifi)
             %      b = Brick('ioType','instrwifi','wfAddr','192.168.1.104','wfPort',5555,'wfSN','0016533dbaf5')
             % - For instrBrickIO (bluetooth)
             %      b = Brick('ioType','instrbt','btDevice','EV3','btChannel',1)
             
             % init the properties
             opt.debug = 0;
             opt.btDevice = 'EV3';
             opt.btChannel = 1;
             opt.wfAddr = '192.168.1.104';
             opt.wfPort = 5555;
             opt.wfSN = '0016533dbaf5';
             opt.ioType = 'usb';
             opt.serPort = '/dev/rfcomm0';
             % read in the options
             opt = tb_optparse(opt, varargin);
             % select the connection interface
             connect = 0;
             % Initialize Communication State
             brick.commState = 0;
             % usb
             if(strcmp(opt.ioType,'usb'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.conn = usbBrickIO(brick.debug);
                connect = 1;
             end
             % wifi
             if(strcmp(opt.ioType,'wifi'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.wfAddr = opt.wfAddr;
                brick.wfPort = opt.wfPort;
                brick.wfSN = opt.wfSN;
                brick.conn = wfBrickIO(brick.debug,brick.wfAddr,brick.wfPort,brick.wfSN);
                connect = 1;
             end
             % bluetooth
             if(strcmp(opt.ioType,'bt'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.serPort = opt.serPort;
                brick.conn = btBrickIO(brick.debug,brick.serPort);
                connect = 1;
             end
             % instrumentation and control wifi 
             if(strcmp(opt.ioType,'instrwifi'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.wfAddr = opt.wfAddr;
                brick.wfPort = opt.wfPort;
                brick.wfSN = opt.wfSN;
                brick.conn = instrBrickIO(brick.debug,'wf',brick.wfAddr,brick.wfPort,brick.wfSN);
                connect = 1;
             end
             % instrumentation and control bluetooth 
             if(strcmp(opt.ioType,'instrbt'))
                brick.debug = opt.debug;
                brick.ioType = opt.ioType;
                brick.btDevice = opt.btDevice;
                brick.btChannel = opt.btChannel;
                fprintf('Connecting...');
                brick.conn = instrBrickIO(brick.debug,'bt',brick.btDevice,brick.btChannel);
                connect = 1;
                fprintf('Successful.\n');
             end
             % error
             if(~connect)
                 fprintf('Please specify a serConn option: ''usb'',''wifi'',''bt'',''instrwifi'' or ''instrbt''.\n');
             end
        end
        
        
        function delete(brick)
            % Brick.delete Delete the Brick object
            %
            % delete(b) closes the connection to the brick
            fprintf('Disconnecting...');
            brick.conn.close();
            pause(5);
            fprintf('Complete.\n');
        end
        
        
        
        function send(brick, cmd)
            % Brick.send Send data to the brick
            %
            % Brick.send(cmd) sends a command to the brick through the
            % connection handle.
            %
            % Notes::
            % - cmd is a command object.
            %
            % Example::
            %           b.send(cmd)
            
            % send the message through the brickIO write function
            
            brick.conn.write(cmd.msg);
            if brick.debug > 0
               fprintf('sent:    [ ');
               for ii=1:length(cmd.msg)
                   fprintf('%d ',cmd.msg(ii))
               end
               fprintf(']\n');
            end
        end
       
        function rmsg = receive(brick)
            % Brick.receive Receive data from the brick
            %
            % rmsg = Brick.receive() receives data from the brick through
            % the connection handle.
            %
            % Example::
            %           rmsg = b.receive()
 
            % read the message through the brickIO read function
            
            rmsg = brick.conn.read();
            if brick.debug > 0
               fprintf('received:    [ ');
               for ii=1:length(rmsg)
                   fprintf('%d ',rmsg(ii))
               end
               fprintf(']\n');
            end
        end
        
        function voltage = uiReadVbatt(brick)
            % Brick.uiReadVbatt Return battery level (voltage)
            % 
            % voltage = uiReadVbatt returns battery level as a voltage.
            %
            % Example::
            %           voltage = b.uiReadVbatt()
            cmd = Command();
            cmd.addHeaderDirectReply(42,4,0);
            cmd.opUI_READ_GET_VBATT(0);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            voltage = typecast(uint8(msg(6:9)),'single');           
            if brick.debug > 0
                fprintf('Battery voltage: %.02fV\n', voltage);
            end
        end
        
        function level = uiReadLbatt(brick)
            % Brick.uiReadLbatt Return battery level (percentage)
            % 
            % level = Brick.uiReadLbatt() returns battery level as a
            % percentage from 0 to 100%.
            %
            % Example::
            %           level = b.uiReadLbatt()
          
            cmd = Command();
            cmd.addHeaderDirectReply(42,1,0);
            cmd.opUI_READ_GET_LBATT(0);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            level = msg(6);
            if brick.debug > 0
                fprintf('Battery level: %d%%\n', level);
            end
        end
        
        function level = GetBattVoltage(brick)
            level = brick.uiReadVbatt();
        end
        
        function level = GetBattLevel(brick)
            level = brick.uiReadLbatt();
        end
        
        
        
        function playTone(brick, volume, frequency, duration)  
            % Brick.playTone Play a tone on the brick
            %
            % Brick.playTone(volume,frequency,duration) plays a tone at a
            % volume, frequency and duration.
            %
            % Notes::
            % - volume is the tone volume from 0 to 100.
            % - frequency is the tone frequency in Hz.
            % - duration is the tone duration in ms.
            %
            % Example:: 
            %           b.playTone(5,400,500)

            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opSOUND_TONE(volume,frequency,duration);
            cmd.addLength();
            brick.send(cmd);
        end
                 
        function beep(brick,volume,duration)
            % Brick.beep Play a beep on the brick
            %
            % Brick.beep(volume,duration) plays a beep tone with volume and
            % duration.
            %
            % Notes::
            % - volume is the beep volume from 0 to 100.
            % - duration is the beep duration in ms.
            %
            % Example:: 
            %           b.beep(5,500)
            
            if nargin < 2
                volume = 10;
            end
            if nargin < 3
                duration = 100;
            end
            brick.playTone(volume, 1000, duration);
        end
        
        function playThreeTones(brick)
            % Brick.playThreeTones Play three tones on the brick
            %
            % Brick.playThreeTones() plays three tones consequentively on
            % the brick with one upload command.
            %
            % Example::
            %           b.playThreeTones();
            
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opSOUND_TONE(5,440,500);
            cmd.opSOUND_READY();
            cmd.opSOUND_TONE(10,880,500);
            cmd.opSOUND_READY();
            cmd.opSOUND_TONE(15,1320,500);
            cmd.opSOUND_READY();
            cmd.addLength();
            % print message
            fprintf('Sending three tone message ...\n');
            brick.send(cmd);    
        end
        
        function name = inputDeviceGetName(brick,no)
            % Brick.inputDeviceGetName Get the input device name
            %
            % Brick.inputDeviceGetName(layer,no) returns the name of the
            % device connected where 'name' is the devicetype-devicemode.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NO is the output port number from [0..3] or sensor port
            % number minus 1.
            %
            % Example::
            %           name = b.inputDeviceGetName(0,Device.Port1)
            
            cmd = Command();
            cmd.addHeaderDirectReply(42,12,0);
            cmd.opINPUT_DEVICE_GET_NAME(0,no,12,0);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            % return the device name
            name = sscanf(char(msg(6:end)),'%s');
        end
        
        function name = inputDeviceSymbol(brick,no)
            % Brick.inputDeviceSymbol Get the input device symbol
            %
            % Brick.inputDeviceSymbol(layer,no) returns the symbol used for
            % the device in its current mode.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NO is the output port number from [0..3] or sensor port
            % number minus 1.
            %
            % Example::
            %           name = b.inputDeviceGetName(0,Device.Port1)
            
            cmd = Command();
            cmd.addHeaderDirectReply(42,5,0);
            cmd.opINPUT_DEVICE_GET_SYMBOL(0,no,5,0);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            % return the symbol name
            name = sscanf(char(msg(6:end)),'%s');
        end
        
        function inputDeviceClrAll(brick)
            % Brick.inputDeviceClrAll Clear the sensors
            %
            % Brick.inputDeviceClrAll(layer) clears the sensors connected
            % to layer.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            %
            % Example::
            %           name = b.inputDeviceClrAll(0)
            
            cmd = Command();
            cmd.addHeaderDirectReply(42,5,0);
            cmd.opINPUT_DEVICE_CLR_ALL(0);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function SetMode(brick,no,mode)
           
            
            cmd = Command();
            cmd.addHeaderDirectReply(42,0,1);
            cmd.opINPUT_DEVICE_SET_MODE(0,no-1,mode);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
        end
        
        function reading = inputReadSI(brick,no,mode)
            % Brick.inputReadSI Input read in SI units
            % 
            % reading = Brick.inputReadSI(layer,no,mode) reads a 
            % connected sensor at a layer, NO and mode in SI units.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NO is the output port number from [0..3] or sensor port
            % number minus 1.
            % - mode is the sensor mode from types.html. (-1=don't change)
            % - returned reading is DATAF.
            %
            % Example::
            %            reading = b.inputReadSI(0,Device.Port1,Device.USDistCM)
            %            reading = b.inputReadSI(0,Device.Port1,Device.Pushed)
           
            cmd = Command();
            cmd.addHeaderDirectReply(42,4,0);
            cmd.opINPUT_READSI(0,no-1,0,mode,0);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            reading = typecast(uint8(msg(6:9)),'single');
            if brick.debug > 0
                 fprintf('Sensor reading: %.02f\n', reading);
            end
        end
        
        function msg = inputReadRaw(brick,no,mode,response_size)
                      
            cmd = Command();
            cmd.addHeaderDirectReply(42,response_size*4,0);
            cmd.opINPUT_READRAW(0,no-1,0,mode,response_size);
            %cmd.opINPUT_DEVICE_READY_RAW(0,no-1,mode);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            %display("Test 2")
            %reading = typecast(uint8(msg(6:9)),'single');
            %if brick.debug > 0
            %    fprintf('Sensor reading: %.02f\n', msg);
           %end
        end
        
        function reading = TouchPressed(brick, SensorPort)
            reading = brick.inputReadSI(SensorPort, Device.Pushed);
        end
        
        function reading = TouchBumps(brick, SensorPort)
            reading = brick.inputReadSI(SensorPort, Device.Bumps);
        end
        
        function SetColorMode(brick, SensorPort, mode)
            brick.SetMode(SensorPort, mode);
        end
        
        function reading = LightReflect(brick, SensorPort)
            reading = brick.inputReadSI(SensorPort, Device.ColReflect);
        end
        
        function reading = LightAmbient(brick, SensorPort)
            reading = brick.inputReadSI(SensorPort, Device.ColAmbient);
        end
        
        function reading = ColorCode(brick, SensorPort)
            reading = brick.inputReadSI(SensorPort, Device.ColColor);
        end
        
        function reading = ColorRGB(brick, SensorPort)
            data = brick.inputReadRaw(SensorPort, Device.ColRGB, 3);
            r = typecast(uint8(data(6:9)),'uint32');  
            g = typecast(uint8(data(10:13)),'uint32'); 
            b = typecast(uint8(data(14:17)),'uint32'); 
            reading = [r g b];
        end
        
        function reading = UltrasonicDist(brick, SensorPort)
            reading = brick.inputReadSI(SensorPort, Device.USDistCM);
        end
        
        function GyroCalibrate(brick, SensorPort)
            brick.SetMode(SensorPort,Device.GyroCalib);
            pause(0.1);
        end
        
        function reading = GyroAngle(brick, SensorPort)
            reading = brick.inputReadSI(SensorPort, Device.GyroAng);
        end
        
        function reading = GyroRate(brick, SensorPort)
            reading = brick.inputReadSI(SensorPort, Device.GyroRate);
        end
        
        function PlotSensor(brick,no,mode)
            % Brick.plotSensor plot the sensor output 
            %
            % Brick.plotSensor(layer,no,mode) plots the sensor output
            % to MATLAB. 
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NO is the output port number from [0..3] or sensor port
            % number minus 1.
            % - mode is the sensor mode from types.html. (-1=don't change)
            %
            % Example::
            %           b.plotSensor(0,Device.Port1,Device.USDistCM)
            %           b.plotSensor(0,Device.Port1,Device.GyroAng)
            
            % start timing
            tic;
            % create figure
            hfig = figure('name','EV3 Sensor');
            % init the the data
            t = 0;
            x = 0;
            hplot = plot(t,x);
            % one read to set the mode
            reading = brick.inputReadSI(0,no,mode);
            % set the title
            name = brick.inputDeviceGetName(0,no);
            title(['Device name: ' name]);
            % set the y label
            name = brick.inputDeviceSymbol(0,no);
            ylabel(['Sensor value (' name(1:end-1) ')']);
            % set the x label
            xlabel('Time (s)');
            % set the x axis
            xlim([0 10]);
            % wait until the figure is closed
            while(findobj('name','EV3 Sensor') == 1)
                % get the reading
                reading = brick.inputReadSI(0,no,mode);
                t = [t toc];
                x = [x reading];
                set(hplot,'Xdata',t)
                set(hplot,'Ydata',x)
                drawnow
                % reset after 10 seconds
                if (toc > 10)
                   % reset
                   t = 0;
                   x = x(end);
                   tic
                end
            end
        end
            
        function displayColor(brick,no)
            % Brick.dispalyColor display sensor color 
            %
            % Brick.dispalyColor(layer,no) displays the color read from the
            % color sensor in a MATLAB figure.
            %
            % Notes::
            % - layer is the usb chain layer (usually 0).
            % - NO is the output port number from [0..3] or sensor port
            % number minus 1.
            %
            % Example::
            %           b.displayColor(0,Device.Port1)
            
            % create figure
            hfig = figure('name','EV3 Color Sensor');
            % wait until the figure is closed
            while(findobj('name','EV3 Color Sensor') == 1)
                % read the color sensor in color detection mode
                color = brick.inputReadSI(no,Device.ColColor);
                % change the figure background according to the color
                switch color
                    case Device.NoColor
                        set(hfig,'Color',[0.8,0.8,0.8])
                    case Device.BlackColor
                        set(hfig,'Color',[0,0,0])
                    case Device.BlueColor
                        set(hfig,'Color',[0,0,1])
                    case Device.GreenColor
                        set(hfig,'Color',[0,1,0])
                    case Device.YellowColor
                        set(hfig,'Color',[1,1,0])
                    case Device.RedColor
                        set(hfig,'Color',[1,0,0])
                    case Device.WhiteColor
                        set(hfig,'Color',[1,1,1])
                    case Device.BrownColor
                        set(hfig,'Color',[0.6,0.3,0])
                    otherwise
                        set(hfig,'Color',[0.8,0.8,0.8])
                end
                drawnow
            end
        end
        
        function StopMotor(brick,nos,brake)
            % Brick.outputStop Stops a motor
            %
            % Brick.outputStop(nos,brake) stops motor at a layer 
            % NOS and brake.
            %
            % Notes::
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            % - brake is [0..1] (0=Coast,  1=Brake).
            %
            % Example::
            %           b.outputStop(0,Device.MotorA,Device.Brake)
            if nargin < 3
                brake = 0;
            end
            nos = makenos(nos);
            brake = makebrake(brake);
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_STOP(0,nos,brake)
            cmd.addLength();
            brick.send(cmd);
        end
        
        
        function StopAllMotors(brick, brake)
            % Brick.outputStopAll Stops all motors
            %
            % Brick.outputStopAll() stops all motors on layer 0.
            %
            % Notes::
            % 
            % - Sends 0x0F as the NOS bit field to stop all motors.
            %
            % Example::
            %           b.outputStopAll(0)
            if nargin < 2
                brake = 0;
            end
            brake = makebrake(brake);
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_STOP(0,15,brake);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function motorPower(brick,nos,power)
            % Brick.outputPower Set the motor output power
            % 
            % Brick.outputPower(nos,power) sets motor output power at
            % a layer, NOS and power.
            %
            % Notes::
            %
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            % - power is the output power with [+-0..100%] range.
            %
            % Example::
            %           b.outputPower(0,Device.MotorA,50)
            nos = makenos(nos);
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_POWER(0,nos,power);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function motorStart(brick,nos)
            % Brick.outputStart Starts a motor
            %
            % Brick.outputStart(nos) starts a motor at a layer and
            % NOS.
            %
            % Notes::
            %
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            %
            % Example::
            %           b.outputStart(0,Device.MotorA)
            nos = makenos(nos);
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_START(0,nos);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function MoveMotor(brick, nos, power)
            nos = makenos(nos);
            brick.motorPower(nos, power);
            brick.motorStart(nos);
        end
        
        function state = MotorBusy(brick,nos)
            % Brick.outputTest Test a motor
            %
            % Brick.outputTest(nos) test a motor state at a layer and
            % NOS.
            %
            % Notes::
            % 
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            % - state is 0 when ready and 1 when busy.
            %
            % Example::
            %           state = b.outputTest(0,Device.MotorA)
            nos = makenos(nos);
            cmd = Command();
            cmd.addHeaderDirectReply(42,1,0);
            cmd.opOUTPUT_TEST(0,nos,0);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            % motor state is the final byte
            state = msg(end);
        end
        
        function motorStepSpeed(brick,nos,speed,step1,step2,step3,brake)
            % Brick.outputStepSpeed Output a step speed 
            %
            % Brick.outputStepSpeed(nos,speed,step1,step2,step3,brake)
            % moves a motor to set position with layer, NOS, speed, ramp up
            % angle, constant angle, ramp down angle and brake.
            %
            % Notes::
            % 
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            % - speed is the output speed with [+-0..100%] range.
            % - step1 is the steps used to ramp up.
            % - step2 is the steps used for constant speed.
            % - step3 is the steps used for ramp down.
            % - brake is [0..1] (0=Coast,  1=Brake).
            %
            % Example::
            %           b.outputStepSpeed(0,Device.MotorA,50,50,360,50,Device.Coast)
            if nargin < 7
                brake = 0;
            end
            nos = makenos(nos);
            brake = makebrake(brake);
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_STEP_SPEED(0,nos,speed,step1,step2,step3,brake);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function MoveMotorAngleRel(brick, nos, speed, angle, brake)
            if nargin < 5
                brake = 0;
            end
            if(angle<0)
               speed = -1*speed;
            end
            angle = abs(angle);
            brick.motorStepSpeed(nos, speed, angle/3, angle/3, angle/3, brake);
        end
        
        function MoveMotorAngleAbs(brick, nos, speed, angle, brake)
            if nargin < 5
                brake = 0;
            end
            brick.StopMotor(nos, 'Coast'); % Motor locks up if Hard brake.
            %pause(0.5);
            tacho = brick.motorGetCount(nos);
            
            diff = angle - tacho;
            
            brick.MoveMotorAngleRel(nos, speed, diff, brake);
        end
        
        function ResetMotorAngle(brick, nos)
            brick.motorClrCount(nos);
        end
        
        function motorClrCount(brick,nos)
            % Brick.outputClrCount Clear output count
            % 
            % Brick.outputClrCount(nos) clears a motor tachometer at a
            % layer and NOS.
            %
            % Notes::
            % 
            % - NOS is a bit field representing output 1 to 4 (0x01, 0x02, 0x04, 0x08).
            %
            % Example::
            %            b.outputClrCount(0,Device.MotorA)
            nos = makenos(nos);
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opOUTPUT_CLR_COUNT(0,nos);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function angle = GetMotorAngle(brick, nos)
            angle = brick.motorGetCount(nos);
        end
        
        function tacho = motorGetCount(brick,nos)
            % Brick.outputGetCount(nos) Get output count
            % 
            % tacho = Brick.outputGetCount(nos) returns the tachometer 
            % at a layer and NOS.
            %
            % Notes::
            % 
            % - NOS is output number [0x00..0x0F].
            % - The NOS here is different to the regular NOS, almost an
            % intermediary between NOS and NO.
            % - tacho is the returned tachometer value.
            %
            % Example::
            %           tacho = b.outputGetCount(0,Device.MotorA)
            % FIX by DS 
            % nos = makenos(nos);
            num = 0;
            switch nos
                case 'A'
                    num = 0;
                case 'B'
                    num = 1;
                case 'C'
                    num = 2;
                case 'D' 
                    num = 3;
            end
            % end fix by DS
            cmd = Command();
            cmd.addHeaderDirectReply(42,4,0);
            % fixed by DS
            %cmd.opOUTPUT_GET_COUNT(0,nos-1,0);
            cmd.opOUTPUT_GET_COUNT(0,num,0);
            % end fix by DS
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            tacho = typecast(uint8(msg(6:9)),'int32');
            if brick.debug > 0
                fprintf('Tacho: %d degrees\n', tacho);
            end
        end
        
        function WaitForMotor(brick, nos)
            nos = makenos(nos);
            
            while(brick.MotorBusy(nos))
                pause(0.1);
            end
            lastangle = brick.GetMotorAngle(nos);
            while(lastangle ~= brick.GetMotorAngle(nos))
                lastangle = brick.GetMotorAngle(nos);
                pause(0.1);
            end
            %pause(0.5);
        end
        
        function drawTest(brick)
            % Brick.drawTest Draw test shapes
            %
            % Brick.drawTest() shows the drawing capabilities of the brick.
            %
            % Example::
            %           b.drawTest()
            
            cmd = Command();
            cmd.addHeaderDirect(42,4,1);
            % save the UI screen
            cmd.opUI_DRAW_STORE(0);
            % change the led pattern
            cmd.opUI_WRITE_LED(Device.LedGreenFlash);
            % clear the screen (top line still remains with remote cmds)
            cmd.opUI_DRAW_FILLWINDOW(0,0,0);
            % draw four pixels
            cmd.opUI_DRAW_PIXEL(vmCodes.vmFGColor,12,15);
            cmd.opUI_DRAW_PIXEL(vmCodes.vmFGColor,12,20);
            cmd.opUI_DRAW_PIXEL(vmCodes.vmFGColor,18,15);
            cmd.opUI_DRAW_PIXEL(vmCodes.vmFGColor,18,20);
            % draw line
            cmd.opUI_DRAW_LINE(vmCodes.vmFGColor,0,25,vmCodes.vmLCDWidth,25);
            cmd.opUI_DRAW_LINE(vmCodes.vmFGColor,15,25,15,127);
            % draw circle
            cmd.opUI_DRAW_CIRCLE(1,40,40,10);
            % draw rectangle
            cmd.opUI_DRAW_RECT(vmCodes.vmFGColor,70,30,20,20);
            % draw filled cricle
            cmd.opUI_DRAW_FILLCIRCLE(vmCodes.vmFGColor,40,70,10);
            % draw filled rectangle
            cmd.opUI_DRAW_FILLRECT(vmCodes.vmFGColor,70,60,20,20);
            % draw inverse rectangle
            cmd.opUI_DRAW_INVERSERECT(30,90,60,20);
            % change font
            cmd.opUI_DRAW_SELECT_FONT(2);
            % draw text
            cmd.opUI_DRAW_TEXT(vmCodes.vmFGColor,100,40,'EV3');
            % change font
            cmd.opUI_DRAW_SELECT_FONT(1);
            % reprint
            cmd.opUI_DRAW_TEXT(vmCodes.vmFGColor,100,70,'EV3');
            % change font
            cmd.opUI_DRAW_SELECT_FONT(0);
            % reprint
            cmd.opUI_DRAW_TEXT(vmCodes.vmFGColor,100,90,'EV3');
            % voltage string
            cmd.opUI_DRAW_TEXT(vmCodes.vmFGColor,100,110,'v =');
            % store voltage
            cmd.opUI_READ_GET_VBATT(0);
            % print the voltage value (global)
            cmd.opUI_DRAW_VALUE(vmCodes.vmFGColor,130,110,0,5,3);
            % update the window
            cmd.opUI_DRAW_UPDATE;
            % 5 second timer (so you can see the changing LED pattern)
            cmd.opTIMER_WAIT(5000,0);
            % wait for timer
            cmd.opTIMER_READY(0);
            % reset the LED
            cmd.opUI_WRITE_LED(Device.LedGreen);
            % return UI screen
            cmd.opUI_DRAW_RESTORE(0);
            % return
            cmd.opUI_DRAW_UPDATE;
            cmd.addLength();
            brick.send(cmd)
        end
        
        function name = getBrickName(brick)
            % Brick.getBrickName Get brick name
            %
            % Brick.getBrickName() returns the name of the brick.
            %
            % Example::
            %           name = b.getBrickName()
          
            cmd = Command();
            cmd.addHeaderDirectReply(42,10,0);
            cmd.opCOMGET_GET_BRICKNAME(10,0);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            % return the brick name
            name = sscanf(char(msg(6:end)),'%s');
        end
        
        function setBrickName(brick,name)
            % Brick.setBrickName Set brick name
            %
            % Brick.setBrickName(name) sets the name of the brick.
            %
            % Example::
            %           b.setBrickName('EV3')
          
            cmd = Command();
            cmd.addHeaderDirectReply(42,0,0);
            cmd.opCOMSET_SET_BRICKNAME(name);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function mailBoxWrite(brick,brickname,boxname,type,msg)
            % Brick.mailBoxWrite Write a mailbox message
            %
            % Brick.mailBoxWrite(brickname,boxname,type,msg) writes a
            % mailbox message from the brick to a remote device.
            %
            % Notes::
            % - brickname is the name of the remote device.
            % - boxname is the name of the receiving mailbox.
            % - type is the sent message type being either 'text',
            % 'numeric' or 'logic'.
            % - msg is the message to be sent.
            %
            % Example::
            %           b.mailBoxWrite('T500','abc','logic',1)
            %           b.mailBoxWrite('T500','abc','numeric',4.24)
            %           b.mailBoxWrite('T500','abc','text','hello!')
            
            cmd = Command();
            cmd.addHeaderDirect(42,0,0);
            cmd.opMAILBOX_WRITE(brickname,boxname,type,msg);
            cmd.addLength();
            brick.send(cmd);
        end      

        function fileUpload(brick,filename,dest)
            % Brick.fileUpload Upload a file to the brick
            %
            % Brick.fileUpload(filename,dest) upload a file from the PC to
            % the brick.
            %
            % Notes::
            % - filename is the local PC file name for upload.
            % - dest is the remote destination on the brick relative to the
            % '/home/root/lms2012/sys' directory. Directories are created
            % in the path if they are not present.
            %
            % Example::
            %           b.fileUpload('prg.rbf','../apps/tst/tst.rbf')
            
            fid = fopen(filename,'r');
            % read in the file in and convert to uint8
            input = fread(fid,inf,'uint8=>uint8');
            fclose(fid); 
            % begin upload
            cmd = Command();
            cmd.addHeaderSystemReply(10);
            cmd.BEGIN_DOWNLOAD(length(input),dest);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            handle = rmsg(end);
            pause(1)
            % send the file
            cmd.clear();
            cmd.addHeaderSystemReply(11);
            cmd.CONTINUE_DOWNLOAD(handle,input);
            cmd.addLength();
            brick.send(cmd);
            % receive the sent response
            rmsg = brick.receive();
            % print message 
            fprintf('%s uploaded\n',filename);
        end
        
        function fileDownload(brick,dest,filename,maxlength)
            % Brick.fileDownload Download a file from the brick
            %
            % Brick.fileDownload(dest,filename,maxlength) downloads a file 
            % from the brick to the PC.
            %
            % Notes::
            % - dest is the remote destination on the brick relative to the
            % '/home/root/lms2012/sys' directory.
            % - filename is the local PC file name for download e.g.
            % 'prg.rbf'.
            % - maxlength is the max buffer size used for download.
            % 
            % Example::
            %           b.fileDownload('../apps/tst/tst.rbf','prg.rbf',59)
            
            % begin download
            cmd = Command();
            cmd.addHeaderSystemReply(12);
            cmd.BEGIN_UPLOAD(maxlength,dest);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            msg = brick.receive()';
            brick.commState = 0;
            % extract payload
            payload = rmsg(13:end);
            % print to file
            fid = fopen(filename,'w');
            % read in the file in and convert to uint8
            fwrite(fid,payload,'uint8');
            fclose(fid); 
        end
        
        function listFiles(brick,pathname,maxlength)
            % Brick.listFiles List files on the brick
            %
            % Brick.listFiles(brick,pathname,maxlength) list files in a 
            % given directory.
            %
            % Notes::
            % - pathname is the absolute path required for file listing.
            % - maxlength is the max buffer size used for file listing.
            % - If it is a file:
            %   32 chars (hex) of MD5SUM + space + 8 chars (hex) of filesize + space + filename + new line is returned.
            % - If it is a folder:
            %   foldername + / + new line is returned.
            %
            % Example::
            %           b.listFiles('/home/root/lms2012/',100)
            
            cmd = Command();
            cmd.addHeaderSystemReply(13);
            cmd.LIST_FILES(maxlength,pathname);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            rmsg = brick.receive();
            brick.commState = 0;
            
            % print
            fprintf('%s',rmsg(13:end));
        end    
        
        function createDir(brick,pathname)
            % Brick.createDir Create a directory on the brick
            % 
            % Brick.createDir(brick,pathname) creates a diretory on the 
            % brick from the given pathname.
            %
            % Notes::
            % - pathname is the absolute path for directory creation.
            %
            % Example::
            %           b.createDir('/home/root/lms2012/newdir')
            
            cmd = Command();
            cmd.addHeaderSystemReply(14);
            cmd.CREATE_DIR(pathname);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            rmsg = brick.receive();
            brick.commState = 0;
            
        end
        
        function deleteFile(brick,pathname)
            % Brick.deleteFile Delete file on the brick
            % 
            % Brick.deleteFile(brick,pathname) deletes a file from the
            % brick with the given pathname. 
            %
            % Notes::
            % - pathname is the absolute file path for deletion.
            % - will only delete files or empty directories.
            %
            % Example::
            %           b.deleteFile('/home/root/lms2012/newdir')
            
            cmd = Command();
            cmd.addHeaderSystemReply(15);
            cmd.DELETE_FILE(pathname);
            cmd.addLength();
            c = onCleanup(@()expectedResponse(brick));
            brick.commState = 1;
            brick.send(cmd);
            % receive the command
            rmsg = brick.receive();
            brick.commState = 0;
            
        end
        
        function writeMailBox(brick,title,type,msg)
            % Brick.writeMailBox Write a mailbox message
            %
            % Brick.writeMailBox(title,type,msg) writes a mailbox message to
            % the connected brick.
            %
            % Notes::
            % - title is the message title sent to the brick.
            % - type is the sent message type being either 'text',
            % 'numeric', or 'logic'.
            % - msg is the message to be sent to the brick.
            %
            % Example::
            %           b.writeMailBox('abc','text','hello!')
            
            cmd = Command();
            cmd.addHeaderSystem(16);
            cmd.WRITEMAILBOX(title,type,msg);
            cmd.addLength();
            brick.send(cmd);
        end
        
        function [title,msg] = readMailBox(brick,type)
            % Brick.readMailBox Read a mailbox message
            %
            % [title,msg] = Brick.readMailBox(type) reads a mailbox
            % message sent from the brick.
            %
            % Notes::
            % - type is the sent message type being either 'text',
            % 'numeric' or 'logic'.
            % - title is the message title sent from the brick.
            % - msg is the message sent from the brick.
            %
            % Example::
            %           [title,msg] = b.readMailBox('text')
            
            mailmsg = brick.receive();
            % extract message title (starts at pos 8, pos 7 is the size)
            title = char(mailmsg(8:7+mailmsg(7)));
            % parse message according to type
            switch type
                case 'text'
                    msg = char(mailmsg(mailmsg(7)+10:end));
                case 'numeric'
                    msg = typecast(uint8(mailmsg(mailmsg(7)+10:end)),'single');
                case 'logic'
                    msg = mailmsg(mailmsg(7)+10:end);
                otherwise
                    fprintf('Error! Type must be ''text'', ''numeric'' or ''logic''.\n');
                    msg = '';
            end
        end
            
        function threeToneByteCode(brick,filename)
            % Brick.threeToneByteCode Create three tone byte code
            %
            % Brick.threeToneByteCode() generates the byte code for the
            % play three tone function. This is an example of how byte code
            % can be generated as an rbf file which can be uploaded to the brick.
            %
            % Notes::
            % - filename is the name of the file to store the byte code in
            % (the rbf extension is added to the filename automatically)
            %
            % Example::
            %           b.threeToneByteCode('threetone')
            
            cmd = Command();
            % program header
            cmd.PROGRAMHeader(0,1,0);                   % VersionInfo,NumberOfObjects,GlobalBytes
            cmd.VMTHREADHeader(0,0);                    % OffsetToInstructions,LocalBytes
            % commands                                  % VMTHREAD1{
            cmd.opSOUND_TONE(5,440,500);                % opSOUND
            cmd.opSOUND_READY();                        % opSOUND_READY
            cmd.opSOUND_TONE(10,880,500);               % opSOUND
            cmd.opSOUND_READY();                        % opSOUND_READY
            cmd.opSOUND_TONE(15,1320,500);              % opSOUND
            cmd.opSOUND_READY();                        % opSOUND_READY
            cmd.opOBJECT_END;                           % }
            % add file size in header
            cmd.addFileSize;
            % generate the byte code
            cmd.GenerateByteCode(filename);
        end
    end
end


function out = makenos(input)
    out = 0;
    if ismember(input, 'ABCD')
       if ismember('A', input)
           out = bitor(out, 1);
       end
       if ismember('B', input)
           out = bitor(out, 2);
       end
       if ismember('C', input)
           out = bitor(out, 4);
       end
       if ismember('D', input)
           out = bitor(out, 8);
       end
    else
        out = input;
    end
end
 
function out = makebrake(input)
    out = 0;
    if input == 'Brake'
        out = 1;
    elseif input == 'Coast'
        out = 0;
    else
        out = input;
    end
end

% Connection Cleanup Function
function expectedResponse(brick)
    if brick.commState == 1
        disp("Cleaning up!");
        % receive the command
        msg = brick.receive()';
        brick.commState = 0;
    end
end

