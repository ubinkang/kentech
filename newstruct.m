%% 스크립트 시작
clc; clear; close all;

%% 1. Groups.mat 파일에서 그룹 구조체 배열 불러오기
% Groups.mat 파일에는 이전 단계에서 생성한 groups 구조체 배열이 저장되어 있다고 가정합니다.
load('Groups.mat', 'groups');

% groups 구조체 배열 확인 (각 그룹에는 필드: groupIndex, step, V, I, t, t_seconds 등이 있음)
disp('불러온 groups 구조체 배열:');
disp(groups);

%% 2. 0.5C pulse에 대해 각 pulse마다 데이터 계산 및 저장 
% (전류, 전압, 시간은 벡터로, Rest 전압은 스칼라로)
% 필드명을 수정: restVoltage_pre_05 -> V_final, restVoltage_pre_1 -> V_after,
% SOC_rest_pre_05 -> SOC_begin, SOC_rest_pre_1 -> SOC_end
newStruct = struct('current', {}, 'voltage', {}, 'time', {}, ...
                   'V_final', {}, 'V_after', {});
pulseIndex = 0;  % 0.5C pulse 개수 카운터

for k = 1:length(groups)
    % 현재 그룹의 step 값이 "0.5C"인지 확인 (대소문자 구분 없이)
    if strcmpi(string(groups(k).step), "0.5C")
        pulseIndex = pulseIndex + 1;
        s = struct();
        
        % 해당 0.5C pulse의 전류, 전압, 시간 벡터 데이터를 그대로 저장
        s.current = groups(k).I;    % 벡터 데이터
        s.voltage = groups(k).V;      % 벡터 데이터
        s.time    = groups(k).t_seconds; % 시간 벡터 (t 대신 t_seconds 사용)
        
        % 해당 0.5C pulse 바로 앞 그룹이 Rest이면 그 그룹의 마지막 전압 값을 스칼라로 저장, 아니면 NaN
        if k > 1 && strcmpi(string(groups(k-1).step), "Rest")
            s.V_final = groups(k-1).V(end);
        else
            s.V_final = NaN;
        end
        
        % 0.5C pulse 이후부터 처음 나타나는 1C pulse의 바로 앞 그룹(즉, Rest)의 마지막 전압을 찾음
        s.V_after = NaN;  % 초기값
        for j = k+1 : length(groups)
            if strcmpi(string(groups(j).step), "1C")
                if j > 1 && strcmpi(string(groups(j-1).step), "Rest")
                    s.V_after = groups(j-1).V(end);
                end
                break;  % 첫 번째 1C pulse만 사용
            end
        end
        
        % 새로운 구조체 배열에 추가
        newStruct(pulseIndex) = s;
    end
end

%% 3. OCV Test 파일에서 방전(Discharge) 과정에 해당하는 OCV, SOC 데이터 불러오기
% 파일 이름: "05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat"
dataOCV = load('05-08-17_13.26 C20 OCV Test_C20_25dC_with_SOC.mat');

% OCV, SOC, state 데이터를 불러옴 (state 값이 "Discharge"인 경우만 사용)
OCV_all   = dataOCV.meas.Voltage;
SOC_all   = dataOCV.meas.SOC;
state_all = dataOCV.meas.state;

% 방전 과정에 해당하는 인덱스 선택 (state가 "Discharge")
discharge_idx = strcmpi(state_all, 'Discharge');
OCV_test = OCV_all(discharge_idx);
SOC_test = SOC_all(discharge_idx);

% 보간에 사용할 샘플점으로 중복 제거 (interp1 함수는 X 값이 고유해야 함)
[OCV_unique, uniqueIdx] = unique(OCV_test);
SOC_unique = SOC_test(uniqueIdx);

%% 4. 각 0.5C pulse 구조체에 대해, Rest 전압에 해당하는 SOC 값을 보간하여 추가
% 필드명을 수정: SOC_rest_pre_05 -> SOC_begin, SOC_rest_pre_1 -> SOC_end
for i = 1:length(newStruct)
    % 0.5C pulse 바로 앞 Rest 전압에 해당하는 SOC 값 (SOC_begin)
    if ~isnan(newStruct(i).V_final)
        newStruct(i).SOC_begin = interp1(OCV_unique, SOC_unique, ...
                                          newStruct(i).V_final, 'linear', 'extrap');
    else
        newStruct(i).SOC_begin = NaN;
    end
    % 1C pulse 바로 앞 Rest 전압에 해당하는 SOC 값 (SOC_end)
    if ~isnan(newStruct(i).V_after)
        newStruct(i).SOC_end = interp1(OCV_unique, SOC_unique, ...
                                        newStruct(i).V_after, 'linear', 'extrap');
    else
        newStruct(i).SOC_end = NaN;
    end
end

%% 5. 결과 확인 및 저장
disp('새로운 구조체 배열 (각각의 0.5C pulse마다):');
disp(newStruct);

% 새로운 구조체 배열을 MAT 파일로 저장 (예: NewPulseData.mat)
save('NewPulseData.mat', 'newStruct');
fprintf('새로운 구조체 배열이 "NewPulseData.mat" 파일로 저장되었습니다.\n');
