#ifndef CHEMSYN_H
#define CHEMSYN_H
//#include <vector>
#include <functional> // pass function as parameter
//#include <string> 
//#include <iostream> 

#include "NeuroPop.h"
class NeuroPop; // #include ".h" for accessing its members, forward declaration for "syntax error: identifier xx" (why both are needed??)

using namespace std;

// Excitatory and inhibitory chemical synapses with transmission delay
class ChemSyn
{
public:
	ChemSyn(); /// default constructor
	ChemSyn(const double dt, const int step_tot, const char delim, const char indicator); /// parameterised constructor

	void init(const int syn_type, const int pop_ind_pre, const int pop_ind_post, const int N_pre, const int N_post, const vector<int> &C_i, const vector<int> &C_j, const vector<double> &K_ij, const vector<double> &D_ij); /// initialise chemical synapses by reading already prepared connections

	void init(const int syn_type, const int pop_ind_post, const int N_pre, const double K_ext, const int Num_ext, const vector<double> &rate_ext_t, const vector<bool> &neurons); /// initialise chemical synapses for simulating external Poissonian neuron population;

	void set_para(string para_str); /// set parameter values

	void recv_pop_data(vector<NeuroPop*> &NeuronPopArray); /// receive data from neuron populations
	void update(const int step_current); /// update by one step
	
	void set_synapse_model(const int synapse_model_input); /// set synapse model
	
	void send_pop_data(vector<NeuroPop*> &NeuronPopArray); ///  send data to neuron populations

	void add_short_term_depression(const int STD_on_step); /// turn on short term depression
	
	void add_inh_STDP(const int inh_STDP_on_step); /// turn on inhibitory STDP
	
	void add_sampling(vector<int> & sample_neurons, vector<bool> & sample_time_points);  /// add data sampling 

	void start_stats_record(); /// turn on basic statistics recording
	void output_results(ofstream& output_file); /// write output to file
#ifdef HDF5
	void output_results(H5File& file_HDF5);
#endif
	const int & get_syn_type(); /// get synapse type
	const int & get_pop_ind_pre(); /// get index of pre-synaptic population
	const int & get_pop_ind_post(); /// get index of post-synaptic population
private:

	char delim; /// delimiter for input and output files, usually comma
	char indicator; /// indicator for protocols, usually a single greater than operator
	void init(); /// parameter-dependent initialisation
	
	string dump_para(); // dump all the parameter values used
	
		
	void calc_I(); /// calculate currents into each post-synaptic neuron
	void update_gs_sum_model_0(const int step_current); /// update the gs_sum term for each post-synaptic neuron using synaptic dynamics model 0
	void update_gs_sum_model_1(const int step_current); /// update the gs_sum term for each post-synaptic neuron using synaptic dynamics model 1
	void update_STD(const int step_current); /// update short-term depression
	void update_inh_STDP(const int step_current); /// update inhibitory STDP
	void sample_data(const int step_current); /// sample data
	void record_stats(); /// record basic statistics

	void write2file(ofstream& output_file, vector< vector<int> >& v); /// write integer matrix to output file
	void write2file(ofstream& output_file, vector< vector<double> >& v); /// write double matrix to output file
	void write2file(ofstream& output_file, vector<int>& v); /// write integer vector to output file
	void write2file(ofstream& output_file, vector<double>& v); /// write double vector to output file
	#ifdef HDF5
	void write_vector_HDF5(Group & group, const vector<int> & v, const string & v_name);
	void write_vector_HDF5(Group & group, const vector<double> & v, const string & v_name);
	void append_vector_to_matrix_HDF5(DataSet & dataset_tmp, const vector<double> & v, const int colNum);
	void write_matrix_HDF5(Group & group, vector< vector<double> > & m, const string & m_name);
	void write_string_HDF5(Group & group, const string & s, const string & s_name);
	#endif
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
		syn_type; // 0 = AMPA, 1 = GABA, 2 = NMDA
	double
		V_ex, // Excitatory reversal
		V_in; // Inhibitory reversal
	int
		max_delay_steps;
		
	// A copy of data from pre-synaptic population
	vector<double> // This is problematic!!!
		V_post; // from post-synaptic population
	vector<int>
		spikes_pre,
		spikes_post; // current spikes from pre-synaptic population


