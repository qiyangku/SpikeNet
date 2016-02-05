#ifndef CHEMICALSYNAPSES_H
#define CHEMICALSYNAPSES_H
#include <vector>
#include <functional> // pass function as parameter
#include <string> 
#include <iostream> 

#include "Neurons.h"
class Neurons; // #include ".h" for accessing its members, forward declaration for "syntax error: identifier xx" (why both are needed??)

using namespace std;

// Excitatory and inhibitory chemical synapses with transmission delay
class ChemicalSynapses{
public:
	vector< vector<double> > tmp_data; // temporary data container for debug

	ChemicalSynapses(); // default constructor
	ChemicalSynapses(double dt, int step_tot); // parameterised constructor
	friend class NeuronNetwork; // Let NeuronNetwork access its private members
	friend class SimulatorInterface;

	void init(int synapses_type, int pop_ind_pre, int pop_ind_post, int N_pre, int N_post, vector<int> &C_i, vector<int> &C_j, vector<double> &K_ij, vector<double> &D_ij); // initialise chemical synapses by reading already prepared connections

	void init(int synapses_type, int pop_ind_post, int N_pre, double K_ext, int Num_ext, vector<double> &rate_ext_t, int ia, int ib); // initialise chemical synapses for simulating external Poissonian neuron population
	// [ia,ib] specifies the neuron index range in post population to receive the external stimulation 


	void init();
	void set_para(string para_str, char delim);
	string dump_para(char delim); // dump all the parameter values used
	void output_results(ofstream& output_file, char delim, char indicator);

	void recv_pop_data(vector<Neurons> &NeuronPopArray, int step_current);
	void update(int step_current); //  Calculate the current post-synaptic conductance changes caused by pre-synaptic spikes.
	void send_pop_data(vector<Neurons> &NeuronPopArray);

	void add_sampling(vector<int> sample_neurons, vector<bool> sample_time_points); 
	void sample_data(int step_current);
	

	void write2file(ofstream& output_file, char delim, vector< vector<int> >& v);
	void write2file(ofstream& output_file, char delim, vector< vector<double> >& v);
	void write2file(ofstream& output_file, char delim, vector<int>& v);
	void write2file(ofstream& output_file, char delim, vector<double>& v);
	
	void start_stats_record();
	void record_stats(); //
	
	
protected:
	// constants
	double
		dt; // (msec) simulation time step
	int
		step_tot,
		pop_ind_pre,
		pop_ind_post,
		N_pre, // pre-synaptic population size
		N_post;
	int
		synapses_type; // 0 = AMPA, 1 = GABA, 2 = NMDA
	double
		V_ex, // Excitatory reversal
		V_in; // Inhibitory reversal
	int
		max_delay_steps,
		history_steps; // for pre-synaptic spikes_pop
		
	// A copy of data from pre-synaptic population
	vector<double>* // This is problematic!!!
		V_post; // from post-synaptic population
	vector< vector<int> >
		spikes_pop; // pre-population spike history, spikes_pop[time index][neuron index], ring buffer

	// currents into post-synaptic population
	vector<double>
		I; 
	//
	bool
		stats_record;
	vector<double>
		I_mean,
		I_std;


	// Data sampling
	vector<int> 
		sample_neurons; // post-synaptic neuron indices
	vector<bool> 
		sample_time_points; // logical vector as long as time vector
	vector< vector<double> >
		sample; //  sampled neurons x time points

	
	


	// Build-in paramters for time-evolution of post-synaptic conductance change
	// 1-variable "s(t)" kinetic synapses model
	double 
		Dt_trans_AMPA, // msec, duration of transmitter release pulse (square-shape) activated by spike
		Dt_trans_GABA,
		Dt_trans_NMDA; // Note that here "transmitter" actually means "the effect of transmitter on gating variable"

	double	
		tau_decay_AMPA,
		tau_decay_GABA,
		tau_decay_NMDA;
	double
		tau_decay; // msec, decay time
	int
		steps_trans; // tranmitter duration in simulation steps
	double
		K_trans; // 1.0/transmitter_steps!
	double
		exp_step; // exp(-dt/tau)
	vector<double>
		exp_step_table; // exp(-dt*steps/tau), 



	// voltage-dependent part B(V) (look-up table):
	double
		miuMg_NMDA, // mM^-1, concentration of [Mg2+] is around 1 mM
		gamma_NMDA, // mV^-1
		B_V_min, // < V_in = -80
		B_V_max, // > V_th = -55
		B_dV;
	vector<double>
		B; // B = 1 / (1 + miuMg_NMDA*exp(-gamma_NMDA*V))





	// connection matrices and bookkeeping for 1-variable kinetic synapse model
	vector<double>
		gs_sum; // g*s, 0<s<1, g=K>0
	vector< vector<int> >
		s_TALS; //  time-step right after last spike (TALS) for each synapse (i.e., each gating variable)
	vector< vector<double> >
		s_full; 
		// s-value for each synapse (full matrix):
		// 	1) the value at TALS if after a spike, or 
		// 	2) the value at current time if during a spike, range [0,1]
	vector< vector<int> >
		C, // connection index
		   // each entry in the C matrix is the index of a POST-SYNAPTIC neuron (pre to post)
		D; // connection delay (in simulation time steps)
	vector< vector<double> >
		K; // connection strength, measuring the strength of synaptic conductance between two cells



	// Simulating external Poisson population (noise)
	double 
		K_ext; // identical connection strength for external pre-synaptic neurons (chemical synapses)
	int 
		Num_ext, // number of external pre-synaptic neurons (chemical synapses) per post-synaptic neuron
		ia, 
		ib; // range of neuron index in post population [ia,ib]
		
	vector<double> 
		rate_ext_t; // identical rate of firing for external pre-synaptic neurons (chemical synapses)
	vector< vector<double> > 
		gs_buffer; // in order to model transmitter, [t_ring][j_post]

	// Random number generator
	int 
		my_seed;
	typedef mt19937 
		base_generator_type; // A typedef is used so that base generator type can be changed
	base_generator_type 
		gen;

};

inline ChemicalSynapses::ChemicalSynapses(){};

#endif