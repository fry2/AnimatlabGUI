classdef CanvasModel < handle
    
    properties (SetAccess = public, GetAccess=public)
        neurons_positions = zeros(0,2)
        num_neurons = 0
        neuron_objects = struct()
        
        link_ends
        num_links = 0
        link_objects = struct()
        
        synapse_types = struct()
        
        obstacles_positions = zeros(0,2)
        num_obstacles = 0        
        
        dtsim = 1e-3;
        tmax = 10;
    end
    
    events (NotifyAccess = private)
        itemAdded
        itemMoved
        itemDeleted
        modelChanged
        modelDeleted
        linkAdded
    end
    
    methods % constructor and destructor
        
        function obj  = CanvasModel()
            obj.setupDefaultSynapseTypes();
        end
        
        function delete(obj)
            obj.notify('modelDeleted');
        end
        
    end
    
    methods (Access = public)
        %% setupSynapseTypes
        function setupDefaultSynapseTypes(obj)
            props = [{'SignalTransmission1','delE',194,'k',1,'max_syn_cond',.115};...
                    {'SignalModulation1','delE',-40,'k',1,'max_syn_cond',.558};...
                    {'SignalModulation2','delE',0,'c',0.05,'max_syn_cond',19};...
                    {'SignalModulation3','delE',-1,'c',0,'max_syn_cond',20}];
            obj.createSynapseType(props);
        end
        %% addItem
        function addItem(obj, type_char, pos, bounds)
            %This will change if the randomized position generated in the Controller creates an
            %object that falls outside the bounds of the canvas. If so, it changes the position
            %so that the object doesn't go out of bounds
            
%             pos = CanvasConstants.ConstrainedPosition(type_char, pos);
            pos = obj.ConstrainedPosition(type_char, pos, bounds);
            
            if type_char == 'n' %neuron
                obj.neurons_positions(end+1,:) = pos;
                obj.num_neurons = size(obj.neurons_positions, 1);
                if obj.num_neurons == 1
                    obj.neuron_objects = obj.create_neuron(pos);
                else
                    obj.neuron_objects(obj.num_neurons,1) = obj.create_neuron(pos);
                end
                index = obj.num_neurons;
            elseif strcmp(type_char,'stimulus')
                [~,modelInd] = min(abs(sum(obj.neurons_positions-pos,2)));
                obj.create_stimulus(modelInd);
                index = modelInd;
            else %obstacle
                obj.obstacles_positions(end+1,:) = pos;
                obj.num_obstacles = size(obj.obstacles_positions, 1);
                index = obj.num_obstacles;
            end
            
            obj.notify('itemAdded', CanvasModelEventData(type_char, index));
            obj.notify('modelChanged');
            
        end
        %% addLink
        function addLink(obj,start_ind,end_ind,beg,ennd,linktype)
            obj.link_ends(end+1,:) = [beg ennd];
            obj.num_links = size(obj.link_ends, 1);
            index = obj.num_links;
            
            if obj.num_links == 1
                obj.link_objects = obj.create_link([beg ennd]);
            else
                obj.link_objects(obj.num_links,1) = obj.create_link([beg ennd]);
            end
            
            numLinks = obj.num_links;
            
            try obj.link_objects(1).ID;           
                while sum(strcmp({obj.link_objects.ID}, ['link',num2str(numLinks),'-ID']))
                                numLinks = numLinks + 1;
                end
            catch
                numLinks = obj.num_links;
            end
            
            obj.link_objects(obj.num_links,1).ID = ['link',num2str(numLinks),'-ID'];
            obj.link_objects(obj.num_links,1).origin_ID = obj.neuron_objects(start_ind).ID;
            obj.link_objects(obj.num_links,1).destination_ID = obj.neuron_objects(end_ind).ID;
            obj.link_objects(obj.num_links,1).origin_cdata_num = start_ind-1;
            obj.link_objects(obj.num_links,1).destination_cdata_num = end_ind-1;
            obj.link_objects(obj.num_links,1).synaptictype = linktype;
            
            obj.neuron_objects(start_ind).outlinks = [obj.neuron_objects(start_ind).outlinks;obj.link_objects(obj.num_links)];
            obj.neuron_objects(end_ind).inlinks = [obj.neuron_objects(end_ind).inlinks;obj.link_objects(obj.num_links)];
            obj.neuron_objects(start_ind).outlink_IDs = [obj.neuron_objects(start_ind).outlink_IDs;{obj.link_objects(obj.num_links).ID}];
            obj.neuron_objects(end_ind).inlink_IDs = [obj.neuron_objects(end_ind).inlink_IDs;{obj.link_objects(obj.num_links).ID}];
            
            if ~isempty(obj.neuron_objects(start_ind).totmem)
                obj.updateStimModel(end_ind);
            end

            obj.notify('linkAdded', CanvasModelEventData(linktype,[index numLinks],[beg ennd]));
        end
        %% moveItem
        function moveItem(obj, type_char, index, pos, bounds)
            
            if size(index,1) > 1
                index = index(1);
            end
            
            modelneurons = {obj.neuron_objects(:).ID};
            
