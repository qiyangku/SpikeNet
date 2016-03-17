function [ EPSP ] = g_2_EPSP( g ,varargin)
%UNTITLED4 Summary of this function goes here
%   This function finds the EPSP amplitude given the coupling strength
%   (conductance)


% default parameters
dt = 0.1; %ms

Cm = 0.25; % nF
V_lk = -70.0;   % Leak reversal, -70.0
g_lk = 0.0167; % muS

V_rev = 0; % for AMPA
tau_r = 1.0; %ms
tau_d = 5; %ms

V_th = -50; % threshold;

% read parameters
for i = 1:(length(varargin)/2)
    eval([varargin{i*2-1}, '=', num2str(varargin{i*2}), ';' ]);
end


EPSP = zeros(size(g));
for i = 1:length(g)
    
    V_old = V_lk; % resting potential
    peaked = false;
    tau_r_step = round(tau_r/dt);
    tau_r_step_left = tau_r_step;
    s = 0;
    while ~peaked && V_old < V_th
        if tau_r_step_left > 0
            s = s + 1/tau_r_step*(1-s);
            tau_r_step_left = tau_r_step_left - 1;
        end
        I = -g(i)*s*(V_old-V_rev);
        I_lk = -g_lk*(V_old-V_lk);
        
        V_dot = (I + I_lk)/Cm;
        V_new = V_old+V_dot*dt;
        
        peaked = V_new < V_old;
        V_old = V_new;
        s = s*exp(-dt/tau_d);
    end
    
    EPSP(i) = V_old - V_lk;
    
end


end

