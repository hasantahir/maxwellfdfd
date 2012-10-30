classdef Painter2d < handle
	% Painter2d is a class that is in charge of plotting Scalar2d based on
	% Scalar2d.
		
	properties (Access = private)
		C
		Xh
		Yv
		maxamp  % maximum amplitude: max(abs(V(:)))
		isCpreped  % true if V is prepared
		isLpreped  % true if Xh, Yv are prepared
	end
	
	% Properties that affect C, Xh, Yv, and hence require draw2d()
	properties (Dependent)
		scalar2d
		withinterp
		withpml
		phase_angle
        withabs
		databound
		isswapped
	end
	
	% Internal properties for the properties affecting C, Xh, Yv
	properties (Access = private)
		scalar2d_
		withinterp_
		withpml_
		phase_angle_
        withabs_
		isswapped_
	end

	% Properties that do not affect C, Xh, Yv, but require draw().
	properties
		obj_array
		src_array
		cscale
		cmax  % if cmax ~= Inf, use cmax in crange and ignore maxamp and cscale
        withgrid
		withcolorbar
	end
	
	methods
		function this = Painter2d()
			this.withinterp_ = true;
			this.withpml_ = false;
			this.phase_angle_ = 0;
			this.withabs_ = false;
			this.isswapped_ = false;

			this.obj_array = [];
			this.src_array = [];
			this.cscale = 1.0;
			this.cmax = Inf;
			this.withgrid = false;
			this.withcolorbar = false;
						
			this.isCpreped = false;
			this.isLpreped = false;
		end
		
		function databound = get.databound(this)
			databound = this.scalar2d.grid2d.bound_plot(this.withpml);
		end
		
		function scalar2d = get.scalar2d(this)
			scalar2d = this.scalar2d_;
		end
		
		function set.scalar2d(this, scalar2d)
			chkarg(istypesizeof(scalar2d, 'Scalar2d'), '"scalar2d" should be instance of Scalar2d.');
			if isempty(this.scalar2d) || ~isequal(this.scalar2d, scalar2d)  % Scalar2d is value class, so same reference means same contents
				this.isCpreped = false;
				this.isLpreped = false;
				this.scalar2d_ = scalar2d;
			end
		end
		
		function truth = get.withinterp(this)
			truth = this.withinterp_;
		end
		
		function set.withinterp(this, truth)
			chkarg(istypesizeof(truth, 'logical'), '"truth" should be logical.');
			if this.withinterp ~= truth
				this.isCpreped = false;
				this.isLpreped = false;
				this.withinterp_ = truth;
			end
		end
		
		function truth = get.withpml(this)
			truth = this.withpml_;
		end
		
		function set.withpml(this, truth)
			chkarg(istypesizeof(truth, 'logical'), '"truth" should be logical.');
			if this.withpml ~= truth
				this.isCpreped = false;
				this.isLpreped = false;
				this.withpml_ = truth;
			end
		end
		
		function phase_angle = get.phase_angle(this)
			phase_angle = this.phase_angle_;
		end
		
		function set.phase_angle(this, phase_angle)
			chkarg(istypesizeof(phase_angle, 'real'), '"phase_angle" should be real.');
			if this.phase_angle ~= phase_angle
				this.isCpreped = false;
				this.phase_angle_ = phase_angle;
			end
		end
		
		function truth = get.withabs(this)
			truth = this.withabs_;
		end
		
		function set.withabs(this, truth)
			chkarg(istypesizeof(truth, 'logical'), '"truth" should be logical.');
			if this.withabs ~= truth
				this.isCpreped = false;
				this.withabs_ = truth;
			end
		end
		
		function truth = get.isswapped(this)
			truth = this.isswapped_;
		end
		
		function set.isswapped(this, truth)
			chkarg(istypesizeof(truth, 'logical'), '"truth" should be logical.');
			if this.isswapped ~= truth
				this.isCpreped = false;
				this.isLpreped = false;
				this.isswapped_ = truth;
			end
		end
		
		function set.obj_array(this, obj_array)
			chkarg(istypesizeof(obj_array, 'Object', [1, 0]), '"obj_array" should be row vector of instances of Object.');
			this.obj_array = obj_array;
		end
		
		function set.src_array(this, src_array)
			chkarg(istypesizeof(src_array, 'Source', [1, 0]), '"src_array" should be row vector of instances of Source.');
			this.src_array = src_array;
		end
		
		function set.cscale(this, cscale)
			chkarg(istypesizeof(cscale, 'real') && cscale > 0, '"cscale" should be positive.');
			this.cscale = cscale;
		end
		
		function set.cmax(this, cmax)
			chkarg(istypesizeof(cmax, 'real') && cmax > 0, '"cmax" should be positive.');
			this.cmax = cmax;
		end
		
		function set.withgrid(this, truth)
			chkarg(istypesizeof(truth, 'logical'), '"truth" should be logical.');
			this.withgrid = truth;
		end
		
		function set.withcolorbar(this, truth)
			chkarg(istypesizeof(truth, 'logical'), '"truth" should be logical.');
			this.withcolorbar = truth;
		end
		
		function prep_data(this)
			if this.isLpreped
				this.C = this.scalar2d.data_for_slice(this.withinterp, this.withpml);
			else
				[this.C, this.Xh, this.Yv] = this.scalar2d.data_for_pcolor(this.withinterp, this.withpml);
			end
			
			if this.isswapped
				this.C = this.C.';
				temp = this.Xh;
				this.Xh = this.Yv.';
				this.Yv = temp.';
			end
			
			this.maxamp = max(abs(this.C(:)));
			
			if this.withabs
				this.C = abs(this.C);
			else
				this.C = real(exp(1i * this.phase_angle) .* this.C);
			end
						
			this.isLpreped = true;
			this.isCpreped = true;
		end
		
		function set_caxis(this, axes_handle)
			if this.withabs
				if isinf(this.cmax)
					crange = this.cscale .* [0, this.maxamp];
				else
					crange = [0, this.cmax];
				end
				caxis(axes_handle, crange);
				colormap(axes_handle, 'hot');
			else
				if isinf(this.cmax)
					crange = this.cscale .* [-this.maxamp, this.maxamp];
				else
					crange = [-this.cmax, this.cmax];
				end
				caxis(axes_handle, crange);
				colormap(axes_handle, 'jet');
			end
		end

		function init_display(this, axes_handle)
			if nargin < 2 || isempty(axes_handle)
				axes_handle = gca;
			end

			if ~this.isCpreped
				this.prep_data();
			end

			init_axes2d(axes_handle, this.scalar2d.grid2d, this.withinterp, this.withpml, this.isswapped);
			this.set_caxis(axes_handle);

			if this.withcolorbar
				hc = colorbar;
				format_colorbar(hc, this.scalar2d);
			else
				colorbar off
			end
		end
		
		function surface_handle = draw_slice(this, axes_handle)
			if nargin < 2 || isempty(axes_handle)
				axes_handle = gca;
			end
			chkarg(ishandle(axes_handle), '"axes_handle" should be handle.');
			
			if ~this.isCpreped
				this.prep_data();
			end
			
			% Update the title.
			str = this.scalar2d.name;
			if this.withabs
				str = ['|', str, '|'];
			end
			if ~isnan(this.scalar2d.intercept)
				str = [str, '  at  ', char(this.scalar2d.grid2d.normal_axis), ' = '];
				intercept = this.scalar2d.intercept;
				if intercept == 0 || (abs(intercept) < 1e5 && abs(intercept) > 1e-3)
					str = [str, num2str(intercept)];
				else
					str = [str, num2str(intercept, '%.2e')];
				end
			end
			title(axes_handle, str);

			surface_handle = pcolor(axes_handle, this.Xh, this.Yv, this.C);
            
			if ~this.withgrid
                set(surface_handle,'EdgeColor', 'none');
			elseif this.withabs
				set(surface_handle, 'EdgeColor', 'w');
			else
				set(surface_handle, 'EdgeColor', 'k');
			end
			
			if this.withinterp
				set(surface_handle,'FaceColor', 'interp');
			end
		end
			
		function plot_handle_array = draw_objsrc(this, axes_handle)
			% See MATLAB > User's Guide > Graphics > Handle Graphics Objects >
			% Plot Objects in Help Browser.
			if nargin < 2 || isempty(axes_handle)
				axes_handle = gca;
			end
			chkarg(ishandle(axes_handle), '"axes_handle" should be handle.');
			
			if ~this.isCpreped
				this.prep_data();
			end
			
			title_curr = get(get(axes_handle, 'Title'), 'String');
			xlabel_curr = get(get(axes_handle, 'Xlabel'), 'String');
			ylabel_curr = get(get(axes_handle, 'Ylabel'), 'String');
			
			n = this.scalar2d.grid2d.normal_axis;
			intercept = this.scalar2d.intercept;
			if this.withinterp
				l_bound = this.scalar2d.l_data(this.withpml);
			else
				l_bound = this.scalar2d.l_pixelbound(this.withpml);
			end

			if this.isswapped
				l_bound = wrev(l_bound);
			end
			
			plot_handle_array = [];
			for obj = this.obj_array
				color = obj.material.color;
				shape = obj.shape;
				if ~isequal(color, 'none')  && shape.interval(n).contains(intercept);
					if ~istypesizeof(shape, 'Plane')
						lsf = shape.lsf;
					else
						lsf = @(r) shape.lsf(r, true);
					end
					
					if n == Axis.x
						lsf2d_temp = @(h,v) lsf([intercept(ones(size(h))), h, v]);
					elseif n == Axis.y
						lsf2d_temp = @(h,v) lsf([v, intercept(ones(size(h))), h]);
					else  % n == Axis.z
						lsf2d_temp = @(h,v) lsf([h, v, intercept(ones(size(h)))]);
					end

					if ~this.isswapped
						lsf2d = lsf2d_temp;
					else
						lsf2d = @(h, v) lsf2d_temp(v, h);
					end

					warning('off', 'MATLAB:contour:ConstantData');
% 					h = ezplot(axes_handle, lsf2d, [this.databound(axis_h,:), this.databound(axis_v,:)]);
					h = ezplot(axes_handle, lsf2d, [l_bound{Dir.h}([1 end]), l_bound{Dir.v}([1 end])]);
					warning('on', 'MATLAB:contour:ConstantData');
					set(h, 'Color', obj.material.color);
					plot_handle_array = [plot_handle_array(1:end), h];
				end
			end
			title(axes_handle, title_curr);
			xlabel(axes_handle, xlabel_curr);
			ylabel(axes_handle, ylabel_curr);
		end
	end	
end

