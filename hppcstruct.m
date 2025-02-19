%% 스크립트 시작
clc; clear; close all;

%% 1. MAT 파일 불러오기
loadedData = load('Step_Data.mat');
T = loadedData.T;  % 테이블 T (변수명: 'Time', 'Current', 'Voltage', 'Step')

% 테이블의 변수명 확인 (출력 결과: {'Time'} {'Current'} {'Voltage'} {'Step'})
disp('T 테이블의 변수명:');
disp(T.Properties.VariableNames);

%% 2. 데이터 전처리
% Time 변수가 문자열/셀 배열이면 duration으로 변환하거나,
% 이미 duration 또는 숫자(초)라면 적절히 처리합니다.
if iscellstr(T.Time) || isstring(T.Time)
    time = duration(T.Time);
elseif isa(T.Time, 'duration')
    time = T.Time;
else
    % 예를 들어, T.Time이 숫자(초)로 저장된 경우
    time = seconds(T.Time);
end

% 나머지 데이터 추출
current = T.Current;   % 전류
voltage = T.Voltage;   % 전압
stepVal = T.Step;      % 그룹화에 사용할 Step 값

%% 3. 연속 구간별 그룹화 (같은 Step 값이 연속된 구간마다 별도의 그룹으로 묶음)
% 그룹별 구조체 배열: fields - groupIndex, step, V, I, t, t_seconds
groups = struct('groupIndex', {}, 'step', {}, 'V', {}, 'I', {}, 't', {}, 't_seconds', {});

groupCount = 1; % 그룹 인덱스
% 첫 번째 행으로 초기 그룹 설정
temp_V = voltage(1);
temp_I = current(1);
temp_t = time(1);

% 테이블은 시간 순서대로 있다고 가정
for i = 2:height(T)
    % 만약 현재 행의 Step 값이 이전 행과 같다면 같은 그룹에 추가
    if stepVal(i) == stepVal(i-1)
        temp_V(end+1,1) = voltage(i);
        temp_I(end+1,1) = current(i);
        temp_t(end+1,1) = time(i);
    else
        % 구간이 바뀌었으므로 이전 그룹을 구조체 배열에 저장
        groups(groupCount).groupIndex = groupCount;
        groups(groupCount).step = stepVal(i-1);
        groups(groupCount).V = temp_V;
        groups(groupCount).I = temp_I;
        groups(groupCount).t = temp_t;
        groups(groupCount).t_seconds = seconds(temp_t);
        
        % 새 그룹으로 초기화
        groupCount = groupCount + 1;
        temp_V = voltage(i);
        temp_I = current(i);
        temp_t = time(i);
    end
end

% 마지막 그룹 저장 (루프 종료 후 남은 데이터)
groups(groupCount).groupIndex = groupCount;
groups(groupCount).step = stepVal(end);
groups(groupCount).V = temp_V;
groups(groupCount).I = temp_I;
groups(groupCount).t = temp_t;
groups(groupCount).t_seconds = seconds(temp_t);

%% 4. 결과 확인
disp('연속 구간별 그룹화된 구조체 배열:');
disp(groups);

% 예시: 첫 번째 그룹 데이터 출력
fprintf('그룹 %d (Step %d) 데이터:\n', groups(1).groupIndex, double(groups(1).step));
disp(groups(1));

%% 5. 구조체 배열을 MAT 파일로 저장
save('Groups.mat', 'groups');
fprintf('구조체 배열 groups가 "Groups.mat" 파일로 저장되었습니다.\n');
