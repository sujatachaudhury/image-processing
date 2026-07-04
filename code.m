clc; clear; close all;

%%  Task 1 — Load images


% Please cd to the base directory containing 
% the natural and out of focus images.
raw_out = double(imread("outoffocus.tiff"));
raw_nat = double(imread("natural.tiff"));

disp(size(raw_out));
disp(size(raw_nat));

[m,n] = size(raw_nat); % same for both


%%  Task 2 — Visualize raw images and illustrate Bayer mosaic


figure; 
subplot(1,2,1); imagesc(raw_out); colormap gray; axis image off;
title("Out-of-focus RAW image");

subplot(1,2,2); imagesc(raw_nat); colormap gray; axis image off;
title("Natural RAW image");

% Bayer mosaic pattern visualization (assumed RGGB)

pattern = ["R" "G"; "G" "B"];   % RGGB
alpha = 0.5;                    % transparency of the overlayed pattern

% CFA color gets multiplied by the raw intensity with an alpha:
% (1–alpha)*raw_gray + alpha*(raw_pixel*CFA_color) 
% To overlay the Bayer Pattern on the images 
overlay_out = make_cfa_visualization(raw_out, pattern, alpha);
overlay_nat = make_cfa_visualization(raw_nat, pattern, alpha);

figure; imshow(overlay_out); title("CFA Visualization – Out-of-Focus");
figure; imshow(overlay_nat); title("CFA Visualization – Natural");


%% Task 3 - Extract 4 Bayer Subchannels (Assuming RGGB)

% Bayer channels (each is m/2 × n/2)
R_out  = raw_out(1:2:end, 1:2:end);
G1_out = raw_out(1:2:end, 2:2:end);
G2_out = raw_out(2:2:end, 1:2:end);
B_out  = raw_out(2:2:end, 2:2:end);

R_nat  = raw_nat(1:2:end, 1:2:end);
G1_nat = raw_nat(1:2:end, 2:2:end);
G2_nat = raw_nat(2:2:end, 1:2:end);
B_nat  = raw_nat(2:2:end, 2:2:end);

% Visualization
figure;
subplot(2,2,1); imagesc(R_out);  colormap gray; axis image off; title("R (out)");
subplot(2,2,2); imagesc(G1_out); colormap gray; axis image off; title("G1 (out)");
subplot(2,2,3); imagesc(G2_out); colormap gray; axis image off; title("G2 (out)");
subplot(2,2,4); imagesc(B_out);  colormap gray; axis image off; title("B (out)");

figure;
subplot(2,2,1); imagesc(R_nat);  colormap gray; axis image off; title("R (natural)");
subplot(2,2,2); imagesc(G1_nat); colormap gray; axis image off; title("G1 (natural)");
subplot(2,2,3); imagesc(G2_nat); colormap gray; axis image off; title("G2 (natural)");
subplot(2,2,4); imagesc(B_nat);  colormap gray; axis image off; title("B (natural)");
%% Task 4 -  Mean–Variance Analysis on Out-of-Focus Image

windowSize = [15 15]; 

fun_mean = @(block) compute_stats(block.data, "mean");
fun_var  = @(block) compute_stats(block.data, "var");

% Compute stats using blockproc
mean_R  = blockproc(R_out,  windowSize, fun_mean);
var_R   = blockproc(R_out,  windowSize, fun_var);

mean_G1 = blockproc(G1_out, windowSize, fun_mean);
var_G1  = blockproc(G1_out, windowSize, fun_var);

mean_G2 = blockproc(G2_out, windowSize, fun_mean);
var_G2  = blockproc(G2_out, windowSize, fun_var);

mean_B  = blockproc(B_out,  windowSize, fun_mean);
var_B   = blockproc(B_out,  windowSize, fun_var);

% Convert to vectors
mv_R  = mean_R(:);  vv_R  = var_R(:);
mv_G1 = mean_G1(:); vv_G1 = var_G1(:);
mv_G2 = mean_G2(:); vv_G2 = var_G2(:);
mv_B  = mean_B(:);  vv_B  = var_B(:);