%             pos = CanvasConstants.ConstrainedPosition(type_char, pos);
            pos = obj.ConstrainedPosition(type_char, pos, bounds);
            
            if type_char == 'n' %neuron
                obj.neurons_positions(index, :) = pos;
                obj.neuron_objects(index).location = pos;
                if ~isempty(obj.neuron_objects(index).inlinks) || ~isempty(obj.neuron_objects(index).outlinks)
                    modellinks = {obj.link_objects(:).ID};
                    if isempty(obj.neuron_objects(index).inlinks)
                        numInlinks = 0;
                    else
                        numInlinks = size(obj.neuron_objects(index).inlinks,1);
                        inlinkcell = obj.neuron_objects(index).inlink_IDs;
                    end
                    
                    if isempty(obj.neuron_objects(index).outlinks)
                        numOutlinks = 0;
                    else
                        numOutlinks = size(obj.neuron_objects(index).outlinks,1);
                        outlinkcell = obj.neuron_objects(index).outlink_IDs;
                    end
                            
                    for i = 1:numInlinks
                        % Finding where everything is (indices are different for different lists)
                        linkID = obj.neuron_objects(index).inlink_IDs{i};
                        modellinkInd = find(contains(modellinks,linkID),1);
                        inlinkInd = find(strcmp(inlinkcell, linkID)==1);
                        proxindex = find(contains(modelneurons,obj.neuron_objects(index).inlinks(inlinkInd).origin_ID),1);
                        proxoutlinkcell = {obj.neuron_objects(proxindex).outlinks.ID};
                        proxoutlinkInd = strcmp(proxoutlinkcell, linkID)==1;
                        
                        % Assigning revised position to each object
                        obj.link_objects(modellinkInd).end = pos;
                        obj.link_ends(modellinkInd,3:4) = pos;
                        obj.neuron_objects(index).inlinks(inlinkInd).end = pos;
                        obj.neuron_objects(proxindex).outlinks(proxoutlinkInd).end = pos;
                    end
                    
                    for j = 1:numOutlinks
                        % Finding where everything is (indices are different for different lists)
                        linkID = obj.neuron_objects(index).outlink_IDs{j};
                        modellinkInd = find(contains(modellinks,linkID),1);
                        outlinkInd = find(strcmp(outlinkcell, linkID)==1);
                        distalindex = find(contains(modelneurons,obj.neuron_objects(index).outlinks(outlinkInd).destination_ID),1);
                        distalinlinkcell = {obj.neuron_objects(distalindex).inlinks.ID};
                        distalinlinkInd = strcmp(distalinlinkcell, linkID)==1;
                        
                        % Assigning revised position to each object
                        obj.link_objects(modellinkInd).start = pos;
                        obj.link_ends(modellinkInd,1:2) = pos;
                        obj.neuron_objects(index).outlinks(outlinkInd).start = pos;
                        obj.neuron_objects(distalindex).inlinks(distalinlinkInd).start = pos;
                    end
                end
            else %obstacle
                obj.obstacles_positions(index, :) = pos;
            end
            
            obj.notify('itemMoved', CanvasModelEventData(type_char,index));
            obj.notify('modelChanged');
            
        end
        %% deleteItem
        function deleteItem(obj, type_char, index)
            
            obj.notify('itemDeleted', CanvasModelEventData(type_char, index));
            
            if type_char == 'n' %neuron
                if ~isempty(obj.neuron_objects(index).outlink_IDs) || ~isempty(obj.neuron_objects(index).inlink_IDs)
                    if size(obj.neuron_objects(index).inlinks,2) == 0
                        numInlinks = 0;
                    else
                        numInlinks = size(obj.neuron_objects(index).inlink_IDs,1);
                    end
                    
                    if size(obj.neuron_objects(index).outlinks,2) == 0
                        numOutlinks = 0;
                    else
                        numOutlinks = size(obj.neuron_objects(index).outlink_IDs,1);
                    end
                    while numOutlinks > 0
                        linkIDs = {obj.link_objects.ID};
                        linkIDstring = obj.neuron_objects(index).outlinks(1).ID;
                        linkind = find(strcmp(linkIDs, linkIDstring)==1);
                        dNeurInd = find(contains({obj.neuron_objects.ID},obj.link_objects(linkind).destination_ID));
                        obj.deleteItem('l', linkind);
                        obj.updateStimModel(dNeurInd);
                        numOutlinks = numOutlinks - 1;
                    end
                    while numInlinks > 0
                        linkIDs = {obj.link_objects.ID};
                        linkIDstring = obj.neuron_objects(index).inlinks(1).ID;
                        linkind = find(strcmp(linkIDs, linkIDstring)==1);
                        obj.deleteItem('l', linkind);
                        numInlinks = numInlinks - 1;
                    end
                end
                if size(obj.neurons_positions,1) == 1
                    obj.neuron_objects = [];
                    obj.neurons_positions = [];
                else
                    obj.neuron_objects(index) = [];
                    obj.neurons_positions(index, :) = [];
                end
                obj.num_neurons = size(obj.neurons_positions, 1);
                obj.update_link_cdata();
            elseif type_char == 'l' %link
                link = obj.link_objects(index);
                neuronIDs = {obj.neuron_objects.ID};
                
                startind = find(strcmp(neuronIDs, link.origin_ID)==1);
                outind = find(strcmp({obj.neuron_objects(startind).outlinks.ID}, link.ID)==1);
                
                if size(obj.neuron_objects(startind).outlinks,1) == 1
                    obj.neuron_objects(startind).outlinks = [];
                    obj.neuron_objects(startind).outlink_IDs = [];
                else
                    obj.neuron_objects(startind).outlinks(outind) = [];
                    obj.neuron_objects(startind).outlink_IDs(outind) = [];
                end

                endind = find(strcmp(neuronIDs, link.destination_ID)==1);
                inind = find(strcmp({obj.neuron_objects(endind).inlinks.ID}, link.ID)==1);
                if size(obj.neuron_objects(endind).inlinks,1) == 1
                    obj.neuron_objects(endind).inlinks = [];
                    obj.neuron_objects(endind).inlink_IDs = [];
                else
                    obj.neuron_objects(endind).inlinks(inind) = [];
                    obj.neuron_objects(endind).inlink_IDs(inind) = [];
                end
                    
                if size(obj.link_objects,1) == 1
                    obj.link_objects = [];
                    obj.link_ends = [];
                else
                    obj.link_objects(index) = [];
                    obj.link_ends(index,:) = [];
                end
                obj.num_links = size(obj.link_ends,1);
            else %obstacle
                obj.obstacles_positions(index, :) = [];
                obj.num_obstacles = size(obj.obstacles_positions, 1);
            end
            
            
            obj.notify('modelChanged');
            
        end
        %% getData
        function S = getData(obj)

            for i=1:size(obj.link_objects,1)
                S.Link_Objects(i) = obj.link_objects(i);
            end
            
            for i=1:size(obj.neuron_objects,1)
                S.Neuron_Objects(i) = obj.neuron_objects(i);
            end
            
        end
        %% setData
        function setData(obj, S)
            
            for k=obj.num_neurons:-1:1
                obj.deleteItem('n', k);
            end
            
            for k=obj.num_obstacles:-1:1
                obj.deleteItem('o', k);
            end
            
            for k=1:size(S.NeuronsPositions, 1)
                obj.addItem('n', S.NeuronsPositions(k,:));
            end
            
            for k=1:size(S.ObstaclesPositions, 1)
                obj.addItem('o', S.ObstaclesPositions(k,1:2) + ...
                    S.ObstaclesPositions(k,3:4)/2);
            end
            
        end
        %% newCanvas
        function newCanvas(obj, numAddNeurons ,bounds)
            
            for k=obj.num_neurons:-1:1
                obj.deleteItem('n', k);
            end
            
            for k=1:numAddNeurons
                obj.addItem('n', [CanvasConstants.NEURON_size(1) CanvasConstants.NEURON_size(2)*1.5*k],bounds);
            end
            
        end
        %% create_stimulus
        function create_stimulus(obj, neurModInd)
            %Update the selected neuron's total neural response first
            newstim = struct;
            newstim.name = [obj.neuron_objects(neurModInd).ID(1:end-3),'-stim'];
            newstim.ID = ['stimID-',num2str(neurModInd)];
            newstim.starttime = randi([0 3],1);
            newstim.endtime = randi([5 8],1);
            newstim.amplitude = randi([10 15],1);
            newstim.enabled = 1;
                dt = obj.dtsim;
                simendtime = obj.tmax;
                t = 0:dt:simendtime;
