% 1. 파일 불러오기
data = load('05-08-17_13.26 C20 OCV Test_C20_25dC.mat');

% 2. 전류(Current) 데이터 추출 (대소문자 주의)
current = data.meas.Current;

% 3. step 배열 초기화 (전류 크기만큼)
step = zeros(size(current));

% 4. 조건에 따라 step 값 할당

% (1) 처음 전류가 0인 구간 (step 1)
first_zero_end = find(current ~= 0, 1) - 1;
if isempty(first_zero_end)
    first_zero_end = length(current);
end
step(1:first_zero_end) = 1;

% (2) 전류가 -0.15에서 절대값 0.01 차이나는 구간 (step 2)
neg_idx = find(abs(current - (-0.15)) <= 0.01);
step(neg_idx) = 2;

% (3) 전류가 다시 0으로 돌아온 구간 (step 3, step 2 이후)
if ~isempty(neg_idx)
    next_zero_start = find(current(neg_idx(end):end) == 0, 1) + neg_idx(end) - 1;
    next_zero_end = find(current(next_zero_start:end) ~= 0, 1) + next_zero_start - 2;
    if isempty(next_zero_end)
        next_zero_end = length(current);
    end
    step(next_zero_start:next_zero_end) = 3;
end

% (4) 전류가 0.15에서 절대값 0.01 차이나는 구간 (step 4)
pos_idx = find(abs(current - 0.15) <= 0.01);
step(pos_idx) = 4;

% (5) 전류가 다시 0으로 돌아온 구간 (step 5, step 4 이후)
if ~isempty(pos_idx)
    final_zero_start = find(current(pos_idx(end):end) == 0, 1) + pos_idx(end) - 1;
    final_zero_end = find(current(final_zero_start:end) ~= 0, 1) + final_zero_start - 2;
    if isempty(final_zero_end)
        final_zero_end = length(current);
    end
    step(final_zero_start:final_zero_end) = 5;
end

% 5. step 데이터를 meas 구조체에 추가
data.meas.step = step;

% 6. 변경된 데이터를 새로운 MAT 파일로 저장
save('05-08-17_13.26 C20 OCV Test_C20_25dC_updated.mat', '-struct', 'data');

% 7. 결과 확인을 위한 step 데이터 출력
disp('Step data successfully added to the MAT file.');

% 8. 시각화 확인
figure;
plot(data.meas.Time, step);
title('Step vs Time');
xlabel('Time');
ylabel('Step');
grid on;
