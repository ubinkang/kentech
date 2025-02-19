function interpolate_and_save()
    clc; clear; close all;
    
    %% 1. 기존 데이터 로드
    % ✅ 146개 R_peak, SOC 값 로드
    S1 = load('R_peak_and_SOC_threshold.mat');  
    R_peak = S1.R_peak_struct.R_peak;   % 146개 R_peak
    SOC_target = S1.R_peak_struct.SOC;  % 146개 SOC (0~1 범위)

    % ✅ 14개 R0, R1, tau, SOC_begin 값 로드
    S2 = load('Fitted_1RC_Params.mat');  
    SOC_source = S2.fitted_params.SOC_begin;  % 14개 SOC 값 (0~1 범위)
    R0_source = S2.fitted_params.R0;
    R1_source = S2.fitted_params.R1;
    tau_source = S2.fitted_params.tau;

    % **정렬 확인 (SOC 값이 오름차순이어야 함)**
    [SOC_source, sort_idx] = sort(SOC_source);
    R0_source = R0_source(sort_idx);
    R1_source = R1_source(sort_idx);
    tau_source = tau_source(sort_idx);
    
    %% 2. SOC 값 기준으로 인터폴레이션 수행 (146개로 확장)
    R0_interp = interp1(SOC_source, R0_source, SOC_target, 'linear', 'extrap');
    R1_interp = interp1(SOC_source, R1_source, SOC_target, 'linear', 'extrap');
    tau_interp = interp1(SOC_source, tau_source, SOC_target, 'linear', 'extrap');

    %% 3. 새로운 데이터 저장 (.mat 파일)
    new_data.R_peak = R_peak;     % 기존 146개 R_peak 값
    new_data.SOC = SOC_target;    % 기존 146개 SOC 값
    new_data.R0 = R0_interp;      % 인터폴레이션된 146개 R0 값
    new_data.R1 = R1_interp;      % 인터폴레이션된 146개 R1 값
    new_data.tau = tau_interp;    % 인터폴레이션된 146개 tau 값

    save('Interpolated_R_1RC_Params.mat', 'new_data');
    
    %% 4. 결과 확인용 플로팅
    figure;
    subplot(3,1,1);
    scatter(SOC_source*100, R0_source, 'ro', 'filled'); hold on;
    plot(SOC_target*100, R0_interp, 'b-'); grid on;
    xlabel('SOC [%]'); ylabel('R0 [Ω]');
    title('Interpolated R0 vs SOC');

    subplot(3,1,2);
    scatter(SOC_source*100, R1_source, 'ro', 'filled'); hold on;
    plot(SOC_target*100, R1_interp, 'b-'); grid on;
    xlabel('SOC [%]'); ylabel('R1 [Ω]');
    title('Interpolated R1 vs SOC');

    subplot(3,1,3);
    scatter(SOC_source*100, tau_source, 'ro', 'filled'); hold on;
    plot(SOC_target*100, tau_interp, 'b-'); grid on;
    xlabel('SOC [%]'); ylabel('\tau [s]');
    title('Interpolated tau vs SOC');

    fprintf('인터폴레이션 후 146개의 R0, R1, tau 값을 포함한 새로운 데이터를 저장했습니다.\n');
end