%                 stim_wave = 0*linspace(0,simendtime,1/dt);
                stim_wave = zeros(size(t));
                ind = @(time) time/dt+1;
            start_ind = ind(newstim.starttime);
            end_ind = ind(newstim.endtime);
            stim_wave(start_ind:end_ind) = newstim.amplitude;
            newstim.waveform = stim_wave;
            obj.neuron_objects(neurModInd).stimulus = newstim;
            obj.updateStimModel(neurModInd);
            
            %Now, iterate through any dependents and update their total response as well
            if ~isempty(obj.neuron_objects(neurModInd).outlinks)
                for i=1:length(obj.neuron_objects(neurModInd).outlinks)
%                     oNeur = obj.neuron_objects(neurModInd);
%                     dNeur = obj.neuron_objects(contains({obj.neuron_objects.ID},obj.neuron_objects(neurModInd).outlinks(i).destination_ID));
                    dNeurInd = find(contains({obj.neuron_objects.ID},obj.neuron_objects(neurModInd).outlinks(i).destination_ID));
                    obj.updateStimModel(dNeurInd);
%                     dSyn = obj.synapse_types(contains({obj.synapse_types.name},obj.neuron_objects(neurModInd).outlinks(i).synaptictype));
%                     delE = dSyn.delE;
%                     R = 20;
%                     dt= obj.dtsim;
%                     Cm = 10;
%                     if ~isempty(dSyn.k) && ~isempty(dSyn.c)
%                         keyboard
%                         fprintf('Error: synapse has both a k and c value. Should have one or the other.')
%                     else
%                         if isempty(dSyn.k)
%                             csyn = dSyn.c;
%                             gsyn = (csyn*R-R)/(delE-csyn*R);
%                         else
%                             ksyn = dSyn.k;
%                             gsyn = (ksyn*R)/(delE-ksyn*R);
%                         end
%                     end
%                     oWave = oNeur.totmem;
%                     if isempty(dNeur.totmem)
%                         dWave = zeros(size(oWave));
%                     else
%                         dWave = dNeur.totmem;
%                     end
%                     
%                     for j = 2:length(dWave)
%                         dWavemod(j) = dWave(j-1)+(dt/Cm)*(gsyn*(delE-oWave(j-1)));
%                     end
%                     obj.neuron_objects(contains({obj.neuron_objects.ID},dNeur.ID)).totmem = dWavemod;
                end
            end
        end
        %% create_link
        function link = create_link(~,pos)
            link = struct;
            link.ID = '';
            link.origin_cdata_num = [];
            link.destination_cdata_num = [];
            link.start = pos(1:2);
            link.end = pos(3:4);
            link.origin_ID = '';
            link.origin_cdata_num = [];
            link.destination_ID = '';
            link.destination_cdata_num = [];
            link.synaptictype = {};
            link.assemblyfile = 'IntegrateFireGUI.dll';
            link.behavior = 'IntegrateFireGUI.DataObjects.Behavior.Synapse';
        end
        %% create synapseType
        function createSynapseType(obj,props)
            transnames = {'transmission','trans','hyperpolarizing'};
            modnames = {'modulation','mod','depolarizing'};
            if isempty(fields(obj.synapse_types))
                numSynapseTypes = 0;
            else
                numSynapseTypes = size(obj.synapse_types,1);
            end
            for j=1:size(props,1)
                synaptic_properties = props(j,:);
                synNum = numSynapseTypes+j;
                obj.synapse_types(synNum).ID = [lower(synaptic_properties{1,1}),'-ID'];
                if contains(lower(synaptic_properties{1,1}),modnames)
                    obj.synapse_types(synNum).arrow_dest_style = 'Circle';
                elseif contains(lower(synaptic_properties{1,1}),transnames)
                    obj.synapse_types(synNum).arrow_dest_style = 'Fork';
                else
                    obj.synapse_types(synNum).arrow_dest_style = 'None';
                end
                    obj.synapse_types(synNum).arrow_dest_size = 'Large';
                    obj.synapse_types(synNum).arrow_dest_angle = 'deg30';
                    obj.synapse_types(synNum).arrow_dest_filled = 'False';
                    obj.synapse_types(synNum).arrow_mid_style = 'None';
                    obj.synapse_types(synNum).arrow_mid_size = 'Small';
                    obj.synapse_types(synNum).arrow_mid_angle = 'deg30';
                    obj.synapse_types(synNum).arrow_mid_filled = 'False';
                    obj.synapse_types(synNum).arrow_origin_style = 'None';
                    obj.synapse_types(synNum).arrow_origin_size = 'Small';
                    obj.synapse_types(synNum).arrow_origin_angle = 'deg30';
                    obj.synapse_types(synNum).arrow_origin_filled = 'False';
                    obj.synapse_types(synNum).presyn_thresh = -60;
                    obj.synapse_types(synNum).presyn_sat = -40;
                    param_ind = logical([0,strcmp(synaptic_properties(1:end-1),'delE')]);
                    delE = synaptic_properties{param_ind};
                    obj.synapse_types(synNum).equil_pot = delE-60;
                if ~any(strcmp(synaptic_properties,'max_syn_cond'))
                    if any(strcmp(synaptic_properties,'delE'))
                        if any(strcmp(synaptic_properties,'k'))
                            param_ind = logical([0,strcmp(synaptic_properties(1:end-1),'k')]);
                            mod_param = synaptic_properties{param_ind};
                        else any(strcmp(synaptic_properties,'c'))
                            param_ind = logical([0,strcmp(synaptic_properties(1:end-1),'c')]);
                            mod_param = synaptic_properties{param_ind};
                        end
                    else
                        delE = input('No delE was provided. Please enter a delE value in mV:\n');
                    end
                    
                    obj.synapse_types(synNum).max_syn_cond = (mod_param*20)/(delE-mod_param*20);
                end
                for k = 2:2:size(props,2)
                    obj.synapse_types(synNum).name = props{j,1};
                    property_string = props{j,k};
                    property_value = props{j,k+1};
                    obj.synapse_types(synNum).(property_string) = property_value;
                end
            end
        end
        %% create_neuron
        function neuron = create_neuron(obj,pos)
            neuron = struct;