% Scatterplots
figure;

subplot(2,2,1); scatter(mv_R, vv_R, 5, 'r', 'filled');
xlabel("Mean"); ylabel("Variance");
title("R channel mean–variance"); grid on;

subplot(2,2,2); scatter(mv_G1, vv_G1, 5, 'g', 'filled');
xlabel("Mean"); ylabel("Variance");
title("G1 channel mean–variance"); grid on;

subplot(2,2,3); scatter(mv_G2, vv_G2, 5, 'g', 'filled');
xlabel("Mean"); ylabel("Variance");
title("G2 channel mean–variance"); grid on;

subplot(2,2,4); scatter(mv_B, vv_B, 5, 'b', 'filled');
xlabel("Mean"); ylabel("Variance");
title("B channel mean–variance"); grid on;

%% Task 5 - Fit affine variance relations

% Fit variance = a*mean + b for each channel
coef_R  = robustfit(mv_R,  vv_R);   
coef_G1 = robustfit(mv_G1, vv_G1);
coef_G2 = robustfit(mv_G2, vv_G2);
coef_B  = robustfit(mv_B,  vv_B);

% Extract slopes (a) and intercepts (b)
b_R  = coef_R(1);  a_R  = coef_R(2);
b_G1 = coef_G1(1); a_G1 = coef_G1(2);
b_G2 = coef_G2(1); a_G2 = coef_G2(2);
b_B  = coef_B(1);  a_B  = coef_B(2);

% Display results
fprintf("R:   variance = %.4g * mean + %.4g\n", a_R,  b_R);
fprintf("G1:  variance = %.4g * mean + %.4g\n", a_G1, b_G1);
fprintf("G2:  variance = %.4g * mean + %.4g\n", a_G2, b_G2);
fprintf("B:   variance = %.4g * mean + %.4g\n", a_B,  b_B);

%Plot the fitted lines over each scatterplot
% x values for the fitted line
x_R  = linspace(min(mv_R),  max(mv_R),  200);
x_G1 = linspace(min(mv_G1), max(mv_G1), 200);
x_G2 = linspace(min(mv_G2), max(mv_G2), 200);
x_B  = linspace(min(mv_B),  max(mv_B),  200);

figure;

% R channel
subplot(2,2,1);
scatter(mv_R, vv_R, 5, 'r', 'filled'); hold on;
plot(x_R, a_R*x_R + b_R, 'k', 'LineWidth', 2);
title("R channel mean–variance + fitted line");
xlabel("Mean"); ylabel("Variance");
grid on;

% G1 channel
subplot(2,2,2);
scatter(mv_G1, vv_G1, 5, 'g', 'filled'); hold on;
plot(x_G1, a_G1*x_G1 + b_G1, 'k', 'LineWidth', 2);
title("G1 channel mean–variance + fitted line");
xlabel("Mean"); ylabel("Variance");
grid on;

% G2 channel
subplot(2,2,3);
scatter(mv_G2, vv_G2, 5, 'g', 'filled'); hold on;
plot(x_G2, a_G2*x_G2 + b_G2, 'k', 'LineWidth', 2);
title("G2 channel mean–variance + fitted line");
xlabel("Mean"); ylabel("Variance");
grid on;

% B channel
subplot(2,2,4);
scatter(mv_B, vv_B, 5, 'b', 'filled'); hold on;
plot(x_B, a_B*x_B + b_B, 'k', 'LineWidth', 2);
title("B channel mean–variance + fitted line");
xlabel("Mean"); ylabel("Variance");
grid on;

sgtitle("Mean–Variance Scatterplots with Fitted Lines");


%% Task 6 - Apply the Anscombe Transform

