%% Get current scenario
clc;
[app, scenario] = getSTKApi();
root = app.Personality2;

%% Set scenario timespan

start_date = '1 Jan 2025 16:00:00.000';
end_date = '1 Jan 2025 20:00:00.000';
root.UnitPreferences.Item('DateFormat').SetCurrentUnit('UTCG');
scenario.SetTimePeriod('1 Jan 2025 16:00:00.000','1 Jan 2025 20:00:00.000');
root.UnitPreferences.Item('DateFormat').SetCurrentUnit('EpSec');

%% Populate in STK

a = 7700; % Semi-Major axis
e = 0;  % Eccentricity
w = 0;
inc = 75; % Inclination
t = 48;  % Total satellites
planes = 8;  % Planes
f = 10;  % Phase - delta_anomaly = f × 360 / t.

% Calculate the number of satellites in each plane
satellites_per_plane = t / planes;

% i is the inclination;
% t is the total number of satellites;
% p is the number of equally spaced planes; and
% f is the relative spacing between satellites in adjacent planes. 
% The change in true anomaly (in degrees) for equivalent satellites 
% in neighbouring planes is equal to f × 360 / t.

scenario_specs = struct('start_date',start_date,'end_date',end_date,...
    'anom_type','true','graz_alt_km',100,'propagator','keplerian','step_seconds',60);
satellite_elements = cell(t,1);

% 1 color per plane
colors = generateDistinctRGBColors(planes);

%%
% Calculate the right ascension of the ascending node (Ω) for each plane
Omega_per_plane = linspace(0, 2*pi - 2*pi/planes, planes);

% Calculate true anomaly (theta) for each satellite
theta_change = deg2rad(f * 360 / t); % Change in true anomaly between adjacent satellites
phase_in_plane = 360 / satellites_per_plane;
theta_per_plane = zeros(satellites_per_plane, 1);

for sat_idx = 1:satellites_per_plane
    theta_per_plane(sat_idx) = deg2rad((sat_idx - 1) * phase_in_plane);
end

% Print orbital elements for each satellite
fprintf('Orbital Elements of Walker Constellation:\n');
fprintf('Semi-major axis (a) = %.2f km\n', a);
fprintf('Orbital Elements for Each Satellite:\n');

cell_idx = 1;
for plane_idx = 1 : planes
    for sat_idx = 1:satellites_per_plane
        name = strcat('P',num2str(plane_idx),'_S',num2str(sat_idx));
        RAAN = Omega_per_plane(plane_idx);
        anom = theta_per_plane(sat_idx) + (plane_idx - 1) * theta_change;
        anom = mod(anom, 2*pi);
        sat = addSatelliteToSTK(scenario,name,a,e,inc,rad2deg(RAAN),w,rad2deg(anom));
        sat.Graphics.Attributes.Color = rgbToUint32Color(colors(plane_idx,:));
        fprintf('Plane %d, Satellite %d:\n', plane_idx, sat_idx);
        fprintf('Right Ascension of Ascending Node (Ω) = %.4f radians\n', Omega_per_plane(plane_idx));
        fprintf('True Anomaly (theta) = %.4f radians\n\n', theta_per_plane(sat_idx));
        
        satellite_elements{cell_idx} = struct('sat_id',name,'sem_maj_axis_km', a, 'ecc',e,'inc', ...
            inc,'RAAN',rad2deg(RAAN),'arg_per',w,'anom',rad2deg(anom));
        cell_idx = cell_idx + 1;
        
    end
end

%% Add GEOs

for geo_idx = 1 : 3
    name = strcat('GEO_',num2str(geo_idx));
    a = 42166.258681;
    e = 0.000;
    inc = 0.139;
    RAAN = 90.815 + (geo_idx - 1) * 120;
    RAAN = deg2rad(RAAN);
    w = 0;
    anom = deg2rad(150.421);
    sat = addSatelliteToSTK(scenario,name,a,e,inc,rad2deg(RAAN),w,rad2deg(anom));
    sat.Graphics.Attributes.Color = rgbToUint32Color(colors(geo_idx,:));
    fprintf('Adding GEO %d\n', geo_idx);
    satellite_elements{cell_idx} = struct('sat_id',name,'sem_maj_axis_km', a, 'ecc',e,'inc', ...
        inc,'RAAN',rad2deg(RAAN),'arg_per',w,'anom',rad2deg(anom));
    cell_idx = cell_idx + 1;
