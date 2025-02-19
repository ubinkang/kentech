function covariance_plot()
    clc; clear; close all;
    
    %% 1. 데이터 로드
    data = load('Interpolated_R_1RC_Params.mat');
    new_data = data.new_data;

    % 개별 변수 추출 (SOC 제외)
    R_peak = new_data.R_peak(:);
    R0 = new_data.R0(:);
    R1 = new_data.R1(:);
    tau = new_data.tau(:);

    % 변수명을 리스트로 저장
    variables = {'R_peak', 'R0', 'R1', 'tau'};
    values = {R_peak, R0, R1, tau};
    
    % 4x4 서브플롯 생성
    figure('Name', 'Covariance Plot', 'Color', 'w');
    set(gcf, 'Units', 'pixels', 'Position', [100, 100, 1000, 900]);
    
    num_vars = length(variables);
    
    for i = 1:num_vars
        for j = 1:num_vars
            subplot(num_vars, num_vars, (i - 1) * num_vars + j);
            scatter(values{j}, values{i}, 15, 'b', 'filled');
            xlabel(variables{j});
            ylabel(variables{i});
            grid on;
            if i == j
                title(['Distribution of ', variables{i}]);
            end
        end
    end
    
    sgtitle('Pairwise Covariance Scatter Plots');
end
