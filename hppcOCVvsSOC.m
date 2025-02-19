%% 스크립트 시작
clc; clear; close all;

%% 1. Groups.mat 파일에서 그룹 구조체 배열 불러오기 및 전압 데이터 추출
load('Groups.mat', 'groups');

% 0.5C 및 1C 구간 직전의 Rest 구간에서 단일(마지막) 데이터 포인트 추출
t_pre_0_5 = [];
V_pre_0_5 = [];
t_pre_1   = [];
V_pre_1   = [];

for k = 2:length(groups)
    if strcmpi(string(groups(k).step), "0.5C")
        if strcmpi(string(groups(k-1).step), "Rest")
            t_val = groups(k-1).t_seconds(end);
            V_val = groups(k-1).V(end);
            t_pre_0_5 = [t_pre_0_5; t_val];
            V_pre_0_5 = [V_pre_0_5; V_val];
        end
    end
    if strcmpi(string(groups(k).step), "1C")
        if strcmpi(string(groups(k-1).step), "Rest")
            t_val = groups(k-1).t_seconds(end);
            V_val = groups(k-1).V(end);
            t_pre_1 = [t_pre_1; t_val];
            V_pre_1 = [V_pre_1; V_val];
        end
    end
end

% 두 데이터셋을 하나로 결합하고, 시간 순으로 정렬
T_all = [t_pre_0_5; t_pre_1];
V_all = [V_pre_0_5; V_pre_1];
[Ts_sorted, sortIdx] = sort(T_all);
Vs_sorted = V_all(sortIdx);

%% 2. OCV Test 파일에서 OCV와 SOC 데이터 불러오기
data1 = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');
OCV_test = data1.meas.Voltage;
SOC_test = data1.meas.SOC;

%% 3. 보간법을 이용하여 Groups.mat에서 추출한 각 전압(Vs_sorted)에 해당하는 SOC 구하기
% 중복된 샘플점을 제거하여 보간에 사용할 고유한 값들 생성
[OCV_unique, uniqueIdx] = unique(OCV_test);
SOC_unique = SOC_test(uniqueIdx);

% Vs_sorted에 대응하는 SOC 값을 보간 (범위 밖도 extrapolation)
SOC_interp = interp1(OCV_unique, SOC_unique, Vs_sorted, 'linear', 'extrap');

%% 4. OCV vs SOC 그래프 그리기
figure;

% (1) OCV Test 파일의 OCV vs SOC 먼저 플롯
plot(SOC_test, OCV_test, '-b', 'LineWidth', 2, 'DisplayName', 'OCV Test Data');
hold on;

% (2) Groups.mat에서 추출한 데이터를 이용한 SOC vs OCV 플롯
plot(SOC_interp, Vs_sorted, 'ok', ...
     'LineWidth', 0.5, 'MarkerSize', 8, 'MarkerFaceColor', 'w', ...
     'DisplayName', 'Interpolated Data from Groups');

xlabel('SOC');
ylabel('OCV (V)');
title('OCV vs SOC');
legend('Location','best');
grid on;

%% 5. (선택사항) 결과 데이터 저장
ResultTable = table(SOC_interp, Vs_sorted, 'VariableNames', {'SOC', 'OCV'});
writetable(ResultTable, 'OCV_vs_SOC.xlsx');
fprintf('OCV vs SOC 데이터가 "OCV_vs_SOC.xlsx" 파일로 저장되었습니다.\n');