end


%% Compute access

pairs = generatePairs(planes, satellites_per_plane);

% Access between LEOs and LEOs
for i = 1 : size(pairs,1)
    satIdx = pairs(i,:);
    sat1name = strcat('P',num2str(satIdx(1)),'_S',num2str(satIdx(2)));
    sat1 = scenario.Children.Item(sat1name);
    data.(sat1name) = struct();
    for j = 1 : size(pairs,1)
        if i == j
            continue
        end
        satIdx = pairs(j,:);
        sat2name = strcat('P',num2str(satIdx(1)),'_S',num2str(satIdx(2)));
        disp([sat1name ' to ' sat2name])
        sat2 = scenario.Children.Item(sat2name);
        access = sat1.GetAccessToObject(sat2);
        access.ComputeAccess();
        intervalCollection = access.ComputedAccessIntervaltimes;
        if intervalCollection.Count ~= 0
            computedIntervals = intervalCollection.ToArray(0, -1);
            data.(sat1name).(sat2name) = cell2mat(computedIntervals);
        else
            data.(sat1name).(sat2name) = [0, 0];
        end
    end
end

% Access between GEOs and LEOs
for geo_idx = 1 : 3
    
    geo_name = strcat('GEO_',num2str(geo_idx));
    sat1 = scenario.Children.Item(geo_name);
    data.(geo_name) = struct();
    
    for i = 1 : planes       
        for j = 1 : t / planes
            sat2name = strcat('P',num2str(i),'_S',num2str(j));
            disp([geo_name ' to ' sat2name])
            sat2 = scenario.Children.Item(sat2name);
            access = sat1.GetAccessToObject(sat2);
            access.ComputeAccess();
            intervalCollection = access.ComputedAccessIntervaltimes;
            if intervalCollection.Count ~= 0
                computedIntervals = intervalCollection.ToArray(0, -1);
                data.(geo_name).(sat2name) = cell2mat(computedIntervals);
            else
                data.(geo_name).(sat2name) = [0, 0];
            end
        end
    end
    
end
%%
% Access between GEOs
for geo_idx_1 = 1 : 3
    
    geo_name_1 = strcat('GEO_',num2str(geo_idx_1));
    sat1 = scenario.Children.Item(geo_name_1);
    data.(geo_name_1) = struct();
    
    for geo_idx_2 = 1 : 3
        if geo_idx_1 == geo_idx_2
            continue;
        end
        geo_name_2 = strcat('GEO_',num2str(geo_idx_2));
        disp([geo_name_1 ' to ' geo_name_2])
        sat2 = scenario.Children.Item(geo_name_2);
        access = sat1.GetAccessToObject(sat2);
        access.ComputeAccess();
        intervalCollection = access.ComputedAccessIntervaltimes;
        if intervalCollection.Count ~= 0
            computedIntervals = intervalCollection.ToArray(0, -1);
            data.(geo_name_1).(geo_name_2) = cell2mat(computedIntervals);
        else
            data.(geo_name_1).(geo_name_2) = [0, 0];
        end
    end
    
end

% Convert the data structure to JSON format
contact_plan_json = jsonencode(data);

%%

path = 'output/';
file_name = strcat('contact_plan_a_',num2str(a),'_i_',num2str(inc),'_t_',num2str(t),'_p_',num2str(planes),'_f_',num2str(f),'_and_GEOs.json');
file_name = strcat(path,file_name);

% Save the contact plan to JSON
fileID = fopen(file_name, 'w');
if fileID == -1
    error('Cannot open file for writing: data.json');
end
fprintf(fileID, '%s', contact_plan_json);
fclose(fileID);

% Save the satellite's specs
file_name = strcat('constellation_specs_a_',num2str(a),'_i_',num2str(inc),'_t_',num2str(t),'_p_',num2str(planes),'_f_',num2str(f),'_and_GEOs.json');
file_name = strcat(path,file_name);
fileID = fopen(file_name, 'w');
if fileID == -1
    error('Cannot open file for writing: data.json');
end
fprintf(fileID, '%s', jsonencode(satellite_elements));
fclose(fileID);

