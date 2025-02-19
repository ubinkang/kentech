clc;
clear;

% 엑셀 파일 로드
excelFileName = '03-11-17_5Pulse_HPPC_Steps.xlsx'; % 엑셀 파일 이름
dataTable = readtable(excelFileName); % 엑셀 파일 읽기

% 테이블의 각 열을 개별 변수로 저장
time = dataTable.Time;         % 시간 데이터
current = dataTable.Current;   % 전류 데이터
voltage = dataTable.Voltage;   % 전압 데이터
step = dataTable.Step;         % Step 데이터 (문자열)

% 새로운 MAT 파일로 저장
matFileName = '03-11-17_5Pulse_HPPC_Steps.mat';
save(matFileName, 'time', 'current', 'voltage', 'step');

disp(['엑셀 데이터를 MAT 파일로 변환하여 저장하였습니다: ', matFileName]);