% Out-of-focus (Anscombe domain)
R_out_A  = apply_anscombe_transform(R_out,  a_R,  b_R);
G1_out_A = apply_anscombe_transform(G1_out, a_G1, b_G1);
G2_out_A = apply_anscombe_transform(G2_out, a_G2, b_G2);
B_out_A  = apply_anscombe_transform(B_out,  a_B,  b_B);

% Natural image (Anscombe domain)
R_nat_A  = apply_anscombe_transform(R_nat,  a_R,  b_R);
G1_nat_A = apply_anscombe_transform(G1_nat, a_G1, b_G1);
G2_nat_A = apply_anscombe_transform(G2_nat, a_G2, b_G2);
B_nat_A  = apply_anscombe_transform(B_nat,  a_B,  b_B);

%% Task 7 - Mean-variance Scatterplots of the transformed out-of-focus

windowSize = [15 15]; 

fun_mean = @(block) compute_stats(block.data, "mean");
fun_var  = @(block) compute_stats(block.data, "var");

% Red channel
mean_RA = blockproc(R_out_A, windowSize, fun_mean);
var_RA  = blockproc(R_out_A, windowSize, fun_var);

% Green 1
mean_G1A = blockproc(G1_out_A, windowSize, fun_mean);
var_G1A  = blockproc(G1_out_A, windowSize, fun_var);

% Green 2
mean_G2A = blockproc(G2_out_A, windowSize, fun_mean);
var_G2A  = blockproc(G2_out_A, windowSize, fun_var);

% Blue
mean_BA = blockproc(B_out_A, windowSize, fun_mean);
var_BA  = blockproc(B_out_A, windowSize, fun_var);

% Flatten & remove NaNs
mv_RA  = mean_RA(:);  vv_RA  = var_RA(:);
mv_G1A = mean_G1A(:); vv_G1A = var_G1A(:);
mv_G2A = mean_G2A(:); vv_G2A = var_G2A(:);
mv_BA  = mean_BA(:);  vv_BA  = var_BA(:);

mask = ~isnan(mv_RA)  & ~isnan(vv_RA);  mv_RA  = mv_RA(mask);   vv_RA  = vv_RA(mask);
mask = ~isnan(mv_G1A) & ~isnan(vv_G1A); mv_G1A = mv_G1A(mask);  vv_G1A = vv_G1A(mask);
mask = ~isnan(mv_G2A) & ~isnan(vv_G2A); mv_G2A = mv_G2A(mask);  vv_G2A = vv_G2A(mask);
mask = ~isnan(mv_BA)  & ~isnan(vv_BA);  mv_BA  = mv_BA(mask);   vv_BA  = vv_BA(mask);

% Visualization
figure;

subplot(2,2,1); scatter(mv_RA, vv_RA, 5, 'r', 'filled');
xlabel("Mean"); ylabel("Variance");
title("R channel — After Anscombe"); grid on;

subplot(2,2,2); scatter(mv_G1A, vv_G1A, 5, 'g', 'filled');
xlabel("Mean"); ylabel("Variance");
title("G1 channel — After Anscombe"); grid on;

subplot(2,2,3); scatter(mv_G2A, vv_G2A, 5, 'g', 'filled');
xlabel("Mean"); ylabel("Variance");
title("G2 channel — After Anscombe"); grid on;

subplot(2,2,4); scatter(mv_BA, vv_BA, 5, 'b', 'filled');
xlabel("Mean"); ylabel("Variance");
title("B channel — After Anscombe"); grid on;

%% Task 8 - Applying the sliding DCT filter to all channels 

disp("Task 8 started OK")

patchSize = 8;
step      = 4;


% threshold factor (paper uses 3σ and also visually it had the best result)
k_raw = 3.0;   % lambda = k * sigma

% estimate a typical signal level per channel 
mu_R_nat  = mean(R_nat(:));
mu_G1_nat = mean(G1_nat(:));
mu_G2_nat = mean(G2_nat(:));
mu_B_nat  = mean(B_nat(:));

