classdef Interval
	% Interval is a 1D version of Shape.  It is a concrete class.
	
	properties (SetAccess = immutable)
		bound  % [min max];
		dl_max  % maximum dl
	end
	
	methods
		function this = Interval(bound, dl_max)
			% bounds
			chkarg(istypesizeof(bound, 'real', [1, Sign.count]), '"bound" should be [min max].');
			chkarg(bound(Sign.n) <= bound(Sign.p), ...
				'lower bound should be smaller than upper bound of "bound".');
			this.bound = bound;
						
			% dl_max
			if nargin < 2  % no dl_max
				this.dl_max = NaN;
			else  % dl_max
				chkarg(istypesizeof(dl_max, 'real') && dl_max > 0, '"dl_max" should be postive and real.');
				this.dl_max = dl_max;
			end
		end
						
		function L = L(this)
			L = this.bound(Sign.p) - this.bound(Sign.n);
		end
						
		function [truth, distance] = contains(this, val)
			chkarg(istypesizeof(val, 'real', [0 1]), '"val" should be column vector with real elements.');
			bn = this.bound(Sign.n);
			bp = this.bound(Sign.p);
			
			truth = (val >= bn) & (val <= bp);
			
			if nargout >= 2  % distance
				distance = min(abs([val-bn, val-bp]), [], 2);
			end
		end
	end
end
