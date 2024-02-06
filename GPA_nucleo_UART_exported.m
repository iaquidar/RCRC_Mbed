classdef GPA_nucleo_UART_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        NucleoconnectionUIFigure  matlab.ui.Figure
        iovaluesPanel             matlab.ui.container.Panel
        in2EditField              matlab.ui.control.NumericEditField
        in2EditFieldLabel         matlab.ui.control.Label
        in1EditField              matlab.ui.control.NumericEditField
        in1EditFieldLabel         matlab.ui.control.Label
        outEditField              matlab.ui.control.NumericEditField
        outEditFieldLabel         matlab.ui.control.Label
        idType1plantcl2plantol3posplantclLabel  matlab.ui.control.Label
        GPAPanel                  matlab.ui.container.Panel
        GPA_IdType                matlab.ui.control.NumericEditField
        IdtypeLabel               matlab.ui.control.Label
        GPA_MotNb                 matlab.ui.control.NumericEditField
        MotNb1or2Label            matlab.ui.control.Label
        gpa_meas_startButton      matlab.ui.control.Button
        GPA_N                     matlab.ui.control.NumericEditField
        NLabel                    matlab.ui.control.Label
        GPA_A1                    matlab.ui.control.NumericEditField
        A1Label                   matlab.ui.control.Label
        GPA_A0                    matlab.ui.control.NumericEditField
        A0Label                   matlab.ui.control.Label
        GPA_f0                    matlab.ui.control.NumericEditField
        f0Label                   matlab.ui.control.Label
        GPA_f1                    matlab.ui.control.NumericEditField
        f1Label                   matlab.ui.control.Label
        VarNameEditField          matlab.ui.control.EditField
        VarNameEditFieldLabel     matlab.ui.control.Label
        GPAtext                   matlab.ui.control.TextArea
        GPAonLamp                 matlab.ui.control.Lamp
        onLampLabel               matlab.ui.control.Label
        TxtOutput                 matlab.ui.control.TextArea
        TimemeasuresPanel         matlab.ui.container.Panel
        HzLabel                   matlab.ui.control.Label
        DwnsampEditField          matlab.ui.control.NumericEditField
        DwnsampEditFieldLabel     matlab.ui.control.Label
        OffsetEditField           matlab.ui.control.NumericEditField
        OffsetEditFieldLabel      matlab.ui.control.Label
        FreqEditField             matlab.ui.control.NumericEditField
        FreqEditFieldLabel        matlab.ui.control.Label
        AmpEditField              matlab.ui.control.NumericEditField
        AmpEditFieldLabel         matlab.ui.control.Label
        TypeDropDown              matlab.ui.control.DropDown
        TypeDropDownLabel         matlab.ui.control.Label
        VarNameEditField_ti       matlab.ui.control.EditField
        VarNameEditField_2Label   matlab.ui.control.Label
        timeMeasstartButton       matlab.ui.control.Button
        connectionLabel           matlab.ui.control.Label
        BREditField               matlab.ui.control.NumericEditField
        BREditFieldLabel          matlab.ui.control.Label
        COMPortsListBox           matlab.ui.control.ListBox
        COMPortsLabel             matlab.ui.control.Label
        V10Label                  matlab.ui.control.Label
        connectButton             matlab.ui.control.Button
        searchCOMPortsButton      matlab.ui.control.Button
    end

    
    properties (Access = public)
        selectedComPort     string % Selected COM Port
        % Flags
        flagPortSelect = false          
        flagPortsFree = false
        flagPortConnect = false
        textposition;
        baudRate
        serialPort
        recData
        GPA_data;
        GPA_i;
        Jumbo;
        loc_data;
    end
    
    properties (Access = private)
        TimerObj % Description
        data
        N=1e4;
    end
    
  
    
    
    methods (Access = private)
       
        function my_callback_fcn(app)
            loc_count = 0;
            while app.serialPort.NumBytesAvailable > 0
                li = readline(app.serialPort); %string
                app.I_li=app.I_li+1;
                loc_count=loc_count+1;
                dum = str2num(li);
                if ~app.array_defined && ~isempty(dum)
                    app.data=zeros(app.N,size(dum,2));
                    app.data(1,:)=dum;
                    app.array_defined = true;
                else
                    app.data(app.I_li,:)=dum;
                end
            %app.reciveLabel.Text=txt;
                if loc_count>0
                   app.TxtOutput.Value{1,:}=sprintf('received %3d lines, %5d in total.',loc_count,app.I_li);
                end
            end
        end

        function sendBinaryData(app,senddat) % binary
            try
                write(app.serialPort,mod(senddat,48),"UINT8");