% Save the scenario specs
file_name = strcat('scenario_specs_a_',num2str(a),'_i_',num2str(inc),'_t_',num2str(t),'_p_',num2str(planes),'_f_',num2str(f),'_and_GEOs.json');
file_name = strcat(path,file_name);
fileID = fopen(file_name, 'w');
if fileID == -1
    error('Cannot open file for writing: data.json');
end
fprintf(fileID, '%s', jsonencode(scenario_specs));
fclose(fileID);

%%

% sat1 = scenario.Children.Item("S1_1");
% sat2 = scenario.Children.Item("S2_1");
% access = sat1.GetAccessToObject(sat2);
% access.ComputeAccess();

%%
function sat = addSatelliteToSTK(scenario, name, a, e, i, O, w, v)
    sat = scenario.Children.New('eSatellite',name);
    keplerian = sat.Propagator.InitialState.Representation.ConvertTo('eOrbitStateClassical');
    sat.Propagator.step=60; % 60 segundos step 
    %keplerian.SizeShapeType = 'eSizeShapeAltitude';
    keplerian.SizeShapeType = 'eSizeShapeSemimajorAxis';
    keplerian.LocationType = 'eLocationTrueAnomaly';
    % keplerian.LocationType = 'eLocationMeanAnomaly';
    keplerian.Orientation.AscNodeType = 1;  % 1=RAAN, 0=LAN
    %semiMajorAxis = parametrosTemp(2);
    keplerian.SizeShape.Eccentricity = e;
    keplerian.SizeShape.SemiMajorAxis = a;
    %keplerian.SizeShape.PerigeeAltitude = semiMajorAxis*(1-eccentricity);
    %keplerian.SizeShape.ApogeeAltitude = semiMajorAxis*(1+eccentricity);
    keplerian.Orientation.Inclination = i;
    keplerian.Orientation.AscNode.Value = O;
    keplerian.Orientation.ArgOfPerigee = w;
    % keplerian.SizeShape.MeanMotion=parametrosTemp(6);
    keplerian.Location.Value = v;
    % keplerian.Orientation.MeanAnomaly = parametrosTemp(6);
    sat.Propagator.InitialState.Representation.Assign(keplerian);
    sat.Propagator.Propagate;
    accessConstraints = sat.AccessConstraints;
    minAngle = accessConstraints.AddConstraint('eCstrGroundElevAngle');
%     minAngle.EnableMin = true;
%     minAngle.Min = 5;   % Degrees
    minGrazingAlt = accessConstraints.AddConstraint('eCstrGrazingAlt');
    minGrazingAlt.EnableMin = true;
    minGrazingAlt.Min = 100; % Km
end

function [app, scenario] = getSTKApi()
    app = actxGetRunningServer('STK11.application');
    root = app.Personality2;
    scenario = root.CurrentScenario;
    root.UnitPreferences.Item('DateFormat').SetCurrentUnit('UTCG');
    scenario.SetTimePeriod('10 Mar 2024 16:00:00.000','10 Mar 2024 16:20:00.000');
    root.UnitPreferences.Item('DateFormat').SetCurrentUnit('EpSec');
    root.Rewind;
end

function randomRGBColors = generateRandomRGBColors(numColors)
    % Initialize the matrix to store random RGB colors
    randomRGBColors = zeros(numColors, 3, 'uint8');
    
    % Generate random RGB colors
    for i = 1:numColors
        randomRGBColors(i, :) = randi([0, 255], 1, 3, 'uint8');
    end
end

function distinctRGBColors = generateDistinctRGBColors(numColors)
    distinctRGBColors = zeros(numColors, 3, 'uint8');
    
    for i = 1:numColors
        hue = mod(i / numColors, 1); % Vary the hue
        saturation = 0.7; % Adjust saturation for clarity
        value = 0.9; % Adjust value for brightness
        
        rgb = hsv2rgb([hue, saturation, value]);
        distinctRGBColors(i, :) = uint8(rgb * 255); % Convert to [0, 255]
    end
end

function uint32Color = rgbToUint32Color(rgb)
    rgb = max(min(rgb, 255), 0);
    uint32Color = uint32(rgb(1)) + bitshift(uint32(rgb(2)), 8) + bitshift(uint32(rgb(3)), 16);
end

function pairs = generatePairs(N, M)
    pairs = [];
    
    for n = 1:N
        for m = 1:M
            pairs = [pairs; [n, m]];  % Add pair (n, m)
        end
    end
end