clc;
clear;

% MAT 파일 로드
fileName = '03-11-17_08.47 25degC_5Pulse_HPPC_Pan18650PF.mat'; % MAT 파일 이름
data = load(fileName); % MAT 파일 로드

% 데이터 추출
time = data.meas.Time;       % 시간 데이터
current = data.meas.Current; % 전류 데이터
voltage = data.meas.Voltage; % 전압 데이터

% 허용 오차 설정
tolerance = 0.1;

% Step 할당 (기본값: REST)
step = strings(size(current)); % Step 배열 초기화

% Step 정의 조건
step(abs(current - (-1.45)) <= tolerance) = "0.5C";
step(abs(current - (-2.9))  <= tolerance) = "1C";
step(abs(current - (-5.8))  <= tolerance) = "2C";
step(abs(current - (-11.6)) <= tolerance) = "4C";
step(abs(current - (-17.4)) <= tolerance) = "6C";
step(abs(current) <= tolerance) = "REST"; % 전류가 0인 경우 REST

% 결과를 테이블로 저장
outputTable = table(time, current, voltage, step, ...
    'VariableNames', {'Time', 'Current', 'Voltage', 'Step'});

% 엑셀 파일로 저장
outputExcelFile = '03-11-17_5Pulse_HPPC_Steps.xlsx';
writetable(outputTable, outputExcelFile);

disp(['Step 데이터가 엑셀 파일로 저장되었습니다: ', outputExcelFile]);