%                 write(app.serialPort,'/n',"char");
            catch
            end
        end
        
        function sendData(app,senddat) % String
            try
                writeline(app.serialPort,senddat);
            catch
                
            end
        end
        
          function addmessage(app,txt)
            if app.textposition<6
                app.textposition = app.textposition+1;
                app.TxtOutput.Value(app.textposition) = txt;
            else
                for kk=1:5
                    app.TxtOutput.Value(kk)=app.TxtOutput.Value(kk+1);
                end
                app.TxtOutput.Value(6) = txt;
            end
        end
        
        
   
        function sendCommand(app, cmdId, data)
            cmdHeader = uint8([254 1 255 cmdId]);
            header = [cmdHeader typecast(uint16(length(data)),'uint8')];
            checksum = uint8(mod(sum(header)+sum(data),256));
            terminator = uint8([char(13) char(10)]); %CR/LF / "\r\n"
            uartPackage = [header data checksum terminator];
            %tic;
            write(app.serialPort ,uartPackage,'uint8') % does not send terminator
        end
        
    end
    
    methods (Access = public)
        
       
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.connectionLabel.Text="no Connection";

            %Timer objekt erstellen
            %app.TimerObj=timer('Period', 0.05, 'TasksToExecute', Inf,'ExecutionMode', 'fixedRate');
            %app.TimerObj.TimerFcn =@(~,~)app.getValuesUART;          
            %Im manuellen Modus Starten
            app.textposition = 2;
            app.TxtOutput.Value(3:6)={''};
            app.GPA_i = 0;
            app.loc_data = [];
            app.loc_data.rest_data = [];
        end

        % Button pushed function: searchCOMPortsButton
        function searchCOMPortsButtonPushed(app, event)
            ports = serialportlist("available"); % evtl. freeports = serialportlist("available") umschreiben zu try/catch
            
            if isempty(ports)
                app.COMPortsListBox.Items = "no Ports";
                %app.portsFree=false;
                app.connectButton.Enable = 'off';
            else
                app.COMPortsListBox.Items=ports;
                %app.portsFree=true;
                app.connectButton.Enable = 'on';
            end
        end

        % Button pushed function: connectButton
        function connectButtonPushed(app, event)
            app.baudRate=app.BREditField.Value;
            serialCallback = @(~,~)app.getValuesUART;
            if ((app.baudRate > 0) & (~app.flagPortConnect))
                app.serialPort = serialport(app.selectedComPort,app.baudRate,"Timeout",3);
                configureTerminator(app.serialPort,"CR/LF","CR/LF");
                configureCallback(app.serialPort,"terminator",serialCallback);

                %configureTerminator(app.serialPort,"LF") % Terminator (default "LF")
                app.flagPortConnect = true;
                app.connectionLabel.Text = "connected";
                app.connectButton.Text = "disconnect";
                %assignin('base', 's', app.serialPort) % export to Workspace
                app.searchCOMPortsButton.Enable = 'off';
                flush(app.serialPort,"output");flush(app.serialPort,"input");
