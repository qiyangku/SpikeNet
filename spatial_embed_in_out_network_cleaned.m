function james_test()
% Use coherent units (msec+mV+nF+miuS+nA) unless otherwise stated


%%%% Seed the Matlab random number generator
seed = 1;

%%%% Open new (uniquely time-stamped) input files for the SpikeNet C++
% simulator.
% FID is the main input file, FID_syn is the input file with the 
% synaptic connectivity definitions (could be very large).
[FID, FID_syn] = new_ygin_files_and_randseed(seed);
% If no FID_syn is needed, use FID = new_ygin_files_and_randseed(seed,0)

%%%% Define some basic parameters
% Time step (ms)
dt = 0.1; % 0.1 is usually small enough
% Total number of simulation steps
step_tot = 10^4;
% Create two neuron populations with 50 neurons in the 1st population 
% and 10 neurons in the 2nd population.

%Define grids [no rows, no columns, grid step size]
Grid(2,:)=[25,25,2];
Grid(1,:)=[50,50,1];

Grid(4,:)=[25,25,2];
Grid(3,:)=[50,50,1];

Drange=[10,15,10,15];
sigma=[12,40,12,40];
W=[0.23,0.3,0.23,0.3];
pbc=1; % periodic boundary conditions

N = [40, 10, 80, 20];
% Write the above basic parameters to the input file
writeBasicPara(FID, dt, step_tot, N);


%%%% Define non-parameters for the neuorn model
% For demo purpose, the values used as following are the still the
% default ones.
% If default values are to be used, there is no need to re-define them.
Cm = 0.25; % (nF) membrane capacitance
tau_ref = 2.0; % (ms) absolute refractory time
V_rt = -60.0;   % (mV) reset potential
V_lk = -70.0;   % (mV) leaky reversal potential
V_th = -50.0;   % (mV) firing threshold
g_lk = 0.0167;   % (miuS) leaky conductance (note that Cm/gL=15 ms)
for pop_ind = 1:length(N)
    writePopPara(FID, pop_ind,'Cm',Cm,'tau_ref',tau_ref,'V_rt',V_rt,...
        'V_lk',V_lk,'V_th',V_th,'g_lk',g_lk);
end

%%%% Add spike-frequency adaptation to the 1st population



%%%% Define the initial condition
p_fire = 0.1*ones(1,length(N)); % initial firing probabilities for both populations
% set initial V distribution to be [V_rt, V_rt + (V_th-V_rt)*r_V0] 
r_V0 = 0.5*ones(1,length(N));
writeInitCond(FID, r_V0, p_fire)

%%%% Add external Poissonian spike trains into the 1st population
pop = 1;
type_ext = 1; % 1 for AMPA-like syanpses
g_ext = 2*10^-3; % synaptic coupling strength (miuS)
N_ext = 1000; % No. of independent external connections onto each neuron
rate_ext = 2*ones(1, step_tot); % Poisson rate for each time step (Hz) 
N_start = 1;
N_end = 10; % only add to neuron No.1-10.
writeExtSpikeSettings(FID, pop, type_ext, g_ext,  N_ext, rate_ext,...
    N_start, N_end );


%%%% Add external currents (Gaussian white noise) to the 2nd population
pop = 2;
I_ext_mean = 0.5*ones(1,N(2)); % defined for each neuron (nA)
I_ext_std = 0.2*ones(1,N(2)); % defined for each neuron (nA)
writeExtCurrentSettings(FID, pop, I_ext_mean, I_ext_std)

%%%% Define runaway killer
% The computational cost of the simulation is directly proportional to 
% the avearage firing rate of the network. Very often, your parameters 
% may lead to biologically unrealistically high firing rate or even 
% runaway activity (the highest rate possible ~1/tau_ref). To save the 
% computational resources for more interesting simulation cases, it is 
% advised to define the runawary killer.
% Note that the simulator will still output all the relevant data before
% the kill.
min_ms = 500; % the min simulation duration that should be guaranteed
runaway_Hz = 40; % the threshold above which the simu should be killed
Hz_ms = 200; % the window length over which the firing rate is averaged
pop = 1; % the population to be monitored by the runaway killer
writeRunawayKiller(FID, pop, min_ms, runaway_Hz, Hz_ms);


%%%% Record the basic statistics for the 1st neuron population
pop = 1;
writePopStatsRecord(FID, pop);

