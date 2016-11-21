function [peak] = show_LFP_continous(R, show)
dt = R.dt;
stamp = R.stamp;
samp_file = [stamp(1:end-3) '0_neurosamp'];
load(samp_file);

[N, steps] = size(I_AMPA);
if N ~= R.N(1)
    error('Not all of the excitatory neurons are sampled!')
end
w = sqrt(N);

hw = (w-1)/2;
[Lattice, ~] = lattice_nD(2, hw);

if ~exist('ripple_power_grid','var')
    dist = lattice_nD_find_dist(Lattice, hw,  0, 0);
    LFP_range_sigma = R.ExplVar.LFP_range_sigma;
    gaus_tmp = 1/(LFP_range_sigma*sqrt(2*pi))*exp(-0.5*(dist/LFP_range_sigma).^2) .* double(dist <= LFP_range_sigma*2.5);
    m = reshape(gaus_tmp, w, w);
    LFP_grid = zeros(w,w,steps);
    for i = 1:steps
        x = reshape(abs(I_AMPA(:,i)) + abs(I_GABA(:,i)), w, w);
        y = convolve2(x, m, 'wrap');
        
        LFP_grid(:,:,i) = y;
        %i
    end
    clear I_AMPA I_GABA;
    %%%% Ripple power
    fs = 1/(R.dt*1e-3); % sampling frequency (Hz)
    % Butterworth filter
    order = 4; % 4th order
    lowFreq = 100; % ripple band (default values for this function are 150-250 Hz)
    hiFreq = 250;
    Wn = [ lowFreq  hiFreq]/(fs/2);
    [b,a] = butter(order/2,Wn,'bandpass'); %The resulting bandpass and bandstop designs are of order 2n.
    gaus_width = 5; %ms
    [ Kernel ] = spike_train_kernel_YG( gaus_width, R.dt, 'gaussian_unit' );
    ripple_power_grid = zeros(size(LFP_grid));
    for i = 1:w
        for j= 1:w
            ripple_tmp = filter(b,a,LFP_grid(i,j,:));
            ripple_tmp = ripple_tmp(:);
            hil_tmp = abs(hilbert( ripple_tmp));
            ripple_power_grid(i,j,:) = conv(hil_tmp, Kernel,'same');
        end
        %w*(i-1)+j
    end
    save(samp_file, 'ripple_power_grid', '-append')
end

if ~exist('peak','var')
    peak = [];
    for i = 1:steps
        A =  ripple_power_grid(:,:,i);
        [peak_mag,I] = max(A(:));
        [I_row, I_col] = ind2sub(size(A),I);
        peak = [peak; I_row, I_col, peak_mag];
    end
    
    save(samp_file,  'peak', '-append')
end
figure('NumberTitle','off','Name','Peak','color', 'w');
multicolor_line(peak(:,1), peak(:,2), peak(:,3), 2)

X = ripple_power_grid;

if nargin == 1;
    show = 1;
end
if show == 1
    figure('NumberTitle','off','Name','Ripple Hilbert Power','color', 'w');
    mm = minmax(reshape(X(:),1,[]));
    xlim([-hw hw]);
    ylim([-hw hw]);
    hold on;
    h1 = imagesc(-hw:hw, -hw:hw,X(:,:,1), mm);
    % h1 = imagesc(-hw:hw, -hw:hw,X(:,:,1));
    s = find(R.spike_hist{1}(:,1));
    h2 = plot(Lattice(s,2),Lattice(s,1),'r.','MarkerSize',15);
    
    t = find(R.neuron_sample.t_ind{1});
    
    for i = 1:steps
        s = find(R.spike_hist{1}(:,t(i)));
        pause(0.01)
        set(h1,'CData',X(:,:,i));
        set(h2,'XData',Lattice(s,2),'YData',Lattice(s,1));
        xlabel([num2str(t(i)*dt ),' ms']);
    end
end

end