	// currents into post-synaptic population
	vector<double>
		I; 
	
	//
	struct Stats {
		bool
			record;
		vector<double>
			I_mean,
			I_std;
	} stats;
	


	// Data sampling
	struct Sample {
		vector<int> 
			neurons; // post-synaptic neuron indices
		vector<bool> 
			time_points; // logical vector as long as time vector
		vector< vector<double> >
			data; //  sampled neurons x time points
	} sample;

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
		tau_rise,
		tau_decay; // msec, decay time
	int
		steps_trans; // tranmitter duration in simulation steps
	vector<double>
		K_trans; // 1.0/transmitter_steps!
	double
		exp_step_decay, // exp(-dt/tau_decay)
		exp_step_rise;
		
	// voltage-dependent part B(V) (look-up table):
	double
		miuMg_NMDA, // mM^-1, concentration of [Mg2+] is around 1 mM
		gamma_NMDA, // mV^-1
		B_V_min, // < V_in = -80
		B_V_max, // > V_th = -55
		B_dV;
	vector<double>
		B; // B = 1 / (1 + miuMg_NMDA*exp(-gamma_NMDA*V))


	// Inhibitory-to-excitatory coupling STDP plasticity as in
	// ref: Inhibitory plasticity balances excitation and inhibition in sensory pathways and memory networks
	struct Inh_STDP {
		bool
			on;
		vector<double>
			x_trace_pre,
			x_trace_post;
		double 
			tau,
			exp_step, // exp(-dt/tau_STPD)
			eta, // learning rate
			rho_0,
			alpha; // depression factor
		int
			on_step;
		vector< vector<int> >
			j_2_i, // j_2_i[j_post] gives all the i_pre's (indices of pre-synaptic neurons)
			j_2_syn_ind; // j_2_syn_ind[j_post] gives all the syn_ind's so that K[i_pre][syn_ind] is a synapse onto j_post
	} inh_STDP;

	// connection matrices and bookkeeping for 1-variable kinetic synapse model
	struct Std {
		double // short-term depression constants
			p_ves, // ves for vesicle
			tau_ves,
			exp_ves;
		bool
			on; //  
		int
			on_step; // the step where STD should turned on
		vector<double>
			f_ves; // the fraction of available vesicles
	} STD;

	//
	int
		synapse_model;
	
	vector<double>
		gs_sum; // post-synaptic dynamics
	
	// model 0
	struct Gsm_0 {
		int
			buffer_steps;
		vector<double>
			s; // pre-synaptic dynamics
		vector<int>
			trans_left; // 
		vector< vector<double> >
			d_gs_sum_buffer; // d_gs_sum_buffer[time index][post-synaptic neuron index], ring buffer
	} gsm_0;

	// model 1
	struct Gsm_1 {
		int
			buffer_steps;
		vector<double>
			gs_rise_sum,
			gs_decay_sum;
		vector< vector<double> >
			d_gs_rd_sum_buffer; // d_gs_rd_sum_buffer[time index][post-synaptic neuron index], ring buffer
	} gsm_1;
	
	vector< vector<int> >
		C, // connection index
		  // each entry in the C matrix is the index of a POST-SYNAPTIC neuron (pre to post)
		D; // connection delay (in simulation time steps)
	vector< vector<double> >
		K; // connection strength, measuring the strength of synaptic conductance between two cells


	vector< vector<double> > 
		tmp_data; // temporary data container for debugging


	// Simulating external Poisson population (noise)
	struct Ext_noise {
		double 
			K_ext; /// identical connection strength for external pre-synaptic neurons
		int 
			Num_ext; /// number of external pre-synaptic neurons per post-synaptic neuron
		vector<bool> 
			neurons; /// true if the post-synaptic neuron receives such noise
		vector<double> 
			rate_ext_t; // identical rate of firing for external pre-synaptic neurons (chemical synapses)
	} ext_noise;

	// Random number generator
	int 
		my_seed;
	typedef mt19937 
		base_generator_type; // A typedef is used so that base generator type can be changed
	base_generator_type 
		gen;

};

inline ChemSyn::ChemSyn(){};

#endif