%%%%%%%%%%%%%%%%%%% Chemical Connections %%%%%%%%%%%%%%%%%%%%%%%
% type(1:AMAP, 2:GABAa, 3:NMDA)

% Define connectivity within each 'layer'
g_EE=10*10^-3*ones(1,length(N)/2);
g_IE=10*10^-3*ones(1,length(N)/2);
g_EI=10*10^-3*ones(1,length(N)/2);
g_II=20*10^-3*ones(1,length(N)/2);

for lay=0:1
    % Define AMAP-like excitatory synaptic connection within the ex pop
    pop_pre = 1+2*lay;
    pop_post = 1+2*lay;
    syn_type = 1; % 1 for AMPA-like synapse
    % Define COnnectivity matrix
    DM=GridDM(Grid(pop_pre,:),Grid(pop_post,:),pbc);
    A=(DM<=Drange(pop_pre)).*W(pop_pre).*exp(-DM.^2/sigma(pop_pre));
    [I_EE, J_EE, K_EE] = find(A);
    K_EE = g_EE(lay+1)*K_EE; 
    D_EE = rand(size(I_EE))*5; % uniformly random conduction delay [0, 5] ms
    writeChemicalConnection(FID_syn, syn_type,  pop_pre, pop_post, ...
        I_EE, J_EE, K_EE, D_EE);

    % Define AMAP-like excitatory synaptic connection from pop 1 to pop 2
    % in the layer
    pop_pre = 1+2*lay;
    pop_post = 2+2*lay;
    syn_type = 1; % 1 for AMPA-like synapse
    % random adjaceny matrix with a wiring probability of 0.5
    DM=GridDM(Grid(pop_pre,:),Grid(pop_post,:),pbc);
    A=(DM<=Drange(pop_pre)).*W(pop_pre).*exp(-DM.^2/sigma(pop_pre));
    [I_IE, J_IE, K_IE] = find(A);
    K_IE = g_IE(lay+1)*K_IE; 
    D_IE = rand(size(I_IE))*5; % uniformly random conduction delay [0, 5] ms
    writeChemicalConnection(FID_syn, syn_type,  pop_pre, pop_post, ...
        I_IE, J_IE, K_IE, D_IE);

    % Define GABA-like excitatory synaptic connection from pop 2 to pop 1
    % in the layer
    pop_pre = 2+2*lay;
    pop_post = 1+2*lay;
    syn_type = 2; % 2 for GABA-like synapse
    % random adjaceny matrix with a wiring probability of 0.5
    DM=GridDM(Grid(pop_pre,:),Grid(pop_post,:),pbc);
    A=(DM<=Drange(pop_pre)).*W(pop_pre).*exp(-DM.^2/sigma(pop_pre));
    [I_EI, J_EI, K_EI] = find(A);
    K_EI = g_EI(lay+1)*K_EI; % identical coupling strength
    D_EI = rand(size(I_EI))*5; % uniformly random conduction delay [0, 5] ms
    writeChemicalConnection(FID_syn, syn_type,  pop_pre, pop_post, ...
        I_EI, J_EI, K_EI, D_EI);

    % Define GABA-like excitatory synaptic connection within the inh pop
    pop_pre = 2+2*lay;
    pop_post = 2+2*lay;
    syn_type = 2; % 2 for GABA-like synapse
    % random adjaceny matrix with a wiring probability of 0.5
    DM=GridDM(Grid(pop_pre,:),Grid(pop_post,:),pbc);
    A=(DM<=Drange(pop_pre)).*W(pop_pre).*exp(-DM.^2/sigma(pop_pre));
    [I_II, J_II, K_II] = find(A);
    K_II = g_II(lay+1)*K_II; % identical coupling strength
    D_II = rand(size(I_II))*5; % uniformly random conduction delay [0, 5] ms
    writeChemicalConnection(FID_syn, syn_type,  pop_pre, pop_post, ...
        I_II, J_II, K_II, D_II);
end

% Define the connectivity between layers
%%%%%%%%%%%%%%%%%%% Chemical Connections Done %%%%%%%%%%%%%%%%%%%%%%%


%%%% Use an existing synapse connectivity definition file instead of
% generating a new one:
% writeSynFilename(FID, 'path/to/existing/XXX.ygin_syn')
% In this case, you should use 
% "FID = new_ygin_files_and_randseed(seed, 0)"
% to avoid creating an empty ygin_syn file.



%%%% Define non-default synapse parameters
writeSynPara(FID, 'tau_decay_GABA', 3); 
% "help writeSynPara" to see all the parameter names and default values

