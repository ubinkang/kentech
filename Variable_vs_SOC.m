function plot_R_1RC_vs_SOC()
    clc; clear; close all;
    
    %% 1. MAT 파일 불러오기
    data = load('Interpolated_R_1RC_Params.mat');
    new_data = data.new_data;

    %% 2. 개별 변수 추출 (SOC 포함)
    R_peak = new_data.R_peak(:);
    R0 = new_data.R0(:);
    R1 = new_data.R1(:);
    tau = new_data.tau(:);
    SOC = new_data.SOC(:) * 100; % SOC를 % 단위로 변환

    %% 3. 그래프 설정 및 플로팅
    figure('Name', 'R and 1RC Parameters vs SOC', 'Color', 'w');
    
    subplot(2,2,1);
    scatter(SOC, R_peak, 20, 'b', 'filled');
    xlabel('SOC [%]');
    ylabel('R_{peak} [mΩ]');
    title('R_{peak} vs SOC');
    grid on;

    subplot(2,2,2);
    scatter(SOC, R0, 20, 'r', 'filled');
    xlabel('SOC [%]');
    ylabel('R0 [Ω]');
    title('R0 vs SOC');
    grid on;

    subplot(2,2,3);
    scatter(SOC, R1, 20, 'g', 'filled');
    xlabel('SOC [%]');
    ylabel('R1 [Ω]');
    title('R1 vs SOC');
    grid on;

    subplot(2,2,4);
    scatter(SOC, tau, 20, 'm', 'filled');
    xlabel('SOC [%]');
    ylabel('Tau [s]');
    title('\tau vs SOC');
    grid on;
    
    set(gcf, 'Position', [100, 100, 1000, 800]); % 창 크기 조정
end
