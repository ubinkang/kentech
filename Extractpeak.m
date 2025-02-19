%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright @ 2023 Stanford Energy Control Laboratory 
% (PI: Simona Onori, sonori@stanford.edu), 
% Stanford University. All Rights Reserved. 
% Developed by Luca Pulvirenti and Dr. Gabriele Pozzato 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
clear all
clc

% Variables for plotting
Markersize = 18;
Fontsize = 20;
LineWidth = 5;
BarLineWidth = 1.5;

%% Load Trips Data
load('Trips.mat', 'trips');  
Ntrips = numel(trips);
fprintf('총 %d개의 트립(충전/방전 이벤트)이 로드되었습니다.\n', Ntrips);

% 저장할 변수 초기화
all_R_peak = [];
all_SOC_peak = [];
peak_threshold = 3;  % 기존 50 → 5로 변경

%% Process Each Trip
for i = 1:Ntrips
    % 각 트립 데이터 추출
    t = trips(i).time;       % 시간
    c = trips(i).current;    % 전류
    v = trips(i).voltage;    % 전압
    ocv = trips(i).OCV;      % OCV
    soc = trips(i).SOC;      % SOC
    
    % Check if the trip has sufficient data
    if length(c) < 100
        fprintf('트립 %d의 데이터가 충분하지 않습니다. 건너뜁니다.\n', i);
        continue;
    end
    
    % Filter on Current (Moving Average)
    dt = 100;   % Number of samples in 1s (sampling time = 0.01s)
    te = 100;
    N = length(c);
    I_filt = zeros(N,1);
    Pre = 0 * ones(te/2,1);
    Post = 0 * ones(te/2,1);
    I_calc = [Pre; c; Post];
    
    for j = 1:N
        for m = 0:te
            I_filt(j) = I_filt(j) + I_calc(j + m);
        end
        I_filt(j) = I_filt(j) / (te + 1);
    end
    
    % Derivative of Current
    dI_dt = diff(c) ./ diff(t);
    dI_dt = [dI_dt; dI_dt(end)];
    
    % Detect Peaks (Acceleration & Braking)
    peak_indices = [];
    for j = 1:(N - dt)
        delta_I = I_filt(j+dt) - I_filt(j);
        
        % 디버깅: 전류 변화량 출력
        if j == 1
            fprintf('트립 %d에서 전류 변화량(delta_I) 최대값: %.3f\n', i, max(I_filt - circshift(I_filt, dt)));
        end
        
        if delta_I > peak_threshold  % 가속
            if c(j) > -5 && c(j) < 5  % 전류 제한
                peak_indices = [peak_indices; j];
            end
        elseif delta_I < -peak_threshold  % 감속
            if c(j) > -2 && c(j) < 2  % 전류 제한
                peak_indices = [peak_indices; j];
            end
        end
    end
    % 피크가 감지되지 않은 경우 경고 메시지 출력
    if isempty(peak_indices)
        fprintf('트립 %d에서 피크를 감지하지 못했습니다.\n', i);
        continue;
    end
    
    %% Compute R and Store SOC at Peaks
for j = 1:length(peak_indices)
    idx = peak_indices(j);
    if idx + dt <= length(c)
        DV = ocv(idx) - v(idx);  % OCV에서 Voltage를 뺌
        DI = c(idx);  % 현재 전류값을 사용
        
        % 0으로 나누는 오류 방지
        if abs(DI) > 1e-6 
            R_peak = DV / DI * 1000; % Convert to mΩ
            all_R_peak = [all_R_peak; R_peak];
            all_SOC_peak = [all_SOC_peak; soc(idx)];
        end
    end
end

end

%% Save Results to .mat File
if isempty(all_R_peak)
    warning('어떤 트립에서도 R_peak 값을 저장하지 못했습니다.');
else
    save('R_SOC_Peaks.mat', 'all_R_peak', 'all_SOC_peak');
    fprintf('R_peak 및 SOC_peak 데이터를 R_SOC_Peaks.mat 파일에 저장 완료.\n');
end

%% Plot R vs SOC
if ~isempty(all_R_peak)
    figure;
    scatter(all_SOC_peak, all_R_peak, 50, 'b', 'filled');
    xlabel('State of Charge (SOC) [%]');
    ylabel('Resistance (R) [mΩ]');
    title('R vs SOC');
    grid on;
    set(gca, 'FontSize', Fontsize);
end