% from variance = a*mean + b  ⇒  sigma = sqrt(a*mu + b)
sigma_R_nat  = sqrt(a_R  * mu_R_nat  + b_R);
sigma_G1_nat = sqrt(a_G1 * mu_G1_nat + b_G1);
sigma_G2_nat = sqrt(a_G2 * mu_G2_nat + b_G2);
sigma_B_nat  = sqrt(a_B  * mu_B_nat  + b_B);

% DCT denoising per subchannel 
R_nat_d  = dct_denoise_channel(R_nat,  sigma_R_nat,  k_raw, patchSize, step);
G1_nat_d = dct_denoise_channel(G1_nat, sigma_G1_nat, k_raw, patchSize, step);
G2_nat_d = dct_denoise_channel(G2_nat, sigma_G2_nat, k_raw, patchSize, step);
B_nat_d  = dct_denoise_channel(B_nat,  sigma_B_nat,  k_raw, patchSize, step);

% Recombine Bayer channels into a full-size RAW mosaic
[m2,n2] = size(R_nat);                 
nat_raw_combined     = zeros(2*m2, 2*n2);
nat_raw_combined_dct = zeros(2*m2, 2*n2);

% Original natural RAW mosaic
nat_raw_combined(1:2:end, 1:2:end) = R_nat;
nat_raw_combined(1:2:end, 2:2:end) = G1_nat;
nat_raw_combined(2:2:end, 1:2:end) = G2_nat;
nat_raw_combined(2:2:end, 2:2:end) = B_nat;

% DCT-denoised natural RAW mosaic
nat_raw_combined_dct(1:2:end, 1:2:end) = R_nat_d;
nat_raw_combined_dct(1:2:end, 2:2:end) = G1_nat_d;
nat_raw_combined_dct(2:2:end, 1:2:end) = G2_nat_d;
nat_raw_combined_dct(2:2:end, 2:2:end) = B_nat_d;


% --- NATURAL IMAGE AFTER ANSCOMBE TRANSFORM ---

% After Anscombe, variance should be ≈ 1 (Task 7)
sigma_A = 1.0;
k_A     = 3.0;


% % DCT denoising in Anscombe domain
R_nat_A_d  = dct_denoise_channel(R_nat_A,  sigma_A, k_A, patchSize, step);
G1_nat_A_d = dct_denoise_channel(G1_nat_A, sigma_A, k_A, patchSize, step);
G2_nat_A_d = dct_denoise_channel(G2_nat_A, sigma_A, k_A, patchSize, step);
B_nat_A_d  = dct_denoise_channel(B_nat_A,  sigma_A, k_A, patchSize, step);


% Recombine Anscombe-domain channels into full-size mosaics
nat_A_combined     = zeros(2*m2, 2*n2);
nat_A_combined_dct = zeros(2*m2, 2*n2);

% Original Anscombe-domain mosaic
nat_A_combined(1:2:end, 1:2:end) = R_nat_A;
nat_A_combined(1:2:end, 2:2:end) = G1_nat_A;
nat_A_combined(2:2:end, 1:2:end) = G2_nat_A;
nat_A_combined(2:2:end, 2:2:end) = B_nat_A;

% DCT-denoised Anscombe-domain mosaic
nat_A_combined_dct(1:2:end, 1:2:end) = R_nat_A_d;
nat_A_combined_dct(1:2:end, 2:2:end) = G1_nat_A_d;
nat_A_combined_dct(2:2:end, 1:2:end) = G2_nat_A_d;
nat_A_combined_dct(2:2:end, 2:2:end) = B_nat_A_d;


% Visualization: choose the best λ (k)
disp("Reached plotting section for Task 8")

figure;
subplot(1,2,1); imshow(nat_raw_combined, []);     
title("Natural RAW combined");
subplot(1,2,2); imshow(nat_raw_combined_dct, []); 
title(sprintf("Natural RAW DCT denoised (k = %.1f)", k_raw));

