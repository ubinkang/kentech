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

%% 2. OCV Test 파일에서 데이터 불러오기
data1 = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');
OCV_test = data1.meas.Voltage;
SOC_test = data1.meas.SOC;

% 아래 변수(State 관련)는 실제 데이터 구조를 확인한 뒤 맞춰주세요.
% 예: data1.meas.State 에 "Charge", "Discharge", "Rest" 등의 문자열이 들어있을 수 있음
%     또는 숫자로 구분되어 있을 수 있음.
%
% 여기서는 예시로 data1.meas.State라는 필드가 있고
% "Discharge"인 구간만 골라낸다고 가정하겠습니다.
state_test = data1.meas.state;

% 방전(discharge) 상태인 인덱스만 추출
dischargeIdx = strcmpi(state_test, "Discharge");

% discharge 상태에서의 OCV 및 SOC
OCV_discharge = OCV_test(dischargeIdx);
SOC_discharge = SOC_test(dischargeIdx);

%% 3. 보간법을 이용하여 Groups.mat에서 추출한 각 전압(Vs_sorted)에 해당하는 SOC 구하기
% 먼저, 중복된 샘플 제거 -> 유일한 OCV, SOC 쌍 만들기
[OCV_unique, uniqueIdx] = unique(OCV_discharge);
SOC_unique = SOC_discharge(uniqueIdx);

% Vs_sorted에 대응하는 SOC 값을 보간 (범위 밖도 extrapolation)
SOC_interp = interp1(OCV_unique, SOC_unique, Vs_sorted, 'linear', 'extrap');

%% 4. OCV vs SOC 그래프 그리기
figure;

% (1) 방전 구간에서 추출한 OCV vs SOC 먼저 플롯
plot(SOC_discharge, OCV_discharge, '-b', 'LineWidth', 2, 'DisplayName', 'OCV Test Data (Discharge)');
hold on;

% (2) Groups.mat에서 추출한 데이터를 이용한 SOC vs OCV 플롯
plot(SOC_interp, Vs_sorted, 'ok', ...
     'LineWidth', 0.5, 'MarkerSize', 8, 'MarkerFaceColor', 'w', ...
     'DisplayName', 'Interpolated Data from Groups');

xlabel('SOC');
ylabel('OCV (V)');
title('OCV vs SOC (방전 구간 기반)');
legend('Location','best');
grid on;

%% 5. (선택사항) 결과 데이터 저장
ResultTable = table(SOC_interp, Vs_sorted, 'VariableNames', {'SOC', 'OCV'});
writetable(ResultTable, 'OCV_vs_SOC.xlsx');
fprintf('OCV vs SOC 데이터가 "OCV_vs_SOC.xlsx" 파일로 저장되었습니다.\n');
