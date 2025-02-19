%% 스크립트 시작
clc; clear; close all;

%% 1. Groups.mat 파일에서 그룹 구조체 배열 불러오기
load('Groups.mat', 'groups');  % groups 구조체 배열 불러오기
disp('불러온 groups 구조체 배열:');
disp(groups);

%% 2. "0.5C" 및 "1C" 충전 단계 바로 앞의 Rest 구간에서 단일(마지막) 데이터 포인트 추출
% 결과 저장용 배열 초기화
t_pre_0_5 = [];  % 0.5C 직전 Rest 그룹의 마지막 데이터 시간 (초)
V_pre_0_5 = [];  % 0.5C 직전 Rest 그룹의 마지막 데이터 전압

t_pre_1   = [];  % 1C 직전 Rest 그룹의 마지막 데이터 시간 (초)
V_pre_1   = [];  % 1C 직전 Rest 그룹의 마지막 데이터 전압

% groups 배열은 시간 순서대로 있다고 가정 (즉, 인덱스가 증가하면 시간이 진행됨)
for k = 2:length(groups)
    % 현재 그룹의 step 값이 "0.5C"인 경우
    if strcmpi(string(groups(k).step), "0.5C")
        % 바로 이전 그룹이 "Rest" 단계인지 확인
        if strcmpi(string(groups(k-1).step), "Rest")
            t_val = groups(k-1).t_seconds(end);
            V_val = groups(k-1).V(end);
            t_pre_0_5 = [t_pre_0_5; t_val];
            V_pre_0_5 = [V_pre_0_5; V_val];
        end
    end
    % 현재 그룹의 step 값이 "1C"인 경우
    if strcmpi(string(groups(k).step), "1C")
        % 바로 이전 그룹이 "Rest" 단계인지 확인
        if strcmpi(string(groups(k-1).step), "Rest")
            t_val = groups(k-1).t_seconds(end);
            V_val = groups(k-1).V(end);
            t_pre_1 = [t_pre_1; t_val];
            V_pre_1 = [V_pre_1; V_val];
        end
    end
end

%% 3. 두 데이터셋을 하나의 연속된 선으로 연결 (시간 순으로 정렬)
% 각 데이터셋에 해당하는 유형 정보를 추가합니다.
type_pre_0_5 = repmat("0.5C", length(t_pre_0_5), 1);
type_pre_1   = repmat("1C",   length(t_pre_1),   1);

% 데이터를 결합
T_all = [t_pre_0_5; t_pre_1];
V_all = [V_pre_0_5; V_pre_1];
Type_all = [type_pre_0_5; type_pre_1];

% 시간 순으로 정렬 (오름차순)
[Ts_sorted, sortIdx] = sort(T_all);
Vs_sorted = V_all(sortIdx);
Type_sorted = Type_all(sortIdx);

%% 4. 하나의 선으로 연결하고, 각 데이터 포인트에 해당하는 색상의 원 표시
figure;
hold on;
% 전체 데이터를 검은색 연속선으로 그리기
plot(Ts_sorted, Vs_sorted, '-k', 'LineWidth', 1.5);

% 각 데이터 포인트에 대해 marker 색상 설정:
% 0.5C이면 빨간색, 1C이면 파란색
idx_05 = strcmp(Type_sorted, "0.5C");
idx_1  = strcmp(Type_sorted, "1C");

% marker 크기는 50 (원하는 크기로 조정 가능)
scatter(Ts_sorted(idx_05), Vs_sorted(idx_05), 50, 'red', 'filled');
scatter(Ts_sorted(idx_1), Vs_sorted(idx_1), 50, 'blue', 'filled');

xlabel('Time (s)');
ylabel('Voltage (V)');
title('하나의 선으로 연결된 Rest 구간 데이터 (0.5C: 빨간색, 1C: 파란색)');
legend('연속 선', '0.5C 직전 Rest', '1C 직전 Rest', 'Location', 'best');
grid on;
hold off;