figure;
subplot(1,2,1); imshow(nat_A_combined, []);       
title("Natural Anscombe combined");
subplot(1,2,2); imshow(nat_A_combined_dct, []);   
title(sprintf("Anscombe DCT denoised (k = %.1f)", k_A));

%% Task 9: Apply Inverse Transform

% Natural image Anscombe-domain
R_nat_rec  = inverse_anscombe(R_nat_A_d,  a_R,  b_R);
G1_nat_rec = inverse_anscombe(G1_nat_A_d, a_G1, b_G1);
G2_nat_rec = inverse_anscombe(G2_nat_A_d, a_G2, b_G2);
B_nat_rec  = inverse_anscombe(B_nat_A_d,  a_B,  b_B);

% Recombine reconstructed channels into a full-size RAW mosaic
[m2,n2] = size(R_nat_rec);
nat_A_inv_combined = zeros(2*m2, 2*n2);

nat_A_inv_combined(1:2:end, 1:2:end) = R_nat_rec;
nat_A_inv_combined(1:2:end, 2:2:end) = G1_nat_rec;
nat_A_inv_combined(2:2:end, 1:2:end) = G2_nat_rec;
nat_A_inv_combined(2:2:end, 2:2:end) = B_nat_rec;

%% Task 10 Compare
% Visualization
figure;
subplot(1,2,1); imshow(nat_raw_combined_dct, []); 
title('Raw DCT denoised (D)');

subplot(1,2,2); imshow(nat_A_inv_combined, []); 
title('Inverse Anscombe DCT denoised');
drawnow;
sgtitle('Task 10: Comparison between Raw and Variance Transformed DCT Denoising');

%% Task 11: Simple Demosaicing using interp2

% For the original natural image (raw domain)
[R_nat_full, G_nat_full, B_nat_full] = simple_demosaic_1(R_nat, G1_nat, G2_nat, B_nat);

% For the DCT-denoised raw image
[R_nat_d_full, G_nat_d_full, B_nat_d_full] = simple_demosaic_1(R_nat_d, G1_nat_d, G2_nat_d, B_nat_d);

% For the inverse Anscombe (reconstructed) image
[R_nat_rec_full, G_nat_rec_full, B_nat_rec_full] = simple_demosaic_1(R_nat_rec, G1_nat_rec, G2_nat_rec, B_nat_rec);

% Create RGB images (normalize to [0,1] range)
rgb_nat = cat(3, R_nat_full, G_nat_full, B_nat_full);
rgb_nat = rgb_nat / max(rgb_nat(:));

rgb_nat_dct = cat(3, R_nat_d_full, G_nat_d_full, B_nat_d_full);
rgb_nat_dct = rgb_nat_dct / max(rgb_nat_dct(:));

rgb_nat_anscombe = cat(3, R_nat_rec_full, G_nat_rec_full, B_nat_rec_full);
rgb_nat_anscombe = rgb_nat_anscombe / max(rgb_nat_anscombe(:));

% Visualization
figure;

subplot(1,2,1); imshow(rgb_nat_dct); 
title('Raw DCT Denoised (Demosaiced)');

subplot(1,2,2); imshow(rgb_nat_anscombe); 
title('Anscombe Denoised (Demosaiced)');

sgtitle('Task 11: Simple Demosaicing Results');
drawnow;

%% Task 12: White Balancing

function rgb_wb = white_balance_by_maxV_HSV(rgb)
% White balance using the pixel with maximum V in HSV space

rgb = im2double(rgb);

% 1) Convert to HSV
hsvImg = rgb2hsv(rgb);
V = hsvImg(:,:,3);

% 2) Find pixel with maximum V
[~, idx] = max(V(:));
[row, col] = ind2sub(size(V), idx);

% 3) Reference RGB at that pixel
refR = rgb(row,col,1);
refG = rgb(row,col,2);
refB = rgb(row,col,3);

% Avoid divide-by-zero
refR = max(refR, eps);
refG = max(refG, eps);
refB = max(refB, eps);

