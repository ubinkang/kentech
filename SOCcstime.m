%% 스크립트 시작
clc; clear; close all;

%% 1. Groups.mat 파일에서 그룹 구조체 배열 불러오기 및 Rest 구간의 시간 추출
load('Groups.mat', 'groups');  % Groups.mat 파일에는 이전 단계에서 생성한 groups 배열이 저장되어 있음
disp('불러온 groups 구조체 배열:');
disp(groups);

% 0.5C pulse 바로 앞 Rest 구간의 시간(t_seconds) 추출
t_pre_0_5 = [];  % 0.5C 직전 Rest 그룹의 마지막 데이터 시간 (초)
t_pre_1   = [];  % 1C 직전 Rest 그룹의 마지막 데이터 시간 (초)

for k = 2:length(groups)
    % 0.5C pulse의 경우: 바로 이전 그룹이 Rest이면 해당 그룹의 마지막 시간 추출
    if strcmpi(string(groups(k).step), "0.5C")
        if strcmpi(string(groups(k-1).step), "Rest")
            t_val = groups(k-1).t_seconds(end);
            t_pre_0_5 = [t_pre_0_5; t_val];
        end
    end
    % 1C pulse의 경우: 바로 이전 그룹이 Rest이면 해당 그룹의 마지막 시간 추출
    if strcmpi(string(groups(k).step), "1C")
        if strcmpi(string(groups(k-1).step), "Rest")
            t_val = groups(k-1).t_seconds(end);
            t_pre_1 = [t_pre_1; t_val];
        end
    end
end

%% 2. NewPulseData.mat 파일에서 새 구조체(newStruct) 불러오기
% newStruct 배열의 각 원소는 각 0.5C pulse에 대해 다음 필드를 포함함:
% - current : 0.5C pulse 내 전류 벡터
% - voltage : 0.5C pulse 내 전압 벡터
% - restVoltage_pre_05 : 해당 pulse 바로 앞 Rest 구간의 마지막 전압 (스칼라)
% - restVoltage_pre_1  : 해당 pulse 이후 처음 나타난 1C pulse 바로 앞 Rest 구간의 마지막 전압 (스칼라)
% - SOC_rest_pre_05 : restVoltage_pre_05에 대응하는 SOC (보간된 값)
% - SOC_rest_pre_1  : restVoltage_pre_1에 대응하는 SOC (보간된 값)
load('NewPulseData.mat', 'newStruct');
disp('불러온 newStruct (NewPulseData.mat):');
disp(newStruct);

%% 3. newStruct에서 SOC 데이터를 추출 (각 pulse별)
% newStruct 배열의 길이는 0.5C pulse의 개수와 동일하다고 가정합니다.
% 각각에 대해, SOC_rest_pre_05와 SOC_rest_pre_1 값을 추출합니다.
SOC_05 = [];  % 0.5C pulse 직전 Rest에 대응하는 SOC (보간값)
SOC_1 = [];   % 1C pulse 직전 Rest에 대응하는 SOC (보간값)

for i = 1:length(newStruct)
    SOC_05(i,1) = newStruct(i).SOC_rest_pre_05;
    SOC_1(i,1) = newStruct(i).SOC_rest_pre_1;
end

%% 4. 두 데이터셋(0.5C와 1C)에 대해 시간과 SOC를 결합 및 정렬
% t_pre_0_5와 SOC_05는 같은 순서라고 가정
% t_pre_1와 SOC_1는 같은 순서라고 가정

% 결합 (세로로 이어붙임)
T_all = [t_pre_0_5; t_pre_1];
SOC_all = [SOC_05; SOC_1];

% 각 데이터셋에 해당하는 유형 정보 추가
type_05 = repmat("0.5C", length(t_pre_0_5), 1);
type_1  = repmat("1C",   length(t_pre_1), 1);
Type_all = [type_05; type_1];

% 시간 순으로 정렬 (오름차순)
[Ts_sorted, sortIdx] = sort(T_all);
SOC_sorted = SOC_all(sortIdx);
Type_sorted = Type_all(sortIdx);

%% 5. SOC vs Time 그래프 그리기
figure;
hold on;
% 전체 데이터를 검은색 연속선으로 그리기
plot(Ts_sorted, SOC_sorted, '-k', 'LineWidth', 1.5);

% 각 데이터 포인트에 대해 marker 색상 설정:
% 0.5C이면 빨간색, 1C이면 파란색
idx_05 = strcmp(Type_sorted, "0.5C");
idx_1  = strcmp(Type_sorted, "1C");

% 각 데이터 포인트를 원(marker)으로 표시 (크기 50)
scatter(Ts_sorted(idx_05), SOC_sorted(idx_05), 50, 'red', 'filled');
scatter(Ts_sorted(idx_1), SOC_sorted(idx_1), 50, 'blue', 'filled');

xlabel('Time (s)');
ylabel('SOC');
title('SOC vs Time (OCV에 대응되는 SOC, NewPulseData.mat 기준)');
legend('연속 선', '0.5C Rest SOC', '1C Rest SOC', 'Location', 'best');
grid on;
hold off;

%% 6. 결과 출력 메시지
fprintf('SOC vs Time 그래프가 생성되었습니다.\n');
