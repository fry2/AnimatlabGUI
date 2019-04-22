classdef CanvasText
    %CANVASNODETEXT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        request
        model
    end
    
    methods
        function obj = CanvasText(model)
            obj.model = model;
        end
        
        function [ns_text,tab_text] = build_text(obj)
            codestring = ['A':'Z' '0':'9';];
            id_char_length = 7;
            ns_name = codestring(randperm(length(codestring),id_char_length));
            nm_name = [ns_name,'-module'];
            
            neural_module_text = obj.build_neural_modules(nm_name);
            
            node_preamble = obj.build_node_preamble(ns_name);
            
            node_text = {};
            if (obj.model.num_neurons) == 0
                node_preamble{end+1,1} = '<Nodes/>';
            else
                node_preamble{end+1,1} = '<Nodes>';
                for i = 1:obj.model.num_neurons
                    node_holder = obj.build_node(obj.model.neuron_objects(i));
                    node_text = [node_text;node_holder];
                end
                node_text{end+1,1} = '</Nodes>';
            end
            
            link_text = {};
            if obj.model.num_links == 0
                link_text = {'<Links/>'};
            else
                link_text = {'<Links>'};
                for i = 1:obj.model.num_links
                    synapse_ind = strcmp({obj.model.synapse_types.name},obj.model.link_objects(i).synaptictype);
                    link_holder = obj.build_link(obj.model.link_objects(i),obj.model.synapse_types(synapse_ind));
                    link_text = [link_text;link_holder];
                end
                link_text{end+1,1} = '</Links>';
            end
            
            cdata_text = obj.build_cdata(ns_name);
            
            ns_text = [neural_module_text;node_preamble;node_text;link_text;cdata_text;'</Node>'];
            tab_text = obj.build_tab_text(ns_name);
            
        end
        
        function out_text = build_neural_modules(obj,name)
            
            preamble = {'<NeuralModules>';...
							'<Node>';...
								['<ID>',name,'</ID>'];...
								'<AssemblyFile>IntegrateFireGUI.dll</AssemblyFile>';...
								'<ClassName>IntegrateFireGUI.DataObjects.Behavior.NeuralModule</ClassName>';...
								'<TimeStep Value="0.2" Scale="milli" Actual="0.0002"/>';...
								['<ID>',name,'</ID>'];...
								'<AHPEquilibriumPotential Value="-70" Scale="milli" Actual="-0.07"/>';...
								'<SpikePeak Value="0" Scale="milli" Actual="0"/>';...
								'<SpikeStrength>1</SpikeStrength>';...
								'<CaEquilibriumPotential Value="200" Scale="milli" Actual="0.2"/>';...
								'<RefractoryPeriod Value="2" Scale="milli" Actual="0.002"/>';...
								'<UseCriticalPeriod>False</UseCriticalPeriod>';...
								'<StartCriticalPeriod Value="0" Scale="None" Actual="0"/>';...
								'<EndCriticalPeriod Value="5" Scale="None" Actual="5"/>';...
								'<TTX>False</TTX>';...
								'<Cd>False</Cd>';...
								'<HH>False</HH>';...
								'<FreezeHebb>False</FreezeHebb>';...
								'<RetainHebbMemory>False</RetainHebbMemory>'};
            synapse_text = {};
            synNum = length(obj.model.synapse_types);
            if synNum == 0
                synapse_text = {'<SynapseTypes/>'};
            else
                synapse_text = {'<SynapseTypes>'};
                for i = 1:synNum
                    synapse = obj.model.synapse_types(i);
                    synapse_holder = obj.build_synapse_type(synapse);
                    synapse_text = [synapse_text;synapse_holder];
                end
                synapse_text{end+1,1} = '</SynapseTypes>';
            end

           out_text = [preamble;synapse_text;'</Node>';'</NeuralModules>'];
        end
        
        function out_text = build_node_preamble(~,name)
            out_text = {'<Node>';...
                            '<AssemblyFile>AnimatGUI.dll</AssemblyFile>';...
                            '<ClassName>AnimatGUI.DataObjects.Behavior.Nodes.Subsystem</ClassName>';...
                            ['<ID>',name,'-ID','</ID>'];...
                            '<Alignment>CenterMiddle</Alignment>';...
                            '<AutoSize>None</AutoSize>';...
                            '<BackMode>Transparent</BackMode>';...
                            '<DashStyle>Solid</DashStyle>';...
                            '<DrawColor>-16777216</DrawColor>';...
                            '<DrawWidth>1</DrawWidth>';...
                            '<FillColor>-8586240</FillColor>';...
                            '<Font Family="Arial" Size="12" Bold="True" Underline="False" Strikeout="False" Italic="False"/>';...
                            '<Gradient>False</Gradient>';...
                            '<GradientColor>0</GradientColor>';...
                            '<GradientMode>BackwardDiagonal</GradientMode>';...
                            '<DiagramImageName/>';...
                            '<ImageName/>';...
                            '<ImageLocation x="0" y="0"/>';...
                            '<ImagePosition>RelativeToText</ImagePosition>';...
                            '<InLinkable>True</InLinkable>';...
                            '<LabelEdit>True</LabelEdit>';...
                            '<Location x="0" y="0"/>';...
                            '<OutLinkable>True</OutLinkable>';...
                            '<ShadowStyle>None</ShadowStyle>';...
                            '<ShadowColor>-16777216</ShadowColor>';...
                            '<ShadowSize Width="0" Height="0"/>';...
                            '<Shape>Rectangle</Shape>';...
                            '<ShapeOrientation>Angle0</ShapeOrientation>';...
                            '<Size Width="40" Height="40"/>';...
                            ['<Text>',name,'</Text>'];...
                            '<TextColor>-16777216</TextColor>';...
                            '<TextMargin Width="0" Height="0"/>';...
                            '<ToolTip/>';...
                            '<Transparent>False</Transparent>';...
                            '<Url/>';...
                            '<XMoveable>True</XMoveable>';...
                            '<XSizeable>True</XSizeable>';...
                            '<YMoveable>True</YMoveable>';...
                            '<YSizeable>True</YSizeable>';...
                            '<ZOrder>0</ZOrder>';...
                            '<ZOrder>0</ZOrder>';...
                            '<TemplateNode>False</TemplateNode>';...
                            '<TemplateNodeCount>1</TemplateNodeCount>';...
                            '<TemplateChangeScript/>';...
                            '<InLinks/>';...
                            '<OutLinks/>'};
        end
        
        function out_text = build_link(~,link,synapse)
            tlink = link;
            tsyn = synapse;
            out_text = [{'<Link>';...
                ['<AssemblyFile>',tlink.assemblyfile,'</AssemblyFile>'];...
                ['<ClassName>',tlink.behavior,'</ClassName>'];...
                ['<ID>',tlink.ID,'</ID>'];...
                '<AdjustDst>False</AdjustDst>';...
                '<AdjustOrg>False</AdjustOrg>';...
                '<ArrowDestination>';...
                ['<Style>',tsyn.arrow_dest_style,'</Style>'];...
                ['<Size>',tsyn.arrow_dest_size,'</Size>'];...
                ['<Angle>',tsyn.arrow_dest_angle,'</Angle>'];...
                ['<Filled>',tsyn.arrow_dest_filled,'</Filled>'];...
                '</ArrowDestination>';...
                '<ArrowMiddle>';...
                ['<Style>',tsyn.arrow_mid_style,'</Style>'];...
                ['<Size>',tsyn.arrow_mid_size,'</Size>'];...
                ['<Angle>',tsyn.arrow_mid_angle,'</Angle>'];...
                ['<Filled>',tsyn.arrow_mid_filled,'</Filled>'];...
                '</ArrowMiddle>';...
                '<ArrowOrigin>';...
                ['<Style>',tsyn.arrow_origin_style,'</Style>'];...
                ['<Size>',tsyn.arrow_origin_size,'</Size>'];...
                ['<Angle>',tsyn.arrow_origin_angle,'</Angle>'];...
                ['<Filled>',tsyn.arrow_origin_filled,'</Filled>'];...
                '</ArrowOrigin>'
                '<BackMode>Transparent</BackMode>';...
                '<DashStyle>Solid</DashStyle>';...
                '<DrawColor>-16777216</DrawColor>';...
                '<DrawWidth>1</DrawWidth>';...
                ['<DestinationID>',tlink.destination_ID,'</DestinationID>'];...
                '<Font Family="Arial" Size="8" Bold="False" Underline="False" Strikeout="False" Italic="False"/>';...
                '<Hidden>False</Hidden>';...
                '<Jump>Arc</Jump>';...
                '<LineStyle>Polyline</LineStyle>';...
                '<OrthogonalDynamic>True</OrthogonalDynamic>';...
                ['<OriginID>',tlink.origin_ID,'</OriginID>'];...
                '<OrientedText>True</OrientedText>';...
                '<Selectable>True</Selectable>';...
                '<Stretchable>True</Stretchable>';...
                '<Text/>';...
                '<ToolTip/>';...
                '<Url/>';...
                '<ZOrder>0</ZOrder>';...
                ['<SynapticTypeID>',synapse.ID,'</SynapticTypeID>'];...
                 '<UserText/>';...
                 ['<SynapticConductance Value="',num2str(synapse.max_syn_cond),'" Scale="micro" Actual="',num2str(synapse.max_syn_cond/1e6),'"/>'];...
                 '<ConductionDelay Value="0" Scale="milli" Actual="0"/>';...
                '</Link>'}];
        end
        
        function out_text = build_node(~,node)
            tnode = node;
            if tnode.type == 'n'
                if isempty(tnode.inlinks)
                    inlinks_snippet = '<InLinks/>';
                else
                    inlinks_inner = {};
                    for i = 1:size(tnode.inlinks,1)
                        inlinks_holder = strcat('<ID>',tnode.inlinks(i).ID,'</ID>');
                        inlinks_inner = [inlinks_inner;inlinks_holder];
                    end
                    inlinks_snippet = ['<InLinks>';...
                        inlinks_inner;...
                        '</InLinks>'];
                end
                if isempty(tnode.outlinks)
                    outlinks_snippet = '<OutLinks/>';
                else
                    outlinks_inner = {};
                    for i = 1:size(tnode.outlinks,1)
                        outlinks_holder = {strcat('<ID>',tnode.outlinks(i).ID,'</ID>')};
                        outlinks_inner = [outlinks_inner;outlinks_holder];
                    end
                    outlinks_snippet = ['<OutLinks>';...
                        outlinks_inner;...
                        '</OutLinks>'];
                end
                out_text = [{'<Node>';...
                    '<AssemblyFile>IntegrateFireGUI.dll</AssemblyFile>';...
                    '<ClassName>IntegrateFireGUI.DataObjects.Behavior.Neurons.NonSpiking</ClassName>';...
                    ['<ID>',tnode.ID,'</ID>'];...
                    '<Alignment>CenterMiddle</Alignment>';...
                    '<AutoSize>None</AutoSize>';...
                    '<BackMode>Transparent</BackMode>';...
                    '<DashStyle>Solid</DashStyle>';...
                    '<DrawColor>-16777216</DrawColor>';...
                    '<DrawWidth>1</DrawWidth>';...
                    '<FillColor>-7876870</FillColor>';...
                    '<Font Family="Arial" Size="8" Bold="True" Underline="False" Strikeout="False" Italic="False"/>';...
                    '<Gradient>False</Gradient>';...
                    '<GradientColor>0</GradientColor>';...
                    '<GradientMode>BackwardDiagonal</GradientMode>';...
                    '<DiagramImageName/>';...
                    '<ImageName/>';...
                    '<ImageLocation x="0" y="0"/>';...
                    '<ImagePosition>RelativeToText</ImagePosition>';...
                    '<InLinkable>True</InLinkable>';...
                    '<LabelEdit>True</LabelEdit>';...
                    ['<Location x="',num2str(tnode.location(1)),'" y="',num2str(tnode.location(2)),'"/>'];...
                    '<OutLinkable>True</OutLinkable>';...
                    '<ShadowStyle>None</ShadowStyle>';...
                    '<ShadowColor>-16777216</ShadowColor>';...
                    '<ShadowSize Width="0" Height="0"/>';...
                    '<Shape>Termination</Shape>';...
                    '<ShapeOrientation>Angle0</ShapeOrientation>';...
                    ['<Size Width="',num2str(tnode.nsize(1)),'" Height="',num2str(tnode.nsize(1)),'"/>'];...
                    ['<Text>',tnode.name,'</Text>'];...
                    '<TextColor>-16777216</TextColor>';...
                    '<TextMargin Width="0" Height="0"/>';...
                    '<ToolTip/>';...
                    '<Transparent>False</Transparent>';...
                    '<Url/>';...
                    '<XMoveable>True</XMoveable>';...
                    '<XSizeable>True</XSizeable>';...
                    '<YMoveable>True</YMoveable>';...
                    '<YSizeable>True</YSizeable>';...
                    '<ZOrder>0</ZOrder>';...
                    '<ZOrder>0</ZOrder>';...
                    '<TemplateNode>False</TemplateNode>';...
                    '<TemplateNodeCount>1</TemplateNodeCount>';...
                    '<TemplateChangeScript/>'};...
                    inlinks_snippet;...
                    outlinks_snippet;...
                    {['<Enabled>',tnode.enabled,'</Enabled>'];...
                    ['<RestingPotential Value="',num2str(tnode.restingpotential),'" Scale="milli" Actual="',num2str(tnode.restingpotential/1000),'"/>'];...
                    '<RelativeSize Value="1" Scale="None" Actual="1"/>';...
                    ['<TimeConstant Value="',num2str(tnode.timeconstant),'" Scale="milli" Actual="',num2str(tnode.timeconstant/1000),'"/>'];...
                    ['<InitialThreshold Value="',num2str(tnode.initialthreshold),'" Scale="milli" Actual="',num2str(tnode.initialthreshold/1000),'"/>'];...
                    ['<RelativeAccomodation Value="0.3" Scale="None" Actual="',num2str(tnode.relativeaccomodation),'"/>'];...
                    ['<AccomodationTimeConstant Value="',num2str(tnode.accomodationtimeconstant),'" Scale="milli" Actual="',num2str(tnode.accomodationtimeconstant/1000),'"/>'];...
                    ['<AHP_Conductance Value="',num2str(tnode.AHPconductance),'" Scale="micro" Actual="',num2str(tnode.AHPconductance/1000000),'"/>'];...
                    ['<AHP_TimeConstant Value="',num2str(tnode.AHPtimeconstant),'" Scale="milli" Actual="',num2str(tnode.AHPtimeconstant/1000),'"/>'];...
                    '<MaxCaConductance Value="0" Scale="micro" Actual="0"/>';...
                    '<CaActivation>';...
                    ['<ID>',tnode.ca_act_ID,'</ID>'];...
                    ['<MidPoint Value="',num2str(tnode.ca_act_midpoint),'" Scale="milli" Actual="',num2str(tnode.ca_act_midpoint/1000),'"/>'];...
                    ['<Slope Value="',num2str(tnode.ca_act_slope),'" Scale="None" Actual="',num2str(tnode.ca_act_slope),'"/>'];...
                    ['<TimeConstant Value="',num2str(tnode.ca_act_timeconstant),'" Scale="milli" Actual="',num2str(tnode.ca_act_timeconstant/1000),'"/>'];...
                    '<ActivationType>True</ActivationType>';...
                    '</CaActivation>';...
                    '<CaDeactivation>';...
                    ['<ID>',tnode.ca_deact_ID,'</ID>'];...
                    ['<MidPoint Value="',num2str(tnode.ca_deact_midpoint),'" Scale="milli" Actual="',num2str(tnode.ca_deact_midpoint/1000),'"/>'];...
                    ['<Slope Value="',num2str(tnode.ca_deact_slope),'" Scale="None" Actual="',num2str(tnode.ca_deact_slope),'"/>'];...
                    ['<TimeConstant Value="',num2str(tnode.ca_deact_timeconstant),'" Scale="milli" Actual="',num2str(tnode.ca_deact_timeconstant/1000),'"/>'];...
                    '<ActivationType>False</ActivationType>';...
                    '</CaDeactivation>';...
                    '<InitAtBottom>True</InitAtBottom>';...
                    ['<TonicStimulus Value="',num2str(tnode.tonicstimulus*1000000000),'" Scale="nano" Actual="',num2str(tnode.tonicstimulus),'"/>'];...
                    ['<TonicNoise Value="',num2str(tnode.tonicnoise*1000),'" Scale="milli" Actual="',num2str(tnode.tonicnoise),'"/>'];...
                    '</Node>'}];
            end
        end
        
        function out_text = build_cdata(obj,ns_name)
            numNeurons = obj.model.num_neurons;
            numLinks = obj.model.num_links;
            numAdapters = 0;
            numMuscles = 0;
            out_text = {};
            link_log = cell(numNeurons+numAdapters+numMuscles,2);
            cdata_ID = [ns_name,'-cdata'];
            
            cdata_preamble = {'<DiagramXml><![CDATA[<Root>';...
                '<Diagram>';...
                ['<ID>',cdata_ID,'</ID>'];...
                '<AssemblyFile>LicensedAnimatGUI.dll</AssemblyFile>';...
                '<ClassName>LicensedAnimatGUI.Forms.Behavior.AddFlowDiagram</ClassName>';...
                ['<PageName>',ns_name,'</PageName>'];...
                '<ZoomX>1</ZoomX>';...
                '<ZoomY>1</ZoomY>';...
                '<BackColor Red="1" Green="1" Blue="1" Alpha="1"/>';...
                '<ShowGrid>True</ShowGrid>';...
                '<GridColor Red="0.427451" Green="0.427451" Blue="0.427451" Alpha="1"/>';...
                '<GridSize Width="16" Height="16"/>';...
                '<GridStyle>DottedLines</GridStyle>';...
                '<JumpSize>Medium</JumpSize>';...
                '<SnapToGrid>False</SnapToGrid>';...
                ['<AddFlow Nodes="',num2str(numNeurons+numAdapters+numMuscles),'" Links="',num2str(numLinks),'">'];...
                '  <Version>1.5.0.1</Version>'};
            
            out_text = [out_text;cdata_preamble];
            
            for i = 1:numMuscles
                cdata_holder = obj.muscles{i,1}.build_cdata_text;
                out_text = [out_text;cdata_holder];
                link_log{i,1} = num2str(i+numNeurons+numAdapters-1);
                link_log{i,2} = obj.model.muscles{i,1}.ID;
            end
            
            for i = 1:numNeurons
                cdata_holder = obj.build_node_cdata(obj.model.neuron_objects(i) );
                out_text = [out_text;cdata_holder];
                link_log{i+numMuscles,1} = num2str(i-1);
                link_log{i+numMuscles,2} = obj.model.neuron_objects(i).ID;
            end
            
            for i = 1:numAdapters
                cdata_holder = obj.adapters{i,1}.build_cdata_text;
                out_text = [out_text;cdata_holder];
                link_log{i+numNeurons+numMuscles,1} = num2str(i+numNeurons-1);
                link_log{i+numNeurons+numMuscles,2} = obj.adapters{i,1}.ID;
            end
            
            for i = numLinks:-1:1