% 4) Divide each channel by reference values
R2 = rgb(:,:,1) ./ refR;
G2 = rgb(:,:,2) ./ refG;
B2 = rgb(:,:,3) ./ refB;

% 5) Recombine and normalize/clamp
rgb_wb = cat(3, R2, G2, B2);
rgb_wb = rgb_wb ./ max(rgb_wb(:)); 
rgb_wb = min(max(rgb_wb, 0), 1);

end

% Apply per-image white balance
rgb_nat_wb       = white_balance_by_maxV_HSV(rgb_nat);
rgb_nat_dct_wb   = white_balance_by_maxV_HSV(rgb_nat_dct);
rgb_nat_ans_wb   = white_balance_by_maxV_HSV(rgb_nat_anscombe);

figure;
subplot(1,2,1); imshow(rgb_nat_dct_wb); 
title('Raw DCT - White Balanced');
subplot(1,2,2); imshow(rgb_nat_ans_wb); 
title('Variance Transformed - White Balanced');

sgtitle('Task 12: White Balancing Results');
drawnow;

%% Task 13 Contrast and Saturation

images = {rgb_nat_dct, rgb_nat_anscombe};           
wb_images = {rgb_nat_dct_wb, rgb_nat_ans_wb};    

n = numel(wb_images);
names = {'Raw DCT denoised', 'Anscombe Transformed'};

% Parameters you can tweak:
sat_factor = 1.25;    
gamma_val  = 0.7;     

% Containers for results
hsv_corrected = cell(1,n);

figure;
hold on;

for k=1:n    
    rgb = wb_images{k};
    if isempty(rgb), continue; end
    
    rgb = im2double(rgb);
    rgb = min(max(rgb,0),1);

    gb_adjusted = zeros(size(rgb));
    for c=1:3
        rgb_adjusted(:,:,c) = imadjust(rgb(:,:,c), stretchlim(rgb(:,:,c),0.01), []);
    end
    rgb_adjusted = min(max(rgb_adjusted,0),1);
   
    
    % 1) Convert to HSV
    hsv = rgb2hsv(rgb_adjusted);

    hsv(:,:,2) = hsv(:,:,2) * 1.8;   
    hsv(:,:,2) = min(hsv(:,:,2), 1);

    H = hsv(:,:,1);
    S = hsv(:,:,2);
    V = hsv(:,:,3);

    % Histogram Equilization
    V2 = histeq(V);

    % Gamma correction on luminance
    V2 = V2 .^ gamma_val;
    
    % Saturation boost
    S2 = S * sat_factor;
    S2 = min(max(S2,0),1);
    
    hsv2 = cat(3, H, S2, V2);
    rgb_hsv_corr = hsv2rgb(hsv2);
    rgb_hsv_corr = min(max(rgb_hsv_corr,0),1);
    hsv_corrected{k} = rgb_hsv_corr;

    subplot(1,2,k); imshow(hsv_corrected{k}); 
    title(names{k});
    
end

sgtitle('Task 13 : Contrast & Saturation Corrections Results');
hold off;


%% Functions

function overlay = make_cfa_visualization(raw_in, pattern, alpha)

    vis_raw = raw_in / max(raw_in(:));  

    [m,n] = size(raw_in);

    overlay = zeros(m,n,3);

    % Use vis_raw to generate the overlay
    for i = 1:m
        for j = 1:n

            c = pattern(mod(i-1,2)+1, mod(j-1,2)+1);

            switch c
                case "R", color = [1 0 0];
                case "G", color = [0 1 0];
                case "B", color = [0 0 1];
            end

            overlay(i,j,:) = vis_raw(i,j) * color;
        end
    end

    % Blending with grayscale visualization
    if alpha < 1
        gray = repmat(vis_raw,1,1,3);
        overlay = (1-alpha)*gray + alpha*overlay;
    end
end



function out = compute_stats(block, mode)
    if nargin == 1 || mode == "mean"
        out = mean(block(:));
    else
        out = var(block(:));
    end