%             codestring = ['A':'Z' '0':'9';];
%             id_char_length = 7;
            numNeurons = obj.num_neurons;
            try obj.neuron_objects(1).name;            
                while sum(strcmp({obj.neuron_objects.name}, ['neur',num2str(numNeurons)]))
                                numNeurons = numNeurons + 1;
                end
            catch
                numNeurons = obj.num_neurons;
            end
            neuron.name = strcat('neur',num2str(numNeurons));
            neuron.ID = [neuron.name,'-ID'];
            neuron.location = pos;
            neuron.nsize = CanvasConstants.NEURON_size;
            neuron.outlinks = [];
            neuron.outlink_IDs = {};
            neuron.inlinks = [];
            neuron.inlink_IDs = {};
            neuron.enabled = CanvasConstants.NEURON_enabled;
            neuron.restingpotential = CanvasConstants.NEURON_restingpotential;
            neuron.timeconstant = CanvasConstants.NEURON_timeconstant;
            neuron.initialthreshold = CanvasConstants.NEURON_initialthreshold;
            neuron.relativeaccomodation = CanvasConstants.NEURON_relativeaccomodation;
            neuron.accomodationtimeconstant = CanvasConstants.NEURON_accomodationtimeconstant;
            neuron.AHPconductance = CanvasConstants.NEURON_AHPconductance;
            neuron.AHPtimeconstant = CanvasConstants.NEURON_AHPtimeconstant;
            neuron.ca_act_ID = [neuron.ID,'-act'];
            neuron.ca_act_midpoint = CanvasConstants.NEURON_ca_act_midpoint;
            neuron.ca_act_slope = CanvasConstants.NEURON_ca_act_slope;
            neuron.ca_act_timeconstant = CanvasConstants.NEURON_ca_act_timeconstant;
            neuron.ca_deact_ID = [neuron.ID,'-deact'];
            neuron.ca_deact_midpoint = CanvasConstants.NEURON_ca_deact_midpoint;
            neuron.ca_deact_slope = CanvasConstants.NEURON_ca_deact_slope;
            neuron.ca_deact_timeconstant =CanvasConstants.NEURON_ca_deact_timeconstant;
            neuron.tonicstimulus = CanvasConstants.NEURON_tonicstimulus;
            neuron.tonicnoise = CanvasConstants.NEURON_tonicnoise;
            neuron.type = 'n';
            neuron.stimulus = {};
            neuron.totmem = {};
        end
        %% create_animatlab project
        function create_animatlab_project(obj)
            file_dir = fileparts(mfilename('fullpath'));
            
    % For pre-determined Animatlab file save location (to be included while testing)
            proj_file = fullfile(file_dir,...
                CanvasConstants.DATA_RELATIVE_PATH,...
                'animatlab_files\EmptySystem\EmptySystem.aproj');
            revised_file = strcat(proj_file(1:end-6),'_fake.aproj');
            
    % For custom Animatlab file save location (to be included when done with testing)