%                start(app.TimerObj);
            
            elseif (app.flagPortConnect)
                clear app.serialPort; % geht nicht
                app.serialPort=[]; % Disconnect serial
                searchCOMPortsButtonPushed(app,event);
                app.flagPortConnect = false;
                app.connectionLabel.Text = "no Connection";
                app.connectButton.Text = "connect";
                app.searchCOMPortsButton.Enable = 'on';
                
            end
        end

        % Value changed function: COMPortsListBox
        function COMPortsListBoxValueChanged(app, event)
            app.selectedComPort = app.COMPortsListBox.Value;
            app.flagPortSelect = true;
        end

        % Value changed function: BREditField
        function BREditFieldValueChanged(app, event)
            if app.BREditField.Value < 0 % evtl druch Dropdownliste ersetzten
                app.baudRate = 0;
                app.BREditField.Value = 0;
            elseif app.BREditField.Value > 0
                app.baudRate = app.BREditField.Value;
            end
        end

        % Close request function: NucleoconnectionUIFigure
        function NucleoconnectionUIFigureCloseRequest(app, event)
            
            try
                fclose(app.serialPort);
            catch end
            try
                stop(app.TimerObj)
                o=timerfindall;
                delete(o);
            catch end
            try
                instrreset
            catch end
            delete(app) 
           
        end

        % Callback function
        function sendDataButtonPushed(app, event)
            sendData(app,app.sendTextEditField.Value)
        end

        % Callback function
        function ButtonPushed(app, event)
       
        end

        % Callback function
        function HomeallButtonPushed(app, event)
       
        end

        % Callback function
        function ChargeSwitchValueChanged(app, event)
            
        end

        % Callback function
        function UserResetButtonValueChanged(app, event)
            value = app.UserResetButton.Value;
            sendData(app,"360000");
        end

        % Callback function
        function CenterButtonPushed(app, event)
            sendData(app,"420000");
        end

        % Callback function
        function clcButtonPushed(app, event)
            app.TxtOutput.Value={''};
        end

        % Callback function
        function send2nucButtonPushed(app, event)
            sendData(app,app.TxtOutput.Value)
        end

        % Callback function
        function sendWSButtonPushed(app, event)
           
        end

        % Callback function
        function getValuesUART(app, event)
             try
                app.N = app.serialPort.NumBytesAvailable;
                if app.N>0
                    if isfield(app.loc_data,'rest_data')
                        da = [app.loc_data.rest_data,uint8(read(app.serialPort,app.N,'uint8'))];
                    else
                        da = uint8(read(app.serialPort,app.N,'uint8'));
                    end
                    app.loc_data = cut_data(da);
                    for k = 1:app.loc_data(1).N
                        if app.loc_data(k).complete_data
                            switch app.loc_data(k).id1
                                case 101
                                    switch app.loc_data(k).id2
                                        case 12
                                            val = double(typecast(uint8(app.loc_data(k).grab), 'single'))';
                                            app.Phi1_act.Value=val(1);
                                            dum=typecast(int64(round(val(1)*4000/2/pi)),'int16');
                                            app.Phi1_act_inc.Value=double(dum(1));
                                            app.Phi2_act.Value=val(2);
                                            dum=typecast(int64(round(val(2)*4000/2/pi)),'int16');
                                            app.Phi2_act_inc.Value=double(dum(1));
                                        case 34
                                            val = double(typecast(uint8(app.loc_data(k).grab), 'single'))';
                                            app.X_act.Value=val(1);
                                            app.Y_act.Value=val(2);
                                            if (val(1)<65 && val(1)>-65 && val(2)<65 && val(2)>-55)
                                                app.laserpoint.XData=val(1);
                                                app.laserpoint.YData=val(2);
                                                app.laserpoint.MarkerSize = 10;
                                            else
                                                app.laserpoint.MarkerSize = 1;
                                            end

                                    end
                                case 115 
                                    switch app.loc_data(k).id2
                                        case 1
                                            val = double(typecast(uint8(app.loc_data(k).grab), 'single'))';
                                            app.outEditField.Value = val(1);
                                            app.in1EditField.Value = val(2);
                                            app.in2EditField.Value = val(3);
                                    end
                                case 202
                                    val = double(typecast(uint8(app.loc_data(k).grab), 'single'))';
                                    switch app.loc_data(k).id2
                                        case 12
                                            app.Phi1_des.Value=val(1);
                                            app.Phi2_des.Value=val(2);
                                        case 34
                                            app.X_des.Value=val(1);
                                            app.Y_des.Value=val(2);
                                    end
                                case 125
                                    switch app.loc_data(k).id2
                                        case 1
                                            val = double(typecast(uint8(app.loc_data(k).grab), 'single'))';
                                    end
                                case 241
                                    switch app.loc_data(k).id2
                                        case 1
                                            app.addmessage({char(typecast(uint8(app.loc_data(k).grab), 'uint8'))});
                                    end
                                case 210
                                    if app.loc_data(k).id2 < 99
                                        %disp(app.loc_data(k).id2)
                                        packet = double(app.loc_data(k).id2);
                                        app.Jumbo=[app.Jumbo,app.loc_data(k).grab];
                                    end
                                    if app.loc_data(k).id2 ==99
                                        val = double(typecast(uint8(app.Jumbo), 'single'));
                                        assignin('base','rawdata',app.Jumbo);
                                        app.Jumbo = [];
                                        NCOL = 4;
                                        val = reshape(val,NCOL,length(val)/NCOL)';
                                        timedata.ti = val(:,1);
                                        timedata.values = val(:,2:NCOL);
                                        assignin('base',app.VarNameEditField_ti.Value,timedata);
                                        addmessage(app,{'sent data to WS'})
                                    end
                                case 250
                                    switch app.loc_data(k).id2
                                        case 1  % get data
                                            try
                                                val = double(typecast(uint8(app.loc_data(k).grab), 'single'))';
                                                app.GPA_i = app.GPA_i+1;
                                                app.GPA_data(app.GPA_i,:)=val;
                                                %disp('received')
                                                app.GPAtext.Value = sprintf('rec. val. @ %4.0f Hz',val(1));
                                                app.GPAonLamp.Color =[0.93,0.69,0.13];
                                            catch
                                                disp('error in communication')
                                                %disp(head)
                                                %disp(dat(1:end-2))
                                            end
                                        case 255  % meas finished
                                            assignin('base','GPA_data',app.GPA_data)
                                            G=frd(app.GPA_data(:,2).*exp(1i*app.GPA_data(:,3)*pi/180),app.GPA_data(:,1)*2*pi);
                                            assignin('base',app.VarNameEditField.Value,G)
                                            app.GPAtext.Value = sprintf('frd with %d pts to WS',size(app.GPA_data,1));
                                            app.GPAonLamp.Color =[0 1 0];
                                        case 2      % reset GPA
                                            app.GPA_i = 0;
                                            app.GPA_data = [];
                                        case 3
                                            %disp(app.loc_data(k).grab
                                            %app.received_packages
                                    end
                            end
                        end
                    end
                end
            catch ME
                4;
            end
        end

        % Button pushed function: timeMeasstartButton
        function timeMeasstartButtonPushed(app, event)
            va = find(strcmp(app.TypeDropDown.Items,app.TypeDropDown.Value));
            dat = [typecast(uint8(va),'uint8') typecast(single(app.AmpEditField.Value),'uint8') ...
                   typecast(single(app.FreqEditField.Value*2*pi),'uint8') typecast(single(app.OffsetEditField.Value),'uint8') typecast(uint8(app.DwnsampEditField.Value),'uint8')];
            sendCommand(app,[210 101],dat);
        end

        % Button pushed function: gpa_meas_startButton
        function gpa_meas_startButtonPushed(app, event)
            dat = [typecast(single(app.GPA_f0.Value),'uint8') typecast(single(app.GPA_f1.Value),'uint8')...
                typecast(single(app.GPA_A0.Value),'uint8') typecast(single(app.GPA_A1.Value),'uint8') typecast(uint8(app.GPA_N.Value),'uint8')...
                typecast(uint8(app.GPA_MotNb.Value-1),'uint8') typecast(uint8(app.GPA_IdType.Value),'uint8')];
            sendCommand(app,[250 101],dat);
        end

        % Value changed function: VarNameEditField_ti
        function VarNameEditField_tiValueChanged(app, event)
            value = app.VarNameEditField_ti.Value;
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create NucleoconnectionUIFigure and hide until all components are created
            app.NucleoconnectionUIFigure = uifigure('Visible', 'off');
            app.NucleoconnectionUIFigure.AutoResizeChildren = 'off';
            app.NucleoconnectionUIFigure.Colormap = [0.2431 0.149 0.6588;0.2431 0.1529 0.6745;0.2471 0.1569 0.6863;0.2471 0.1608 0.698;0.251 0.1647 0.7059;0.251 0.1686 0.7176;0.2549 0.1725 0.7294;0.2549 0.1765 0.7412;0.2588 0.1804 0.749;0.2588 0.1843 0.7608;0.2627 0.1882 0.7725;0.2627 0.1922 0.7843;0.2627 0.1961 0.7922;0.2667 0.2 0.8039;0.2667 0.2039 0.8157;0.2706 0.2078 0.8235;0.2706 0.2157 0.8353;0.2706 0.2196 0.8431;0.2745 0.2235 0.851;0.2745 0.2275 0.8627;0.2745 0.2314 0.8706;0.2745 0.2392 0.8784;0.2784 0.2431 0.8824;0.2784 0.2471 0.8902;0.2784 0.2549 0.898;0.2784 0.2588 0.902;0.2784 0.2667 0.9098;0.2784 0.2706 0.9137;0.2784 0.2745 0.9216;0.2824 0.2824 0.9255;0.2824 0.2863 0.9294;0.2824 0.2941 0.9333;0.2824 0.298 0.9412;0.2824 0.3059 0.9451;0.2824 0.3098 0.949;0.2824 0.3137 0.9529;0.2824 0.3216 0.9569;0.2824 0.3255 0.9608;0.2824 0.3294 0.9647;0.2784 0.3373 0.9686;0.2784 0.3412 0.9686;0.2784 0.349 0.9725;0.2784 0.3529 0.9765;0.2784 0.3569 0.9804;0.2784 0.3647 0.9804;0.2745 0.3686 0.9843;0.2745 0.3765 0.9843;0.2745 0.3804 0.9882;0.2706 0.3843 0.9882;0.2706 0.3922 0.9922;0.2667 0.3961 0.9922;0.2627 0.4039 0.9922;0.2627 0.4078 0.9961;0.2588 0.4157 0.9961;0.2549 0.4196 0.9961;0.251 0.4275 0.9961;0.2471 0.4314 1;0.2431 0.4392 1;0.2353 0.4431 1;0.2314 0.451 1;0.2235 0.4549 1;0.2196 0.4627 0.9961;0.2118 0.4667 0.9961;0.2078 0.4745 0.9922;0.2 0.4784 0.9922;0.1961 0.4863 0.9882;0.1922 0.4902 0.9882;0.1882 0.498 0.9843;0.1843 0.502 0.9804;0.1843 0.5098 0.9804;0.1804 0.5137 0.9765;0.1804 0.5176 0.9725;0.1804 0.5255 0.9725;0.1804 0.5294 0.9686;0.1765 0.5333 0.9647;0.1765 0.5412 0.9608;0.1765 0.5451 0.9569;0.1765 0.549 0.9529;0.1765 0.5569 0.949;0.1725 0.5608 0.9451;0.1725 0.5647 0.9412;0.1686 0.5686 0.9373;0.1647 0.5765 0.9333;0.1608 0.5804 0.9294;0.1569 0.5843 0.9255;0.1529 0.5922 0.9216;0.1529 0.5961 0.9176;0.149 0.6 0.9137;0.149 0.6039 0.9098;0.1451 0.6078 0.9098;0.1451 0.6118 0.9059;0.1412 0.6196 0.902;0.1412 0.6235 0.898;0.1373 0.6275 0.898;0.1373 0.6314 0.8941;0.1333 0.6353 0.8941;0.1294 0.6392 0.8902;0.1255 0.6471 0.8902;0.1216 0.651 0.8863;0.1176 0.6549 0.8824;0.1137 0.6588 0.8824;0.1137 0.6627 0.8784;0.1098 0.6667 0.8745;0.1059 0.6706 0.8706;0.102 0.6745 0.8667;0.098 0.6784 0.8627;0.0902 0.6824 0.8549;0.0863 0.6863 0.851;0.0784 0.6902 0.8471;0.0706 0.6941 0.8392;0.0627 0.698 0.8353;0.0549 0.702 0.8314;0.0431 0.702 0.8235;0.0314 0.7059 0.8196;0.0235 0.7098 0.8118;0.0157 0.7137 0.8078;0.0078 0.7176 0.8;0.0039 0.7176 0.7922;0 0.7216 0.7882;0 0.7255 0.7804;0 0.7294 0.7765;0.0039 0.7294 0.7686;0.0078 0.7333 0.7608;0.0157 0.7333 0.7569;0.0235 0.7373 0.749;0.0353 0.7412 0.7412;0.051 0.7412 0.7373;0.0627 0.7451 0.7294;0.0784 0.7451 0.7216;0.0902 0.749 0.7137;0.102 0.7529 0.7098;0.1137 0.7529 0.702;0.1255 0.7569 0.6941;0.1373 0.7569 0.6863;0.1451 0.7608 0.6824;0.1529 0.7608 0.6745;0.1608 0.7647 0.6667;0.1686 0.7647 0.6588;0.1725 0.7686 0.651;0.1804 0.7686 0.6471;0.1843 0.7725 0.6392;0.1922 0.7725 0.6314;0.1961 0.7765 0.6235;0.2 0.7804 0.6157;0.2078 0.7804 0.6078;0.2118 0.7843 0.6;0.2196 0.7843 0.5882;0.2235 0.7882 0.5804;0.2314 0.7882 0.5725;0.2392 0.7922 0.5647;0.251 0.7922 0.5529;0.2588 0.7922 0.5451;0.2706 0.7961 0.5373;0.2824 0.7961 0.5255;0.2941 0.7961 0.5176;0.3059 0.8 0.5059;0.3176 0.8 0.498;0.3294 0.8 0.4863;0.3412 0.8 0.4784;0.3529 0.8 0.4667;0.3686 0.8039 0.4549;0.3804 0.8039 0.4471;0.3922 0.8039 0.4353;0.4039 0.8039 0.4235;0.4196 0.8039 0.4118;0.4314 0.8039 0.4;0.4471 0.8039 0.3922;0.4627 0.8 0.3804;0.4745 0.8 0.3686;0.4902 0.8 0.3569;0.5059 0.8 0.349;0.5176 0.8 0.3373;0.5333 0.7961 0.3255;0.5451 0.7961 0.3176;0.5608 0.7961 0.3059;0.5765 0.7922 0.2941;0.5882 0.7922 0.2824;0.6039 0.7882 0.2745;0.6157 0.7882 0.2627;0.6314 0.7843 0.251;0.6431 0.7843 0.2431;0.6549 0.7804 0.2314;0.6706 0.7804 0.2235;0.6824 0.7765 0.2157;0.698 0.7765 0.2078;0.7098 0.7725 0.2;0.7216 0.7686 0.1922;0.7333 0.7686 0.1843;0.7451 0.7647 0.1765;0.7608 0.7647 0.1725;0.7725 0.7608 0.1647;0.7843 0.7569 0.1608;0.7961 0.7569 0.1569;0.8078 0.7529 0.1529;0.8157 0.749 0.1529;0.8275 0.749 0.1529;0.8392 0.7451 0.1529;0.851 0.7451 0.1569;0.8588 0.7412 0.1569;0.8706 0.7373 0.1608;0.8824 0.7373 0.1647;0.8902 0.7373 0.1686;0.902 0.7333 0.1765;0.9098 0.7333 0.1804;0.9176 0.7294 0.1882;0.9255 0.7294 0.1961;0.9373 0.7294 0.2078;0.9451 0.7294 0.2157;0.9529 0.7294 0.2235;0.9608 0.7294 0.2314;0.9686 0.7294 0.2392;0.9765 0.7294 0.2431;0.9843 0.7333 0.2431;0.9882 0.7373 0.2431;0.9961 0.7412 0.2392;0.9961 0.7451 0.2353;0.9961 0.7529 0.2314;0.9961 0.7569 0.2275;0.9961 0.7608 0.2235;0.9961 0.7686 0.2196;0.9961 0.7725 0.2157;0.9961 0.7804 0.2078;0.9961 0.7843 0.2039;0.9961 0.7922 0.2;0.9922 0.7961 0.1961;0.9922 0.8039 0.1922;0.9922 0.8078 0.1922;0.9882 0.8157 0.1882;0.9843 0.8235 0.1843;0.9843 0.8275 0.1804;0.9804 0.8353 0.1804;0.9765 0.8392 0.1765;0.9765 0.8471 0.1725;0.9725 0.851 0.1686;0.9686 0.8588 0.1647;0.9686 0.8667 0.1647;0.9647 0.8706 0.1608;0.9647 0.8784 0.1569;0.9608 0.8824 0.1569;0.9608 0.8902 0.1529;0.9608 0.898 0.149;0.9608 0.902 0.149;0.9608 0.9098 0.1451;0.9608 0.9137 0.1412;0.9608 0.9216 0.1373;0.9608 0.9255 0.1333;0.9608 0.9333 0.1294;0.9647 0.9373 0.1255;0.9647 0.9451 0.1216;0.9647 0.949 0.1176;0.9686 0.9569 0.1098;0.9686 0.9608 0.1059;0.9725 0.9686 0.102;0.9725 0.9725 0.0941;0.9765 0.9765 0.0863;0.9765 0.9843 0.0824];
            app.NucleoconnectionUIFigure.Position = [300 300 623 334];
            app.NucleoconnectionUIFigure.Name = 'Nucleo connection';
            app.NucleoconnectionUIFigure.Icon = 'nuc.jpg';
            app.NucleoconnectionUIFigure.Resize = 'off';
            app.NucleoconnectionUIFigure.CloseRequestFcn = createCallbackFcn(app, @NucleoconnectionUIFigureCloseRequest, true);

            % Create searchCOMPortsButton
            app.searchCOMPortsButton = uibutton(app.NucleoconnectionUIFigure, 'push');
            app.searchCOMPortsButton.ButtonPushedFcn = createCallbackFcn(app, @searchCOMPortsButtonPushed, true);
            app.searchCOMPortsButton.Position = [18 234 123 22];
            app.searchCOMPortsButton.Text = 'search COM Ports';

            % Create connectButton
            app.connectButton = uibutton(app.NucleoconnectionUIFigure, 'push');
            app.connectButton.ButtonPushedFcn = createCallbackFcn(app, @connectButtonPushed, true);
            app.connectButton.Enable = 'off';
            app.connectButton.Position = [150 235 86 22];
            app.connectButton.Text = 'connect';

            % Create V10Label
            app.V10Label = uilabel(app.NucleoconnectionUIFigure);
            app.V10Label.FontColor = [0.651 0.651 0.651];
            app.V10Label.Position = [12 -141 30 22];
            app.V10Label.Text = 'V1.0';

            % Create COMPortsLabel
            app.COMPortsLabel = uilabel(app.NucleoconnectionUIFigure);
            app.COMPortsLabel.HorizontalAlignment = 'right';
            app.COMPortsLabel.Position = [12 266 31 53];
            app.COMPortsLabel.Text = {'COM'; 'Ports'};

            % Create COMPortsListBox
            app.COMPortsListBox = uilistbox(app.NucleoconnectionUIFigure);
            app.COMPortsListBox.Items = {};
            app.COMPortsListBox.ValueChangedFcn = createCallbackFcn(app, @COMPortsListBoxValueChanged, true);
            app.COMPortsListBox.Position = [50 266 91 53];
            app.COMPortsListBox.Value = {};

            % Create BREditFieldLabel
            app.BREditFieldLabel = uilabel(app.NucleoconnectionUIFigure);
            app.BREditFieldLabel.HorizontalAlignment = 'right';
            app.BREditFieldLabel.Position = [211 281 25 22];
            app.BREditFieldLabel.Text = 'BR';

            % Create BREditField
            app.BREditField = uieditfield(app.NucleoconnectionUIFigure, 'numeric');
            app.BREditField.Limits = [0 2560000];
            app.BREditField.ValueDisplayFormat = '%.0f';
            app.BREditField.ValueChangedFcn = createCallbackFcn(app, @BREditFieldValueChanged, true);
            app.BREditField.Position = [150 281 52 22];
            app.BREditField.Value = 115200;

            % Create connectionLabel
            app.connectionLabel = uilabel(app.NucleoconnectionUIFigure);
            app.connectionLabel.Position = [150 262 62 22];
            app.connectionLabel.Text = '---';

            % Create TimemeasuresPanel
            app.TimemeasuresPanel = uipanel(app.NucleoconnectionUIFigure);
            app.TimemeasuresPanel.AutoResizeChildren = 'off';
            app.TimemeasuresPanel.Title = 'Time measures';
            app.TimemeasuresPanel.Position = [305 27 198 159];

            % Create timeMeasstartButton
            app.timeMeasstartButton = uibutton(app.TimemeasuresPanel, 'push');
            app.timeMeasstartButton.ButtonPushedFcn = createCallbackFcn(app, @timeMeasstartButtonPushed, true);
            app.timeMeasstartButton.Position = [150 87 35 21];
            app.timeMeasstartButton.Text = 'start';

            % Create VarNameEditField_2Label
            app.VarNameEditField_2Label = uilabel(app.TimemeasuresPanel);
            app.VarNameEditField_2Label.HorizontalAlignment = 'right';
            app.VarNameEditField_2Label.Position = [39 7 70 22];
            app.VarNameEditField_2Label.Text = 'VarName';

            % Create VarNameEditField_ti
            app.VarNameEditField_ti = uieditfield(app.TimemeasuresPanel, 'text');
            app.VarNameEditField_ti.ValueChangedFcn = createCallbackFcn(app, @VarNameEditField_tiValueChanged, true);
            app.VarNameEditField_ti.Position = [132 7 59 22];
            app.VarNameEditField_ti.Value = 'data';

            % Create TypeDropDownLabel
            app.TypeDropDownLabel = uilabel(app.TimemeasuresPanel);
            app.TypeDropDownLabel.HorizontalAlignment = 'right';
            app.TypeDropDownLabel.Position = [15 112 32 22];
            app.TypeDropDownLabel.Text = 'Type';

            % Create TypeDropDown
            app.TypeDropDown = uidropdown(app.TimemeasuresPanel);
            app.TypeDropDown.Items = {'Step Sequence', 'Sine Wave', 'ZigZag'};
            app.TypeDropDown.Position = [62 112 100 22];
            app.TypeDropDown.Value = 'Sine Wave';

            % Create AmpEditFieldLabel
            app.AmpEditFieldLabel = uilabel(app.TimemeasuresPanel);
            app.AmpEditFieldLabel.HorizontalAlignment = 'right';
            app.AmpEditFieldLabel.Position = [19 87 34 22];
            app.AmpEditFieldLabel.Text = 'Amp.';

            % Create AmpEditField
            app.AmpEditField = uieditfield(app.TimemeasuresPanel, 'numeric');
            app.AmpEditField.Limits = [-5000 5000];
            app.AmpEditField.Position = [58 87 39 22];
            app.AmpEditField.Value = 1;

            % Create FreqEditFieldLabel
            app.FreqEditFieldLabel = uilabel(app.TimemeasuresPanel);
            app.FreqEditFieldLabel.HorizontalAlignment = 'right';
            app.FreqEditFieldLabel.Position = [20 62 34 17];
            app.FreqEditFieldLabel.Text = 'Freq.';

            % Create FreqEditField
            app.FreqEditField = uieditfield(app.TimemeasuresPanel, 'numeric');
            app.FreqEditField.Limits = [0.1 100];
            app.FreqEditField.Position = [59 60 38 22];
            app.FreqEditField.Value = 5;

            % Create OffsetEditFieldLabel
            app.OffsetEditFieldLabel = uilabel(app.TimemeasuresPanel);
            app.OffsetEditFieldLabel.HorizontalAlignment = 'right';
            app.OffsetEditFieldLabel.Position = [18 30 37 22];
            app.OffsetEditFieldLabel.Text = 'Offset';

            % Create OffsetEditField
            app.OffsetEditField = uieditfield(app.TimemeasuresPanel, 'numeric');
            app.OffsetEditField.Limits = [-1000 1000];
            app.OffsetEditField.Position = [60 33 38 22];

            % Create DwnsampEditFieldLabel
            app.DwnsampEditFieldLabel = uilabel(app.TimemeasuresPanel);
            app.DwnsampEditFieldLabel.HorizontalAlignment = 'right';
            app.DwnsampEditFieldLabel.Position = [105 33 59 22];
            app.DwnsampEditFieldLabel.Text = 'Dwnsamp';

            % Create DwnsampEditField
            app.DwnsampEditField = uieditfield(app.TimemeasuresPanel, 'numeric');
            app.DwnsampEditField.Limits = [1 50];
            app.DwnsampEditField.Position = [167 33 23 22];
            app.DwnsampEditField.Value = 1;

            % Create HzLabel
            app.HzLabel = uilabel(app.TimemeasuresPanel);
            app.HzLabel.Position = [101 59 25 22];
            app.HzLabel.Text = 'Hz';

            % Create TxtOutput
            app.TxtOutput = uitextarea(app.NucleoconnectionUIFigure);
            app.TxtOutput.FontName = 'Courier New';
            app.TxtOutput.FontSize = 11;
            app.TxtOutput.FontColor = [0 1 0];
            app.TxtOutput.BackgroundColor = [0 0 0];
            app.TxtOutput.Position = [251 215 221 88];
            app.TxtOutput.Value = {'Nucleo Communication'; '---------------'};

            % Create GPAPanel
            app.GPAPanel = uipanel(app.NucleoconnectionUIFigure);
            app.GPAPanel.AutoResizeChildren = 'off';
            app.GPAPanel.Title = 'GPA';
            app.GPAPanel.Position = [29 27 258 150];

            % Create onLampLabel
            app.onLampLabel = uilabel(app.GPAPanel);
            app.onLampLabel.HorizontalAlignment = 'right';
            app.onLampLabel.Position = [6 54 25 22];
            app.onLampLabel.Text = 'on';

            % Create GPAonLamp
            app.GPAonLamp = uilamp(app.GPAPanel);
            app.GPAonLamp.Position = [46 54 20 20];
            app.GPAonLamp.Color = [0.8 0.8 0.8];

            % Create GPAtext
            app.GPAtext = uitextarea(app.GPAPanel);
            app.GPAtext.FontName = 'Courier New';
            app.GPAtext.FontSize = 11;
            app.GPAtext.Position = [6 102 155 19];
            app.GPAtext.Value = {'Wait'};

            % Create VarNameEditFieldLabel
            app.VarNameEditFieldLabel = uilabel(app.GPAPanel);
            app.VarNameEditFieldLabel.HorizontalAlignment = 'right';
            app.VarNameEditFieldLabel.Position = [6 75 70 22];
            app.VarNameEditFieldLabel.Text = 'VarName';

            % Create VarNameEditField
            app.VarNameEditField = uieditfield(app.GPAPanel, 'text');
            app.VarNameEditField.Position = [99 75 63 22];
            app.VarNameEditField.Value = 'G_est';

            % Create f1Label
            app.f1Label = uilabel(app.GPAPanel);
            app.f1Label.HorizontalAlignment = 'right';
            app.f1Label.Position = [172 82 25 22];
            app.f1Label.Text = 'f1';

            % Create GPA_f1
            app.GPA_f1 = uieditfield(app.GPAPanel, 'numeric');
            app.GPA_f1.Limits = [1 10000];
            app.GPA_f1.Position = [197 82 45 22];
            app.GPA_f1.Value = 1000;

            % Create f0Label
            app.f0Label = uilabel(app.GPAPanel);
            app.f0Label.HorizontalAlignment = 'right';
            app.f0Label.Position = [172 106 25 22];
            app.f0Label.Text = 'f0';

            % Create GPA_f0
            app.GPA_f0 = uieditfield(app.GPAPanel, 'numeric');
            app.GPA_f0.Limits = [0.01 10000];
            app.GPA_f0.Position = [212 106 29 22];
            app.GPA_f0.Value = 1;

            % Create A0Label
            app.A0Label = uilabel(app.GPAPanel);
            app.A0Label.HorizontalAlignment = 'right';
            app.A0Label.Position = [173 58 25 22];
            app.A0Label.Text = 'A0';

            % Create GPA_A0
            app.GPA_A0 = uieditfield(app.GPAPanel, 'numeric');
            app.GPA_A0.Limits = [0 Inf];
            app.GPA_A0.Position = [207 58 36 22];
            app.GPA_A0.Value = 1;

            % Create A1Label
            app.A1Label = uilabel(app.GPAPanel);
            app.A1Label.HorizontalAlignment = 'right';
            app.A1Label.Position = [173 34 25 22];
            app.A1Label.Text = 'A1';

            % Create GPA_A1
            app.GPA_A1 = uieditfield(app.GPAPanel, 'numeric');
            app.GPA_A1.Limits = [0 Inf];
            app.GPA_A1.Position = [207 34 36 22];
            app.GPA_A1.Value = 1;

            % Create NLabel
            app.NLabel = uilabel(app.GPAPanel);
            app.NLabel.HorizontalAlignment = 'right';
            app.NLabel.Position = [173 8 25 22];
            app.NLabel.Text = 'N';

            % Create GPA_N
            app.GPA_N = uieditfield(app.GPAPanel, 'numeric');
            app.GPA_N.Limits = [1 255];
            app.GPA_N.RoundFractionalValues = 'on';
            app.GPA_N.Position = [207 8 36 22];
            app.GPA_N.Value = 30;

            % Create gpa_meas_startButton
            app.gpa_meas_startButton = uibutton(app.GPAPanel, 'push');
            app.gpa_meas_startButton.ButtonPushedFcn = createCallbackFcn(app, @gpa_meas_startButtonPushed, true);
            app.gpa_meas_startButton.Position = [101 54 35 21];
            app.gpa_meas_startButton.Text = 'start';

            % Create MotNb1or2Label
            app.MotNb1or2Label = uilabel(app.GPAPanel);
            app.MotNb1or2Label.HorizontalAlignment = 'right';
            app.MotNb1or2Label.Position = [-11 7 101 22];
            app.MotNb1or2Label.Text = 'MotNb (1, or 2)';

            % Create GPA_MotNb
            app.GPA_MotNb = uieditfield(app.GPAPanel, 'numeric');
            app.GPA_MotNb.Limits = [1 2];
            app.GPA_MotNb.RoundFractionalValues = 'on';
            app.GPA_MotNb.Position = [99 7 36 22];
            app.GPA_MotNb.Value = 2;

            % Create IdtypeLabel
            app.IdtypeLabel = uilabel(app.GPAPanel);
            app.IdtypeLabel.HorizontalAlignment = 'right';
            app.IdtypeLabel.Position = [-11 30 101 22];
            app.IdtypeLabel.Text = 'Id. type';

            % Create GPA_IdType
            app.GPA_IdType = uieditfield(app.GPAPanel, 'numeric');
            app.GPA_IdType.Limits = [1 4];
            app.GPA_IdType.RoundFractionalValues = 'on';
            app.GPA_IdType.Position = [99 30 36 22];
            app.GPA_IdType.Value = 2;

            % Create idType1plantcl2plantol3posplantclLabel
            app.idType1plantcl2plantol3posplantclLabel = uilabel(app.NucleoconnectionUIFigure);
            app.idType1plantcl2plantol3posplantclLabel.HorizontalAlignment = 'right';
            app.idType1plantcl2plantol3posplantclLabel.Position = [19 -1 367 22];
            app.idType1plantcl2plantol3posplantclLabel.Text = 'id. Type:1 = plant (c.l); 2 = plant (ol); 3 = pos plant (cl)';

            % Create iovaluesPanel
            app.iovaluesPanel = uipanel(app.NucleoconnectionUIFigure);
            app.iovaluesPanel.AutoResizeChildren = 'off';
            app.iovaluesPanel.Title = 'i/o values';
            app.iovaluesPanel.Position = [511 52 100 134];

            % Create outEditFieldLabel
            app.outEditFieldLabel = uilabel(app.iovaluesPanel);
            app.outEditFieldLabel.HorizontalAlignment = 'right';
            app.outEditFieldLabel.Position = [18 72 25 22];
            app.outEditFieldLabel.Text = 'out';

            % Create outEditField
            app.outEditField = uieditfield(app.iovaluesPanel, 'numeric');
            app.outEditField.Limits = [-5000 5000];
            app.outEditField.Position = [48 72 39 22];
            app.outEditField.Value = 1;

            % Create in1EditFieldLabel
            app.in1EditFieldLabel = uilabel(app.iovaluesPanel);
            app.in1EditFieldLabel.HorizontalAlignment = 'right';
            app.in1EditFieldLabel.Position = [10 42 34 22];
            app.in1EditFieldLabel.Text = 'in1';

            % Create in1EditField
            app.in1EditField = uieditfield(app.iovaluesPanel, 'numeric');
            app.in1EditField.Position = [49 45 38 22];
            app.in1EditField.Value = 5;

            % Create in2EditFieldLabel
            app.in2EditFieldLabel = uilabel(app.iovaluesPanel);
            app.in2EditFieldLabel.HorizontalAlignment = 'right';
            app.in2EditFieldLabel.Position = [20 15 25 22];
            app.in2EditFieldLabel.Text = 'in2';

            % Create in2EditField
            app.in2EditField = uieditfield(app.iovaluesPanel, 'numeric');
            app.in2EditField.Limits = [-1000 1000];
            app.in2EditField.Position = [50 18 38 22];

            % Show the figure after all components are created
            app.NucleoconnectionUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GPA_nucleo_UART_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.NucleoconnectionUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.NucleoconnectionUIFigure)
        end
    end
end