end


function I_transformed = apply_anscombe_transform(Ic, a, b)
    
    I_transformed = 2 * sqrt(Ic./a + 3/8 + b/(a^2));
end


function out = dct_denoise_channel(I, sigma, k, patchSize, step)
% DCT denoising (Yu & Sapiro-style) for a single channel.
% I      : input (one Bayer subchannel)
% sigma  : estimated noise std of this channel
% k      : threshold factor (paper uses k = 3 → 3σ)

    if nargin < 4, patchSize = 8; end
    if nargin < 5, step      = 4; end 

    [m,n] = size(I);
    out   = zeros(m,n);
    count = zeros(m,n);

    lambda = k * sigma;

    for i = 1:step:m-patchSize+1
        for j = 1:step:n-patchSize+1
            patch = I(i:i+patchSize-1, j:j+patchSize-1);

            C = dct2(patch);
            C(abs(C) < lambda) = 0;       % hard threshold
            patch_d = idct2(C);

            out(i:i+patchSize-1, j:j+patchSize-1)   = out(i:i+patchSize-1, j:j+patchSize-1) + patch_d;
            count(i:i+patchSize-1, j:j+patchSize-1) = count(i:i+patchSize-1, j:j+patchSize-1) + 1;
        end
    end

    count(count == 0) = 1;  
    out = out ./ count;
end


function I_rec = inverse_anscombe(D, a, b)

    s  = sqrt(3/2);

    term = (1/4)*(D.^2) + ...
           (1/4)*s*(D.^(-1)) - ...
           (11/8)*(D.^(-2)) + ...
           (5/8)*s*(D.^(-3)) - ...
           (1/8) ...
           - b/(a^2);

    I_rec = a * term;

    I_rec(I_rec < 0) = 0;
end


function [R_full, G_full, B_full] = simple_demosaic_1(R, G1, G2, B)
    [m2, n2] = size(R);
    m = 2*m2; n = 2*n2;

    % Subchannel sample coordinates
    xR = 1:2:n;    yR = 1:2:m;    % R at (1,1)
    xG1 = 2:2:n;   yG1 = 1:2:m;   % G1 at (1,2)
    xG2 = 1:2:n;   yG2 = 2:2:m;   % G2 at (2,1)
    xB = 2:2:n;    yB = 2:2:m;    % B at (2,2)

    [Xq, Yq] = meshgrid(1:n, 1:m);

    [XR, YR]   = meshgrid(xR,  yR);
    [XG1, YG1] = meshgrid(xG1, yG1);
    [XG2, YG2] = meshgrid(xG2, yG2);
    [XB, YB]   = meshgrid(xB,  yB);

    % Linear interpolation
    R_lin  = interp2(XR, YR, R,  Xq, Yq, 'linear');
    B_lin  = interp2(XB, YB, B,  Xq, Yq, 'linear');
    G1_lin = interp2(XG1, YG1, G1, Xq, Yq, 'linear');
    G2_lin = interp2(XG2, YG2, G2, Xq, Yq, 'linear');

    % Nearest interpolation as fallback
    R_near  = interp2(XR, YR, R,  Xq, Yq, 'nearest');
    B_near  = interp2(XB, YB, B,  Xq, Yq, 'nearest');
    G1_near = interp2(XG1, YG1, G1, Xq, Yq, 'nearest');
    G2_near = interp2(XG2, YG2, G2, Xq, Yq, 'nearest');

    R_full  = R_lin;  R_full(isnan(R_full))  = R_near(isnan(R_full));
    B_full  = B_lin;  B_full(isnan(B_full))  = B_near(isnan(B_full));
    G1_full = G1_lin; G1_full(isnan(G1_full)) = G1_near(isnan(G1_full));
    G2_full = G2_lin; G2_full(isnan(G2_full)) = G2_near(isnan(G2_full));

    % Average the two green estimates
    G_full = (G1_full + G2_full) / 2;
 
end