%             proj_file = fullfile(file_dir,...
%                 CanvasConstants.DATA_RELATIVE_PATH,...
%                 'animatlab_files\');
%             [filename, pathname] = uiputfile(proj_file,'Save Subunit');
%             revised_file = [pathname,filename(1:end-7),'.aproj'];

            if size(revised_file,2) <= 7
                return
            end

            load('EmptyProjectText.mat','original_text');
            modified_text = original_text;
            
            %%%Overwrite the <NervousSystem> neural subsystem information
%             if isempty(find(contains(original_text,'</NeuralModules>'),1))
%                 nervoussystem_inject_start = find(contains(original_text,'<NeuralModules/>'));
%             else
%                 nervoussystem_inject_start = find(contains(original_text,'</NeuralModules>'));
%             end
            nervoussystem_inject_start = find(contains(original_text,'<NeuralModules>'))-1;
            nervoussystem_inject_end = find(contains(original_text,'</NervousSystem>'));
            [ns_nervoussystem_text,ns_tab_text] = CanvasText(obj).build_text;            
            modified_text = [modified_text(1:nervoussystem_inject_start,1);...
                ns_nervoussystem_text;...
                modified_text(nervoussystem_inject_end:end,1)];
            
            %%%Overwrite the <TabbedGroupsConfig> Information
            tab_inject_start = find(contains(modified_text,'&lt;Page Title="Neural Subsystem"'));
            tab_inject_end_holder = find(contains(modified_text,'&lt;/Page&gt;'));
            tab_inject_end = tab_inject_end_holder(tab_inject_end_holder>tab_inject_start);
            modified_text = [modified_text(1:tab_inject_start-1,1);...
                            ns_tab_text;...
                            modified_text(tab_inject_end+1:end,1)];
                        
            filePh = fopen(revised_file,'w');
            fprintf(filePh,'%s\n',modified_text{:,1});
            fclose(filePh);
        end
        %% update_link_cdata: Update the cdata numbers in the link objects
        function update_link_cdata(obj)
            no_links = 0;
            try no_links = isempty(fields(obj.link_objects));
            catch
                no_links  = 1;
            end
            if size(obj.neuron_objects,1) > 1 && ~no_links
                neurons = {obj.neuron_objects(:,1).name};
                for ii = 1:size(obj.link_objects,1)
                    link = obj.link_objects(ii);
                    origin_num = find(ismember(neurons, link.origin_ID(1:end-3)))-1;
                    destination_num = find(ismember(neurons, link.destination_ID(1:end-3)))-1;
                    obj.link_objects(ii).origin_cdata_num = origin_num;
                    obj.link_objects(ii).destination_cdata_num = destination_num;
                end
            end
        end
        %% ConstrainedPosition
        function pos = ConstrainedPosition(obj,type,pos,bounds)
            if strcmp(type,'n') %target
                sz = CanvasConstants.NEURON_size;
            elseif strcmp(type,'selectionbox')
                sz = 0;
            else %obstacle
                sz = CanvasConstants.OBSTACLE_SIZE;
            end
            
            bottomLeftLimits = [1 1] + sz/2;
            topRightLimits = bounds - [1 1] - sz/2;
            
            blCond = pos < bottomLeftLimits;
            pos(blCond) = bottomLeftLimits(blCond);
            
            urCond = pos > topRightLimits;
            pos(urCond) = topRightLimits(urCond);
            pos = floor(pos);
        end
        %% updateStimModel
        function updateStimModel(obj,neur_index)
                neuron = obj.neuron_objects(neur_index);
                dt = obj.dtsim;
                simendtime = obj.tmax;
                R = 20;
                Cm = .1;
                
                Upost = zeros(1,simendtime/dt+1);
                Upre = {};
                
                if ~isempty(neuron.inlinks)
                    Upre = cell(length(neuron.inlinks),3);
                    for i = 1:length(neuron.inlinks)
                        oNeur = obj.neuron_objects(contains({obj.neuron_objects.ID},neuron.inlinks(i).origin_ID));
                        oLink = neuron.inlinks(i);
                        oSyn = obj.synapse_types(contains({obj.synapse_types.name},oLink.synaptictype));
                        delE = oSyn.delE;
                        if ~isempty(oSyn.k) && ~isempty(oSyn.c)
                            keyboard
                            fprintf('Error: synapse has both a k and c value. Should have one or the other.')
                        else
                            if isempty(oSyn.k)
                                csyn = oSyn.c;
                                gMax = (csyn*R-R)/(delE-csyn*R);
                            else
                                ksyn = oSyn.k;
                                gMax = (ksyn*R)/(delE-ksyn*R);
                            end
                        end
                            Upre{i,1} = (dt/Cm)*(gMax/R);
                            Upre{i,2} = delE;
                        if ~isempty(oNeur.totmem)
                            Upre{i,3} = oNeur.totmem;
                        else
                            Upre{i,3} = zeros(1,simendtime/dt+1);
                        end
                    end
                end
                
                if ~isempty(neuron.stimulus)
                    %Hardcoded, to be changed
                    stim = neuron.stimulus;
                    dt = obj.dtsim;
                    simendtime = obj.tmax;

                    %Gather stimulus info
                    amp = stim.amplitude;
                    t = 0:dt:simendtime;

                    %Make new stimulus waveform
                    Iapp = zeros(size(t));
                    ind = @(time) time/dt+1;
                    start_ind = ind(stim.starttime);
                    end_ind = ind(stim.endtime);
                    Iapp(start_ind:end_ind) = amp;

                    %Store the stimulus waveform in the model
                    neuron.stimulus.waveform = Iapp;
                else
                    Iapp = zeros(1,simendtime/dt+1);
                end

                for i = 2:length(Upost)
                    inlink_adder = 0;
                    for j = 1:size(Upre,1)
                        inlink_adder = inlink_adder + Upre{j,1}*Upre{j,3}(i-1)*(Upre{j,2}-Upost(i-1));
                    end
                    stimterm(i-1) = (dt/Cm)*Iapp(i);
                    uposterm(i-1) = (1-dt/Cm)*Upost(i-1);
                    Upost(i) = (1-dt/Cm)*Upost(i-1)+(dt/Cm)*Iapp(i)+inlink_adder;
                end
                
                neuron.totmem = Upost;
                obj.neuron_objects(neur_index) = neuron;
        end
    end
    
end