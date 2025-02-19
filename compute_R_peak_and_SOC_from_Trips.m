function compute_R_peak_and_SOC_from_allTrips()
    
    
    %% 1. Trips.mat 파일 불러오기
    load('Trips.mat', 'trips');  
    Ntrips = numel(trips);
    fprintf('총 %d개의 트립(충전/방전 이벤트)이 로드되었습니다.\n', Ntrips);
    
    %% 2. 모든 트립에 대해 positive current 조건을 만족하는 피크에서 R_peak와 해당 SOC 추출
    all_R_peak = [];
    all_SOC_peak = [];
    
    for i = 1:Ntrips
        % 각 트립 데이터 추출
        t = trips(i).time;       % 시간
        c = trips(i).current;    % 전류
        v = trips(i).voltage;    % 전압
        ocv = trips(i).OCV;      % OCV
        soc = trips(i).SOC;      % SOC
        
        % t가 duration 타입이면 초(sec)로 변환
        if isduration(t)
            t = seconds(t);
        end
        
        %% 3. findpeaks로 전압의 국소 최대 찾기
        [pksMaxAll, idxMaxAll] = findpeaks(v, 'MinPeakProminence', 0.02);
        
        %% 4. 전류 조건 필터링 (전류가 양수인 피크만 선택)
        condMax = (c(idxMaxAll) > 2.3);
        idxMax = idxMaxAll(condMax);
        pksMax = pksMaxAll(condMax);
        
        %% 5. 각 선택된 피크에서 R_peak와 해당 SOC 계산
        % 임피던스 계산: R = (OCV - v_peak) / |current_peak|, mΩ 단위로 변환, 절대값 처리
        for j = 1:length(idxMax)
            idx_peak = idxMax(j);
            % R_inst 계산 후 절대값 처리
            R_inst = abs((ocv(idx_peak) - v(idx_peak)) / abs(c(idx_peak)));
            R_val = 1000 * R_inst;  % mΩ 단위
            all_R_peak = [all_R_peak; R_val];  %#ok<AGROW>
            all_SOC_peak = [all_SOC_peak; soc(idx_peak)];  %#ok<AGROW>
        end
    end
    
    %% 6. 결과 저장 (.mat 파일)
    R_peak_struct.R_peak = all_R_peak;
    R_peak_struct.SOC = all_SOC_peak;
    save('R_peak_and_SOC.mat', 'R_peak_struct');
    
    %% 7. 결과 출력 및 간단한 플로팅
    fprintf('총 %d개의 positive current peak 임피던스가 추출되었습니다.\n', length(all_R_peak));
    disp(R_peak_struct);
    
    figure;
    scatter(all_SOC_peak*100, all_R_peak, 50, 'filled');
    xlabel('SOC [%]');
    ylabel('R_{peak} (m\Omega)');
    title('Positive Current Peaks: R_{peak} vs SOC');
    grid on;
end
