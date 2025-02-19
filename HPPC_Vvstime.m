clc;
clear;

% MAT 파일 로드
matFileName = '03-11-17_5Pulse_HPPC_Steps.mat'; % MAT 파일 이름
load(matFileName);

% Step 데이터를 문자열로 변환 (만약 cell형태라면)
if iscell(step)
    step = string(step); % 셀 배열을 문자열 배열로 변환
end

% 0.5C에 해당하는 인덱스 찾기
step_05C_indices = find(step == "0.5C");

% 최종 인덱스 저장을 위한 배열
final_indices = [];
segments = {};

% 각 0.5C 구간에 대해 앞뒤로 Rest 30개 추가
for i = 1:length(step_05C_indices)
    idx = step_05C_indices(i);

    % 앞뒤 Rest 구간 인덱스
    rest_before = max(1, idx - 30):idx - 1;  % 앞쪽 30개
    rest_after = idx + 1:min(length(time), idx + 30);  % 뒤쪽 30개

    % 인덱스 추가 (중복 방지를 위해 unique 사용)
    segment_indices = unique([rest_before, idx, rest_after]);
    segments{end+1} = segment_indices;
end

% 그래프 그리기 (점으로 표시)
figure;
hold on;
for j = 1:length(segments)
    segment = segments{j};
    scatter(time(segment), voltage(segment), 10, 'b', 'filled'); % 파란색 점 그래프
    plot(time(segment), voltage(segment), 'b-'); % 연결선 추가 (같은 trip 연결)
end
hold off;

xlabel('Time (s)');
ylabel('Voltage (V)');
title('Voltage vs Time for 0.5C with 30 Rest Points Before and After Each');
grid on;

% 선택된 step도 출력해서 검증
disp('Selected step values:');
for j = 1:length(segments)
    disp(step(segments{j}));
end

% 그래프 저장
outputGraphFile = 'Voltage_vs_Time_0.5C_Discrete_With_30_Rest_Fixed_Per_Section.png';
saveas(gcf, outputGraphFile);
disp(['0.5C 전류 구간 + Rest 30개씩 개별 데이터 포인트 그래프가 저장되었습니다: ', outputGraphFile]);