%%%% Add short-term depression to the synapses with the 1st population
% pop_pre = 1;
% % pop_post = 1;
% step_start = round(step_tot/3); % Turn on STD at this time step
% writeSTD(FID, pop_pre, pop_post, step_start);


%%%% Add inhibitory STDP to the synapses from pop 2 to pop 1
% pop_pre = 2;
% pop_post = 1;
% % Turn on inhibitory STDP at a certain time step
% step_start = round(step_tot/3*2);
% writeInhSTDP(FID, pop_pre, pop_post, step_start);

%%%% Record the basic statistics for the excitatory synapses within 
% the 1st neuron population
pop_pre = 1;
pop_post = 1;
syn_type = 1; % 1 for AMPA-like synapse
writeSynStatsRecord(FID, pop_pre, pop_post, syn_type);

%%%% Sample detailed time serious data from the 1st population
pop = 1;
sample_neuron = 1:10:N(1); % sample every 10th neuron
sample_steps = 1:2:step_tot; % sample every 2nd time step
sample_data_type = logical([1,1,1,1,0,0,1,0]); 
% The logical vector above corresponds to 
% [V,I_leak,I_AMPA,I_GABA,I_NMDA,I_GJ,I_ext, I_K]
writeNeuronSampling(FID, pop, sample_data_type, ...
    sample_neuron, sample_steps)

%%%% Record explanatory variables that are nacessary for post-processing
discard_transient = 0; % transient period data to be discarded (ms)
writeExplVar(FID, 'discard_transient', discard_transient, ...
    'g_EE1', g_EE(1), ...
    'g_EI1', g_EI(1), ...
    'g_IE1', g_IE(1), ...
    'g_II1', g_II(1), ...
    'g_EE2', g_EE(2), ...
    'g_EI2', g_EI(2), ...
    'g_IE2', g_IE(2), ...
    'g_II2', g_II(2), ...
    'g_ext', g_ext, ...
    'N_ext', N_ext, ...
    'rate_ext', rate_ext);


%%%% Additional comments to be passed to the post-processing stage
comment1 = 'This is a demo.';
comment2 = ['If you have any question regarding SpikeNet,'...
    'please contact Yifan Gu (yigu8115@gmail.com).'];
writeExplVar(FID, 'comment1', comment1, 'comment2', comment2);

%%%% append this matlab file to the input file for future reference
appendThisMatlabFile(FID)

end



function appendThisMatlabFile(FID)
breaker = ['>',repmat('#',1,80)];
fprintf(FID, '%s\n', breaker);
fprintf(FID, '%s\n', '> MATLAB script generating this file: ');
fprintf(FID, '%s\n', breaker);
Fself = fopen([mfilename('fullpath'),'.m'],'r');
while ~feof(Fself)
    tline = fgetl(Fself);
    fprintf(FID, '%s\n', tline);
end
fprintf(FID, '%s\n', breaker);
fprintf(FID, '%s\n', breaker);
fprintf(FID, '%s\n', breaker);
end

function DM=GridDM(InGrid, OutGrid, pbc)
% Calculates the distance between all pairs of points from one grid to
% another.
% Grid is a vector of [ no rows, no columns, grid step size]
NoIn=InGrid(1)*InGrid(2);
NoOut=OutGrid(2)*OutGrid(2);

DM=zeros(NoIn,NoOut);

for i=0:NoIn-1
    % Convert 1D index to 2D spat coords
    yi=floor(i/InGrid(1));
    xi=i-yi*InGrid(1);
    
    % Scale for grid step size
    yi=yi*InGrid(3);
    xi=xi*InGrid(3);
    
    for j=0:NoOut-1
        % Convert 1D index to 2D spat coords
        yj=floor(j/OutGrid(1));
        xj=j-yj*OutGrid(1);

        % Scale for grid step size
        yj=yj*OutGrid(3);
        xj=xj*OutGrid(3);
        
        delx=abs(xi-xj);
        dely=abs(yi-yj);
        
        if pbc
            %If grid has periodic boundaries then check to see which
            % distance is shortest (i.e via the periodic boundary or not
            delx=min([delx,abs(InGrid(2)*InGrid(3)-delx)]);
            dely=min([dely,abs(InGrid(1)*InGrid(3)-dely)]);
        end
        
        DM(i+1,j+1)=sqrt(delx^2+dely^2);
        
    end 
end
end
