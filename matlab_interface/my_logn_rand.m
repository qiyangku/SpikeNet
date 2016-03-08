function [ X ] = my_logn_rand( Mu, Sigma, CorrMat_log, N, mu_sigma_mode )
%[ X ] = my_logn_rand( Mu, Sigma, CorrMat_log, N, mu_sigma_mode )
%   'mu_sigma_mode' specifies whether the input Mu and Sigma are for the
%   pre-exponentiated normal distribution ('mu_sigma_norm') or for the
%   post-exponentiated lognormal distritbution ('mu_sigma_norm')
%
%
%   Code tested.

%   For more information see: Aggregration of Correlated Risk Portfolios:
%   Models and Algorithms; Shaun S. Wang, Phd.  Casualty Actuarial Society
%   Proceedings Volume LXXXV www.casact.org
%
%   Author: Stephen Lienhard


switch lower(mu_sigma_mode)
    case 'mu_sigma_log'
        Mu_norm = log((Mu.^2)./sqrt(Sigma.^2+Mu.^2));
        Sigma_norm = sqrt(log(Sigma.^2./(Mu.^2)+1));
    case 'mu_sigma_norm'
        Mu_norm = Mu;
        Sigma_norm = Sigma;
end
% The inverse transformation of the above one is lognstat
% [Mu_log, Sigma_log] = [Mu_norm, Sigma_norm]

% Calculate the covariance structure
sigma_down = repmat( Sigma_norm(:)' , numel(Sigma_norm(:)), 1                    );
sigma_acrs = repmat( Sigma_norm(:)  , 1                   , numel(Sigma_norm(:)) );
covv = log( CorrMat_log .* sqrt(exp(sigma_down.^2)-1) .* ...
                       sqrt(exp(sigma_acrs.^2)-1) + 1 );

% The Simulation
X = exp( mvnrnd( Mu_norm(:) , covv , N ));

% error check
min_error = 0.05; % percent
if length(Mu) == 2
    X_c = corrcoef(X);
    error = abs( (X_c(1,2)-CorrMat_log(1,2) ) / CorrMat_log(1,2) );
    if error > min_error
        clear X;
        % disp('regenerating...')
        [ X ] = my_logn_rand( Mu, Sigma, CorrMat_log, N, mu_sigma_mode );
    end
else
    disp('length(Mu) ~= 2, error check skipped.')
end


end