%                 origin_ID = obj.links{i,1}.origin_ID;
%                 destination_ID = obj.links{i,1}.destination_ID;
%                 [origin_num,~] = find(contains(link_log,origin_ID));
%                 [destination_num,~] = find(contains(link_log,destination_ID));
%                 cdata_holder = obj.links{i,1}.build_cdata_text(origin_num-1,destination_num-1);
                synapse_ind = strcmp({obj.model.synapse_types.name},obj.model.link_objects(i).synaptictype);
                cdata_holder = obj.build_link_cdata(obj.model.link_objects(i),obj.model.synapse_types(synapse_ind));
                out_text = [out_text;cdata_holder];
            end
            
            cdata_postscript = {'</AddFlow>';...
                                '</Diagram>';...
                                '</Root>';...
                                ']]></DiagramXml>'};
            
            out_text = [out_text;cdata_postscript];
        end
        
        function out_text = build_link_cdata(~,link,synapse)
            tlink = link;
            tsyn = synapse;
            out_text = {['  <Link Org="',num2str(tlink.origin_cdata_num),'" Dst="',num2str(tlink.destination_cdata_num),'">'];...
                '    <OrientedText>True</OrientedText>';...
                '    <Line Style="Polyline" OrthogonalDynamic="True" RoundedCorner="True" />';...
                ['    <ArrowDst Head="',tsyn.arrow_dest_style,'" Size="',tsyn.arrow_dest_size,'" Angle="',tsyn.arrow_dest_angle,'" Filled="',tsyn.arrow_dest_filled,'" />'];...
                ['    <ArrowOrg Head="',tsyn.arrow_origin_style,'" Size="',tsyn.arrow_origin_size,'" Angle="',tsyn.arrow_origin_angle,'" Filled="',tsyn.arrow_origin_filled,'" />'];...
                ['    <ArrowMid Head="',tsyn.arrow_mid_style,'" Size="',tsyn.arrow_mid_size,'" Angle="',tsyn.arrow_mid_angle,'" Filled="',tsyn.arrow_mid_filled,'" />'];...
                '    <Jump>Arc</Jump>';...
                '    <DrawColor>-16777216</DrawColor>';...
                '    <TextColor>-16777216</TextColor>';...
                '    <Font Name="Arial" Size="8" Bold="False" Italic="False" Strikeout="False" Underline="False" />';...
                ['    <Tag>',tlink.ID,'</Tag>'];...
                '  </Link>'};
        end
        
        function out_text = build_node_cdata(~,node)
            if node.type == 'n'
                mod_loc = node.location-CanvasConstants.NEURON_size/2-1;
                out_text = 	{['  <Node Left="',num2str(mod_loc(1)),'" Top="',num2str(mod_loc(2)),'" Width="',num2str(node.nsize(1)/2),'" Height="',num2str(node.nsize(2)/2),'">'];...
                    '    <Shadow Style="None" Color="-16777216" Width="0" Height="0" />';...
                    '    <Shape Style="Termination" Orientation="so_0" />';...
                    '    <FillColor>-7876870</FillColor>';...
                    '    <DrawColor>-16777216</DrawColor>';...
                    '    <TextColor>-16777216</TextColor>';...
                    '    <GradientColor>0</GradientColor>';...
                    ['    <Text>',node.name,'</Text>'];...
                    '    <Font Name="Arial" Size="8" Bold="True" Italic="False" Strikeout="False" Underline="False" />';...
                    ['    <Tag>',node.ID,'</Tag>'];...
                    '  </Node>'};
            else
                disp('other cdata nodes not loaded')
                disp(' ')
            end
        end
        
        function out_text = build_tab_text(~,ns_name)
            cdata_ID = [ns_name,'-cdata'];
            out_text = {['      &lt;Page Title="',ns_name,'" ImageList="True" ImageIndex="1" Selected="True" Control="null" UniqueName=""&gt;'];...
            '        &lt;CustomPageData&gt;&lt;![CDATA[&lt;TabPage&gt;';...
            '&lt;Form&gt;';...
            ['&lt;ID&gt;',cdata_ID,'&lt;/ID&gt;'];...
            ['&lt;Title&gt;',ns_name,'&lt;/Title&gt;'];...
            ['&lt;TabPageName&gt;',ns_name,'&lt;/TabPageName&gt;'];...
            '&lt;AssemblyFile&gt;LicensedAnimatGUI.dll&lt;/AssemblyFile&gt;';...
            '&lt;ClassName&gt;LicensedAnimatGUI.Forms.Behavior.AddFlowDiagram&lt;/ClassName&gt;';...
            '&lt;OrganismID&gt;e40d2c4f-9c31-49f8-8a5c-5688fb768225&lt;/OrganismID&gt;';...
            ['&lt;SubSystemID&gt;',ns_name,'-ID','&lt;/SubSystemID&gt;'];...
            '&lt;/Form&gt;';...
            '&lt;/TabPage&gt;';...
            ']]&gt;&lt;/CustomPageData&gt;';...
            '      &lt;/Page&gt;'};
        end
        
        function out_text = build_synapse_type(~,synapse)
            out_text = {'<Link>'
                        '<AssemblyFile>IntegrateFireGUI.dll</AssemblyFile>';...
                        '<ClassName>IntegrateFireGUI.DataObjects.Behavior.SynapseTypes.NonSpikingChemical</ClassName>';...
                        ['<ID>',synapse.ID,'</ID>'];...
                        '<AdjustDst>False</AdjustDst>';...
                        '<AdjustOrg>False</AdjustOrg>';...
                        '<ArrowDestination>';...
                            ['<Style>',synapse.arrow_dest_style,'</Style>'];...
                            ['<Size>',synapse.arrow_dest_size,'</Size>'];...
                            ['<Angle>',synapse.arrow_dest_angle,'</Angle>'];...
                            ['<Filled>',synapse.arrow_dest_filled,'</Filled>'];...
                        '</ArrowDestination>';...
                        '<ArrowMiddle>';...
                            ['<Style>',synapse.arrow_mid_style,'</Style>'];...
                            ['<Size>',synapse.arrow_mid_size,'</Size>'];...
                            ['<Angle>',synapse.arrow_mid_angle,'</Angle>'];...
                            ['<Filled>',synapse.arrow_mid_filled,'</Filled>'];...
                        '</ArrowMiddle>';...
                        '<ArrowOrigin>';...
                            ['<Style>',synapse.arrow_origin_style,'</Style>'];...
                            ['<Size>',synapse.arrow_origin_size,'</Size>'];...
                            ['<Angle>',synapse.arrow_origin_angle,'</Angle>'];...
                            ['<Filled>',synapse.arrow_origin_filled,'</Filled>'];...
                        '</ArrowOrigin>';...
                        '<BackMode>Transparent</BackMode>';...
                        '<DashStyle>Solid</DashStyle>';...
                        '<DrawColor>-16777216</DrawColor>';...
                        '<DrawWidth>1</DrawWidth>';...
                        '<DestinationID/>';...
                        '<Font Family="Arial" Size="12" Bold="False" Underline="False" Strikeout="False" Italic="False"/>';...
                        '<Hidden>False</Hidden>';...
                        '<Jump>Arc</Jump>';...
                        '<LineStyle>Polyline</LineStyle>';...
                        '<OrthogonalDynamic>True</OrthogonalDynamic>';...
                        '<OriginID/>';...
                        '<OrientedText>True</OrientedText>';...
                        '<Selectable>True</Selectable>';...
                        '<Stretchable>True</Stretchable>';...
                        '<Text/>';...
                        '<ToolTip/>';...
                        '<Url/>';...
                        '<ZOrder>0</ZOrder>';...
                        ['<Name>',synapse.name,'</Name>'];...
                        ['<EquilibriumPotential Value="',num2str(synapse.equil_pot),'" Scale="milli" Actual="',num2str(synapse.equil_pot/1000),'"/>'];...
                        ['<MaxSynapticConductance Value="',num2str(synapse.max_syn_cond),'" Scale="micro" Actual="',num2str(synapse.max_syn_cond/1e6),'"/>'];...
                        ['<PreSynapticThreshold Value="',num2str(synapse.presyn_thresh),'" Scale="milli" Actual="',num2str(synapse.presyn_thresh/1000),'"/>'];...
                        ['<PreSynapticSaturationLevel Value="',num2str(synapse.presyn_sat),'" Scale="milli" Actual="',num2str(synapse.presyn_sat/1000),'"/>'];...
                        '</Link>'};
        end
    end
    
end
